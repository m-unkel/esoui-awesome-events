--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: Clock.lua
  Last Modified: 28.05.18 17:45

  Copyright (c) 2018 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('clock')

local LABEL_CLOCK,LABEL_DATE = 1,2

MOD.title = GetString(SI_AWEMOD_CLOCK)
MOD.hint = GetString(SI_AWEMOD_CLOCK_HINT)
MOD.order = 10
MOD.debug = false

MOD.label = {}
MOD.label[LABEL_CLOCK] = {}
MOD.label[LABEL_DATE] = {}

-- USER SETTINGS

MOD.options = {
    hoursFormat24 = {
        type = "checkbox",
        name = GetString(SI_AWEMOD_CLOCK_FORMAT),
        tooltip = GetString(SI_AWEMOD_CLOCK_FORMAT_HINT),
        default = true,
        order = 1,
    },
    style = {
        type = 'dropdown',
        name = GetString(SI_AWEMOD_CLOCK_STYLE),
        tooltip = GetString(SI_AWEMOD_CLOCK_STYLE_HINT),
        choices = {GetString(SI_AWEMOD_CLOCK_STYLE_TIME),GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_SHORT),GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_LONG)},
        default = GetString(SI_AWEMOD_CLOCK_STYLE_TIME),
        order = 2,
    },
}
MOD.fontSize = 5

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.dataUpdated = true
end -- MOD:Enable

function MOD:Set(key,value)
    self:d('Set['..key..']',value)

    if(key=='style')then
        if(value~=GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_LONG))then
            self.label[LABEL_DATE]:SetText('')
        end
    end
    self.dataUpdated = true
end -- MOD:Set

-- EVENT LISTENER

function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_AWESOME_MODULE_TIMER,
            callback = function(eventCode, timestamp) return MOD:OnTimer(timestamp) end,
        },
    }
end -- MOD:GetEventListeners

-- EVENT HANDLER

function MOD:OnTimer(timestamp)
    self:d('OnTimer')
    self.dataUpdated = true
    self:d(' => dataUpdated')
end -- MOD:OnTimer

-- LABEL HANDLER

local function GetDateString(short)
    local date = GetDate()
    local year,month,day = string.sub(date,1,4), string.sub(date,5,6), string.sub(date,7,8)
    local dateString = short and GetString(SI_AWEMOD_CLOCK_DATEFORMAT_SHORT) or GetString(SI_AWEMOD_CLOCK_DATEFORMAT_LONG)
    dateString = string.gsub(dateString,"year",year,1)
    dateString = string.gsub(dateString,"day",day,1)
    dateString = string.gsub(dateString,"month",month,1)
    return dateString
end -- GetDateString

function MOD:Update(options)
    self:d('Update',options)
    local labelText = ''

    if(options.style == GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_LONG)) then
        self.label[LABEL_DATE]:SetText(GetDateString(false))
    elseif(options.style == GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_SHORT)) then
        labelText = GetDateString(true) .. ' - '
    end

    local timeFormat = TIME_FORMAT_PRECISION_TWELVE_HOUR
    if (options.hoursFormat24) then
        timeFormat = TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
    end
    labelText = labelText .. FormatTimeSeconds(GetSecondsSinceMidnight(), TIME_FORMAT_STYLE_CLOCK_TIME, timeFormat, TIME_FORMAT_DIRECTION_NONE)
    self.label[LABEL_CLOCK]:SetText(labelText)
end -- MOD:Update