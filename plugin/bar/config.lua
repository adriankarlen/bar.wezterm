local wez = require "wezterm"
local utilities = require "bar.utilities"

---@class bar.config
local M = {}

---@class option.separator
---@field space number
---@field left_icon string
---@field right_icon string
---@field field_icon string

---@class option.tabs
---@field active_tab_fg number
---@field inactive_tab_fg number

---@class option.module
---@field enabled boolean
---@field icon string
---@field color number

---@class option.spotify : option.module
---@field max_width number
---@field throttle number

---@class option.modules
---@field tabs option.tabs
---@field workspace option.module
---@field leader option.module
---@field pane option.module
---@field username option.module
---@field hostname option.module
---@field clock option.module
---@field cwd option.module
---@field spotify option.spotify

---@class bar.options
---@field position "top" | "bottom"
---@field max_width number
---@field separator option.separator
---@field modules option.modules
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

---@param default bar.options
---@param options bar.options
---@return bar.options
function M.extend_options(default, options)
  return utilities._merge(default, options)
end

return M
