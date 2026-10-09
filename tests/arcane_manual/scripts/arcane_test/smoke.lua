local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local policy = require('scripts.arcane_misfires.policy')
local elapsed, finished, casting, pressed = 0, false, false, false
local expectedProgress, observedSchool, observedGain
I.SkillProgression.addSkillUsedHandler(function(skill, options)
    if casting then observedSchool, observedGain = skill, options.skillGain end
end)
return {engineHandlers={onFrame=function()
    if not casting then return end
    self.controls.use = self.ATTACK_TYPE.NoAttack
    if elapsed > 0.8 and not pressed then
        self.controls.use = self.ATTACK_TYPE.Any
        pressed = true
    end
end, onUpdate=function(dt)
    if finished then return end
    elapsed=elapsed+dt
    if (not casting and elapsed<2) or (casting and elapsed<4) then return end
    local ok, message = pcall(function()
        if casting then
            assert(I.ArcaneMisfires.getBackfireCount()==1, 'Restoration failure did not misfire once')
            assert(observedSchool=='destruction', 'misfire XP went to '..tostring(observedSchool))
            assert(observedGain==core.stats.Skill.records.destruction.skillGain[1], 'wrong success-equivalent XP')
            assert(math.abs(types.NPC.stats.skills.destruction(self).progress-expectedProgress)<0.00001,
                'normal skill progress not applied')
            print('AMF_EXPERIENCE_PASS: failed Restoration cast awarded normal Destruction progress')
            return
        end
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
        assert(settings:get('failedCastExperience') and settings:get('experienceOnlyMisfires')
            and settings:get('useMisfireSchool'), 'experience defaults missing')
        types.NPC.stats.skills.destruction(self).base=50
        types.NPC.stats.skills.destruction(self).progress=0
        expectedProgress=core.stats.Skill.records.destruction.skillGain[1]
            / I.SkillProgression.getSkillProgressRequirement('destruction')
        I.Controls.overrideCombatControls(true)
        types.Actor.setSelectedSpell(self,core.magic.spells.records.amft_fatigue)
        types.Actor.setStance(self,types.Actor.STANCE.Spell)
    end)
    if ok and not casting then casting=true; elapsed=0; return end
    finished=true
    print(ok and 'AMF_MANUAL_PASS' or ('AMF_MANUAL_FAIL: '..tostring(message)))
    core.quit()
end}}
