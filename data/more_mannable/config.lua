mods.moreMannable = {}
local moreMannable = mods.moreMannable

mods.moreMannable.auxEnabled = Hyperspace.metaVariables['_moreMannable_auxEnabled'] > 0

mods.moreMannable.MAINLOOP_PRIORITY = -99999

mods.moreMannable.LEVELUP_EXP = 60
mods.moreMannable.MAX_LEVEL = 3
mods.moreMannable.MAX_RECENT_SKILL = 2
mods.moreMannable.EXP_TIME = 30

local mainSystems = {
    [2] = true,
    [4] = true,
    [11] = true
}

local auxSystems = {
    [10] = true,
    [14] = true,
    [15] = true,
    [20] = true
}

---@param sysId integer
---@return boolean
function mods.moreMannable.isAux(sysId)
    return (moreMannable.auxEnabled and auxSystems[sysId]) or false
end

---@param sysId integer
---@return boolean
function mods.moreMannable.isMms(sysId)
    return mainSystems[sysId] or (moreMannable.auxEnabled and auxSystems[sysId]) or false
end
