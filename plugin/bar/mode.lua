local M = {}

---Return active key table mode as a user friendly name
---@param window table
---@return string
M.get_mode = function(window)
  local key_table = window:active_key_table()
  if not key_table then
    return ""
  end
  if key_table == "copy_mode" then
    return "copy"
  end
  return key_table
end

return M