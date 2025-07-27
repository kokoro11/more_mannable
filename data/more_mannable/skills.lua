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

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_CREWMEMBER, function(crew)
    if not crew.table.moreMannable then
        crew.table.moreMannable = {}
    end
    local crewTable = crew.table.moreMannable
    crewTable.skills = newSkillTable()
    crewTable.skillUp = false
    crewTable.levelUp = false
end)

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
        end
    else
        skill[2] = skill[2] + 1
        skill[4] = skill[4] + 1
        crewTable.skillUp = 0
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
