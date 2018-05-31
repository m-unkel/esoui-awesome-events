--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: AwesomeEvents.lua
  Last Modified: 31.05.18 15:30

  Copyright (c) 2018 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

Awesome_Events = {
    name = 'AwesomeEvents',
    panelName = 'AwesomeEventsOptions',
    title = 'Awesome Events',
    version = '1.4-RC4',

    defaults = {
        isDefault = true,
        window = {
            left = GuiRoot:GetWidth()/2,
            top = 100,
            movable = true,
            scaling = 1.0,
            textAlign = TEXT_ALIGN_CENTER,
            textColor = {
                [COLOR_AWEVS_AVAILABLE] = {r=0.5,g=0.83,b=0.5},
                [COLOR_AWEVS_HINT] = {r=0.83,g=0.8,b=0.5},
                [COLOR_AWEVS_WARNING] = {r=0.83,g=0.59,b=0.5},
            }
        },
    },

    events = {},

    initialized = false,
    dragging = false,
    lastUpdate = 0,
    lastWidth = 0,
    updateFrequency = 10,

    inSettingsPanel = false,
    position = {left=1000,top=30},

    importFromCharacter = nil
}

local libAM = LibStub('LibAwesomeModule-1.0')
local LIBMW = LibStub:GetLibrary("LibMsgWin-1.0")
local debugWindow

-- Create Debug Window
local function __ShowDebugWindow()
    if(debugWindow==nil)then
        debugWindow = LIBMW:CreateMsgWindow("AwesomeEventsDebugWindow", "Awesome Events Debug Log", 0, 0)
        if(libAM.debug)then
            for i,value in ipairs(libAM.log) do
                debugWindow:AddText(value)
            end
            libAM.log = {}
        end
        libAM.logCallback = function(value) debugWindow:AddText(value) end
    else
        debugWindow:SetHidden(false)
    end

    if(not libAM.debug)then
        debugWindow:AddText('Debug-Log: '..GetString(SI_AWEVS_DEBUG_DISABLED))
        debugWindow:AddText('Usage: /aedebug mod_id (on\off)')
    end
end -- __ShowDebugWindow

local function __HideDebugWindow()
    if(debugWindow~=nil)then
        debugWindow:SetHidden(true)
    end
end -- __HideDebugWindow


--- Initialize modules, config menu, views and user configuration
function Awesome_Events:Initialize()
    -- debugging
    for mod_id,mod in libAM:module_pairs() do
        if(mod.debug)then
            libAM.debug = true
        end
    end
    if(libAM.debug)then
        __ShowDebugWindow()
    end

    -- load module- and user configuration
    local panelOptions = self:LoadModulesConfiguration()
    self.vars = ZO_SavedVars:New('AwesomeEvents', 1, nil, self.defaults)
    self.vars.isDefault = false

    -- init modules: create labels and preload data
    local previousControl = AwesomeEventsView:GetChild(2)
    for mod_id,mod in libAM:module_pairs() do
        libAM.d('main','Initialize['..mod_id..']')
        previousControl = mod:Initialize( self.vars[mod_id], AwesomeEventsView, previousControl )
    end

    -- restore gui user config
    for key,color in pairs(self.vars.window.textColor) do
        libAM.SetColorDef(key,color.r,color.g,color.b)
    end
    AwesomeEventsView:SetScale(self.vars.window.scaling)
    AwesomeEventsView:SetMovable(self.vars.window.movable)
    self:SetTextAlign(self.vars.window.textAlign)
    self:UpdateFontSize()
    self:UpdateViewSize()

    -- create addon menu (LAM)
    self:CreateSettingsMenu(panelOptions)

    -- register LAM/optionsPanel events
    local lamControl = WINDOW_MANAGER:GetControlByName('LAMAddonSettingsWindow')
    local lamOnShowHandler = lamControl:GetHandler('OnShow')
    if(lamOnShowHandler ~= nil) then
        lamControl:SetHandler('OnShow',function(self,hidden)
            Awesome_Events.LAM_OnChangeActivePanel()
            lamOnShowHandler(self,hidden)
        end)
    else
        lamControl:SetHandler('OnShow',function(self,hidden)
            Awesome_Events.LAM_OnChangeActivePanel()
        end)
    end
    CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel",Awesome_Events.LAM_OnChangeActivePanel)

    -- register SCENE events
    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene,oldState,newState)
        if(scene.name == 'hud' or scene.name == 'hudui')then
            if(newState == SCENE_HIDING)then
                AwesomeEventsView:SetHidden(true)
            elseif(newState == SCENE_SHOWN)then
                Awesome_Events:Show()
            end
        elseif(scene.name == 'gameMenuInGame')then
            if(newState == SCENE_HIDING)then
                Awesome_Events.inSettingsPanel = false
                AwesomeEventsView:SetHidden(true)
            elseif(newState == SCENE_SHOWN)then
                Awesome_Events.inSettingsPanel = true
            end
        end
    end)

    -- register MODULE events
    self:UpdateEventListeners()

    self.initialized = true

    self:Show()
