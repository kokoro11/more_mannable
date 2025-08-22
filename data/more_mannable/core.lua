local moreMannable = mods.moreMannable
local GlobalShips = moreMannable.GlobalShips
local trainSkill = moreMannable.trainSkill
local globalFrameTime = Hyperspace.FPS.SpeedFactor / 16
local min = math.min
local max = math.max
local modf = math.modf
local abs = math.abs
local random = math.random

local directions = {
    [0] = 'down',
    [1] = 'right',
    [2] = 'up',
    [3] = 'left',
    [4] = 'none',
}

---@param sys Hyperspace.ShipSystem
local function enableManning(sys)
    sys.bBoostable = true
    sys.computerLevel = max(sys.computerLevel, 0) -- important
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(sys)
    if not sys.table.moreMannable then
        sys.table.moreMannable = {}
    end
    local sysTable = sys.table.moreMannable
    local sysId = sys.iSystemType
    sysTable.isAux = moreMannable.isAux(sysId)
    sysTable.isMms = moreMannable.isMms(sysId)
    if sysTable.isMms then
        enableManning(sys)
    end
    sysTable.prevLock = sys.iLockCount
    sysTable.resolved = false
    sysTable.manningCrew = false
    sysTable.remnant = 0
    sysTable.slotId = -1
    sysTable.direction = -1
end)

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, function(sysBox)
    local sys = sysBox.pSystem
    local sysTable = sys.table.moreMannable
    if sysTable.isMms then
        enableManning(sys)
    end
    if not sysBox.bPlayerUI then
        return
    end
    local sysId = sys.iSystemType
    local sysInfo = GlobalShips[0].myBlueprint.systemInfo[sysId]
    sysTable.slotId = sysInfo.slot
    sysTable.direction = sysInfo.direction
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipMgr)
    local roomToSys = {}
    local vSystemList = shipMgr.vSystemList
    for i = 0, vSystemList:size() - 1 do
        local sys = vSystemList[i]
        roomToSys[sys.roomId] = sys
    end
    local vCrewList = shipMgr.vCrewList
    for i = 0, vCrewList:size() - 1 do
        local crew = vCrewList[i]
        if crew.bOutOfGame or crew.bDead then
            crew.currentSystem = nil
        else
            crew.currentSystem = roomToSys[crew.iRoomId]
        end
    end
end)

---@param shipMgr Hyperspace.ShipManager
local function auxManning(shipMgr)
    if not moreMannable.auxEnabled then
        return
    end
    local vSystemList = shipMgr.vSystemList
    for i = 0, vSystemList:size() - 1 do
        local sysTable = vSystemList[i].table.moreMannable
        sysTable.resolved = false
        sysTable.manningCrew = false
    end
    local iShipId = shipMgr.iShipId
    ---@type Hyperspace.CrewMember?
    local idleCrew = nil
    local vCrewList = shipMgr.vCrewList
    for i = 0, vCrewList:size() - 1 do
        local crew = vCrewList[i]
        local crewAnim = crew.crewAnim
        local crewTable = crew.table.moreMannable
        if crewTable.forced then
            crewAnim.forcedAnimation = -1
            crewAnim.forcedDirection = -1
            crewTable.forced = false
        end
        -- Do not use crew.currentSystem or crew.bActiveManning if crew:GetIntruder() is true, it's not updated for intruders
        if crew.bOutOfGame or crew.bDead or crew.intruder then
            crew.bActiveManning = false
        else
            local sys = crew.currentSystem
            if sys then
                local sysTable = sys.table.moreMannable
                if not sysTable.resolved then
                    if sysTable.isMms and sys:Powered() and sys.iHackEffect <= 0 then
                        local sysId = sys.iSystemType
                        if sysTable.isAux then
                            if crew.bActiveManning then
                                sys.iActiveManned = max(sys.iActiveManned, crewTable.skills[sysId][1])
                                sysTable.resolved = true
                                sysTable.manningCrew = crew
                            else
                                if iShipId == 0 then
                                    if sysId == 20 then -- bandaid for temporal, should be fixed in Hyperspace sometime
                                        if sysTable.slotId == crew.currentSlot.slotId then
                                            if not crew:IsBusy() and crew:CanMan() then
                                                crew.bActiveManning = true
                                                -- -1 disable, 0 walk, 1 punch, 2 repair, 3 death animation, 4 extinguishing,
                                                -- 5 complete invisibility, 6 teleport, 7 shoot, 8&9 manning, 10 game crashes
                                                crewAnim.forcedAnimation = 8
                                                crewAnim.forcedDirection = sysTable.direction
                                                crewTable.forced = true
                                                idleCrew = nil
                                                sys.iActiveManned = max(sys.iActiveManned, crewTable.skills[sysId][1])
                                                sysTable.resolved = true
                                                sysTable.manningCrew = crew
                                            else
                                                idleCrew = nil
                                                sysTable.resolved = true
                                            end
                                            -- Hyperspace.CrewStat.CAN_MOVE == 48
                                        elseif not idleCrew and not crew:IsBusy() and crew:CanMan() and select(2, crew.extend:CalculateStat(48)) then
                                            idleCrew = crew
                                        end
                                    elseif sysTable.slotId == crew.currentSlot.slotId then
                                        if not crew:IsBusy() and crew:CanMan() then
                                            crew.bActiveManning = true
                                            sys.iActiveManned = max(sys.iActiveManned, crewTable.skills[sysId][1])
                                            sysTable.resolved = true
                                            sysTable.manningCrew = crew
                                        else
                                            -- slot is occupied
                                            sysTable.resolved = true
                                        end
                                    end
                                elseif not crew:IsBusy() and crew:CanMan() then
                                    crew.bActiveManning = true
                                    sys.iActiveManned = max(sys.iActiveManned, crewTable.skills[sysId][1])
                                    sysTable.resolved = true
                                    sysTable.manningCrew = crew
                                end
                            end
                        elseif crew.bActiveManning then
                            sys.iActiveManned = max(sys.iActiveManned, crewTable.skills[sysId][1])
                            sysTable.resolved = true
                            sysTable.manningCrew = crew
                        end
                    else
                        sysTable.resolved = true
                    end
                end
            end
        end
    end
    if not idleCrew then
        return
    end
    local temporalSlotId = idleCrew.currentSystem.table.moreMannable.slotId
    if temporalSlotId < 0 then
        return
    end
    local temporalRoomId = idleCrew.iRoomId
    local actualSlot = idleCrew:FindSlot(temporalRoomId, temporalSlotId, false)
    if actualSlot.roomId == temporalRoomId and actualSlot.slotId == temporalSlotId then
        idleCrew:MoveToRoom(temporalRoomId, temporalSlotId, true)
    end
