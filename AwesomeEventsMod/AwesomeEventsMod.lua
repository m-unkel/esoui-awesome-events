--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: AwesomeEventsMod.lua
  Last Modified: 25.08.18 10:25

  Copyright (c) 2018 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('balancing')

-- title: header in settings menu
MOD.title = GetString(SI_AWEMOD_BALANCING)
-- hint: tootltip at module show/hide toggle in settings menu
MOD.hint = GetString(SI_AWEMOD_BALANCING_HINT)
-- order: default in the middle order = 40, at bottom ORDER_AWESOME_MODULE_PUSH_NOTIFICATION = 75
MOD.order = ORDER_AWESOME_MODULE_PUSH_NOTIFICATION
-- enable debugging ingame via /aedebug balancing on
-- disable debugging ingame via /aedebug balancing off
-- show debugging state ingame via /aedebug balancing
MOD.debug = false


-- USER SETTINGS

MOD.options = {
    showSessionTotal = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_BALANCING_TOTAL),
        tooltip = GetString(SI_AWEMOD_BALANCING_TOTAL_HINT),
        default = true,
        order = 1,
    },
    secondsFadeOut = {
        type = 'slider',
        name = GetString(SI_AWEMOD_BALANCING_TIMER),
        tooltip = GetString(SI_AWEMOD_BALANCING_TIMER_HINT),
        min  = 10,
        max = 120,
        default = 30,
        order = 2,
    },
}
-- fontSie: default = 1, max = 5
MOD.fontSize = 5

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable')
    self.data = {
        total = 0,
        last = 0,
        secondsFadeOut = options.secondsFadeOut,
        storeOpened = false,
        visible = false
    }
end

function MOD:Set(key,value)
    self:d('Set[' .. key .. '] ', value)
    if(key=='secondsFadeOut')then
        self.data.secondsFadeOut = value
    end
end

-- EVENT LISTENER
-- EVENT_MONEY_UPDATE (integer eventCode,number newMoney,number oldMoney,number reason)
function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_AWESOME_MODULE_TIMER,
            callback = function(eventCode, timestamp) return MOD:OnTimer(timestamp) end,
        },
        {
            eventCode = EVENT_OPEN_STORE,
            callback = function(eventCode)
                MOD.data.last = 0
                MOD.data.storeOpened = true
            end,
        },
        {
            eventCode = EVENT_OPEN_FENCE,
            callback = function(eventCode)
                MOD.data.last = 0
                MOD.data.storeOpened = true
            end,
        },
        {
            eventCode = EVENT_MONEY_UPDATE,
            callback = function(eventCode,newMoney,oldMoney,reason)
                self:d('EVENT_MONEY_UPDATE[reason] = ' .. reason)
                if(MOD.data.storeOpened)then
                    MOD.data.last = MOD.data.last + (newMoney-oldMoney)
                end
            end,
        },
        {
            eventCode = EVENT_CLOSE_STORE,
            callback = function(eventCode)
                if(MOD.data.storeOpened)then
                    MOD:OnCloseStore()
                end
            end,
        },
    }
end

-- EVENT HANDLER

function MOD:OnTimer(timestamp)
    self:d('OnTimer')
    self.data.visible = false
    self.dataUpdated = true
    self:d(' => dataUpdated')
    -- return the number of seconds when your timer should be executed the next time
    -- return nothing (nil) to execute the timer every full minute
    -- return 0 is equal to calling self:StopTimer()
    return 0
end

function MOD:OnCloseStore()
    self:d('OnCloseStore')
    self.data.storeOpened = false

    self.data.total = self.data.total + self.data.last
    self.data.visible = true
	self:StartTimer(self.data.secondsFadeOut)

    self.dataUpdated = true
    self:d(' => dataUpdated')
end -- MOD:OnFenceUpdate

-- LABEL HANDLER

function MOD:Update(options)
    self:d('Update')
    local labelText = ''
    if(self.data.visible)then
        local bilance = self.data.last
        if (options.showSessionTotal) then
            bilance = self.data.total
        end
        local color = (bilance >= 0) and COLOR_AWEVS_AVAILABLE or COLOR_AWEVS_WARNING
        labelText = MOD.Colorize(color, GetString(SI_AWEMOD_BALANCING_LABEL)) .. ': ' ..bilance
    end

    self.label:SetText(labelText)
end -- MOD:Update
