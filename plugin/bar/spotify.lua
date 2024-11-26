local wez = require "wezterm"
local utilities = require "bar.utilities"

---@private
---@class bar.spotify
local M = {}

local last_update = 0
local stored_playback = ""

---format spotify playback, to handle max_width nicely
---@param pb string
---@param max_width number
---@return string
local format_playback = function(pb, max_width)
  if #pb <= max_width then
    return pb
  end

  -- split on " - "
  local artist, track = pb:match "^(.-) %- (.+)$"
  -- get artist before first ","
  local pb_main_artist = artist:match "([^,]+)" .. " - " .. track
  if #pb_main_artist <= max_width then
    return pb_main_artist
  end

  -- fallback, return track name (trimmed to max width)
  return track:sub(1, max_width)
end

---gets the currently playing song from spotify
---@param max_width number
---@param throttle number
---@return string
M.get_currently_playing = function(max_width, throttle)
  if utilities._wait(throttle, last_update) then
    return stored_playback
  end
  -- fetch playback using spotify-tui
  local success, pb, stderr = wez.run_child_process { "spt", "pb", "--format", "%a - %t" }
  if not success then
    wez.log_error(stderr)
    return ""
  end
  local res = format_playback(utilities._trim(pb), max_width)
  stored_playback = res
  last_update = os.time()

  return res
end

return M