end -- Awesome_Events.Initialize

local function __recursive_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[__recursive_copy(orig_key)] = __recursive_copy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end -- __recursive_copy

function Awesome_Events:ImportConfigFromCharacter(characterName)
    libAM.d('main','ImportConfigFromCharacter',characterName)
    if(characterName == nil or characterName == GetString(SI_AWEVS_IMPORT_CHARACTER_SELECT))then
        return
    end

    local characterId
    if(characterName ~= GetUnitName('player'))then
        for i = 1, GetNumCharacters() do
            local name, _, _, _, _, _, id = GetCharacterInfo(i)
            if(characterName == zo_strformat("<<1>>", name))then
                characterId = id
            end
        end
    end

    if(characterId ~= nil)then
        local tempVars = ZO_SavedVars:New('AwesomeEvents', 1, nil, self.defaults, "Default", GetDisplayName(), characterName, characterId, ZO_SAVED_VARS_CHARACTER_NAME_KEY)
        if(not tempVars.isDefault)then
            for key in pairs(self.defaults) do
                self.vars[key] = __recursive_copy(tempVars[key])
            end
            libAM.d('main','Imported successfully!')
            -- restore module user config
            for mod_id,mod in libAM:module_pairs() do
                mod:Disable()
                if(self.vars[mod_id].enabled)then
                    mod:Enable(self.vars[mod_id])
                end
            end
            -- restore gui user config
            for key,color in pairs(self.vars.window.textColor) do
                libAM.SetColorDef(key,color.r,color.g,color.b)
            end
            AwesomeEventsView:SetScale(self.vars.window.scaling)
            AwesomeEventsView:SetMovable(self.vars.window.movable)
            self:SetTextAlign(self.vars.window.textAlign)
            self:UpdateFontSize()
            self:UpdateViewSize()
        end
    end
end -- Awesome_Events:ImportConfigFromCharacter

---
-- CONFIGURATION (LibAddonMenu-2.0)
---

--- create a getFcn function callback for LAM panelOptions
local function __CreateSettingsGetter(mod_id,key,transformer)
    if(libAM.modules[mod_id] == nil) then return end
    local mod = libAM.modules[mod_id]
    if(key=='spacingPosition')then
        return function() return Awesome_Events.GetSpacingPositionString(Awesome_Events.vars[mod_id][key]) end
    else
        if(transformer ~= nil)then
            return function() return transformer(Awesome_Events.vars[mod_id][key]) end
        else
            return function() return Awesome_Events.vars[mod_id][key] end
        end
    end
end -- __CreateSettingsGetter

--- create a setFcn function callback for LAM panelOptions
local function __CreateSettingsSetter(mod_id,key,transformer)
    if(libAM.modules[mod_id] == nil) then return end
    local mod = libAM.modules[mod_id]
    if(key=='enabled')then
        return function(value)
            Awesome_Events.vars[mod.id][key] = value
            if(value)then
                libAM.d('main','Enable['..mod_id..']')
                mod:Enable(Awesome_Events.vars[mod_id])
            else
                libAM.d('main','Disable['..mod_id..']')
                mod:Disable()
            end
            Awesome_Events:UpdateEventListeners()
            Awesome_Events:UpdateViewSize()
        end
    elseif(key=='spacingPosition')then
        return function(value)
            Awesome_Events:SetSpacingPosition(mod_id,value)
        end
    elseif(key=='spacing')then
        return function(value)
            Awesome_Events.vars[mod_id][key] = value
            Awesome_Events:UpdateViewSize()
        end
    elseif(key=='fontSize')then
        return function(value)
            Awesome_Events.vars[mod_id][key] = value
            Awesome_Events:UpdateFontSize()
            Awesome_Events:UpdateViewSize()
        end
    end
    return function(value)
        if(transformer ~= nil)then
            value = transformer(value)
        end
        Awesome_Events.vars[mod_id][key] = value
        libAM.d('main','Set['..mod_id..']: '..key,value)
        mod:Set(key,value)
    end
end -- __CreateSettingsSetter

--- create a disabled function callback for LAM panelOptions
local function __CreateSettingsDisabler(mod_id,key)
    return function() return not(Awesome_Events.vars[mod_id][key]) end
end -- __CreateSettingsDisabler

--- create the addon menu with libaddonmenu
function Awesome_Events:CreateSettingsMenu(panelOptions)
    local LAM2 = LibStub('LibAddonMenu-2.0')
    local panelData = {
        type = 'panel',
        name = self.name,
        author = 'Ze_Mi',
        version = '|c60FF60' .. self.version .. '|r',
        displayName = '|c8080FF' .. self.title .. '|r',
        registerForRefresh  = true,
        registerForDefaults = true,
    }

    LAM2:RegisterAddonPanel(self.panelName, panelData)
    LAM2:RegisterOptionControls(self.panelName, panelOptions)
