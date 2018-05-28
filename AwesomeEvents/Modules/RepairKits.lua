--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: RepairKits.lua
  Last Modified: 02.11.17 16:36

  Copyright (c) 2017 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('repairkits')

MOD.title = GetString(SI_AWEMOD_REPAIRKITS)
MOD.hint = GetString(SI_AWEMOD_REPAIRKITS_HINT)
MOD.order = 65
MOD.debug = false

-- MOD FUNCTIONS

function MOD:ScanBag(bagId)
    for slotId=1,GetBagSize(bagId) do
        if IsItemRepairKit(bagId,slotId) then
            local _,stackCount = GetItemInfo(bagId,slotId)
            local tier = GetRepairKitTier(bagId,slotId)
            self.data.details[tier] = (self.data.details[tier]==nil) and stackCount or self.data.details[tier] + stackCount
            self.data.count = self.data.count + stackCount
        end
    end
end

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data = { count = 0, details = {} }
    self:ScanBag(BAG_BACKPACK)
    self:ScanBag(BAG_VIRTUAL)
    self.dataUpdated = true
end -- MOD:Enable

-- EVENT LISTENER

function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
            callback = function(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
                if( (bagId == BAG_BACKPACK or bagId == BAG_VIRTUAL) and IsItemRepairKit(bagId,slotId))then
                    self:d('EVENT_INVENTORY_SINGLE_SLOT_UPDATE',self.data.count,stackCountChange)
                    self.data.count = self.data.count + stackCountChange
                    self.dataUpdated = true
                end
            end
        },
    }
end -- MOD:GetEventListeners

-- EVENT HANDLER

-- LABEL HANDLER


function MOD:Update(options)
    self:d('Update')
    self.label:SetText(MOD.Colorize(COLOR_AWEVS_AVAILABLE, zo_strformat(SI_AWEMOD_REPAIRKITS_LABEL, self.data.count)))
end -- MOD:Update