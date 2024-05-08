local M = {}
local wez = require("wezterm")

M.get_conf = function(window)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end
  return conf
end

---User home directory
---@return string home path to the suer home directory.
M.home = (os.getenv("USERPROFILE") or os.getenv("HOME") or wez.home_dir or ""):gsub(
  "\\",
  "/"
)

M.is_windows = package.config:sub(1, 1) == "\\"

---Will search the git project root directory of the given directory path.
---NOTE: this functions exits purely because calling the following function
---`wezterm.run_child_process({ "git", "rev-parse", "--show-toplevel" })` would cause
---the status bar to blinck every `config.status_update_interval` milliseconds. Moreover
---when changing tab, the status bar wouldn't be drawn.
---
---@param directory string The directory path.
---@return string|nil git_root If found, the `git_root`, else `nil`
M.find_git_dir = function(directory)
  directory = directory:gsub("~", M.home)

  while directory do
    local handle = io.open(directory .. "/.git/HEAD", "r")
    if handle then
      handle:close()
      directory = directory:match("([^/]+)$")
      return directory
    elseif directory == "/" or directory == "" then
      break
    else
      directory = directory:match("(.+)/[^/]*")
    end
  end

  return nil
end

M.get_cwd_hostname = function(pane, search_git_root_instead)
  local cwd, hostname = "", ""
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    if type(cwd_uri) == "userdata" then
      -- Running on a newer version of wezterm and we have
      -- a URL object here, making this simple!

      ---@diagnostic disable-next-line: undefined-field
      cwd = cwd_uri.file_path
      hostname = cwd_uri.host or wez.hostname()
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find("/")
      if slash then
        hostname = cwd_uri:sub(1, slash - 1)
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    -- Remove the domain name portion of the hostname
    local dot = hostname:find("[.]")
    if dot then
      hostname = hostname:sub(1, dot - 1)
    end
    if hostname == "" then
      hostname = wez.hostname()
    end

    if M.is_windows then
      cwd = cwd:gsub("/" .. M.home .. "(.-)$", "~%1")
    else
      cwd = cwd:gsub(M.home .. "(.-)$", "~%1")
    end

    ---search for the git root of the project if specified
    if search_git_root_instead then
      local git_root = M.find_git_dir(cwd)
      cwd = git_root or cwd ---fallback to cwd
    end
  end

  return cwd, hostname
end

return M
