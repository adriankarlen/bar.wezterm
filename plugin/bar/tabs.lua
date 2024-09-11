local utilities = require "bar.utilities"
local M = {}

-- get tab title
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
