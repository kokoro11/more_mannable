local moreMannable = mods.moreMannable
local GlobalShips = moreMannable.GlobalShips
local trainSkill = moreMannable.trainSkill

local directions = {
    [0] = 'down',
    [1] = 'right',
    [2] = 'up',
    [3] = 'left',
    [4] = 'none',
}

--[[ local mainSystems = {
    [2] = true,
    [4] = true,
    [11] = true
}

local auxSystems = {
    [10] = true,
    [14] = true,
    [15] = true,
    [20] = true
} ]]

---@param sys Hyperspace.ShipSystem
local function enableManning(sys)
    sys.bBoostable = true
    sys.computerLevel = math.max(sys.computerLevel, 0) -- important
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

---@param shipMgr Hyperspace.ShipManager
local function auxManning(shipMgr)
    if not moreMannable.auxEnabled then
        return
    end
    local vSystemList = shipMgr.vSystemList
    local size = vSystemList:size()
    for i = 0, size - 1 do
        local sysTable = vSystemList[i].table.moreMannable
        sysTable.resolved = false
        sysTable.manningCrew = false
    end
    local vCrewList = shipMgr.vCrewList
    size = vCrewList:size()
    for i = 0, size - 1 do
        local crew = vCrewList[i]
        if not (crew.bOutOfGame or crew.bDead) then
            local sys = crew.currentSystem
            if sys then
                if not sys.table then
                    print("MMS.auxManning: something went wrong: sys.table is nil")
                    log(string.format(
                        "MMS.auxManning:sysId=%s,sysName=%s,iShipId=%s,roomId=%s,shipBp=%s",
                        sys.iSystemType, sys.name, sys._shipObj.iShipId, sys.roomId,
                        GlobalShips[sys._shipObj.iShipId].myBlueprint.blueprintName
                    ))
                else
                    local sysTable = sys.table.moreMannable
                    if not sysTable.resolved then
                        if sysTable.isMms and sys:Powered() and sys.iHackEffect <= 0 then
                            local sysId = sys.iSystemType
                            if sysTable.isAux then
                                if crew.bActiveManning then
                                    sys.iActiveManned = math.max(sys.iActiveManned,
                                        crew.table.moreMannable.skills[sysId][1])
                                    --sys.bManned = true
                                    sysTable.resolved = true
                                    sysTable.manningCrew = crew
                                else
                                    if shipMgr.iShipId == 0 then
                                        if sysTable.slotId == crew.currentSlot.slotId and not crew:IsBusy() and not crew:GetIntruder() and crew:CanMan() then
                                            crew.bActiveManning = true
                                            sys.iActiveManned = math.max(sys.iActiveManned,
                                                crew.table.moreMannable.skills[sysId][1])
                                            --sys.bManned = true
                                            sysTable.resolved = true
                                            sysTable.manningCrew = crew
                                        end
                                    elseif not crew:IsBusy() and not crew:GetIntruder() and crew:CanMan() then
                                        crew.bActiveManning = true
                                        sys.iActiveManned = math.max(sys.iActiveManned,
                                            crew.table.moreMannable.skills[sysId][1])
                                        --sys.bManned = true
                                        sysTable.resolved = true
                                        sysTable.manningCrew = crew
                                    end
                                end
                            else
                                if crew.bActiveManning then
                                    sys.iActiveManned = math.max(sys.iActiveManned,
                                        crew.table.moreMannable.skills[sysId][1])
                                    --sys.bManned = true
                                    sysTable.resolved = true
                                    sysTable.manningCrew = crew
                                end
                            end
                        else
                            sysTable.resolved = true
                        end
                    end
                end
            end
        end
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
        local delta = Hyperspace.FPS.SpeedFactor / 16 * 0.1 * boost
        cooldown.first = math.min(math.max(cooldown.first + delta, 0), safeMaxCooldown)
    end
end

