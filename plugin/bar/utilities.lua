local wez = require "wezterm"

---@private
---@class bar.utilities
local H = {}

---@type string
H.home = (os.getenv "USERPROFILE" or os.getenv "HOME" or wez.home_dir or ""):gsub("\\", "/")

---@type boolean
H.is_windows = package.config:sub(1, 1) == "\\"

---waits for a specified throttle time before proceeding.
---@param throttle number
---@param last_update number
---@return boolean
H._wait = function (throttle, last_update)
  local current_time = os.time()
  return current_time - last_update < throttle
end

---get basename for dir/file, removing ft and path
---@param s string
---@return string?
---@return number?
H._basename = function(s)
  if type(s) ~= "string" then
    return nil
  end
  local name = s:match("[^/\\]*$")  -- match everything after the last / or \
  if name then
    return name:gsub("%.%w+$", "")  -- remove extension if present
  end
  return nil
end

---add spaces to each side of a string
---@param s string
---@param space number
---@param trailing_space number
---@return string
H._space = function(s, space, trailing_space)
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

---trim string from trailing spaces and newlines
---@param s string
---@return string
H._trim = function(s)
  return s:match "^%s*(.-)%s*$"
end

---merges two tables
---@param t1 table
---@param t2 table
---@return table
function H._merge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        H._merge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

---return string with spacing adjusted to prev string
---@param prev string
---@param next string
---@return string
H._constant_width = function(prev, next)
  local spacing = #prev - #next
  local first_half = math.floor(spacing / 2)
  local second_half = math.ceil(spacing / 2)
  return H._space(next, first_half, second_half)
end

return H