end -- Awesome_Events:CreateSettingsMenu

--- load module configuration and inject getter/setter, build default configuration
function Awesome_Events:LoadModulesConfiguration()
    -- load characters for copy button
    local importOptions = {GetString(SI_AWEVS_IMPORT_CHARACTER_SELECT)}
    for i = 1, GetNumCharacters() do
        local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
        if(characterId ~= GetCurrentCharacterId())then
            table.insert(importOptions,zo_strformat("<<1>>", name))
        end
    end

    local panelOptions = {
        {
            type = 'description',
            text = GetString(SI_AWEVS_DESCRIPTION),
        },
        {
            type = 'header',
            name = '|c45D7F7' .. GetString(SI_AWEVS_APPEARANCE) .. '|r',
        },
        {
            type = 'checkbox',
            name = GetString(SI_AWEVS_APPEARANCE_MOVABLE),
            tooltip = GetString(SI_AWEVS_APPEARANCE_MOVABLE_HINT),
            getFunc = function() return Awesome_Events.vars.window.movable end,
            setFunc = function(newValue) Awesome_Events:SetMovable(newValue) end,
            default = self.defaults.window.movable,
        },
        {
            type = 'dropdown',
            name = GetString(SI_AWEVS_APPEARANCE_TEXTALIGN),
            tooltip = GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_HINT),
            choices = {GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_LEFT),GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_CENTER),GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_RIGHT)},
            getFunc = function() return Awesome_Events.GetTextAlignString(Awesome_Events.vars.window.textAlign) end,
            setFunc = function(newValue) Awesome_Events:SetTextAlign(newValue) end,
            default = function() return Awesome_Events.GetTextAlignString(Awesome_Events.defaults.window.textAlign) end,
        },
        {
            type = 'slider',
            name = GetString(SI_AWEVS_APPEARANCE_UISCALE),
            tooltip = GetString(SI_AWEVS_APPEARANCE_UISCALE_HINT),
            min  = 5,
            max = 15,
            getFunc = function() return 10 * Awesome_Events.vars.window.scaling end,
            setFunc = function(newValue) Awesome_Events:SetScale(newValue) end,
            default = 10 * self.defaults.window.scaling,
        },
        {
            type = 'colorpicker',
            name = GetString(SI_AWEVS_APPEARANCE_COLOR_AVAILABLE),
            tooltip = GetString(SI_AWEVS_APPEARANCE_COLOR_AVAILABLE_HINT),
            getFunc = function() local c=Awesome_Events.vars.window.textColor[COLOR_AWEVS_AVAILABLE]; return c.r,c.g,c.b,1 end,
            setFunc = function(r, g, b, a) Awesome_Events:SetTextColor(COLOR_AWEVS_AVAILABLE,r,g,b) end,
            default = self.defaults.window.textColor[COLOR_AWEVS_AVAILABLE],
        },
        {
            type = 'colorpicker',
            name = GetString(SI_AWEVS_APPEARANCE_COLOR_HINT),
            tooltip = GetString(SI_AWEVS_APPEARANCE_COLOR_HINT_HINT),
            getFunc = function() local c=Awesome_Events.vars.window.textColor[COLOR_AWEVS_HINT]; return c.r,c.g,c.b,1 end,
            setFunc = function(r, g, b, a) Awesome_Events:SetTextColor(COLOR_AWEVS_HINT,r,g,b) end,
            default = self.defaults.window.textColor[COLOR_AWEVS_HINT],
        },
        {
            type = 'colorpicker',
            name = GetString(SI_AWEVS_APPEARANCE_COLOR_WARNING),
            tooltip = GetString(SI_AWEVS_APPEARANCE_COLOR_WARNING_HINT),
            getFunc = function() local c=Awesome_Events.vars.window.textColor[COLOR_AWEVS_WARNING]; return c.r,c.g,c.b,1 end,
            setFunc = function(r, g, b, a) Awesome_Events:SetTextColor(COLOR_AWEVS_WARNING,r,g,b) end,
            default = self.defaults.window.textColor[COLOR_AWEVS_WARNING],
        },
        {
            type = 'header',
            name = '|c45D7F7' .. GetString(SI_AWEVS_IMPORT) .. '|r',
        },
        {
            type = 'description',
            text = GetString(SI_AWEVS_IMPORT_DESCRIPTION),
        },
        {
            type = 'dropdown',
            name = GetString(SI_AWEVS_IMPORT_CHARACTER_LABEL),
            choices = importOptions,
            getFunc = function() return GetString(SI_AWEVS_IMPORT_CHARACTER_SELECT) end,
            setFunc = function(newValue) Awesome_Events.importFromCharacter = newValue end,
            default = GetString(SI_AWEVS_IMPORT_CHARACTER_SELECT),
        },
        {
            type = 'button',
            name = GetString(SI_AWEVS_IMPORT_BUTTON),
            func = function() Awesome_Events:ImportConfigFromCharacter(Awesome_Events.importFromCharacter) end,
        },
    }
    -- foreach module
    for mod_id,mod in libAM:module_pairs() do
        libAM.d('main','LoadModule['..mod_id..']')
        -- create defaults
        self.defaults[mod_id] = self.defaults[mod_id] or {}
        self.defaults[mod_id].enabled = true
        self.defaults[mod_id].spacingPosition = mod.spacingPosition or TEXT_ALIGN_BOTTOM
        self.defaults[mod_id].spacing = mod.spacing or 5
        self.defaults[mod_id].fontSize = mod.fontSize or 1
        table.insert( panelOptions,{
            type = 'header',
            name = '|c45D7F7' .. mod.title .. '|r',
        })
        table.insert( panelOptions,{
            type = 'checkbox',
            name = GetString(SI_AWEMOD_SHOW),
            tooltip = mod.hint,
            getFunc = __CreateSettingsGetter(mod_id,'enabled'),
            setFunc = __CreateSettingsSetter(mod_id,'enabled'),
            default = self.defaults[mod_id].enabled,
        })
        table.insert( panelOptions, {
            type = 'dropdown',
            name = GetString(SI_AWEMOD_SPACING_POSITION),
            tooltip = GetString(SI_AWEMOD_SPACING_POSITION_HINT),
            choices = {GetString(SI_AWEMOD_SPACING_TOP),GetString(SI_AWEMOD_SPACING_BOTTOM),GetString(SI_AWEMOD_SPACING_BOTH)},
            getFunc = __CreateSettingsGetter(mod_id,'spacingPosition'),
            setFunc = __CreateSettingsSetter(mod_id,'spacingPosition'),
            disabled = __CreateSettingsDisabler(mod_id,'enabled'),
            default = self.GetSpacingPositionString(self.defaults[mod_id].spacingPosition),
        })
        table.insert( panelOptions,{
            type = 'slider',
            name = GetString(SI_AWEMOD_SPACING),
            tooltip = GetString(SI_AWEMOD_SPACING_HINT),
            min  = 0,
            max = 30,
            getFunc = __CreateSettingsGetter(mod_id,'spacing'),
            setFunc = __CreateSettingsSetter(mod_id,'spacing'),
            disabled = __CreateSettingsDisabler(mod_id,'enabled'),
            default = self.defaults[mod_id].spacing,
        })
        table.insert( panelOptions,{
            type = 'slider',
            name = GetString(SI_AWEMOD_FONTSIZE),
            tooltip = GetString(SI_AWEMOD_FONTSIZE_HINT),
            min  = 1,
            max = 5,
            getFunc = __CreateSettingsGetter(mod_id,'fontSize'),
            setFunc = __CreateSettingsSetter(mod_id,'fontSize'),
            disabled = __CreateSettingsDisabler(mod_id,'enabled'),
            default = self.defaults[mod_id].fontSize,
        })
        -- foreach options
        for key,option in mod:option_pairs() do
            if(option.type~=nil and option.name ~= nil and option.tooltip ~= nil and option.default ~= nil)then
                self.defaults[mod_id][key] = option.default
                if(option.getTransformer ~= nil)then
                    option.getFunc = __CreateSettingsGetter(mod_id,key,option.getTransformer)
                else
                    option.getFunc = __CreateSettingsGetter(mod_id,key)
                end
                if(option.setTransformer ~= nil)then
                    option.setFunc = __CreateSettingsSetter(mod_id,key,option.setTransformer)
                else
                    option.setFunc = __CreateSettingsSetter(mod_id,key)
                end
                option.disabled = __CreateSettingsDisabler(mod_id,'enabled')
                table.insert( panelOptions, option )
            else
                libAM.d('main','LoadModule['..mod_id..']',GetString(SI_AWEVS_DEBUG_MODULE_OPTION_INVALID),option)
            end
        end
    end
    return panelOptions
