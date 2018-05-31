--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: Clock.lua
  Last Modified: 31.05.18 15:30

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

local function GetDateString(dateString)
    local date = GetDate()
    local year,month,day = string.sub(date,1,4), string.sub(date,5,6), string.sub(date,7,8)
    dateString = string.gsub(dateString,"year",year,1)
    dateString = string.gsub(dateString,"day",day,1)
    dateString = string.gsub(dateString,"month",month,1)
    return dateString
end -- GetDateString

local function GetLocalDateString(dateString)
    dateString = string.gsub(dateString,"year",GetString(SI_AWEMOD_CLOCK_DATEFORMAT_YEAR),1)
    dateString = string.gsub(dateString,"day",GetString(SI_AWEMOD_CLOCK_DATEFORMAT_DAY),1)
    dateString = string.gsub(dateString,"month",GetString(SI_AWEMOD_CLOCK_DATEFORMAT_MONTH),1)
    return dateString
end
local function GetGlobalDateString(dateString)
    dateString = string.gsub(dateString,GetString(SI_AWEMOD_CLOCK_DATEFORMAT_YEAR),"year",1)
    dateString = string.gsub(dateString,GetString(SI_AWEMOD_CLOCK_DATEFORMAT_DAY),"day",1)
    dateString = string.gsub(dateString,GetString(SI_AWEMOD_CLOCK_DATEFORMAT_MONTH),"month",1)
    return dateString
end

local CONFIG_DATE_FORMAT,DATE_FORMAT = {},{
    "day/month/year",
    "day/month",
    "month/day/year",
    "month/day",
    "day.month.year",
    "day.month",
    "month.day.year",
    "month.day",
}

for k,v in pairs(DATE_FORMAT) do
    table.insert(CONFIG_DATE_FORMAT,GetLocalDateString(v) .. ' (' .. GetDateString(v) .. ')')
end


-- USER SETTINGS

MOD.options = {
    style = {
        type = 'dropdown',
        name = GetString(SI_AWEMOD_CLOCK_STYLE),
        tooltip = GetString(SI_AWEMOD_CLOCK_STYLE_HINT),
        choices = {GetString(SI_AWEMOD_CLOCK_STYLE_TIME),GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_SHORT),GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_LONG)},
        default = GetString(SI_AWEMOD_CLOCK_STYLE_TIME),
        order = 1,
    },
    hoursFormat24 = {
        type = "checkbox",
        name = GetString(SI_AWEMOD_CLOCK_FORMAT),
        tooltip = GetString(SI_AWEMOD_CLOCK_FORMAT_HINT),
        default = true,
        order = 2,
    },
    dateFormat = {
        type = "dropdown",
        name = GetString(SI_AWEMOD_CLOCK_DATEFORMAT),
        tooltip = GetString(SI_AWEMOD_CLOCK_DATEFORMAT_HINT),
        choices = CONFIG_DATE_FORMAT,
        default = GetString(SI_AWEMOD_CLOCK_DATEFORMAT_DEFAULT),
        getTransformer = function(value) return GetLocalDateString(value) .. ' (' .. GetDateString(value) .. ')'  end,
        setTransformer = function(value) return GetGlobalDateString(string.match(value, "(.*)%s")) end,
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

function MOD:Update(options)
    self:d('Update',options)
    local labelText = ''

    if(options.style == GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_LONG)) then
        self.label[LABEL_DATE]:SetText(GetDateString(options.dateFormat))
    elseif(options.style == GetString(SI_AWEMOD_CLOCK_STYLE_DATETIME_SHORT)) then
        labelText = GetDateString(options.dateFormat) .. ' - '
    end

    local timeFormat = TIME_FORMAT_PRECISION_TWELVE_HOUR
    if (options.hoursFormat24) then
        timeFormat = TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
    end
    labelText = labelText .. FormatTimeSeconds(GetSecondsSinceMidnight(), TIME_FORMAT_STYLE_CLOCK_TIME, timeFormat, TIME_FORMAT_DIRECTION_NONE)
    self.label[LABEL_CLOCK]:SetText(labelText)
end -- MOD:Update