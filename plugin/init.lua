local wezterm = require "wezterm"
local utils = require "utils"

local config = {
  position = "bottom",
  max_width = 32,
  left_separator = "  ",
  right_separator = "  ",
  field_separator = "  |  ",
  workspace_icon = "",
  pane_icon = "",
  user_icon = "",
  hostname_icon = "󰒋",
  clock_icon = "󰃰",
  cwd_icon = "",
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

wezterm.on("format-tab-title", function(tab, _, _, conf, _, max_width)
  local palette = conf.resolved_palette
  local index = tab.tab_index + 1
  local title = ""

  if tab.is_active then
    title = index .. config.left_separator .. tab_title(tab) .. "  "
  else
    title = index .. " "
  end

  if #title > max_width then
    print("title too long", #title, max_width)
    local diff = #title - max_width
    title = title:sub(1, #title - diff - 3) .. "..."
  end

  return {
    { Background = { Color = palette.background } },
    { Foreground = { Color = palette.ansi[4] } },
    { Text = title },
  }
end)

-- Name of workspace
wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = " " .. config.workspace_icon .. " " .. window:active_workspace() .. " "
  local pane_title = pane:get_title()
  local tty = pane:get_tty_name()
  if tty then
    pane_title = tty
  end

  local conf = utils.get_conf(window)
  ---@diagnostic disable-next-line: need-check-nil
  local palette = conf.resolved_palette
  local stat_fg = palette.tab_bar.active_tab.fg_color

  if window:leader_is_active() then
    stat_fg = palette.ansi[2]
    stat = " leader "
  end

  window:set_left_status(wezterm.format {
    { Foreground = { Color = stat_fg } },
    { Text = stat },

    { Foreground = { Color = palette.ansi[7] } },
    { Text = config.pane_icon .. " " .. pane_title .. " " },
  })
end)

wezterm.on("update-right-status", function(window, pane)
  local conf = utils.get_conf(window)
  ---@diagnostic disable-next-line: need-check-nil
  local palette = conf.resolved_palette
  local username = io.popen("whoami"):read("*a"):gsub("\n", "")

  local time = wezterm.time.now():format "%H:%M"
  local cwd, hostname = utils.get_cwd_hostname(pane, true)

  window:set_right_status(wezterm.format {
    { Foreground = { Color = palette.ansi[6] } },
    { Text = username },

    { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } },
    { Text = config.right_separator .. config.user_icon .. config.field_separator },

    { Foreground = { Color = palette.ansi[8] } },
    { Text = hostname },

    { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } },
    { Text = config.right_separator .. config.hostname_icon .. config.field_separator },

    { Foreground = { Color = palette.ansi[5] } },
    { Text = time },

    { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } },
    { Text = config.right_separator .. config.clock_icon .. "  " },

    { Foreground = { Color = palette.tab_bar.inactive_tab.fg_color } },
    { Text = config.cwd_icon .. " " },

    { Foreground = { Color = palette.ansi[7] } },
    { Text = cwd .. " " },
  })
end)

return M