end -- Awesome_Events:LoadModulesConfiguration


---
-- GLOBAL Configuration / Layout
---

--- return a textAlign property as localized string
function Awesome_Events.GetTextAlignString(textAlign)
    if(textAlign == TEXT_ALIGN_LEFT) then return GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_LEFT) end
    if(textAlign == TEXT_ALIGN_CENTER) then return GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_CENTER) end
    if(textAlign == TEXT_ALIGN_RIGHT) then return GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_RIGHT) end
    return nil
end -- Awesome_Events.GetTextAlignString

--- return a spacingPosition property as localized string
function Awesome_Events.GetSpacingPositionString(spacingPosition)
    if(spacingPosition == TEXT_ALIGN_TOP) then return GetString(SI_AWEMOD_SPACING_TOP) end
    if(spacingPosition == TEXT_ALIGN_BOTTOM) then return GetString(SI_AWEMOD_SPACING_BOTTOM) end
    if(spacingPosition == TEXT_ALIGN_CENTER) then return GetString(SI_AWEMOD_SPACING_BOTH) end
    return nil
end -- Awesome_Events.GetSpacingPositionString

--- change view movability
function Awesome_Events:SetMovable(movable)
    self.vars.window.movable = movable
    AwesomeEventsView:SetMovable(movable)
