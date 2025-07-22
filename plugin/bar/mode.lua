local M = {}

--- Return active mode
---@param window window  
---@return string
M.get_mode = function(window)
    local key_table = window:active_key_table()
    if not key_table then
        return "default"
    end
    if key_table == "copy_mode" then
        return "copy"
        -- TODO: CHECK MODES AND UPDATE
        -- elseif key_table == "paste_mode" then
        --     return "paste"
        -- elseif key_table == "command_mode" then
        --     return "command"
        -- elseif key_table == "search_mode" then
        --     return "search"
        -- elseif key_table == "resize_mode" then
        --     return "resize"
        -- elseif key_table == "scroll_mode" then
        --     return "scroll"
    end

    return key_table
end

return M
