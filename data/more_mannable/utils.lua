---@type {[0]: Hyperspace.ShipManager?, [1]: Hyperspace.ShipManager?}
mods.moreMannable.GlobalShips = { [0] = nil, [1] = nil }
script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_MANAGER, function(shipMgr)
    mods.moreMannable.GlobalShips[shipMgr.iShipId] = shipMgr
end)

local Settings = Hyperspace.Settings
local TextMeta = {
    __index = function(texts, language)
        if language == '' then
            return select(2, next(texts)) or ''
        else
            return texts['']
        end
    end,
    __call = function(texts, ...)
        local success, result = pcall(string.format, texts[Settings.language], ...)
        if success then
            return result
        else
            log("ERROR: " .. result)
            return texts[Settings.language]
        end
    end,
    __tostring = function(texts)
        return texts[Settings.language]
    end
}

---@alias Text table<string, string> | fun(...): string | string
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

function mods.moreMannable.vectorToString(vec, func)
    local s = '['
    if func then
        for i = 0, vec:size() - 1 do
            s = s .. func(vec[i]) .. ','
        end
    else
        for i = 0, vec:size() - 1 do
            s = s .. tostring(vec[i]) .. ','
        end
    end
    return s .. ']'
end