end -- Awesome_Events:SetMovable

--- change view scale
function Awesome_Events:SetScale(scaling)
    self.vars.window.scaling = scaling / 10;
    AwesomeEventsView:SetScale(self.vars.window.scaling)
    self:UpdateViewSize()
end -- Awesome_Events:SetScale

--- change horizontal alignment of all labels, adjust view position
function Awesome_Events:SetTextAlign(newTextAlign)
    -- translate value to key
    if(newTextAlign == GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_LEFT)) then
        newTextAlign = TEXT_ALIGN_LEFT
    elseif(newTextAlign == GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_RIGHT)) then
        newTextAlign = TEXT_ALIGN_RIGHT
    elseif(newTextAlign == GetString(SI_AWEVS_APPEARANCE_TEXTALIGN_CENTER)) then
        newTextAlign = TEXT_ALIGN_CENTER
    end
    -- keep the position even if the anchor changes
    if(self.initialized)then
        local halfWindowWidth,leftShift = math.floor(AwesomeEventsView:GetWidth()/2),0
        if(self.vars.window.textAlign == TEXT_ALIGN_LEFT)then
            leftShift = halfWindowWidth
        elseif(self.vars.window.textAlign == TEXT_ALIGN_RIGHT)then
            leftShift = 0 - halfWindowWidth
        end
        if(newTextAlign == TEXT_ALIGN_LEFT)then
            leftShift = leftShift - halfWindowWidth
        elseif(newTextAlign == TEXT_ALIGN_RIGHT)then
            leftShift = leftShift + halfWindowWidth
        end
        self.position.left = self.position.left + leftShift
        self.vars.window.left = self.vars.window.left + leftShift
    end
    self.vars.window.textAlign = newTextAlign

    self:UpdateViewPosition()
    for i = 2, AwesomeEventsView:GetNumChildren() do
        local child = AwesomeEventsView:GetChild(i)
        child:SetHorizontalAlignment(newTextAlign)
    end
end -- Awesome_Events:SetTextAlign

function Awesome_Events:SetTextColor(type,rValue,gValue,bValue)
    rValue = math.floor(rValue*100)/100
    gValue = math.floor(gValue*100)/100
    bValue = math.floor(bValue*100)/100
    libAM.SetColorDef(type,rValue,gValue,bValue)
    self.vars.window.textColor[type] = {r=rValue,g=gValue,b=bValue}
    for mod_id,mod in libAM:module_pairs() do
        if(self.vars[mod_id].enabled)then
            mod.dataUpdated = true
        end
    end
end -- Awesome_Events:SetTextColor

--- change vertical alignment of a label, adjust view size
function Awesome_Events:SetSpacingPosition(mod_id,newSpacingPosition)
    -- translate value to key
    if(newSpacingPosition == GetString(SI_AWEMOD_SPACING_TOP)) then
        newSpacingPosition = TEXT_ALIGN_TOP
    elseif(newSpacingPosition == GetString(SI_AWEMOD_SPACING_BOTTOM)) then
        newSpacingPosition = TEXT_ALIGN_BOTTOM
    elseif(newSpacingPosition == GetString(SI_AWEMOD_SPACING_BOTH)) then
        newSpacingPosition = TEXT_ALIGN_CENTER
    end
    self.vars[mod_id].spacingPosition = newSpacingPosition
    self:UpdateViewSize()
end -- Awesome_Events:SetSpacingPosition

--- after resizing the window, or on first load, the anchors have to be resetted
function Awesome_Events:UpdateViewPosition()
    AwesomeEventsView:ClearAnchors()
    if (self.vars.window.textAlign == TEXT_ALIGN_LEFT) then
        AwesomeEventsView:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.position.left, self.position.top)
    elseif (self.vars.window.textAlign == TEXT_ALIGN_RIGHT) then
        AwesomeEventsView:SetAnchor(TOPRIGHT, GuiRoot, TOPLEFT, self.position.left, self.position.top)
    else
        AwesomeEventsView:SetAnchor(TOP, GuiRoot, TOPLEFT, self.position.left, self.position.top)
    end
end -- Awesome_Events:UpdateViewPosition

--- update the font size of all labels
function Awesome_Events:UpdateFontSize()
    -- starting at 1, but 1 = backgorund, 2 = titel
    for i = 3, AwesomeEventsView:GetNumChildren() do
        local child = AwesomeEventsView:GetChild(i)
        local mod_id = libAM.labelToMod[i]
        local fontSize = 6-self.vars[mod_id].fontSize
        if(fontSize<1)then fontSize = 1 end
        if(fontSize>5)then fontSize = 5 end
        child:SetFont('ZoFontWinH'..fontSize)
    end