end

-- 10/20/30% faster charge speed
local function artilleryManning(sys)
    local weapon = sys.projectileFactory
    local boost = sys.iActiveManned
    if not weapon.powered or boost < 1 or sys.iHackEffect >= 2 then
        return
    end
    local cooldown = weapon.cooldown
    local safeMaxCooldown = cooldown.second - 0.001
    if safeMaxCooldown > 0 and cooldown.first < safeMaxCooldown then
        local delta = globalFrameTime * 0.1 * boost
        cooldown.first = min(max(cooldown.first + delta, 0), safeMaxCooldown)
    end
end

---@type table<integer, fun(enemyShip: Hyperspace.ShipManager, rate: number, roomId: integer)>
local hackingSpeedupCases = {
    -- shields
    [0] = function(enemyShip, rate)
        local shields = enemyShip.shieldSystem.shields
        if shields.power.first > 0 then
            local frameTime = globalFrameTime
            if shields.charger > frameTime then
                local delta = frameTime * rate
                shields.charger = max(shields.charger - delta, frameTime)
            end
        end
    end,
    -- oxygen
    [2] = function(enemyShip, rate)
        local sys = enemyShip.oxygenSystem
        local refill = sys:GetRefillSpeed()
        local delta = abs(refill) * rate
        local oxygenLevels = sys.oxygenLevels
        for i = 0, oxygenLevels:size() - 1 do
            oxygenLevels[i] = max(oxygenLevels[i] - delta, 0)
        end
    end,
    -- weapons
    [3] = function(enemyShip, rate)
        local weapons = enemyShip.weaponSystem.weapons
        for i = 0, weapons:size() - 1 do
            local weapon = weapons[i]
            local cooldown = weapon.cooldown
            if weapon.powered and cooldown.second > 0 and cooldown.first > 0 then
                local delta = globalFrameTime * rate
                cooldown.first = max(cooldown.first - delta, 0)
            end
        end
    end,
    -- drones
    [4] = function(enemyShip, rate)
        if rate < 0.4 then
            return
        end
        local time = 20 * rate - 5
        local drones = enemyShip.droneSystem.drones
        for i = 0, drones:size() - 1 do
            local drone = drones[i]
            local dTimer = drone.destroyedTimer
            if drone.deployed and not drone.bDead and dTimer <= 0 then
                drone:BlowUp(false)
            end
            drone.destroyedTimer = max(dTimer, time)
        end
    end,
    -- medbay
    [5] = function(enemyShip, rate, roomId)
        local iShipId = enemyShip.iShipId
        local vCrewList = enemyShip.vCrewList
        for i = 0, vCrewList:size() - 1 do
            local crew = vCrewList[i]
            if not (crew.bOutOfGame or crew.bDead or crew:IsDrone()) and crew:InsideRoom(roomId) and crew.iShipId == iShipId then
                crew.fMedbay = crew.fMedbay * (1 + rate)
            end
        end
    end,
    -- artilleries
    [11] = function(enemyShip, rate, roomId)
        local artillerySystems = enemyShip.artillerySystems
        local artillery = nil
        for i = 0, artillerySystems:size() - 1 do
            local sys = artillerySystems[i]
            if sys.roomId == roomId then
                artillery = sys
                break
            end
        end
        if not artillery then
            return
        end
        local weapon = artillery.projectileFactory
        local cooldown = weapon.cooldown
        if weapon.powered and cooldown.second > 0 and cooldown.first > 0 then
            local delta = globalFrameTime * rate
            cooldown.first = max(cooldown.first - delta, 0)
        end
    end,
    -- clonebay
    [13] = function(enemyShip, rate)
        local sys = enemyShip.cloneSystem
        if sys.fDeathTime >= 0 then
            local delta = globalFrameTime * rate
            sys.fDeathTime = sys.fDeathTime + delta
        end
    end
}

