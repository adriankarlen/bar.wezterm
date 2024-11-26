local utilities = require "bar.utilities"

---@private
---@class bar.tabs
local M = {}

---@class tabs.tabinfo
---@field tab_title string
---@field active_pane table
---@field active_pane.title string

---get tab titletab_info 
---@param tab_info tabs.tabinfo
---@return string
M.get_title = function(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return utilities._basename(tab_info.active_pane.title)
end
return M
