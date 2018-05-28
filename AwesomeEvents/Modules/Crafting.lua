--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: Crafting.lua
  Last Modified: 28.05.18 16:53

  Copyright (c) 2018 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('crafting')

MOD.title = GetString(SI_AWEMOD_CRAFTING)
MOD.hint = GetString(SI_AWEMOD_CRAFTING_HINT)
MOD.order = 35
MOD.debug = false

local LABEL_BLACKSMITHING,LABEL_CLOTHIER,LABEL_JEWELRYCRAFTING,LABEL_WOODWORKING = 1,2,3,4

MOD.label = {
    [LABEL_BLACKSMITHING] = {},
    [LABEL_CLOTHIER] = {},
    [LABEL_JEWELRYCRAFTING] = {},
    [LABEL_WOODWORKING] = {}
}

-- USER SETTINGS

MOD.options = {
    showBlacksmithing = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_CRAFTING_BLACKSMITHING),
        tooltip = GetString(SI_AWEMOD_CRAFTING_BLACKSMITHING_HINT),
        default = true,
        order = 1,
    },
    showClothier = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_CRAFTING_CLOTHING),
        tooltip = GetString(SI_AWEMOD_CRAFTING_CLOTHING_HINT),
        default = true,
        order = 2,
    },
    showJewelry = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_CRAFTING_JEWELRY),
        tooltip = GetString(SI_AWEMOD_CRAFTING_JEWELRY_HINT),
        default = true,
        order = 3,
    },
    showWoodworking = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_CRAFTING_WOODWORKING),
        tooltip = GetString(SI_AWEMOD_CRAFTING_WOODWORKING_HINT),
        default = true,
        order = 4,
    },
    minutesLeftInfo = {
        type = 'slider',
        name = GetString(SI_AWEMOD_CRAFTING_TIMER),
        tooltip = GetString(SI_AWEMOD_CRAFTING_TIMER_HINT),
        min  = 1,
        max = 960,
        default = 480,
        order = 5,
    },
}

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data[CRAFTING_TYPE_BLACKSMITHING] = { unusedSlots = 0, availableAt = 0, minutesLeft = 9999, name = GetString(SI_ITEMFILTERTYPE13)}
    self.data[CRAFTING_TYPE_CLOTHIER] = { unusedSlots = 0, availableAt = 0, minutesLeft = 9999, name = GetString(SI_ITEMFILTERTYPE14)}
    self.data[CRAFTING_TYPE_WOODWORKING] = { unusedSlots = 0, availableAt = 0, minutesLeft = 9999, name = GetString(SI_ITEMFILTERTYPE15) }
    self.data[CRAFTING_TYPE_JEWELRYCRAFTING] = { unusedSlots = 0, availableAt = 0, minutesLeft = 9999, name = GetString(SI_ITEMFILTERTYPE24) }

    if(options.showBlacksmithing)then
        self:OnSmithingTraitResearch(CRAFTING_TYPE_BLACKSMITHING)
    end
    if(options.showClothier)then
        self:OnSmithingTraitResearch(CRAFTING_TYPE_CLOTHIER)
    end
    if(options.showWoodworking)then
        self:OnSmithingTraitResearch(CRAFTING_TYPE_JEWELRYCRAFTING)
    end
    if(options.showJewelry)then
        self:OnSmithingTraitResearch(CRAFTING_TYPE_WOODWORKING)
    end
    self.dataUpdated = true
end -- MOD:Enable

function MOD:Set(key,value)
    self:d('Set['..key..']',value)

    if(key=='showBlacksmithing')then
        if(value)then
            self:OnSmithingTraitResearch(CRAFTING_TYPE_BLACKSMITHING)
        else
            self.label[LABEL_BLACKSMITHING]:SetText('')
            self.dataUpdated = true
        end
    elseif(key=='showClothier')then
        if(value)then
            self:OnSmithingTraitResearch(CRAFTING_TYPE_CLOTHIER)
        else
            self.label[LABEL_CLOTHIER]:SetText('')
            self.dataUpdated = true
        end
    elseif(key=='showJewelry')then
        if(value)then
            self:OnSmithingTraitResearch(CRAFTING_TYPE_JEWELRYCRAFTING)
        else
            self.label[LABEL_JEWELRYCRAFTING]:SetText('')
            self.dataUpdated = true
        end
    elseif(key=='showWoodworking')then
        if(value)then
            self:OnSmithingTraitResearch(CRAFTING_TYPE_WOODWORKING)
        else
            self.label[LABEL_WOODWORKING]:SetText('')
            self.dataUpdated = true
        end
    elseif(key=='minutesLeftInfo')then
        self:OnTimer(GetTimeStamp())
    end
end -- MOD:Set