local o2Boost = { [0] = 0, [1] = 0 }
---@type table<integer, fun(m:Hyperspace.ShipManager, s:Hyperspace.ShipSystem, b:integer, o:Hyperspace.ShipManager)>
local manningCases = {
    -- oxygen
    -- 100/200/300% faster refill speed
    -- 1/1.3/1.6x repair, move, heal speed
    [2] = function(shipMgr, shipSys, boost)
        if not shipSys:Powered() then
            return
        end
        if boost >= 2 then
            o2Boost[shipMgr.iShipId] = boost * 0.3 + 0.7
        end
        local sys = shipMgr.oxygenSystem
        local delta = sys:GetRefillSpeed() * boost
        local oxygenLevels = sys.oxygenLevels
        for i = 0, oxygenLevels:size() - 1 do
            oxygenLevels[i] = min(max(oxygenLevels[i] + delta, 0), 100)
        end
    end,
    -- drones
    -- 20/30/40% faster operating speed
    [4] = function(shipMgr, shipSys, boost, otherShip)
        local boostValue = 0.1 + 0.1 * boost
        local sysTable = shipSys.table.moreMannable
        local extraLoops = boostValue + sysTable.remnant
        extraLoops, sysTable.remnant = modf(extraLoops)
        local drones = shipMgr.spaceDrones
        for i = 0, drones:size() - 1 do
            ---@type any
            local drone = drones[i]
            if drone.powered then
                if drone.currentSpeed and drone.weaponCooldown >= 0 then
                    drone.weaponCooldown = drone.weaponCooldown - globalFrameTime * boostValue
                    if drone.weaponCooldown <= 0 then
                        drone.weaponCooldown = -1
                    end
                end
                for _ = 1, extraLoops do
                    drone:OnLoop()
                end
            end
        end
        if extraLoops < 1 then
            return
        end
        local crewList = shipMgr.vCrewList
        for i = 0, crewList:size() - 1 do
            local crew = crewList[i]
            if crew:IsDrone() and not (crew.bOutOfGame or crew.bDead or crew.intruder) then
                for _ = 1, extraLoops do
                    crew:OnLoop()
                end
            end
        end
        if not otherShip then
            return
        end
        crewList = otherShip.vCrewList
        for i = 0, crewList:size() - 1 do
            local crew = crewList[i]
            if crew:IsDrone() and not (crew.bOutOfGame or crew.bDead) and crew.intruder then
                for _ = 1, extraLoops do
                    crew:OnLoop()
                end
            end
        end
    end,
    -- cloaking
    -- 40% increased active dodge chance
    -- 25% faster system cooldown
    -- 10% increased passive dodge chance
    [10] = function(_, shipSys)
        if shipSys.iActiveManned < 2 or shipSys.iLockCount <= 0 then
            return
        end
        local timer = shipSys.lockTimer
        timer.currTime = timer.currTime + globalFrameTime * 0.25
    end,
    -- artillery
    [11] = function() end,
    -- mind
    -- 25% longer mind control
    -- 100% faster system cooldown
    -- crew 100% faster
    [14] = function(shipMgr, _, boost)
        local sys = shipMgr.mindSystem
        local crewList = sys.controlledCrew
        local size = crewList:size()
        if size > 0 then
            local controlTimer = sys.controlTimer
            controlTimer.first = max(controlTimer.first - globalFrameTime * 0.2, 0)
        end
        if boost < 2 then
            return
        end
        if sys.iLockCount > 0 then
            local timer = sys.lockTimer
            timer.currTime = timer.currTime + globalFrameTime
        end
        if boost < 3 then
            return
        end
        for i = 0, size - 1 do
            crewList[i]:OnLoop()
        end
    end,
    -- hacking
    -- 25% faster hacking
    -- 25% faster system cooldown
    -- counter hacking
    [15] = function(shipMgr, _, boost, otherShip)
        local sys = shipMgr.hackingSystem
        if boost >= 2 and sys.iLockCount > 0 then
            local timer = sys.lockTimer
            timer.currTime = timer.currTime + globalFrameTime * 0.25
        end
        if not (sys:Powered() and otherShip) then
            return
        end
        local hackedSys = sys.currentSystem
        if hackedSys and hackedSys.iHackEffect >= 2 then
            local case = hackingSpeedupCases[hackedSys.iSystemType]
            if case then
                case(otherShip, 0.25 * boost, hackedSys.roomId)
            end
        end
        if boost < 3 then
            return
        end
        local otherHacking = otherShip.hackingSystem
        if otherHacking then
            local drone = otherHacking.drone
            if drone.arrived then
                drone:BlowUp(false)
            elseif drone.deployed and drone.currentSpace == shipMgr.iShipId then
                drone.ionStun = drone.ionStun + globalFrameTime * (0.06 + random() * 1.94)
            end
        end
    end,
    -- temporal
    -- 25/50/75% faster system cooldown
    [20] = function(_, shipSys, boost)
        if shipSys.iLockCount <= 0 then
            return
        end
        local timer = shipSys.lockTimer
        timer.currTime = timer.currTime + globalFrameTime * 0.25 * boost
    end
}

