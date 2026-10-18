local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local wild = require('scripts.arcane_misfires.wild_player')
local elapsed, stage, readyAt = 0, 0, 0

return {
    eventHandlers={
        AMFT_DropSeeded=function() stage, readyAt = 2, elapsed+0.5 end,
        AMFT_DropResult=function(data)
            print(data.ok and 'AMF_DROP_PASS: '..data.message or 'AMF_DROP_FAIL: '..data.message)
            core.quit()
        end,
    },
    engineHandlers={onUpdate=function(dt)
        elapsed = elapsed+dt
        if elapsed > 30 then print('AMF_DROP_FAIL: timeout'); core.quit(); return end
        if stage == 0 and elapsed > 2 then
            core.sendGlobalEvent('AMFT_DropSeed', {target=self})
            stage = 1
        elseif stage == 2 and elapsed > readyAt then
            local slot = types.Actor.EQUIPMENT_SLOT
            types.Actor.setEquipment(self, {[slot.Shirt]='common_shirt_01',
                [slot.Pants]='common_pants_01', [slot.CarriedRight]='iron dagger'})
            stage, readyAt = 3, elapsed+0.5
        elseif stage == 3 and elapsed > readyAt then
            local plan = wild.dropPlan()
            if not plan then print('AMF_DROP_FAIL: no departure floor'); core.quit(); return end
            core.sendGlobalEvent('AMFT_DropArm', {target=self, plan=plan})
            stage = 4
        end
    end},
}
