local wez = require "wezterm"

local config = {
  position = "bottom",
  max_width = 32,
  separator = {
    space = 1,
    left_icon = wez.nerdfonts.fa_long_arrow_right,
    right_icon = wez.nerdfonts.fa_long_arrow_left,
    field_icon = wez.nerdfonts.indent_line,
  },
  modules = {
    tabs = {
      active_tab_fg = 4,
      inactive_tab_fg = 6,
    },
    workspace = {
      enabled = true,
      icon = wez.nerdfonts.cod_window,
      color = 8,
    },
    leader = {
      enabled = true,
      icon = wez.nerdfonts.oct_rocket,
      color = 2,
    },
    pane = {
      enabled = true,
      icon = wez.nerdfonts.cod_multiple_windows,
      color = 7,
    },
    username = {
      enabled = true,
      icon = wez.nerdfonts.fa_user,
      color = 6,
    },
    hostname = {
      enabled = true,
      icon = wez.nerdfonts.cod_server,
      color = 8,
    },
    clock = {
      enabled = true,
      icon = wez.nerdfonts.md_calendar_clock,
      color = 5,
    },
    cwd = {
      enabled = true,
      icon = wez.nerdfonts.oct_file_directory,
      color = 7,
    },
  },
}

local username = os.getenv "USER" or os.getenv "LOGNAME" or os.getenv "USERNAME"
local home = (os.getenv "USERPROFILE" or os.getenv "HOME" or wez.home_dir or ""):gsub("\\", "/")
local is_windows = package.config:sub(1, 1) == "\\"

local M = {}

-- get basename for dir/file, removing ft and path
local _basename = function(s)
  if type(s) ~= "string" then
    return nil
  end
  return s:gsub("(.*[/\\])(.*)%.(.*)", "%2")
end

-- add spaces to each side of a string
local _space = function(s, space, trailing_space)
  if type(s) ~= "string" or type(space) ~= "number" then
    return ""
  end
  local spaces = string.rep(" ", space)
  local trailing_spaces = spaces
  if trailing_space ~= nil then
    trailing_spaces = string.rep(" ", trailing_space)
  end
  return spaces .. s .. trailing_spaces
end

-- trim string from trailing spaces and newlines
local function _trim(s)
  return s:match "^%s*(.-)%s*$"
end

-- merges two tables
local function _merge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        _merge(t1[k] or {}, t2[k] or {})
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

-- get tab title
local function get_tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return _basename(tab_info.active_pane.title)
end

-- get leader icon/string if make it occupy the space of the workspace name
local get_leader = function(prev)
  local leader = config.modules.leader.icon
  local spacing = #prev - #leader
  local first_half = math.floor(spacing / 2)
  local second_half = math.ceil(spacing / 2)
  return _space(leader, first_half, second_half)
end

-- conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
M.apply_to_config = function(c, opts)
  -- make the opts arg optional
  if not opts then
    opts = {}
  end

  -- combine user config with defaults
  config = _merge(config, opts)

  local scheme = wez.color.get_builtin_schemes()[c.color_scheme]
  local default_colors = {
    tab_bar = {
      background = "transparent",
      active_tab = {
        bg_color = "transparent",
        fg_color = scheme.ansi[config.modules.tabs.active_tab_fg],
      },
      inactive_tab = {
        bg_color = "transparent",
        fg_color = scheme.ansi[config.modules.tabs.inactive_tab_fg],
      },
    },
  }

  if c.colors == nil then
    c.colors = default_colors
  else
    c.colors = _merge(default_colors, c.colors)
  end

  -- make the plugin own these settings
  c.use_fancy_tab_bar = false
  c.tab_bar_at_bottom = config.position == "bottom"
  c.tab_max_width = config.max_width
end

wez.on("format-tab-title", function(tab, _, _, conf, _, _)
  local palette = conf.resolved_palette

  local index = tab.tab_index + 1
  local offset = #tostring(index) + #config.separator.left_icon + (2 * config.separator.space) + 2
  local title = index .. _space(config.separator.left_icon, config.separator.space, nil) .. get_tab_title(tab)

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
    { Text = _space(title, 0, 2) },
  }
end)

-- Name of workspace
wez.on("update-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  local palette = conf.resolved_palette

  -- left status
  local left_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  if config.modules.workspace.enabled then
    local stat = " " .. config.modules.workspace.icon .. " " .. window:active_workspace() .. " "
    local stat_fg = palette.ansi[config.modules.workspace.color]

    if window:leader_is_active() then
      stat_fg = palette.ansi[config.modules.leader.color]
      stat = get_leader(stat)
    end

    table.insert(left_cells, { Foreground = { Color = stat_fg } })
    table.insert(left_cells, { Text = stat })
  end

  if config.modules.pane.enabled then
    local process = pane:get_foreground_process_name()
    if not process then
      goto set_left_status
    end
    table.insert(left_cells, { Foreground = { Color = palette.ansi[config.modules.pane.color] } })
    table.insert(left_cells, { Text = config.modules.pane.icon .. " " .. _basename(process) .. " " })
  end

  ::set_left_status::
  window:set_left_status(wez.format(left_cells))

  -- right status
  local right_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  if config.modules.username.enabled then
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.modules.username.color] } })
    table.insert(right_cells, { Text = username })
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(right_cells, {
      Text = _space(config.separator.right_icon, config.separator.space, nil)
        .. config.modules.username.icon
        .. _space(config.separator.field_icon, config.separator.space, nil),
    })
  end

  local cwd, hostname = get_cwd_hostname(pane, true)
  if config.modules.hostname.enabled then
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.modules.hostname.color] } })
    table.insert(right_cells, { Text = hostname })
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(right_cells, {
      Text = _space(config.separator.right_icon, config.separator.space, nil)
        .. config.modules.hostname.icon
        .. _space(config.separator.field_icon, config.separator.space, nil),
    })
  end

  if config.modules.clock.enabled then
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.modules.clock.color] } })
    table.insert(right_cells, { Text = wez.time.now():format "%H:%M" })
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(
      right_cells,
      { Text = _space(config.separator.right_icon, config.separator.space, nil) .. config.modules.clock.icon .. "  " }
    )
  end

  if config.modules.cwd.enabled then
    table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(right_cells, { Text = config.modules.cwd.icon .. " " })
    table.insert(right_cells, { Foreground = { Color = palette.ansi[config.modules.cwd.color] } })
    table.insert(right_cells, { Text = cwd .. " " })
  end

  window:set_right_status(wez.format(right_cells))
end)

return M
