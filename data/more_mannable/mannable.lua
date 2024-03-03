local moreMannable = mods.moreMannable

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

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(sys)
    if not sys.table.moreMannable then
        sys.table.moreMannable = {}
    end
    local iSystemType = sys.iSystemType
    if mainSystems[iSystemType] or (moreMannable.auxEnabled and auxSystems[iSystemType]) then
        sys.bBoostable = true
        sys.computerLevel = math.max(sys.computerLevel, 0)
    end
    if iSystemType == 4 then
        sys.table.moreMannable.remnant = 0
    end
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    if not moreMannable.auxEnabled then
        return
    end
    local iShipId = shipMgr.iShipId
    if iShipId ~= 0 then
        return
    end
    local vSystemList = shipMgr.vSystemList
    for i = 0, vSystemList:size() - 1 do
        local sys = vSystemList[i]
        local iSystemType = sys.iSystemType
        if auxSystems[iSystemType] and not sys.table.moreMannable.slot then
            local room = Hyperspace.ShipGraph.GetShipInfo(iShipId):GetRoomShape(sys:GetRoomId())
            local sysInfo = shipMgr.myBlueprint.systemInfo[iSystemType]
            local slot = sysInfo.slot
            local w = room.w // 35
            sys.table.moreMannable.slot = {
                x = room.x // 35 + slot % w,
                y = room.y // 35 + slot // w
            }
        end
    end
end)

local function auxManning(shipMgr)
    if not moreMannable.auxEnabled then
        return
    end
    local temporal = shipMgr:GetSystem(20)
    if temporal then
        temporal.bBoostable = true
    end
    local iShipId = shipMgr.iShipId
    local vCrewList = shipMgr.vCrewList
    for i = 0, vCrewList:size() - 1 do
        local crew = vCrewList[i]
        local sys = crew.currentSystem
        if sys and auxSystems[sys.iSystemType] and sys.iActiveManned < 1 and sys:Powered() and sys.iHackEffect <= 0 then
            if iShipId == 0 then
                local slot = sys.table.moreMannable.slot
                if slot and slot.x == crew.x // 35 and slot.y == crew.y // 35
                    and not crew:IsBusy() and not crew:GetIntruder() and crew:CanMan() then
                    crew.bActiveManning = true
                    sys.iActiveManned = 1
                end
            elseif not crew:IsBusy() and not crew:GetIntruder() and crew:CanMan() then
                crew.bActiveManning = true
                sys.iActiveManned = 1
            end
        end
    end
end

local function artilleryManning(sys)
    local weapon = sys.projectileFactory
    if not weapon.powered or sys.iActiveManned < 1 or sys.iHackEffect > 0 then
        return
    end
    -- 25% faster charge speed
    local cooldown = weapon.cooldown
    local safeMaxCooldown = cooldown.second - 0.001
    if safeMaxCooldown > 0 and cooldown.first < safeMaxCooldown then
        local delta = Hyperspace.FPS.SpeedFactor / 16 * 0.25
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
        local delta = math.abs(refill * rate)
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
            if not crew:IsDrone() and crew:InsideRoom(roomId) and crew.iShipId == iShipId then
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

local manningCases = {
    -- oxygen
    [2] = function(shipMgr)
        local sys = shipMgr.oxygenSystem
        if sys.iActiveManned < 1 or sys.iHackEffect > 0 then
            return
        end
        -- 100% faster refill speed
        local delta = sys:GetRefillSpeed() * 1
        local oxygenLevels = sys.oxygenLevels
        for i = 0, oxygenLevels:size() - 1 do
            oxygenLevels[i] = math.max(oxygenLevels[i] + delta, 0)
        end
    end,
    -- drones
    [4] = function(shipMgr, otherShip)
        local sys = shipMgr.droneSystem
        if sys.iActiveManned < 1 or sys.iHackEffect > 0 then
            return
        end
        -- 25% faster operating speed
        local boostValue = 0.25
        local userdata = sys.table.moreMannable
        local extraUpdates = boostValue + userdata.remnant
        extraUpdates, userdata.remnant = math.modf(extraUpdates)
        local drones = shipMgr.spaceDrones
        for i = 0, drones:size() - 1 do
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
        for i = 0, crewList:size() - 1 do
            local crew = crewList[i]
            if crew:IsDrone() and not crew:GetIntruder() then
                for _ = 1, extraUpdates do
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
            if crew:IsDrone() and crew:GetIntruder() then
                for _ = 1, extraUpdates do
                    crew:OnLoop()
                end
            end
        end
    end,
    -- mind
    [14] = function(shipMgr)
        if not moreMannable.auxEnabled then
            return
        end
        local sys = shipMgr.mindSystem
        if sys.iActiveManned < 1 or sys.iHackEffect > 0 or sys.controlledCrew:empty() then
            return
        end
        -- 25% longer mind control
        local controlTimer = sys.controlTimer
        controlTimer.first = math.max(controlTimer.first - Hyperspace.FPS.SpeedFactor / 16 * 0.2, 0)
    end,
    -- hacking
    [15] = function(shipMgr, otherShip)
        if not moreMannable.auxEnabled or not otherShip then
            return
        end
        local sys = shipMgr.hackingSystem
        if sys.iActiveManned < 1 or sys.iHackEffect > 0 then
            return
        end
        -- 25% faster hacking
        local hackedSys = sys.currentSystem
        if not hackedSys or hackedSys.iHackEffect < 2 then
            return
        end
        local case = hackingSpeedupCases[hackedSys.iSystemType]
        if case then
            case(otherShip, 0.25, hackedSys:GetRoomId())
        end
    end,
    -- temporal
    [20] = function(shipMgr)
        if not moreMannable.auxEnabled then
            return
        end
        local sys = shipMgr:GetSystem(20)
        if sys.iActiveManned < 1 or sys.iHackEffect > 0 or sys.iLockCount <= 0 then
            return
        end
        -- 25% faster system cooldown
        local timer = sys.lockTimer
        timer.currTime = timer.currTime + Hyperspace.FPS.SpeedFactor / 16 * 0.25
    end
}

-- cloaking
script.on_internal_event(Defines.InternalEvents.GET_DODGE_FACTOR, function(shipMgr, dodge)
    -- 40% increased dodge chance
    local sys = shipMgr.cloakSystem
    if moreMannable.auxEnabled and sys and sys.bTurnedOn and sys.iActiveManned >= 1 and sys.iHackEffect <= 0 then
        return Defines.Chain.CONTINUE, dodge + 40
    else
        return Defines.Chain.CONTINUE, dodge
    end
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    auxManning(shipMgr)
    local otherShip = Hyperspace.ships(1 - shipMgr.iShipId)
    local otherShipCloaked = otherShip and otherShip.ship.bCloaked or false
    local vSystemList = shipMgr.artillerySystems
    for i = 0, vSystemList:size() - 1 do
        if not otherShipCloaked then
            artilleryManning(vSystemList[i])
        end
    end
    vSystemList = shipMgr.vSystemList
    for i = 0, vSystemList:size() - 1 do
        local sys = vSystemList[i]
        local iSystemType = sys.iSystemType
        if iSystemType ~= 11 then
            local case = manningCases[iSystemType]
            if case then
                case(shipMgr, otherShip)
            end
        end
    end
end)
