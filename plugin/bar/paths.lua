local wez = require "wezterm"
local utilities = require "bar.utilities"

local M = {}

local find_git_dir = function(directory)
  directory = directory:gsub("~", utilities.home)

  while directory do
    local handle = io.open(directory .. "/.git/HEAD", "r")
    if handle then
      handle:close()
      directory = directory:match "([^/]+)$"
      return directory
    elseif directory == "/" or directory == "" then
      break
    else
      directory = directory:match "(.+)/[^/]*"
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
      ---@diagnostic disable-next-line: undefined-field
      hostname = cwd_uri.host or wez.hostname()
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find "/"
      if slash then
        hostname = cwd_uri:sub(1, slash - 1)
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    -- Remove the domain name portion of the hostname
    local dot = hostname:find "[.]"
    if dot then
      hostname = hostname:sub(1, dot - 1)
    end
    if hostname == "" then
      hostname = wez.hostname()
    end

    if utilities.is_windows then
      cwd = cwd:gsub("/" .. utilities.home .. "(.-)$", "~%1")
    else
      cwd = cwd:gsub(utilities.home .. "(.-)$", "~%1")
    end

    ---search for the git root of the project if specified
    if search_git_root_instead then
      local git_root = find_git_dir(cwd)
      cwd = git_root or cwd ---fallback to cwd
    end
  end

  return cwd, hostname
end
return M
