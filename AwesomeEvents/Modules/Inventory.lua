--[[
  This file is part of Awesome Events.

  Author: @Ze_Mi <zemi@unive.de>
  Filename: Inventory.lua
  Last Modified: 28.05.18 17:35

  Copyright (c) 2018 by Martin Unkel
  License : CreativeCommons CC BY-NC-SA 4.0 Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

  Please read the README file for further information.
  ]]

local libAM = LibStub('LibAwesomeModule-1.0')
local MOD = libAM:New('inventory')

MOD.title = GetString(SI_AWEMOD_INVENTORY)
MOD.hint = GetString(SI_AWEMOD_INVENTORY_HINT)
MOD.order = 60
MOD.debug = false

local LABEL_LOW,LABEL_DETAILS,LABEL_MONEY,LABEL_ADVCURRENCY = 1,2,3,4

MOD.label = {
    [LABEL_LOW] = {},
    [LABEL_DETAILS] = {},
    [LABEL_MONEY] = {},
    [LABEL_ADVCURRENCY] = {},
}

-- USER SETTINGS

MOD.options = {
    showLow = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_INVENTORY_LOW),
        tooltip = GetString(SI_AWEMOD_INVENTORY_LOW_HINT),
        default = true,
        order = 1,
    },
    valueLowInfo = {
        type = 'slider',
        name = GetString(SI_AWEMOD_INVENTORY_LOW_INFO),
        tooltip = GetString(SI_AWEMOD_INVENTORY_LOW_INFO_HINT),
        min  = 1,
        max = 60,
        default = 20,
        order = 2,
    },
    valueLowWarning = {
        type = 'slider',
        name = GetString(SI_AWEMOD_INVENTORY_LOW_WARNING),
        tooltip = GetString(SI_AWEMOD_INVENTORY_LOW_WARNING_HINT),
        min  = 1,
        max = 40,
        default = 10,
        order = 3,
    },
    showDetails = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_INVENTORY_DETAILS),
        tooltip = GetString(SI_AWEMOD_INVENTORY_DETAILS_HINT),
        default = true,
        order = 4,
    },
    showMoney = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_INVENTORY_MONEY),
        tooltip = GetString(SI_AWEMOD_INVENTORY_MONEY_HINT),
        default = true,
        order = 5,
    },
    showAdvCurrencies = {
        type = 'checkbox',
        name = GetString(SI_AWEMOD_INVENTORY_ADVCURRENCIES),
        tooltip = GetString(SI_AWEMOD_INVENTORY_ADVCURRENCIES_HINT),
        default = true,
        order = 6,
    }
}

-- OVERRIDES

function MOD:Enable(options)
    self:d('Enable (in debug-mode)')
    self.data = {
        [BAG_BACKPACK] = {
            numUsedSlots = 0,
            numFreeSlots = 0,
            numSlots = 0,
            money = GetCurrentMoney(),
			telvarStones = GetCurrencyAmount(CURT_TELVAR_STONES,CURRENCY_LOCATION_CHARACTER),
			writVouchers = GetCurrencyAmount(CURT_WRIT_VOUCHERS,CURRENCY_LOCATION_CHARACTER),
        },
        [BAG_BANK] = {
            numUsedSlots = 0,
            numFreeSlots = 0,
            numSlots = 0,
            money = GetBankedMoney(),
			telvarStones = 0,
			writVouchers = 0,
        },
    }
	
    self:OnUpdateBag(BAG_BACKPACK,0)
    self:OnUpdateBag(BAG_BANK,0)
    self.dataUpdated = true
end -- MOD:Enable

