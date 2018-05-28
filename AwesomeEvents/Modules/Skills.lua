--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: Skills.lua
  Last Modified: 02.11.17 16:36

  Copyright (c) 2017 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('skills')

MOD.title = GetString(SI_AWEMOD_SKILLS)
MOD.hint = GetString(SI_AWEMOD_SKILLS_HINT)
MOD.order = 20
MOD.debug = false

local CHAMPION_ATTRIBUTES = { ATTRIBUTE_HEALTH, ATTRIBUTE_STAMINA, ATTRIBUTE_MAGICKA }

-- USER SETTINGS

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data = {
        attributes = 0,
        championPoints = 0,
        skills = 0,
        hasUnspentPoints = false,
    }
    self:OnPointsChanged(0)
    self.dataUpdated = true
end

-- EVENT LISTENER
-- points (attribute- and skillpoints)
-- EVENT_SKILL_POINTS_CHANGED (integer eventCode,number pointsBefore, number pointsNow, number partialPointsBefore, number partialPointsNow)
-- EVENT_ATTRIBUTE_UPGRADE_UPDATED (number eventCode)
-- EVENT_LEVEL_UPDATE (integer eventCode,string unitTag, number level)
function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_SKILL_POINTS_CHANGED,
            callback = function(eventCode, pointsBefore, pointsNow, partialPointsBefore, partialPointsNow)
                self:d("EVENT_SKILL_POINTS_CHANGED: ", pointsBefore .. '=>' .. pointsNow, partialPointsBefore .. '=>' .. partialPointsNow)
                MOD:OnPointsChanged(pointsNow-pointsBefore)
            end
        },
        {
            eventCode = EVENT_ATTRIBUTE_UPGRADE_UPDATED,
            callback = function(eventCode)
                self:d("EVENT_ATTRIBUTE_UPGRADE_UPDATED")
                MOD:OnPointsChanged(0)
            end
        },
        {
            eventCode = EVENT_UNSPENT_CHAMPION_POINTS_CHANGED,
            callback = function(eventCode)
                self:d("EVENT_UNSPENT_CHAMPION_POINTS_CHANGED")
                MOD:OnPointsChanged(0)
            end
        }
}
end -- MOD:GetEventListeners

-- EVENT HANDLER

function MOD:OnPointsChanged(numChanged)
    self:d('OnSkillPointsChanged ' .. numChanged)
    local attributes,skills,championPoints = GetAttributeUnspentPoints(),GetAvailableSkillPoints(),GetPlayerChampionPointsEarned()

    for i=1,GetNumChampionDisciplines() do
        championPoints = championPoints - GetNumPointsSpentInChampionDiscipline(i)
    end
    self:d(attributes,skills,championPoints)
    if(championPoints<0) then championPoints = 0 end

    if( attributes ~= self.data.attributes or championPoints ~= self.data.championPoints or skills ~= self.data.skills) then
        self.data.attributes = attributes
        self.data.championPoints = championPoints
        self.data.skills = skills
        self.data.hasUnspentPoints = ( attributes + championPoints + skills ) > 0

        self.dataUpdated = true
        self:d(' => dataUpdated')
    end
end -- MOD:OnPointsChanged

-- LABEL HANDLER

function MOD:Update(options)
    self:d('Update')
    local labelText = ''
    if (self.data.hasUnspentPoints) then
        if (self.data.attributes > 0) then
            labelText = MOD.Colorize(COLOR_AWEVS_AVAILABLE, GetString(SI_AWEMOD_SKILLS_ATTRIBUTES_LABEL)) .. ': ' .. self.data.attributes
        end
        if (self.data.skills > 0) then
            if(labelText~='')then labelText = labelText .. MOD.Colorize(COLOR_AWEVS_AVAILABLE, ' || ') end
            labelText = labelText .. MOD.Colorize(COLOR_AWEVS_AVAILABLE, GetString(SI_AWEMOD_SKILLS_SKILLS_LABEL)) .. ': ' .. self.data.skills
        end
        if (self.data.championPoints > 0) then
            if(labelText~='')then labelText = labelText .. MOD.Colorize(COLOR_AWEVS_AVAILABLE, ' || ') end
            labelText = labelText .. MOD.Colorize(COLOR_AWEVS_AVAILABLE, GetString(SI_AWEMOD_SKILLS_CHAMPIONPOINTS_LABEL)) .. ': ' .. self.data.championPoints
        end
    end
    self.label:SetText(labelText)
end -- MOD:Update