end -- Awesome_Events:UpdateFontSize

--- resize the window to show all visible labels
function Awesome_Events:UpdateViewSize()
    if self.dragging then return end

    local maxWidth,totalHeight,lastModId,lastLabel,lastModLabelCount = 0,0,nil,nil,0
    local lazyAddSpacing = 0

    -- starting at 1, but 1 = backgorund, 2 = titel
    for i = 3, AwesomeEventsView:GetNumChildren() do
        local child = AwesomeEventsView:GetChild(i)
        local text = child:GetText()
        -- hide if text is empty
        if(text == '')then
            -- not hidden yet?
            if(child:GetHeight() > 0)then
                child:SetHeight(0)
            end
        -- show label with text
        else
            child:SetWidth(0)
            local mod_id,spacing = libAM.labelToMod[i],0
            -- last mod ended ?
            if(lastModId~=mod_id)then
                -- add bottom spacing to previous label (if mod has multiple label for)
                if(lazyAddSpacing>0)then
                    lastLabel:SetHeight(lastLabel:GetHeight() + lazyAddSpacing);
                    totalHeight = totalHeight + lazyAddSpacing
                    if(lastModLabelCount>1 or self.vars[lastModId].spacingPosition==TEXT_ALIGN_TOP)then
                        lastLabel:SetVerticalAlignment(TEXT_ALIGN_TOP);
                    else
                        lastLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER);
                    end
                    lazyAddSpacing = 0
                end
                lastModLabelCount = 0

                -- add top spacing
                if(self.vars[mod_id].spacingPosition==TEXT_ALIGN_BOTTOM)then
                    spacing = self.vars[mod_id].spacing
                    child:SetVerticalAlignment(TEXT_ALIGN_BOTTOM);
                elseif(self.vars[mod_id].spacingPosition==TEXT_ALIGN_CENTER)then
                    spacing = self.vars[mod_id].spacing
                    child:SetVerticalAlignment(TEXT_ALIGN_BOTTOM);
                    lazyAddSpacing = spacing
                elseif(self.vars[mod_id].spacingPosition==TEXT_ALIGN_TOP)then
                    child:SetVerticalAlignment(TEXT_ALIGN_TOP);
                    lazyAddSpacing = self.vars[mod_id].spacing
                end
            end

            local newHeight = child:GetTextHeight() + spacing
            -- not yet visible or wrong spacing ?
            if(newHeight ~= child:GetHeight())then
                child:SetHeight(newHeight)
            end
            totalHeight = totalHeight + newHeight
            maxWidth = math.max(maxWidth,child:GetTextWidth())

            lastModLabelCount = lastModLabelCount+1
            lastModId = mod_id
            lastLabel = child
        end
    end

    if(lazyAddSpacing>0)then
        lastLabel:SetHeight(lastLabel:GetHeight() + lazyAddSpacing);
        totalHeight = totalHeight + lazyAddSpacing
        if(lastModLabelCount>1)then
            lastLabel:SetVerticalAlignment(TEXT_ALIGN_TOP);
        else
            lastLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER);
        end
    end

    -- show awesome events label if no other label active
    local child = AwesomeEventsView:GetChild(2)
    local text = child:GetText()
    if(totalHeight>0 and text~='')then
        child:SetText('')
        child:SetHeight(0)
    elseif(totalHeight==0)then
        text = GetString(SI_AWEVS_NO_ACTIVE_MOD)
        for mod_id in libAM:module_pairs() do
            if(self.vars[mod_id].enabled)then
                text = self.title
            end
        end
        child:SetText(text)
        child:SetWidth(0)
        totalHeight = child:GetTextHeight()
        child:SetHeight(totalHeight)
        maxWidth = child:GetTextWidth()
    end

    maxWidth = (maxWidth+20)
    totalHeight = totalHeight+10

    for i = 2, AwesomeEventsView:GetNumChildren() do
        local child = AwesomeEventsView:GetChild(i)
        child:SetWidth(maxWidth)
    end

    AwesomeEventsView:SetWidth(maxWidth)
    AwesomeEventsView:SetHeight(totalHeight)

    if(self.lastWidth ~= maxWidth)then
        self.lastWidth = maxWidth
        self:UpdateViewPosition();
    end
end -- Awesome_Events:UpdateViewSize

---
-- MAIN FRAME UPDATE
---