local hackingSpeedupCases = {
    -- shields
    [0] = function(enemyShip, rate)
        local shields = enemyShip.shieldSystem.shields
        if shields.power.first > 0 then
            local frameTime = Hyperspace.FPS.SpeedFactor / 16
            if shields.charger > frameTime then
                local delta = frameTime * rate
                shields.charger = math.max(shields.charger - delta, frameTime)
            end
        end
    end,
    -- oxygen
    [2] = function(enemyShip, rate)
        local sys = enemyShip.oxygenSystem
        local refill = sys:GetRefillSpeed()
        local delta = math.abs(refill) * rate
        local oxygenLevels = sys.oxygenLevels
        for i = 0, oxygenLevels:size() - 1 do
            oxygenLevels[i] = math.max(oxygenLevels[i] - delta, 0)
        end
    end,
    -- weapons
    [3] = function(enemyShip, rate)
        local sys = enemyShip.weaponSystem
        local weapons = sys.weapons
        for i = 0, weapons:size() - 1 do
            local weapon = weapons[i]
            local cooldown = weapon.cooldown
            if weapon.powered and cooldown.second > 0 and cooldown.first > 0 then
                local delta = Hyperspace.FPS.SpeedFactor / 16 * rate
                cooldown.first = math.max(cooldown.first - delta, 0)
            end
        end
    end,
    -- medbay
    [5] = function(enemyShip, rate, roomId)
        local iShipId = enemyShip.iShipId
        local vCrewList = enemyShip.vCrewList
        for i = 0, vCrewList:size() - 1 do
            local crew = vCrewList[i]
            if not crew.bOutOfGame and not crew:IsDrone() and crew:InsideRoom(roomId) and crew.iShipId == iShipId then
                crew.fMedbay = crew.fMedbay * (1 + rate)
            end
        end
    end,
    -- artilleries
    [11] = function(enemyShip, rate, roomId)
        local artillerySystems = enemyShip.artillerySystems
        local artillery = false
        for i = 0, artillerySystems:size() - 1 do
            local sys = artillerySystems[i]
            if sys:GetRoomId() == roomId then
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
            local delta = Hyperspace.FPS.SpeedFactor / 16 * rate
            cooldown.first = math.max(cooldown.first - delta, 0)
        end
    end,
    -- clonebay
    [13] = function(enemyShip, rate)
        local sys = enemyShip.cloneSystem
        if sys.fDeathTime >= 0 then
            local delta = Hyperspace.FPS.SpeedFactor / 16 * rate
            sys.fDeathTime = sys.fDeathTime + delta
        end
    end
}