-- cloaking
-- 40% increased active dodge chance
-- 25% faster system cooldown
-- 10% increased passive dodge chance
script.on_internal_event(Defines.InternalEvents.GET_DODGE_FACTOR, function(shipMgr, dodge)
    local sys = shipMgr.cloakSystem
    if not (sys and sys.bBoostable and sys:Powered() and sys.iHackEffect < 2) then
        ---@diagnostic disable-next-line: missing-return-value
        return
    end
    local boost = sys.iActiveManned
    if boost < 1 then
        ---@diagnostic disable-next-line: missing-return-value
        return
    end
    if sys.bTurnedOn then
        dodge = dodge + 40
    end
    if boost >= 3 then
        dodge = dodge + 10
    end
    -- Defines.Chain.CONTINUE == 0
    return 0, dodge
end)

---@param crew Hyperspace.CrewMember
---@param stat Hyperspace.CrewStat
---@param amount number
---@return Defines.Chain?, number?, boolean?
local function o2Buff(crew, stat, _, amount, _)
    -- Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER == 2
    -- Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER == 3
    -- Hyperspace.CrewStat.HEAL_SPEED_MULTIPLIER == 20
    if stat ~= 2 and stat ~= 3 and stat ~= 20 then
        return
    end
    local boost = o2Boost[crew.currentShipId]
    if boost <= 0 or crew:IsDrone() then
        return
    end
    local def = crew.extend:GetDefinition()
    if not def.canSuffocate or def.isAnaerobic then
        return
    end
    return 0, amount * boost
end

if Hyperspace.version.major > 1 or (Hyperspace.version.major == 1 and Hyperspace.version.minor >= 20) then
    ---@diagnostic disable-next-line: undefined-field
    script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, o2Buff)
end

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    globalFrameTime = Hyperspace.FPS.SpeedFactor / 16
    o2Boost[shipMgr.iShipId] = 0
    auxManning(shipMgr)
    local otherShip = Hyperspace.ships(1 - shipMgr.iShipId)
    local canTrain = otherShip and otherShip._targetable.hostile
    if not (otherShip and otherShip.ship.bCloaked or shipMgr.bJumping) then
        local artillerySystems = shipMgr.artillerySystems
        for i = 0, artillerySystems:size() - 1 do
            artilleryManning(artillerySystems[i])
        end
    end
    local vSystemList = shipMgr.vSystemList
    for i = 0, vSystemList:size() - 1 do
        local sys = vSystemList[i]
        local sysTable = sys.table.moreMannable
        if sysTable.isMms then
            local boost = sys.iActiveManned
            if boost >= 1 and sys.iHackEffect < 2 then
                local sysId = sys.iSystemType
                if canTrain then
                    ---@type Hyperspace.CrewMember
                    local manningCrew = sysTable.manningCrew
                    if manningCrew and manningCrew.iShipId == 0 and not manningCrew:IsDrone() then
                        if sysTable.isAux then
                            if sysTable.prevLock ~= -1 and sys.iLockCount == -1 then
                                trainSkill(manningCrew, sysId)
                            end
                        else
                            trainSkill(manningCrew, sysId, globalFrameTime)
                        end
                    end
                end
                manningCases[sysId](shipMgr, sys, boost, otherShip)
            end
            sysTable.prevLock = sys.iLockCount
        end
    end
end, moreMannable.MAINLOOP_PRIORITY)