function MOD:Set(key,value)
    self:d('Set['..key..']',value)

    if(key=='showLow')then
        if(value)then
            self:OnUpdateBag(BAG_BACKPACK,0)
        else
            self.label[LABEL_LOW]:SetText('')
        end
    elseif(key=='showDetails')then
        if(value)then
            self:OnUpdateBag(BAG_BACKPACK,0)
            self:OnUpdateBag(BAG_BANK,0)
        else
            self.label[LABEL_DETAILS]:SetText('')
        end
    elseif(key=='showMoney')then
        if(value)then
            self.data[BAG_BACKPACK].money = GetCurrentMoney()
            self.data[BAG_BANK].money = GetBankedMoney()
        else
            self.label[LABEL_MONEY]:SetText('')
        end
    elseif(key=='showAdvCurrencies')then
        if(value)then
            self.data[BAG_BACKPACK].telvarStones = GetCurrencyAmount(CURT_TELVAR_STONES,CURRENCY_LOCATION_CHARACTER)
            self.data[BAG_BACKPACK].writVouchers = GetCurrencyAmount(CURT_WRIT_VOUCHERS,CURRENCY_LOCATION_CHARACTER)
        else
            self.label[LABEL_ADVCURRENCY]:SetText('')
        end
    else
        self:OnUpdateBag(BAG_BACKPACK,0)
        self:OnUpdateBag(BAG_BANK,0)
    end
    self.dataUpdated = true
end -- MOD:Set