-- main update: firering timer, call mod update functions, update the viewsize
function Awesome_Events:Update(timestamp)
    -- trigger EVENT_AWESOME_MODULE_TIMER
    if(self.events[EVENT_AWESOME_MODULE_TIMER] ~= nil)then
        local secondsToNextMinute = 60 - timestamp%60
        if(secondsToNextMinute<10)then
            secondsToNextMinute = secondsToNextMinute + 60
        end
        for mod_id,callback in pairs(self.events[EVENT_AWESOME_MODULE_TIMER]) do
            if(self.vars[mod_id].enabled and libAM.timer[mod_id] > 0 and libAM.timer[mod_id]<=timestamp)then
                libAM.d('main','OnTimer['..mod_id..']')
                local seconds = callback(EVENT_AWESOME_MODULE_TIMER,timestamp)
                -- no return value => execute every minute
                if(type(seconds)~= 'number')then
                    seconds = secondsToNextMinute
                else
                    libAM.d('main','NextCustomTimer['..mod_id..'] in ' .. tostring(seconds) .. ' seconds')
                end
                -- timer still enabled ?
                if(libAM.timer[mod_id]>0)then
                    if(seconds<1)then
                        libAM.d('main','StopTimer['..mod_id..']')
                        libAM.timer[mod_id] = 0
                    else
                        libAM.timer[mod_id] = timestamp + seconds
                    end
                end
            end
        end
    end
    local resizeView = false
    -- update each module
    for mod_id,mod in libAM:module_pairs() do
        if(self.vars[mod.id].enabled and mod:HasUpdate())then
            mod.dataUpdated = false
            mod:Update(self.vars[mod.id])
            resizeView = true
        end
    end
    if(resizeView)then
        self:UpdateViewSize();
    end
end -- Awesome_Events:Update

function Awesome_Events:UpdateEventListeners()
    libAM.d('main','UpdateEventListeners')
    -- remove old listeners
    for eventCode,event in pairs(self.events) do
        EVENT_MANAGER:UnregisterForEvent('Awesome_Events', eventCode)
    end

    self.events = {}
    self.events[EVENT_AWESOME_MODULE_TIMER] = {}
    -- foreach module
    for mod_id,mod in libAM:module_pairs() do
        if(self.vars[mod.id].enabled)then
            local events = mod:GetEventListeners()
            for i,event in pairs(events) do
                if(event.eventCode ~= nil and event.callback ~= nil)then
                    if(self.events[event.eventCode] == nil)then
                        self.events[event.eventCode] = {}
                        EVENT_MANAGER:RegisterForEvent('Awesome_Events', event.eventCode, function(...) Awesome_Events:OnEvent(unpack({...})) end)
                    end
                    self.events[event.eventCode][mod.id] = event.callback
                else
                    libAM.d('main','UpdateEventListeners['..mod_id..']',GetString(SI_AWEVS_DEBUG_MODULE_EVENT_INVALID),event)
                end
            end
        end
    end
    libAM.timer = {}
    if(self.events[EVENT_AWESOME_MODULE_TIMER] ~= nil)then
        -- foreache awesome events timer
        for mod_id,callback in pairs(self.events[EVENT_AWESOME_MODULE_TIMER]) do
            libAM.timer[mod_id] = 1
        end
    end
end -- Awesome_Events:UpdateEventListeners

---
--- SHOW
---

function Awesome_Events:Show()
    if AwesomeEventsView:IsHidden() then
        if (self.inSettingsPanel) then
            local sub = {
                [TEXT_ALIGN_LEFT] = AwesomeEventsView:GetWidth(),
                [TEXT_ALIGN_CENTER] = AwesomeEventsView:GetWidth()/2,
                [TEXT_ALIGN_RIGHT] = 0,
            }
            self.position.left = math.floor(GuiRoot:GetWidth()*0.96) - sub[self.vars.window.textAlign]
            self.position.top = 200

            AwesomeEventsView:SetDrawLayer(DL_OVERLAY)
            AwesomeEventsView:SetMovable(true)
            AwesomeEventsViewBg:SetAlpha(1)
        else
            self.position.left = self.vars.window.left
            self.position.top = self.vars.window.top

            AwesomeEventsView:SetDrawLayer(DL_BACKGROUND)
            AwesomeEventsView:SetMovable(self.vars.window.movable)
            AwesomeEventsViewBg:SetAlpha(0)
        end
        self:UpdateViewPosition()
        AwesomeEventsView:SetHidden(false)
    end
end -- Awesome_Events:ShowInSettings


--------------------
-- EVENT LISTENER --
--------------------

function Awesome_Events.OnPlayerActivated(event, initial)
    -- Only initialize the addon (after all addons are loaded)
    EVENT_MANAGER:UnregisterForEvent('Awesome_Events', EVENT_PLAYER_ACTIVATED)
    Awesome_Events:Initialize()
end -- Awesome_Events.OnAddOnLoaded

function Awesome_Events:OnEvent(...)
    local args = {... }
    local eventCode = args[1] or 'unknown'
    if(self.events[eventCode] ~= nil)then
        for mod_id,callback in pairs(self.events[eventCode]) do
            -- slibAM.d('main','OnEvent['..mod_id..']: '..eventCode)
            callback(unpack(args))
        end
    else
        libAM.d('main','OnEvent: '..eventCode..' - ' .. GetString(SI_AWEVS_DEBUG_NO_EVENT_CALLBACKS),self.events)
        EVENT_MANAGER:UnregisterForEvent('Awesome_Events', eventCode)
    end
