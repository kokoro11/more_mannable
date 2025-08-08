local moreMannable = mods.moreMannable
local TEXTS = moreMannable.TEXTS

local skillsMeta = {
    __index = function() return { 1, 0, 0, 0 } end
}

---@alias SkillTable table<integer, [integer, integer, number, integer]>
---@return SkillTable
local function newSkillTable()
    local t = {
        [2] = { 1, 0, 0, 0 },  -- oxygen
        [4] = { 1, 0, 0, 0 },  -- drones
        [11] = { 1, 0, 0, 0 }, -- artilleries
        [10] = { 1, 0, 0, 0 }, -- cloaking
        [14] = { 1, 0, 0, 0 }, -- mind
        [15] = { 1, 0, 0, 0 }, -- hacking
        [20] = { 1, 0, 0, 0 }, -- temporal
    }
    setmetatable(t, skillsMeta)
    return t
end

local dataOrder0 = { 2, 4, 11, 10 }
local dataOrder1 = { 14, 15, 20 }

---@param crew Hyperspace.CrewMember
---@param skills SkillTable
local function saveSkillTable(crew, skills)
    local data0 = 0
    local data1 = 0
    local exp = moreMannable.LEVELUP_EXP
    for i, v in ipairs(dataOrder0) do
        local skill = skills[v]
        local totalSkillPoints = skill[1] * exp + skill[2]
        data0 = data0 | (totalSkillPoints << (8 * (i - 1)))
    end
    for i, v in ipairs(dataOrder1) do
        local skill = skills[v]
        local totalSkillPoints = skill[1] * exp + skill[2]
        data1 = data1 | (totalSkillPoints << (8 * (i - 1)))
    end
    local playerVariables = Hyperspace.playerVariables
    local idStr = math.floor(crew.extend.selfId)
    playerVariables["_moreMannable_skillTable_data0_" .. idStr] = data0
    playerVariables["_moreMannable_skillTable_data1_" .. idStr] = data1
end

---@param crew Hyperspace.CrewMember
local function loadSkillTable(crew)
    ---@type SkillTable
    local skills = crew.table.moreMannable.skills
    local playerVariables = Hyperspace.playerVariables
    local idStr = math.floor(crew.extend.selfId)
    ---@diagnostic disable-next-line: param-type-mismatch
    if not playerVariables:has_key("_moreMannable_skillTable_data0_" .. idStr) then
        return
    end
    local data0 = math.floor(playerVariables["_moreMannable_skillTable_data0_" .. idStr])
    local data1 = math.floor(playerVariables["_moreMannable_skillTable_data1_" .. idStr])
    local exp = moreMannable.LEVELUP_EXP
    for i, v in ipairs(dataOrder0) do
        local skill = skills[v]
        local totalSkillPoints = (data0 >> (8 * (i - 1))) & 0xff
        skill[1] = totalSkillPoints // exp
        skill[2] = totalSkillPoints % exp
    end
    for i, v in ipairs(dataOrder1) do
        local skill = skills[v]
        local totalSkillPoints = (data1 >> (8 * (i - 1))) & 0xff
        skill[1] = totalSkillPoints // exp
        skill[2] = totalSkillPoints % exp
    end
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_CREWMEMBER, function(crew)
    if not crew.table.moreMannable then
        crew.table.moreMannable = {}
    end
    local crewTable = crew.table.moreMannable
    crewTable.skills = newSkillTable()
    crewTable.skillUp = false
    crewTable.levelUp = false
end)

local saveLoaded = true
script.on_init(function(newGame)
    if newGame then
        saveLoaded = true
    else
        saveLoaded = false
    end
end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if saveLoaded then
        return
    end
    local shipMgr = Hyperspace.ships.player
    if not shipMgr then
        return
    end
    saveLoaded = true
    local vCrewList = shipMgr.vCrewList
    local size = vCrewList:size()
    for i = 0, size - 1 do
        loadSkillTable(vCrewList[i])
    end
    local enemyShip = Hyperspace.ships.enemy
    if not enemyShip then
        return
    end
    vCrewList = enemyShip.vCrewList
    size = vCrewList:size()
    for i = 0, size - 1 do
        loadSkillTable(vCrewList[i])
    end
end, 99999)

---@param shipMgr Hyperspace.ShipManager
local function resetRecentSkillGain(shipMgr)
    local vCrewList = shipMgr.vCrewList
    local size = vCrewList:size()
    for i = 0, size - 1 do
        local crew = vCrewList[i]
        local skills = crew.table.moreMannable.skills
        for _, skillTable in pairs(skills) do
            skillTable[4] = 0
        end
    end
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, resetRecentSkillGain)
script.on_internal_event(Defines.InternalEvents.ON_WAIT, resetRecentSkillGain)

---@param manningCrew Hyperspace.CrewMember
---@param sysId integer
---@param time number?
function mods.moreMannable.trainSkill(manningCrew, sysId, time)
    local crewTable = manningCrew.table.moreMannable
    ---@type SkillTable
    local skillTable = crewTable.skills
    local skill = skillTable[sysId]
    if skill[1] >= moreMannable.MAX_LEVEL or skill[4] >= moreMannable.MAX_RECENT_SKILL then
        return
    end
    if time then
        skill[3] = skill[3] + time
        if skill[3] >= moreMannable.EXP_TIME then
            skill[3] = skill[3] - moreMannable.EXP_TIME
            skill[2] = skill[2] + 1
            skill[4] = skill[4] + 1
            crewTable.skillUp = 0
            saveSkillTable(manningCrew, skillTable)
        end
    else
        skill[2] = skill[2] + 1
        skill[4] = skill[4] + 1
        crewTable.skillUp = 0
        saveSkillTable(manningCrew, skillTable)
    end
    if skill[2] >= moreMannable.LEVELUP_EXP then
        skill[2] = skill[2] - moreMannable.LEVELUP_EXP
        skill[1] = skill[1] + 1
        Hyperspace.Sounds:PlaySoundMix("levelup", -1, false)
        crewTable.levelUp = true
    end
end

function mods.moreMannable.skillTableDesc(skillTable)
    local text = TEXTS.SKILLS()
    local skills = 0
    for sysId, skill in pairs(skillTable) do
        local level = skill[1]
        local exp = skill[2]
        local recent = skill[4]
        local cannotTrain = recent >= moreMannable.MAX_RECENT_SKILL
        if level ~= 1 or exp ~= 0 or cannotTrain then
            skills = skills + 1
            if level >= moreMannable.MAX_LEVEL then
                text = text .. "\n" .. TEXTS.SKILL_ENTRY_MAXLEVEL(TEXTS.SYS_NAMES[sysId](), TEXTS.SKILL_LEVEL[level]())
            else
                text = text .. "\n" .. TEXTS.SKILL_ENTRY(TEXTS.SYS_NAMES[sysId](), TEXTS.SKILL_LEVEL[level](), exp,
                    moreMannable.LEVELUP_EXP, cannotTrain and TEXTS.CANNOT_TRAIN() or "")
            end
        end
    end
    if skills <= 0 then
        text = text .. "\n" .. TEXTS.NO_SKILLS()
    end
    return text
end
