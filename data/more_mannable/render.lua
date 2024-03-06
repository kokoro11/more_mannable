local moreMannable = mods.moreMannable

local function createPrimitive(filename, x, y)
    return Hyperspace.Resources:CreateImagePrimitiveString(filename, x, y, 0, Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_MANAGER, function(shipMgr)
    if not shipMgr.table.moreMannable then
        shipMgr.table.moreMannable = {}
    end
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    if shipMgr.iShipId ~= 0 then
        return
    end
    local userdata = shipMgr.table.moreMannable
    if not userdata.init then
        userdata.customInteriorImages = moreMannable.imgs[shipMgr.myBlueprint.blueprintName]
        userdata.init = true
    end
    local customInteriorImages = userdata.customInteriorImages
    if not customInteriorImages then
        return
    end
    local vSystemList = shipMgr.artillerySystems
    for i = 0, vSystemList:size() - 1 do
        local sys = vSystemList[i]
        if not sys.table.moreMannable.interiorImageReplaced then
            local img_name = customInteriorImages[sys:GetRoomId()]
            if img_name then
                local img_path = 'ship/interior/' .. img_name .. '.png'
                local loc = sys.pLoc
                if sys.interiorImage then
                    Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImage)
                end
                sys.interiorImage = createPrimitive(img_path, loc.x, loc.y)
                if sys.interiorImageOn then
                    Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImageOn)
                end
                sys.interiorImageOn = createPrimitive(img_path, loc.x, loc.y)
                if sys.interiorImageManned then
                    Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImageManned)
                end
                sys.interiorImageManned = createPrimitive(img_path, loc.x, loc.y)
                if sys.interiorImageMannedFancy then
                    Graphics.CSurface.GL_DestroyPrimitive(sys.interiorImageMannedFancy)
                end
                sys.interiorImageMannedFancy = createPrimitive(img_path, loc.x, loc.y)
            end
            sys.table.moreMannable.interiorImageReplaced = true
        end
    end
end)

local TextMeta = {
    __index = function(texts)
        return texts['']
    end,
    __call = function(texts)
        return texts[Hyperspace.Settings.language]
    end
}

local function Text(texts)
    setmetatable(texts, TextMeta)
    return texts
end
moreMannable.Text = Text

local tooltips = {}
moreMannable.tooltips = tooltips

tooltips.off = {}
tooltips.off.title = Text {
    [''] = [[Manning disabled for auxiliary systems]],
}
tooltips.off.text = Text {
    [''] = [[Current mannable systems and manning bonuses:
Oxygen: Doubles the speed of oxygen refill.
Drones: Increases operating speed by 25% for crew drones and space drones.
Artillery: Boosts recharge speed by 25%.
Enable Aux Manning for more mannable systems.]],
}

tooltips.on = {}
tooltips.on.title = Text {
    [''] = [[Manning enabled for auxiliary systems]],
}
tooltips.on.text = Text {
    [''] = [[Current mannable systems and manning bonuses:
Oxygen: Doubles the speed of oxygen refill.
Drones: Increases operating speed by 25% for crew drones and space drones.
Artillery: Boosts recharge speed by 25%.
Cloaking: Enhances evasion by 40%.
Mind Control: Extends control duration by 25%.
Hacking: Accelerates hacking speed by 25%.
Temporal: Reduces system cooldown by 20%.]],
}

local whiteColor = Graphics.GL_Color(255 / 255, 255 / 255, 255 / 255, 1.0)
local goldColor = Graphics.GL_Color(250 / 255, 250 / 255, 90 / 255, 1.0)

local optionBoxOn = {
    text = "AUX MANNING: ON",
    x = 40,
    y = 670,
    w = 284,
    h = 27
}

local optionBoxOff = {
    text = "AUX MANNING: OFF",
    x = 40,
    y = 670,
    w = 303,
    h = 27
}

local function mouseInside(box)
    local mouse = Hyperspace.Mouse.position
    return box.x <= mouse.x and mouse.x < box.x + box.w and
        box.y <= mouse.y and mouse.y < box.y + box.h
end

script.on_render_event(Defines.RenderEvents.MAIN_MENU, function() end, function()
    local menu = Hyperspace.Global.GetInstance():GetCApp().menu
    if menu.shipBuilder.bOpen then
        return
    end
    moreMannable.auxEnabled = Hyperspace.metaVariables['_moreMannable_auxEnabled'] > 0
    local optionOn = moreMannable.auxEnabled
    local optionBox = optionOn and optionBoxOn or optionBoxOff
    local color
    if mouseInside(optionBox) then
        color = goldColor
        local tooltip = optionOn and tooltips.on or tooltips.off
        Hyperspace.Mouse:SetTooltipTitle(tooltip.title())
        Hyperspace.Mouse:SetTooltip(tooltip.text())
    else
        color = whiteColor
    end
    Graphics.CSurface.GL_PushMatrix()
    Graphics.CSurface.GL_SetColor(color)
    Graphics.freetype.easy_print(63, optionBox.x, optionBox.y, optionBox.text)
    Graphics.CSurface.GL_PopMatrix()
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function()
    local menu = Hyperspace.Global.GetInstance():GetCApp().menu
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
