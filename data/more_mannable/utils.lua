---@type {[0]: Hyperspace.ShipManager?, [1]: Hyperspace.ShipManager?}
mods.moreMannable.GlobalShips = { [0] = nil, [1] = nil }
script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_MANAGER, function(shipMgr)
    mods.moreMannable.GlobalShips[shipMgr.iShipId] = shipMgr
end)

local Settings = Hyperspace.Settings
local TextMeta = {
    __index = function(texts)
        return texts['']
    end,
    __call = function(texts, ...)
        local success, result = pcall(string.format, texts[Settings.language], ...)
        if success then
            return result
        else
            log("ERROR: " .. result)
            return texts[Settings.language]
        end
    end
}

---@alias Text table<string, string> | fun(...): string
---@param texts table<string, string>
---@return Text
function mods.moreMannable.Text(texts)
    setmetatable(texts, TextMeta)
    return texts
end

local Text = mods.moreMannable.Text
local ErrorMeta = {
    __index = function(_, entry)
        return Text {
            [''] = "ERROR_Text_entry_not_found_[" .. entry .. "]"
        }
    end
}

function mods.moreMannable.TextCollection(default)
    local collection = {}
    if not default then
        setmetatable(collection, ErrorMeta)
    else
        local meta = {
            __index = function() return default end
        }
        setmetatable(collection, meta)
    end
    return collection
end

function mods.moreMannable.vector_to_string(vec, func)
    local s = '['
    for i = 0, vec:size() - 1 do
        if func then
            s = s .. func(vec[i]) .. ','
        else
            s = s .. tostring(vec[i]) .. ','
        end
    end
    s = s .. ']'
    return s
end
