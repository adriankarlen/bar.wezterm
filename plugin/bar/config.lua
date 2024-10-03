local wez = require "wezterm"
local utilities = require "bar.utilities"

local M = {}

M.options = {
  position = "bottom",
  max_width = 32,
  padding = {
    left = 1,
    right = 1,
  },
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
    spotify = {
      enabled = false,
      icon = wez.nerdfonts.fa_spotify,
      color = 3,
      max_width = 64,
      throttle = 15,
    },
  },
}

function M.extend_options(default, options)
  return utilities._merge(default, options)
end

return M
