---@private
---@class bar.rules
local M = {}

---@class option.rule
---@field domain? string|table|fun(name: string): boolean
---@field cwd? string|table|fun(path: string): boolean
---@field active_tab_fg number|string|nil
---@field active_tab_bg number|string|nil
---@field inactive_tab_fg number|string|nil
---@field inactive_tab_bg number|string|nil
---@field icon string|nil

---properties a rule may override, in no particular order
---@type string[]
M.overridable = {
  "active_tab_fg",
  "active_tab_bg",
  "inactive_tab_fg",
  "inactive_tab_bg",
  "icon",
}

---fields a rule may match on, checked in this order
---@type string[]
M.matchable = {
  "domain",
  "cwd",
}

---tests one matcher against a context value, never raising
---@param matcher string|table|fun(name: string): boolean|nil
---@param value string|nil
---@return boolean
M.matches = function(matcher, value)
  if type(value) ~= "string" then
    return false
  end

  local kind = type(matcher)

  if kind == "string" then
    return matcher == value
  end

  if kind == "function" then
    local ok, result = pcall(matcher, value)
    if not ok then
      return false
    end
    return result ~= false and result ~= nil
  end

  if kind == "table" and type(matcher.pattern) == "string" then
    local ok, result = pcall(string.match, value, matcher.pattern)
    return ok and result ~= nil
  end

  return false
end

---normalises whatever a pane reports as its working directory into a plain
---path. accepts a Url object carrying a decoded file_path, a legacy
---file:// URI string, or anything else. never raises.
---@param value any
---@return string|nil
M.extract_path = function(value)
  if type(value) == "table" or type(value) == "userdata" then
    local ok, path = pcall(function()
      return value.file_path
    end)
    if ok and type(path) == "string" and #path > 0 then
      return path
    end
    return nil
  end

  if type(value) ~= "string" or value:sub(1, 7) ~= "file://" then
    return nil
  end

  -- strip the scheme, then take everything from the first slash, which is
  -- where the host ends and the path begins
  local rest = value:sub(8)
  local slash = rest:find "/"
  if not slash then
    return nil
  end

  local path = rest:sub(slash):gsub("%%(%x%x)", function(hex)
    local code = tonumber(hex, 16)
    if not code then
      return "-"
    end
    return string.char(code)
  end)

  return path
end

---reports whether any rule carries a matcher for the named field, so a
---caller can skip computing a value nothing will test
---@param rule_list option.rule[]|nil
---@param field string
---@return boolean
M.uses = function(rule_list, field)
  if type(rule_list) ~= "table" then
    return false
  end

  for _, rule in ipairs(rule_list) do
    if type(rule) == "table" and rule[field] ~= nil then
      return true
    end
  end

  return false
end

---accumulates overrides from every rule matching the context, in list order.
---a rule applies when every field it names matches; a rule naming no field
---matches nothing.
---@param rule_list option.rule[]|nil
---@param context table|nil
---@return table
M.resolve = function(rule_list, context)
  local overrides = {}

  if type(rule_list) ~= "table" then
    return overrides
  end

  local ctx = type(context) == "table" and context or {}

  for _, rule in ipairs(rule_list) do
    if type(rule) ~= "table" then
      goto continue
    end

    local tested = false
    for _, field in ipairs(M.matchable) do
      if rule[field] ~= nil then
        if not M.matches(rule[field], ctx[field]) then
          goto continue
        end
        tested = true
      end
    end

    if not tested then
      goto continue
    end

    for _, key in ipairs(M.overridable) do
      local value = rule[key]
      if value ~= nil and (key ~= "icon" or type(value) == "string") then
        overrides[key] = value
      end
    end

    ::continue::
  end

  return overrides
end

return M
