local H = {}

local wez = require "wezterm"

H.home = (os.getenv "USERPROFILE" or os.getenv "HOME" or wez.home_dir or ""):gsub("\\", "/")
H.is_windows = package.config:sub(1, 1) == "\\"

H._wait = function (throttle, last_update)
  local current_time = os.time()
  return current_time - last_update < throttle
end

-- get basename for dir/file, removing ft and path
H._basename = function(s)
  if type(s) ~= "string" then
    return nil
  end
  return s:gsub("(.*[/\\])(.*)%.(.*)", "%2")
end

-- add spaces to each side of a string
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

-- trim string from trailing spaces and newlines
H._trim = function(s)
  return s:match "^%s*(.-)%s*$"
end

-- merges two tables
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

-- return string with spacing adjusted to prev string
H._constant_width = function(prev, next)
  local spacing = #prev - #next
  local first_half = math.floor(spacing / 2)
  local second_half = math.ceil(spacing / 2)
  return H._space(next, first_half, second_half)
end

return H
