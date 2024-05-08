local wez = require "wezterm"

local config = {
  position = "bottom",
  max_width = 32,
  left_separator = " -> ",
  right_separator = " <- ",
  field_separator = "  |  ",
  workspace_icon = "",
  pane_icon = "",
  user_icon = "",
  hostname_icon = "󰒋",
  clock_icon = "󰃰",
  cwd_icon = "",
  enabled_modules = {
    username = true,
    hostname = true,
    clock = true,
    cwd = true,
  },
}

local M = {}

local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

local function tableMerge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        tableMerge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

local home = (os.getenv "USERPROFILE" or os.getenv "HOME" or wez.home_dir or ""):gsub("\\", "/")

local is_windows = package.config:sub(1, 1) == "\\"

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

-- conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
-- exporting an apply_to_config function, even though we don't change the users config
M.apply_to_config = function(c, opts)
  -- make the opts arg optional
  if not opts then
    opts = {}
  end

  -- combine user config with defaults
  config = tableMerge(config, opts)

  c.use_fancy_tab_bar = false
  c.tab_bar_at_bottom = config.position == "bottom"
  c.tab_max_width = config.max_width
end

wez.on("format-tab-title", function(tab, _, _, conf, _, _)
  local palette = conf.resolved_palette
  local index = tab.tab_index + 1
  local title = index .. config.left_separator .. tab_title(tab) .. "  "
  local fg = palette.ansi[6]

  if tab.is_active then
    fg = palette.ansi[4]
  end

  local fillerwidth = 4 + index
  local width = conf.tab_max_width - fillerwidth - 1
  if (#title + fillerwidth) > conf.tab_max_width then
    title = wez.truncate_right(title, width) .. "…"
  end

  return {
    { Background = { Color = palette.background } },
    { Foreground = { Color = fg } },
    { Text = title },
  }
end)

-- Name of workspace
wez.on("update-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  local palette = conf.resolved_palette

  -- Workspace name
  local stat = " " .. config.workspace_icon .. " " .. window:active_workspace() .. " "
  local stat_fg = palette.tab_bar.active_tab.fg_color

  if window:leader_is_active() then
    stat_fg = palette.ansi[2]
    stat = " leader "
  end

  window:set_left_status(wez.format {
    { Foreground = { Color = stat_fg } },
    { Text = stat },

    { Foreground = { Color = palette.ansi[7] } },
    { Text = config.pane_icon .. " " .. pane:get_title() .. " " },
  })
end)

wez.on("update-right-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end
  local palette = conf.resolved_palette

  local cells = {}
  local enabled_modules = config.enabled_modules

  if enabled_modules.username then
    table.insert(cells, { Foreground = { Color = palette.ansi[6] } })
    table.insert(cells, { Text = io.popen("whoami"):read("*a"):gsub("\n", "") })
    table.insert(cells, { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } })
    table.insert(cells, { Text = config.right_separator .. config.user_icon .. config.field_separator })
  end

  local cwd, hostname = get_cwd_hostname(pane, true)
  if enabled_modules.hostname then
    table.insert(cells, { Foreground = { Color = palette.ansi[8] } })
    table.insert(cells, { Text = hostname })
    table.insert(cells, { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } })
    table.insert(cells, { Text = config.right_separator .. config.hostname_icon .. config.field_separator })
  end

  if enabled_modules.clock then
    table.insert(cells, { Foreground = { Color = palette.ansi[5] } })
    table.insert(cells, { Text = wez.time.now():format "%H:%M" })
    table.insert(cells, { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } })
    table.insert(cells, { Text = config.right_separator .. config.clock_icon .. "  " })
  end

  if enabled_modules.cwd then
    table.insert(cells, { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } })
    table.insert(cells, { Text = config.cwd_icon .. " " })
    table.insert(cells, { Foreground = { Color = palette.ansi[7] } })
    table.insert(cells, { Text = cwd .. " " })
  end

  window:set_right_status(wez.format(cells))
end)

return M
