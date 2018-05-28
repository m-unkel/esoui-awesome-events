--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: SoulGems.lua
  Last Modified: 02.11.17 16:36

  Copyright (c) 2017 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('soulgems')

MOD.title = GetString(SI_AWEMOD_SOULGEMS)
MOD.hint = GetString(SI_AWEMOD_SOULGEMS_HINT)
MOD.order = 65
MOD.debug = false

-- MOD FUNCTIONS

local function __ScanBag(bagId)
    local empty,filled = 0,0
    for slotId=1,GetBagSize(bagId) do
        if(IsItemSoulGem(SOUL_GEM_TYPE_EMPTY,bagId,slotId)) then
            local _,stackCount = GetItemInfo(bagId,slotId)
            empty = empty + stackCount
        elseif(IsItemSoulGem(SOUL_GEM_TYPE_FILLED,bagId,slotId)) then
            local _,stackCount = GetItemInfo(bagId,slotId)
            filled = filled + stackCount
        end
    end
    return empty,filled
end

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data = {
        numFilled = 0,
        numEmpty = 0,
    }
    self:OnChangeSoulGemCount()
    self.dataUpdated = true
end -- MOD:Enable

-- EVENT LISTENER
function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
            callback = function(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
                if(bagId == BAG_BACKPACK and ( IsItemSoulGem(SOUL_GEM_TYPE_FILLED,bagId,slotId) or IsItemSoulGem(SOUL_GEM_TYPE_EMPTY,bagId,slotId)))then
                    self:OnChangeSoulGemCount()
                end
            end
        },
    }
end -- MOD:GetEventListeners

-- EVENT HANDLER

function MOD:OnChangeSoulGemCount()
    self:d('OnChangeSoulGemCount')
    local empty,filled = __ScanBag(BAG_BACKPACK)
    local emptyV,filledV = __ScanBag(BAG_VIRTUAL)

    filled = filled + filledV
    empty = empty + emptyV

    if(self.data.numFilled ~= filled or self.data.numEmpty ~= empty)then
        self.data.numFilled = filled
        self.data.numEmpty = empty
        self.dataUpdated = true
        self:d(' => dataUpdated')
    end

end -- MOD:OnChangeSoulGemCount

-- LABEL HANDLER


function MOD:Update(options)
    self:d('Update')
    self.label:SetText(MOD.Colorize(COLOR_AWEVS_AVAILABLE, zo_strformat(SI_AWEMOD_SOULGEMS_LABEL, self.data.numFilled, self.data.numEmpty)))
end -- MOD:Update