---@private
---@class bar.user
local M = {}

---@type string?
M.username = os.getenv "USER" or os.getenv "LOGNAME" or os.getenv "USERNAME"

return M
