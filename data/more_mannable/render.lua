local moreMannable = mods.moreMannable
local isMms = moreMannable.isMms
local GlobalShips = moreMannable.GlobalShips
local TEXTS = moreMannable.TEXTS
local skillTableDesc = moreMannable.skillTableDesc

local WHITE_COLOR = Graphics.GL_Color(1, 1, 1, 1)
local GOLD_COLOR = Graphics.GL_Color(250 / 255, 250 / 255, 90 / 255, 1.0)
local ANIME_FRAMES = 120

local function createPrimitive(filename, x, y)
    return Hyperspace.Resources:CreateImagePrimitiveString(filename, x, y, 0, WHITE_COLOR, 1.0, false)
end

local manningPrimitive = {
    [0] = createPrimitive("systemUI/manning_outline.png", 0, 0),
    [1] = createPrimitive("systemUI/manning_white.png", 0, 0),
    [2] = createPrimitive("systemUI/manning_green.png", 0, 0),
    [3] = createPrimitive("systemUI/manning_yellow.png", 0, 0),
}

local skillUpPrimitive = createPrimitive("systemUI/mms_exp_up.png", 0, 0)
local levelUpPrimitive = createPrimitive("systemUI/mms_lvl_up.png", 0, 0)

script.on_render_event(Defines.RenderEvents.SYSTEM_BOX, function() end, function(sysBox)
    if not (moreMannable.auxEnabled and Hyperspace.App.world.bStartedGame) then
        return
    end
    local playerShip = Hyperspace.ships.player
    local haveSensor = sysBox.bPlayerUI or playerShip:DoSensorsProvide(3)
    if not haveSensor then
        return
    end
    local sys = sysBox.pSystem
    local boost = sys.iActiveManned
    local sysTable = sys.table.moreMannable
    if not sysTable.isMms or boost < 1 or sys.bOnFire or sys.bOccupied or sys.iHackEffect > 0 then
        return
    end
    local y = -8 - 8 * sys:GetPowerCap()
    if sysTable.isAux and sys.iLockCount ~= 0 then
        y = y - 21
        if boost > 3 then
            boost = 3
        end
        Graphics.CSurface.GL_PushMatrix()
        Graphics.CSurface.GL_Translate(25, y)
        Graphics.CSurface.GL_RenderPrimitive(manningPrimitive[boost])
        Graphics.CSurface.GL_PopMatrix()
    end
    local crew = sysTable.manningCrew
    if not crew then
        return
    end
    local crewTable = crew.table.moreMannable
    if crewTable.skillUp then
        local primitive = crewTable.levelUp and levelUpPrimitive or skillUpPrimitive
        y = y - 14
        Graphics.CSurface.GL_PushMatrix()
        Graphics.CSurface.GL_Translate(14, y)
        Graphics.CSurface.GL_RenderPrimitive(primitive)
        Graphics.CSurface.GL_PopMatrix()
        crewTable.skillUp = crewTable.skillUp + 1
        if crewTable.skillUp >= ANIME_FRAMES then
            crewTable.skillUp = false
            crewTable.levelUp = false
        end
    end
end)

local GetLevelDescription = Hyperspace.ShipSystem.GetLevelDescription
local useOrig = false
script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, function(sysId, level, isTooltip)
    if not (isTooltip and isMms(sysId)) then
        ---@diagnostic disable-next-line: missing-return-value
        return
    end
    if useOrig then
        ---@diagnostic disable-next-line: missing-return-value
        return
    else
        useOrig = true
        local orig = GetLevelDescription(sysId, level - 1, isTooltip)
        useOrig = false
        return orig .. TEXTS.MANNING_BONUS() .. TEXTS.MANNING_BONUS_ENTRY[sysId]()
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local cApp = Hyperspace.App
    if not (moreMannable.auxEnabled and cApp.world.bStartedGame) then
        return
    end
    local list = cApp.gui.crewControl.potentialSelectedCrew
    if list:size() ~= 1 then
        return
    end
    local crew = list[0]
    if crew.iShipId ~= 0 or crew:IsDrone() then
        return
    end
    local mouse = Hyperspace.Mouse
    local tooltip = mouse.tooltip
    if #tooltip <= 0 then
        return
    end
    tooltip = tooltip .. "\n\n" .. skillTableDesc(crew.table.moreMannable.skills)
    mouse:SetTooltip(tooltip)
end)

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, function(sysBox)
    if not sysBox.bPlayerUI then
        return
    end
    local customInteriorImages = moreMannable.imgs[GlobalShips[0].myBlueprint.blueprintName]
    if not customInteriorImages then
        return
    end
    local sys = sysBox.pSystem
    local imgName = customInteriorImages[sys.roomId]
    if not imgName then
        return
    end
    local imgPath = 'ship/interior/' .. imgName .. '.png'
    local loc = sys.pLoc
    if sys.interiorImage then
        Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImage)
    end
    sys.interiorImage = createPrimitive(imgPath, loc.x, loc.y)
    if sys.interiorImageOn then
        Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImageOn)
    end
    sys.interiorImageOn = createPrimitive(imgPath, loc.x, loc.y)
    if sys.interiorImageManned then
        Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImageManned)
    end
    sys.interiorImageManned = createPrimitive(imgPath, loc.x, loc.y)
    if sys.interiorImageMannedFancy then
        Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImageMannedFancy)
    end
    sys.interiorImageMannedFancy = createPrimitive(imgPath, loc.x, loc.y)
end)

local optionBoxOn = {
    text = "ADVANCED MANNING: ON",
    x = 40,
    y = 670,
    w = 263,
    h = 18
}

local optionBoxOff = {
    text = "ADVANCED MANNING: OFF",
    x = 40,
    y = 670,
    w = 276,
    h = 18
}

local function mouseInside(box)
    local mouse = Hyperspace.Mouse.position
    return box.x <= mouse.x and mouse.x < box.x + box.w and
        box.y <= mouse.y and mouse.y < box.y + box.h
end

script.on_render_event(Defines.RenderEvents.MAIN_MENU, function() end, function()
    local menu = Hyperspace.App.menu
    if menu.shipBuilder.bOpen then
        return
    end
    moreMannable.auxEnabled = Hyperspace.metaVariables['_moreMannable_auxEnabled'] > 0
    local optionOn = moreMannable.auxEnabled
    local optionBox = optionOn and optionBoxOn or optionBoxOff
    local color
    if mouseInside(optionBox) then
        color = GOLD_COLOR
        local mouse = Hyperspace.Mouse
        mouse.overrideTooltipWidth = 720
        mouse:SetTooltip(optionOn and TEXTS.AUX_ON_TOOLTIP(moreMannable.MAX_RECENT_SKILL) or TEXTS.AUX_OFF_TOOLTIP())
    else
        color = WHITE_COLOR
    end
    Graphics.CSurface.GL_PushMatrix()
    Graphics.CSurface.GL_SetColor(color)
    Graphics.freetype.easy_print(62, optionBox.x, optionBox.y, optionBox.text)
    Graphics.CSurface.GL_PopMatrix()
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function()
    local menu = Hyperspace.App.menu
    if not menu.bOpen or menu.shipBuilder.bOpen then
        return
    end
    moreMannable.auxEnabled = Hyperspace.metaVariables['_moreMannable_auxEnabled'] > 0
    local optionOn = moreMannable.auxEnabled
    local optionBox = optionBoxOn and optionBoxOn or optionBoxOff
    if mouseInside(optionBox) then
        Hyperspace.metaVariables['_moreMannable_auxEnabled'] = optionOn and 0 or 1
        moreMannable.auxEnabled = not optionOn
    end
end)
