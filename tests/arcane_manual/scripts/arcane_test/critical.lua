local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local settings = storage.playerSection('SettingsPlayerArcaneMisfires')
local elapsed, prepared, arrivalAt = 0, false, nil
local droppedItems = false
local slot = types.Actor.EQUIPMENT_SLOT
local gear = {[slot.Shirt]='common_shirt_01', [slot.Pants]='common_pants_01',
    [slot.Boots]='common_shoes_01', [slot.LeftRing]='common_ring_01', [slot.CarriedRight]='iron dagger'}

local function report(message)
    ui.showMessage(message)
    print('[Arcane Critical Test] '..message)
end

return {
    eventHandlers={
        AMFT_EquipCriticalKit=function()
            types.Actor.setEquipment(self, gear)
            report('Test gear equipped. F6 returns; F7 restores gear; F8 toggles criticals; F10 refills.')
        end,
        AMFT_ReturnNotice=function(data) report(data.message) end,
        AMF_WildArrival=function(data)
            if data.critical then
                arrivalAt, droppedItems = elapsed + 0.5, data.droppedItems == true
            end
        end,
    },
    engineHandlers={
        onUpdate=function(dt)
            if dt <= 0 then return end
            elapsed = elapsed + dt
            if not prepared and elapsed > 1 then
                settings:set('enabled', true)
                settings:set('chance', 100)
                settings:set('criticalChance', 100)
                settings:set('severity', 1)
                settings:set('niftyWildIntervention', true)
                settings:set('criticalTeleportDropItems', false)
                settings:set('immersion', false)
                types.Actor.setSelectedSpell(self, core.magic.spells.records.amft_burden)
                core.sendGlobalEvent('AMFT_CriticalKit', {target=self})
                prepared = true
                report('Critical test ready: 100% miscasts / 100% criticals. Feather selected.')
            end
            if arrivalAt and elapsed >= arrivalAt then
                arrivalAt = nil
                local empty = next(types.Actor.getEquipment(self)) == nil
                local retained = true
                for _, id in pairs(gear) do
                    if #types.Actor.inventory(self):findAll(id) == 0 then retained = false end
                end
                if droppedItems then
                    local cleared = #types.Actor.inventory(self):getAll() == 0
                    report((empty and cleared and 'PASS' or 'FAIL')..
                        ': drop-all critical left inventory and equipment empty. Press F6 to inspect the departure point.')
                else
                    report((empty and retained and 'PASS' or 'FAIL')..
                        ': teleport critical unequipped all slots and retained the test kit. Confirm the voice by ear.')
                end
            end
        end,
        onSave=function() return {prepared=prepared} end,
        onLoad=function(data)
            prepared = data and data.prepared == true or false
            elapsed, arrivalAt = 0, nil
        end,
        onKeyPress=function(key)
            if not prepared or I.UI.getMode() ~= nil or key.withCtrl or key.withAlt
                or key.withShift or key.withSuper then return end
            if key.code == input.KEY.F6 then
                arrivalAt = nil
                core.sendGlobalEvent('AMFT_ReturnToDeparture', {target=self})
            elseif key.code == input.KEY.F7 then
                core.sendGlobalEvent('AMFT_CriticalKit', {target=self})
            elseif key.code == input.KEY.F8 then
                local chance = settings:get('criticalChance') == 100 and 0 or 100
                settings:set('criticalChance', chance)
                report('Critical chance: '..chance..'%. Wait for previous effects to expire before comparing.')
            end
        end,
    },
}
