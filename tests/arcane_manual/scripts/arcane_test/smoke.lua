local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local policy = require('scripts.arcane_misfires.policy')
local elapsed, finished = 0, false
return {engineHandlers={onUpdate=function(dt)
    if finished then return end
    elapsed=elapsed+dt
    if elapsed<2 then return end
    finished=true
    local ok, message = pcall(function()
        assert(I.ArcaneMisfires, 'mod interface missing')
        assert(core.sound.isEnabled(), 'sound disabled')
        local settings=storage.playerSection('SettingsPlayerArcaneMisfires')
        assert(settings:get('chance')==100 and settings:get('severity')==1,
            'manual test settings missing')
        for _, id in ipairs({'fire','frost','shock','burden','blind','silence','magicka','weakness','fatigue','success','power'}) do
            assert(types.Actor.spells(self)['amft_'..id], 'test spell missing: '..id)
            if id~='success' and id~='power' then
                local spell=core.magic.spells.records['amft_'..id]
                local outcome,tier=policy.choose(spell,spell.effects[1].effect.school,1)
                assert(outcome==id and tier==1, 'wrong backfire route: '..id)
            end
        end
        assert(types.Actor.getSelectedSpell(self).id=='amft_fire', 'Fire not selected')
        assert(types.Actor.getStance(self)==types.Actor.STANCE.Spell, 'casting stance not ready')
        assert(types.Actor.stats.dynamic.magicka(self).current==2000, 'magicka not refilled')
        assert(types.Actor.stats.dynamic.health(self).current==500, 'health not refilled')
        assert(types.NPC.stats.skills.destruction(self).base==0, 'failure setup missing')
        assert(types.Actor.stats.attributes.willpower(self).base==0, 'willpower setup missing')
    end)
    print(ok and 'AMF_MANUAL_PASS' or ('AMF_MANUAL_FAIL: '..tostring(message)))
    core.quit()
end}}