---@type table<integer, fun(m:Hyperspace.ShipManager, s:Hyperspace.ShipSystem, b:integer, o:Hyperspace.ShipManager)>
local manningCases = {
    -- oxygen
    -- 100/200/300% faster refill speed
    [2] = function(shipMgr, shipSys, boost)
        if not shipSys:Powered() then
            return
        end
        local sys = shipMgr.oxygenSystem
        local delta = sys:GetRefillSpeed() * boost
        local oxygenLevels = sys.oxygenLevels
        local size = oxygenLevels:size()
        for i = 0, size - 1 do
            oxygenLevels[i] = math.min(math.max(oxygenLevels[i] + delta, 0), 100)
        end
    end,
    -- drones
    -- 20/30/40% faster operating speed
    [4] = function(shipMgr, shipSys, boost, otherShip)
        local boostValue = 0.1 + 0.1 * boost
        local userdata = shipSys.table.moreMannable
        local extraUpdates = boostValue + userdata.remnant
        extraUpdates, userdata.remnant = math.modf(extraUpdates)
        local drones = shipMgr.spaceDrones
        local size = drones:size()
        for i = 0, size - 1 do
            ---@type any
            local drone = drones[i]
            if drone.powered then
                if drone.currentSpeed and drone.weaponCooldown >= 0 then
                    drone.weaponCooldown = drone.weaponCooldown - Hyperspace.FPS.SpeedFactor / 16 * boostValue
                    if drone.weaponCooldown <= 0 then
                        drone.weaponCooldown = -1
                    end
                end
                for _ = 1, extraUpdates do
                    drone:OnLoop()
                end
            end
        end
        local crewList = shipMgr.vCrewList
        size = crewList:size()
        for i = 0, size - 1 do
            local crew = crewList[i]
            if not crew.bOutOfGame and crew:IsDrone() and not crew:GetIntruder() then
                for _ = 1, extraUpdates do
                    crew:OnLoop()
                end
            end
        end
        if not otherShip then
            return
        end
        crewList = otherShip.vCrewList
        size = crewList:size()
        for i = 0, size - 1 do
            local crew = crewList[i]
            if not crew.bOutOfGame and crew:IsDrone() and crew:GetIntruder() then
                for _ = 1, extraUpdates do
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
        timer.currTime = timer.currTime + Hyperspace.FPS.SpeedFactor / 16 * 0.25
    end,
    -- artillery
    [11] = function() end,
    -- mind
    -- 25% longer mind control
    -- 100% faster system cooldown
    -- crew 100% faster
    [14] = function(shipMgr, _, boost)
        local sys = shipMgr.mindSystem
        if not sys.controlledCrew:empty() then
            local controlTimer = sys.controlTimer
            controlTimer.first = math.max(controlTimer.first - Hyperspace.FPS.SpeedFactor / 16 * 0.2, 0)
        end
        if boost < 2 then
            return
        end
        if sys.iLockCount > 0 then
            local timer = sys.lockTimer
            timer.currTime = timer.currTime + Hyperspace.FPS.SpeedFactor / 16
        end
        if boost < 3 then
            return
        end
        local crewList = sys.controlledCrew
        local size = crewList:size()
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
            timer.currTime = timer.currTime + Hyperspace.FPS.SpeedFactor / 16 * 0.25
        end
        if not (sys:Powered() and otherShip) then
            return
        end
        local hackedSys = sys.currentSystem
        if hackedSys and hackedSys.iHackEffect >= 2 then
            local case = hackingSpeedupCases[hackedSys.iSystemType]
            if case then
                case(otherShip, 0.25, hackedSys:GetRoomId())
            end
        end
        if boost < 3 then
            return
        end
        local otherHacking = otherShip.hackingSystem
        if otherHacking then
            local drone = otherHacking.drone
            if drone and not drone.bDead and drone.currentSpace == shipMgr.iShipId then
                drone:BlowUp(false)
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
        timer.currTime = timer.currTime + Hyperspace.FPS.SpeedFactor / 16 * 0.25 * boost
    end
}

-- cloaking
-- 40% increased active dodge chance
-- 25% faster system cooldown
-- 10% increased passive dodge chance
script.on_internal_event(Defines.InternalEvents.GET_DODGE_FACTOR, function(shipMgr, dodge)
    local sys = shipMgr.cloakSystem
    if sys and sys.bBoostable and sys:Powered() and sys.iHackEffect < 2 then
        local boost = sys.iActiveManned
        if boost >= 1 then
            if sys.bTurnedOn then
                dodge = dodge + 40
            end
            if boost >= 3 then
                dodge = dodge + 10
            end
        end
    end
    return Defines.Chain.CONTINUE, dodge
end)

--[[ script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    if not moreMannable.auxEnabled then
        return
    end
    local temporal = shipMgr:GetSystem(20)
    if temporal and not temporal.bBoostable then
        enableManning(temporal)
    end
end, 99999) ]]

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    auxManning(shipMgr)
    local otherShip = Hyperspace.ships(1 - shipMgr.iShipId)
    local canTrain = otherShip and otherShip._targetable.hostile
    if not (otherShip and otherShip.ship.bCloaked or shipMgr.bJumping) then
        local artillerySystems = shipMgr.artillerySystems
        local size = artillerySystems:size()
        for i = 0, size - 1 do
            local sys = artillerySystems[i]
            artilleryManning(sys)
        end
    end
    local vSystemList = shipMgr.vSystemList
    local size = vSystemList:size()
    for i = 0, size - 1 do
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
                            trainSkill(manningCrew, sysId, Hyperspace.FPS.SpeedFactor / 16)
                        end
                    end
                end
                manningCases[sysId](shipMgr, sys, boost, otherShip)
            end
            sysTable.prevLock = sys.iLockCount
        end
    end
end, moreMannable.MAINLOOP_PRIORITY)