end -- Awesome_Events:OnEvent

function Awesome_Events.OnMoveStart()
    -- start dragging mode
    Awesome_Events.dragging = true

    -- do not change alpha in LAMSettingsPanel
    if(not Awesome_Events.inSettingsPanel)then
        AwesomeEventsViewBg:SetAlpha(0.5)
    end
end -- Awesome_Events.OnMoveStart

function Awesome_Events.OnMoveStop()
    if (Awesome_Events.vars.window.textAlign == TEXT_ALIGN_LEFT) then
        Awesome_Events.position.left = AwesomeEventsView:GetLeft()
        Awesome_Events.position.top = AwesomeEventsView:GetTop()
    elseif (Awesome_Events.vars.window.textAlign == TEXT_ALIGN_RIGHT) then
        Awesome_Events.position.left = AwesomeEventsView:GetRight()
        Awesome_Events.position.top = AwesomeEventsView:GetTop()
    else
        Awesome_Events.position.left = AwesomeEventsView:GetCenter()
        Awesome_Events.position.top = AwesomeEventsView:GetTop()
    end

    -- do not store movement or change alpha in LAMSettingsPanel
    if(not Awesome_Events.inSettingsPanel)then
        AwesomeEventsViewBg:SetAlpha(0)
        Awesome_Events.vars.window.left = math.floor(Awesome_Events.position.left*100)/100;
        Awesome_Events.vars.window.top = math.floor(Awesome_Events.position.top*100)/100;
    end
    Awesome_Events.dragging = false
end -- Awesome_Events.OnMoveStop

function Awesome_Events.OnUpdate(timestamp)
    -- Bail if we haven't completed the initialisation routine yet.
    if (not Awesome_Events.initialized or Awesome_Events.dragging) then return end
    -- Only run this update if a full second has elapsed since last time we did so.
    --local timestamp = GetTimeStamp()
    if ( timestamp > Awesome_Events.lastUpdate ) then
        Awesome_Events.lastUpdate = timestamp
        Awesome_Events:Update(GetTimeStamp())
    end
end -- Awesome_Events.OnUpdate

function Awesome_Events.LAM_OnChangeActivePanel(panel)
    if(panel==nil or panel:GetName() == '')then
        panel = WINDOW_MANAGER:GetControlByName(Awesome_Events.panelName)
        if not panel:IsHidden() then
            Awesome_Events:Show()
        end
    elseif(panel:GetName()==Awesome_Events.panelName)then
        Awesome_Events:Show()
    else
        AwesomeEventsView:SetHidden(true)
    end
end

--------------------
-- SLASH COMMANDS --
--------------------

-- Typing /aedump as a command will activate this function. Primarily used for testing.
local function __SlashAEDebug(command)
    local args = {}
    for word in command:gmatch("%w+") do table.insert(args, word) end

    local task = args[1] or 'unknown';

    if(task=='show')then
        return __ShowDebugWindow()
    end
    if(task=='hide')then
        return __HideDebugWindow()
    end

    local mod_id = task
    local value = args[2] or nil

    if(mod_id ~= nil and libAM.modules[mod_id] ~= nil)then
        local mod = libAM.modules[mod_id]
        if(value ~= nil)then
            if(value=='on' or value=='On' or value=='ON'or value=='oN')then
                mod.debug = true
                libAM.debug = true
                __ShowDebugWindow()
            else
                mod.debug = false

                -- any other module in debug mode ?
                libAM.debug = false
                for mod_id,mod in libAM:module_pairs() do
                    if(mod.debug)then
                        libAM.debug = true
                    end
                end

                -- clear old logs
                if(not libAM.debug)then
                    libAM.log = {}
                    if(debugWindow)then
                        debugWindow:SetHidden(true)
                        debugWindow:ClearText()
                    end
                end
            end
        end
        local enabled = GetString(SI_AWEVS_DEBUG_DISABLED)
        if(mod.debug)then enabled =  GetString(SI_AWEVS_DEBUG_ENABLED) end
        d('[AwesomeEvents] Debug [' .. mod_id .. ']: ' .. enabled)
        libAM.d('Debug-Log: ' .. enabled)
    else
        d('[AwesomeEvents] Debug [' .. mod_id .. ']: '..GetString(SI_AWEVS_DEBUG_MODULE_NOT_FOUND),'Usage: /aedebug mod_id (on||off)')
    end
end -- __SlashAEDebug

SLASH_COMMANDS['/aedebug'] = __SlashAEDebug

EVENT_MANAGER:RegisterForEvent('Awesome_Events', EVENT_PLAYER_ACTIVATED, Awesome_Events.OnPlayerActivated)