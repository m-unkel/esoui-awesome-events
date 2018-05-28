--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: SkyShards.lua
  Last Modified: 02.11.17 16:36

  Copyright (c) 2017 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('skyshards')

MOD.title = GetString(SI_AWEMOD_SKYSHARDS)
MOD.hint = GetString(SI_AWEMOD_SKYSHARDS_HINT)
MOD.order = 25
MOD.debug = false

-- OVERRIDES

-- USER SETTINGS

MOD.options = {
    shardsLeftInfo = {
        type = 'slider',
        name = GetString(SI_AWEMOD_SKYSHARDS_REMAINING),
        tooltip = GetString(SI_AWEMOD_SKYSHARDS_REMAINING_HINT),
        min  = 1,
        max = 3,
        default = 1,
        order = 1,
    },
}

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data = {
        shardsLeft = 0,
    }
    self:OnAchievementUpdate(0)
    self.dataUpdated = true
end

-- EVENT LISTENER

function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_ACHIEVEMENT_UPDATED,
            callback = function(eventCode,id) MOD:OnAchievementUpdate(id) end
        }
    }
end

-- EVENT HANDLER

function MOD:OnAchievementUpdate(id)
    self:d('OnAchievementUpdate ' .. id)
    local shardsLeft = 3-GetNumSkyShards()
    if( shardsLeft ~= self.data.shardsLeft ) then
        self.data.shardsLeft = shardsLeft
        self.dataUpdated = true
        self:d(' => dataUpdated')
    end
end

-- LABEL HANDLER

function MOD:Update(options)
    self:d('Update')
    local labelText = ''
    if (self.data.shardsLeft <= options.shardsLeftInfo) then
        local color = (self.data.shardsLeft == 1) and COLOR_AWEVS_AVAILABLE or COLOR_AWEVS_HINT
        labelText = MOD.Colorize(color, GetString(SI_AWEMOD_SKYSHARDS_REMAINING_LABEL)) .. ': ' .. self.data.shardsLeft
    end
    self.label:SetText(labelText)
end -- MOD:Update