-- EVENT LISTENER
-- EVENT_SMITHING_TRAIT_RESEARCH_TIMES_UPDATED(eventCode)
function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_AWESOME_MODULE_TIMER,
            callback = function(eventCode, timestamp) return MOD:OnTimer(timestamp) end,
        },
        {
            eventCode = EVENT_SMITHING_TRAIT_RESEARCH_STARTED,
            callback = function(eventCode, craftingSkillType, researchLineIndex, traitIndex) MOD:OnSmithingTraitResearch(craftingSkillType) end,
        },
        {
            eventCode = EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED,
            callback = function(eventCode, craftingSkillType, researchLineIndex, traitIndex) MOD:OnSmithingTraitResearch(craftingSkillType) end,
        },
        {
            eventCode = EVENT_SMITHING_TRAIT_RESEARCH_TIMES_UPDATED,
            callback = function(eventCode) 
				MOD:OnSmithingTraitResearch(CRAFTING_TYPE_BLACKSMITHING)
				MOD:OnSmithingTraitResearch(CRAFTING_TYPE_CLOTHIER)
				MOD:OnSmithingTraitResearch(CRAFTING_TYPE_JEWELRYCRAFTING)
				MOD:OnSmithingTraitResearch(CRAFTING_TYPE_WOODWORKING)
			end,
        },
    }
end

-- EVENT HANDLER

function MOD:OnTimer(timestamp)
    self:d('OnTimer')
    local i
    for i,_data in pairs(self.data) do
        if(_data.availableAt > 0)then
            self.data[i].minutesLeft = math.ceil( GetDiffBetweenTimeStamps(_data.availableAt, timestamp) / 60)
            self.dataUpdated = true
            self:d(' => dataUpdated')
        end
    end

    if(self.data[CRAFTING_TYPE_BLACKSMITHING].availableAt == 0 and self.data[CRAFTING_TYPE_CLOTHIER].availableAt == 0 and self.data[CRAFTING_TYPE_WOODWORKING].availableAt == 0 and self.data[CRAFTING_TYPE_JEWELRYCRAFTING].availableAt == 0)then
        self:StopTimer()
    end
end

function MOD:OnSmithingTraitResearch(craftingSkillType)
    self:d('OnSmithingResearchTrait '.. craftingSkillType)
    local maxTimer = 2000000
    local maxResearch = GetMaxSimultaneousSmithingResearch(craftingSkillType)   -- This is the number of research slots
    local maxLines = GetNumSmithingResearchLines(craftingSkillType)     -- This is the number of different items craftable by this profession
    for i = 1, maxLines, 1 do       -- loop through the different craftable items, looking to see if there is research on that item
        local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingSkillType, i)  -- Get info on that specific item
        for j = 1, numTraits, 1 do      -- loop through the traits, looking for one that is being researched
            local duration, timeRemaining = GetSmithingResearchLineTraitTimes(craftingSkillType, i, j)
            if (duration ~= nil and timeRemaining ~= nil) then
                maxResearch = maxResearch - 1
                maxTimer = math.min(maxTimer,timeRemaining)
            end
        end
    end
    if (maxResearch > 0) then   -- There is an unused research slots
        self.data[craftingSkillType].availableAt = 0
        self.data[craftingSkillType].minutesLeft = 0
    else
        local timestamp = GetTimeStamp()
        self.data[craftingSkillType].availableAt = timestamp + maxTimer
        self.data[craftingSkillType].minutesLeft = math.ceil(maxTimer / 60)
        self:StartTimer()
    end
    self.data[craftingSkillType].unusedSlots = maxResearch

    self.dataUpdated = true
    self:d(' => dataUpdated')
end

-- LABEL HANDLER

function MOD:Update(options)
    self:d('Update')
    if(options.showBlacksmithing) then
        self.label[LABEL_BLACKSMITHING]:SetText(self.FormatLabelText(self.data[CRAFTING_TYPE_BLACKSMITHING], options.minutesLeftInfo))
    end
    if(options.showClothier) then
        self.label[LABEL_CLOTHIER]:SetText(self.FormatLabelText(self.data[CRAFTING_TYPE_CLOTHIER], options.minutesLeftInfo))
    end
    if(options.showJewelry) then
        self.label[LABEL_JEWELRYCRAFTING]:SetText(self.FormatLabelText(self.data[CRAFTING_TYPE_JEWELRYCRAFTING], options.minutesLeftInfo))
    end
    if(options.showWoodworking) then
        self.label[LABEL_WOODWORKING]:SetText(self.FormatLabelText(self.data[CRAFTING_TYPE_WOODWORKING], options.minutesLeftInfo))
    end
end

function MOD.FormatLabelText(data, minutesLeftInfo)
    local text = ''
    if (data.minutesLeft <= minutesLeftInfo) then
        if (data.minutesLeft == 0) then
            text = MOD.Colorize(COLOR_AWEVS_AVAILABLE,data.name) .. ': ' .. data.unusedSlots .. ' ' .. GetString(SI_AWEMOD_CRAFTING_AVAILABLE_LABEL)
        else
            text = MOD.Colorize(COLOR_AWEVS_HINT,data.name) .. ': ' .. FormatTimeSeconds(60 * data.minutesLeft, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT , TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR , TIME_FORMAT_DIRECTION_NONE)
        end
    end
    return text
end

-- |c82D482 GREEN
-- |cD4CD82 YELLOW
-- |cD49682 RED
-- |r WHITE