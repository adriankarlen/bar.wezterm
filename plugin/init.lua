local wez = require "wezterm"

local config = {
  position = "bottom",
  max_width = 32,
  separator_space = 1,
  left_separator = wez.nerdfonts.fa_long_arrow_right,
  right_separator = wez.nerdfonts.fa_long_arrow_left,
  field_separator = wez.nerdfonts.indent_line,
  leader_icon = wez.nerdfonts.oct_rocket,
  workspace_icon = wez.nerdfonts.cod_window,
  pane_icon = wez.nerdfonts.cod_multiple_windows,
  user_icon = wez.nerdfonts.fa_user,
  hostname_icon = wez.nerdfonts.cod_server,
  clock_icon = wez.nerdfonts.md_calendar_clock,
  cwd_icon = wez.nerdfonts.oct_file_directory,
  enabled_modules = {
    workspace = true,
    pane = true,
    username = true,
    hostname = true,
    clock = true,
    cwd = true,
  },
  ansi_colors = {
    workspace = 8,
    leader = 2,
    pane = 7,
    active_tab = 4,
    inactive_tab = 6,
    username = 6,
    hostname = 8,
    clock = 5,
    cwd = 7,
  },
}

local username = os.getenv "USER" or os.getenv "LOGNAME" or os.getenv "USERNAME"
local home = (os.getenv "USERPROFILE" or os.getenv "HOME" or wez.home_dir or ""):gsub("\\", "/")
local is_windows = package.config:sub(1, 1) == "\\"

local M = {}

local function table_merge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        table_merge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

local find_git_dir = function(directory)
  directory = directory:gsub("~", home)

  while directory do
    local handle = io.open(directory .. "/.git/HEAD", "r")
    if handle then
      handle:close()
      directory = directory:match "([^/]+)$"
      return directory
    elseif directory == "/" or directory == "" then
      break
    else
      directory = directory:match "(.+)/[^/]*"
    end
  end

  return nil
end

local get_cwd_hostname = function(pane, search_git_root_instead)
  local cwd, hostname = "", ""
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    if type(cwd_uri) == "userdata" then
      -- Running on a newer version of wezterm and we have
      -- a URL object here, making this simple!

      ---@diagnostic disable-next-line: undefined-field
      cwd = cwd_uri.file_path
      ---@diagnostic disable-next-line: undefined-field
      hostname = cwd_uri.host or wez.hostname()
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find "/"
      if slash then
        hostname = cwd_uri:sub(1, slash - 1)
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    -- Remove the domain name portion of the hostname
    local dot = hostname:find "[.]"
    if dot then
      hostname = hostname:sub(1, dot - 1)
    end
    if hostname == "" then
      hostname = wez.hostname()
    end

    if is_windows then
      cwd = cwd:gsub("/" .. home .. "(.-)$", "~%1")
    else
      cwd = cwd:gsub(home .. "(.-)$", "~%1")
    end

    ---search for the git root of the project if specified
    if search_git_root_instead then
      local git_root = find_git_dir(cwd)
      cwd = git_root or cwd ---fallback to cwd
    end
  end

  return cwd, hostname
end

local basename = function(s)
  if type(s) ~= "string" then
    return nil
  end
  return s:gsub("(.*[/\\])(.*)%.(.*)", "%2")
end

local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return basename(tab_info.active_pane.title)
end

local get_leader = function(prev)
  local leader = config.leader_icon
  local spacing = #prev - #leader
  local first_half = math.floor(spacing / 2)
  local second_half = math.ceil(spacing / 2)
  return string.rep(" ", first_half) .. leader .. string.rep(" ", second_half)
end

local with_spaces = function(icon, space)
  if type(icon) ~= "string" or type(space) ~= "number" then
    return ""
  end
  local spaces = string.rep(" ", space)
  return spaces .. icon .. spaces
end

-- conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
-- exporting an apply_to_config function, even though we don't change the users config
M.apply_to_config = function(c, opts)
  -- make the opts arg optional
  if not opts then
    opts = {}
  end

  -- combine user config with defaults
  config = table_merge(config, opts)

  local scheme = wez.color.get_builtin_schemes()[c.color_scheme]
  local default_colors = {
    tab_bar = {
      background = "transparent",
      active_tab = {
        bg_color = "transparent",
        fg_color = scheme.ansi[config.ansi_colors.active_tab],
      },
      inactive_tab = {
        bg_color = "transparent",
        fg_color = scheme.ansi[config.ansi_colors.inactive_tab],
      },
    },
  }

  if c.colors == nil then
    c.colors = default_colors
  else
    c.colors = table_merge(default_colors, c.colors)
  end

  c.use_fancy_tab_bar = false
  c.tab_bar_at_bottom = config.position == "bottom"
  c.tab_max_width = config.max_width
end

wez.on("format-tab-title", function(tab, _, _, conf, _, _)
  local palette = conf.resolved_palette

  local index = tab.tab_index + 1
  local offset = #tostring(index) + #config.left_separator + (2 * config.separator_space) + 2
  wez.log_info(offset)
  local title = index .. with_spaces(config.left_separator, config.separator_space) .. tab_title(tab)

  local width = conf.tab_max_width - offset
  if #title > conf.tab_max_width then
    title = wez.truncate_right(title, width) .. "…"
  end

  local fg = palette.tab_bar.inactive_tab.fg_color
  local bg = palette.tab_bar.inactive_tab.bg_color
  if tab.is_active then
    fg = palette.tab_bar.active_tab.fg_color
    bg = palette.tab_bar.active_tab.bg_color
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = title .. "  " },
  }
end)

-- Name of workspace
wez.on("update-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  local palette = conf.resolved_palette
  local enabled_modules = config.enabled_modules

  -- left status
  local left_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  if enabled_modules.workspace then
    local stat = " " .. config.workspace_icon .. " " .. window:active_workspace() .. " "
    local stat_fg = palette.ansi[config.ansi_colors.workspace]

    if window:leader_is_active() then
      stat_fg = palette.ansi[config.ansi_colors.leader]
      stat = get_leader(stat)
    end

    table.insert(left_cells, { Foreground = { Color = stat_fg } })
    table.insert(left_cells, { Text = stat })
  end

  if enabled_modules.pane then
    local process = pane:get_foreground_process_name()
    if not process then
      goto set_left_status
    end
    table.insert(left_cells, { Foreground = { Color = palette.ansi[config.ansi_colors.pane] } })
    table.insert(left_cells, { Text = config.pane_icon .. " " .. basename(process) .. " " })
  end

  ::set_left_status::
  window:set_left_status(wez.format(left_cells))

  -- right status
  local right_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  if enabled_modules.username then
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.ansi_colors.username] } })
    table.insert(right_cells, { Text = username })
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(right_cells, {
      Text = with_spaces(config.right_separator, config.separator_space)
        .. config.user_icon
        .. with_spaces(config.field_separator, config.separator_space),
    })
  end

  local cwd, hostname = get_cwd_hostname(pane, true)
  if enabled_modules.hostname then
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.ansi_colors.hostname] } })
    table.insert(right_cells, { Text = hostname })
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(right_cells, {
      Text = with_spaces(config.right_separator, config.separator_space)
        .. config.hostname_icon
        .. with_spaces(config.field_separator, config.separator_space),
    })
  end

  if enabled_modules.clock then
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.ansi_colors.clock] } })
    table.insert(right_cells, { Text = wez.time.now():format "%H:%M" })
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(
      right_cells,
      { Text = with_spaces(config.right_separator, config.separator_space) .. config.clock_icon .. "  " }
    )
  end

  if enabled_modules.cwd then
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(right_cells, { Text = config.cwd_icon .. " " })
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.ansi_colors.cwd] } })
    table.insert(right_cells, { Text = cwd .. " " })
  end

  window:set_right_status(wez.format(right_cells))
end)

return M