-- EVENT LISTENER
function MOD:GetEventListeners()
    return {
        {
            eventCode = EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
            callback = function(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
                if(bagId == BAG_BACKPACK or bagId == BAG_BANK) then
                    self:OnUpdateBag(bagId,stackCountChange)
                end
            end
        },
        {
            eventCode = EVENT_INVENTORY_BAG_CAPACITY_CHANGED,
            callback = function(eventCode, previousCapacity, currentCapacity, previousUpgrade, currentUpgrade)
                self:d("EVENT_INVENTORY_BAG_CAPACITY_CHANGED: ", previousCapacity .. '=>' .. currentCapacity, previousUpgrade .. '=>' .. currentUpgrade)
                self:OnUpdateBag(BAG_BACKPACK,previousCapacity-currentCapacity)
            end
        },
        {
            eventCode = EVENT_INVENTORY_BANK_CAPACITY_CHANGED,
            callback = function(eventCode, previousCapacity, currentCapacity, previousUpgrade, currentUpgrade)
                self:d("EVENT_INVENTORY_BANK_CAPACITY_CHANGED: ", previousCapacity .. '=>' .. currentCapacity, previousUpgrade .. '=>' .. currentUpgrade)
                self:OnUpdateBag(BAG_BANK,previousCapacity-currentCapacity)
            end
        },
        {
            eventCode = EVENT_MONEY_UPDATE,
            callback = function(eventCode, newMoney, oldMoney, reason)
                self:d("EVENT_MONEY_UPDATE: ", oldMoney .. '=>' .. newMoney .. ' Reason: ' .. reason)
                self.data[BAG_BACKPACK].money = newMoney
                self.dataUpdated = true
            end
        },
        {
            eventCode = EVENT_BANKED_MONEY_UPDATE,
            callback = function(eventCode, newBankedMoney, oldBankedMoney)
                self:d("EVENT_BANKED_MONEY_UPDATE: ", oldBankedMoney .. '=>' .. newBankedMoney)
                self.data[BAG_BANK].money = newBankedMoney
                self.dataUpdated = true
            end
        },
        {
            eventCode = EVENT_TELVAR_STONE_UPDATE,
            callback = function(eventCode, newTelvarStones, oldTelvarStones, reason)
                self:d("EVENT_TELVAR_STONE_UPDATE")
				self.data[BAG_BACKPACK].telvarStones = newTelvarStones
                self.dataUpdated = true
            end
        },
        {
            eventCode = EVENT_WRIT_VOUCHER_UPDATE,
            callback = function(eventCode, newWritVouchers, oldWritVouchers, reason)
                self:d("EVENT_WRIT_VOUCHER_UPDATE")
				self.data[BAG_BACKPACK].writVouchers = newWritVouchers
                self.dataUpdated = true
            end
        }
    }
end -- MOD:GetEventListeners

-- EVENT HANDLER

function MOD:OnUpdateBag(bagId,stackCountChange)
    local predicted = self.data[bagId].numFreeSlots - stackCountChange
    local numFreeSlots, numUsedSlots, numSlots = GetNumBagFreeSlots(bagId),GetNumBagUsedSlots(bagId),GetBagSize(bagId)
    -- eso+ bank fix
    if(bagId==BAG_BANK and IsESOPlusSubscriber())then
        numFreeSlots = numFreeSlots + GetNumBagFreeSlots(BAG_SUBSCRIBER_BANK)
        numUsedSlots = numUsedSlots + GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
        numSlots = numSlots + GetBagSize(BAG_SUBSCRIBER_BANK)
    end

    if( numFreeSlots ~= self.data[bagId].numFreeSlots or numSlots ~= self.data[bagId].numSlots) then
        self.data[bagId].numSlots = numSlots
        self.data[bagId].numUsedSlots = numUsedSlots
        self.data[bagId].numFreeSlots = numFreeSlots
        self.dataUpdated = true
        if(predicted ~= self.data[bagId].numFreeSlots)then
            self:d(' => dataUpdated('..bagId..') Pred.: ' .. predicted .. ' / Act.:' .. self.data[bagId].numFreeSlots)
        else
            self:d(' => dataUpdated('..bagId..')')
        end
    end
end -- MOD:OnUpdateBag

-- LABEL HANDLER

local function __MoneyInK(money)
    return math.floor(money/100) / 10
end

function MOD:Update(options)
    self:d('Update')

    if(options.showLow)then
        local labelText = ''
        if (self.data[BAG_BACKPACK].numFreeSlots <= options.valueLowInfo) then
            if (self.data[BAG_BACKPACK].numFreeSlots <= options.valueLowWarning) then
                labelText = MOD.Colorize(COLOR_AWEVS_WARNING, zo_strformat(SI_AWEMOD_INVENTORY_LOW_LABEL, self.data[BAG_BACKPACK].numFreeSlots))
            else
                labelText = MOD.Colorize(COLOR_AWEVS_HINT, zo_strformat(SI_AWEMOD_INVENTORY_LOW_LABEL, self.data[BAG_BACKPACK].numFreeSlots))
            end
        end
        self.label[LABEL_LOW]:SetText(labelText)
    end

    if(options.showDetails)then
        self.label[LABEL_DETAILS]:SetText(zo_strformat(SI_AWEMOD_INVENTORY_DETAILS_LABEL,MOD.GetColorStr(COLOR_AWEVS_HINT),self.data[BAG_BACKPACK].numUsedSlots,self.data[BAG_BACKPACK].numSlots,self.data[BAG_BANK].numUsedSlots,self.data[BAG_BANK].numSlots))
    end

    if(options.showMoney)then
        self.label[LABEL_MONEY]:SetText(MOD.Colorize(COLOR_AWEVS_AVAILABLE, zo_strformat(SI_AWEMOD_INVENTORY_MONEY_LABEL,__MoneyInK(self.data[BAG_BACKPACK].money),__MoneyInK(self.data[BAG_BANK].money))))
    end

    if(options.showAdvCurrencies and (self.data[BAG_BACKPACK].telvarStones > 0 or self.data[BAG_BACKPACK].writVouchers > 0))then
        self.label[LABEL_ADVCURRENCY]:SetText(MOD.Colorize(COLOR_AWEVS_AVAILABLE, zo_strformat(SI_AWEMOD_INVENTORY_TELVARSTONES_LABEL,self.data[BAG_BACKPACK].telvarStones)) .. MOD.Colorize(COLOR_AWEVS_AVAILABLE, ' || ' .. zo_strformat(SI_AWEMOD_INVENTORY_WRITVOUCHER_LABEL,self.data[BAG_BACKPACK].writVouchers)) )
    end
end -- MOD:Update