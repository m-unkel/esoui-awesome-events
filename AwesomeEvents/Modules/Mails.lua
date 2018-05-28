--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: Mails.lua
  Last Modified: 02.11.17 16:36

  Copyright (c) 2017 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('mails')

MOD.title = GetString(SI_AWEMOD_MAILS)
MOD.hint = GetString(SI_AWEMOD_MAILS_HINT)
MOD.order = 15
MOD.debug = false

-- OVERRIDES

-- USER SETTINGS

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data = {
        numUnread = 0,
    }
    self:OnMailNumUnreadChanged(GetNumUnreadMail())
    self.dataUpdated = true
end

-- EVENT LISTENER

function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_MAIL_NUM_UNREAD_CHANGED,
            callback = function(eventCode,numUnread) MOD:OnMailNumUnreadChanged(numUnread) end
        }
    }
end

-- EVENT HANDLER

function MOD:OnMailNumUnreadChanged(numUnread)
    self:d('OnMailNumUnreadChanged ' .. numUnread)
    if( numUnread ~= self.data.numUnread ) then
        self.data.numUnread = numUnread
        self.dataUpdated = true
        self:d(' => dataUpdated')
    end
end

-- LABEL HANDLER

function MOD:Update(options)
    self:d('Update')
    local labelText = ''
    if (self.data.numUnread > 0) then
        labelText = MOD.Colorize(COLOR_AWEVS_AVAILABLE, GetString(SI_AWEMOD_MAILS_LABEL)) .. ': ' .. self.data.numUnread
    end
    self.label:SetText(labelText)
end -- MOD:Update