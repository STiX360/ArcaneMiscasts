local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local settings = storage.playerSection('SettingsPlayerArcaneMisfires')
local elapsed, stage, pendingUse = 0, 0, false
local controlReleased, controlApplied, controlFailed = false, false, false
I.AnimationController.addTextKeyHandler('spellcast', function(_, key)
    if (stage==8 or stage==10) and key:sub(-7)=='release' then controlReleased=true end
end)
local function check(value, message)
    if value then return true end
    print('AMF_SMOKE_FAIL: '..message); core.quit(); stage=99
end
local function cast(id, mana)
    types.Actor.stats.dynamic.magicka(self).base = 1000
    types.Actor.stats.dynamic.magicka(self).current = mana
    types.Actor.setSelectedSpell(self, core.magic.spells.records[id])
    types.Actor.setStance(self, types.Actor.STANCE.Spell)
    pendingUse = true
end
return {
    engineHandlers={onFrame=function(dt)
        if dt <= 0 or stage == 99 then return end
        elapsed = elapsed + dt
        if stage==8 or stage==10 then
            controlApplied = controlApplied or types.Actor.activeSpells(self):isSpellActive('amf_test_success')
            controlFailed = controlFailed or core.sound.isSoundPlaying(
                core.stats.Skill.records.alteration.school.failureSound,self)
        end
        self.controls.use = self.ATTACK_TYPE.NoAttack
        if pendingUse and elapsed > 0.2 then types.Actor.setStance(self, types.Actor.STANCE.Spell) end
        if pendingUse and elapsed > 0.8 then
            self.controls.use = self.ATTACK_TYPE.Any
            pendingUse = false
        end
        if elapsed < 2 then return end
        if stage == 0 then
            if not check(core.sound.isEnabled(), 'sound unavailable; detector cannot be tested') then return end
            if not check(I.ArcaneMisfires ~= nil, 'missing mod interface') then return end
            I.Controls.overrideCombatControls(true)
            settings:set('chance',100)
            settings:set('severity',1)
            types.NPC.stats.skills.alteration(self).base = 0
            types.Actor.stats.dynamic.health(self).base = 200
            types.Actor.stats.dynamic.health(self).current = 200
            types.Actor.spells(self):add('amf_test_fail')
            types.Actor.spells(self):add('amf_test_success')
            types.Actor.spells(self):add('amf_test_fire')
            types.Actor.spells(self):add('amf_test_silence')
            local outcomes = {fire='firedamage',frost='frostdamage',shock='shockdamage',
                fatigue='damagefatigue',burden='burden',blind='blind',silence='silence',
                magicka='drainmagicka',weakness='weaknesstomagicka'}
            for outcome, id in pairs(outcomes) do
                for tier=1,3 do
                    local record = core.magic.spells.records['amf_'..outcome..'_'..tier]
                    if not check(record and record.effects[1].id==id, 'incorrect engine effect '..outcome) then return end
                end
            end
            print('AMF_SMOKE_RECORDS: 27 effects resolved')
            cast('amf_test_fail',1000); stage=1; elapsed=0
        elseif stage == 1 and elapsed > 3 then
            if not check(I.ArcaneMisfires.getBackfireCount()==1, 'failed cast did not cause exactly one backfire') then return end
            local effect = types.Actor.activeEffects(self):getEffect('burden')
            if not check(effect and effect.magnitude>0 and effect.magnitude<=15
                and types.Actor.activeSpells(self):isSpellActive('amf_burden_1'),
                'failed Feather did not produce tier-one Burden') then return end
            print('AMF_SMOKE_FAILED_CAST: tier-one Burden (resistance respected)')
            cast('amf_test_fail',1000); stage=1.5; elapsed=0
        elseif stage == 1.5 and elapsed > 3 then
            if not check(I.ArcaneMisfires.getBackfireCount()==2,
                'consecutive failed cast was suppressed') then return end
            print('AMF_SMOKE_CONSECUTIVE_BACKFIRES')
            cast('amf_test_success',1000); stage=2; elapsed=0
        elseif stage == 2 and elapsed > 3 then
            if not check(I.ArcaneMisfires.getBackfireCount()==2, 'successful cast caused a backfire') then return end
            print('AMF_SMOKE_SUCCESS_EXCLUDED')
            cast('amf_test_fail',0); stage=3; elapsed=0
        elseif stage == 3 and elapsed > 3 then
            if not check(I.ArcaneMisfires.getBackfireCount()==2, 'insufficient magicka caused a backfire') then return end
            print('AMF_SMOKE_NO_MANA_EXCLUDED')
            settings:set('enabled',false)
            cast('amf_test_fail',1000); stage=4; elapsed=0
        elseif stage == 4 and elapsed > 3 then
            if not check(I.ArcaneMisfires.getBackfireCount()==2, 'disabled mod caused a backfire') then return end
            local effect = types.Actor.activeEffects(self):getEffect('burden')
            if not check((not effect or math.abs(effect.magnitude)<0.001)
                and not types.Actor.activeSpells(self):isSpellActive('amf_burden_1'),
                'temporary Burden did not expire; magnitude='..tostring(effect and effect.magnitude)) then return end
            print('AMF_SMOKE_DISABLED_AND_EXPIRY')
            settings:set('enabled',true); settings:set('severity',3)
            types.NPC.stats.skills.destruction(self).base=0
            cast('amf_test_fire',1000); stage=5; elapsed=0
        elseif stage == 5 and elapsed > 3 then
            if not check(I.ArcaneMisfires.getBackfireCount()==3
                and types.Actor.activeSpells(self):isSpellActive('amf_fire_3'),
                'failed Fire did not produce tier-three elemental recoil') then return end
            if not check(types.Actor.stats.dynamic.health(self).current<200, 'elemental recoil did not damage health') then return end
            print('AMF_SMOKE_ELEMENTAL_RECOIL')
            stage=6
        elseif stage == 6 and elapsed > 7 then
            settings:set('severity',1)
            types.NPC.stats.skills.conjuration(self).base=0
            -- Avoid a random innate resistance roll obscuring the duration check.
            types.Actor.stats.attributes.willpower(self).base=0
            types.Actor.stats.attributes.luck(self).base=0
            cast('amf_test_silence',1000); stage=7; elapsed=0
        elseif stage == 7 and elapsed > 4.5 then
            if not check(core.magic.spells.records.amf_silence_1.effects[1].duration==6,
                'incorrect mild Silence duration') then return end
            if not check(I.ArcaneMisfires.getBackfireCount()==4
                and types.Actor.activeSpells(self):isSpellActive('amf_silence_1'),
                'mild Silence did not outlast casting recovery; backfires='..I.ArcaneMisfires.getBackfireCount()) then return end
            local effect = types.Actor.activeEffects(self):getEffect('silence')
            if not check(effect and effect.magnitude>0, 'Silence not effective after recovery') then return end
            print('AMF_SMOKE_SILENCE_AFTER_RECOVERY')
            settings:set('enabled',false)
            controlReleased, controlApplied, controlFailed = false, false, false
            cast('amf_test_success',1000); elapsed=0
            stage=8
        elseif stage == 8 and elapsed > 3 then
            if not check(controlReleased and controlFailed and not controlApplied,
                'normally successful spell did not fail while silenced') then return end
            print('AMF_SMOKE_SILENCE_PREVENTED_SUCCESS')
            stage=9
        elseif stage == 9 and elapsed > 5 then
            if not check(not types.Actor.activeSpells(self):isSpellActive('amf_silence_1'),
                'Silence did not expire') then return end
            print('AMF_SMOKE_SILENCE_EXPIRED')
            controlReleased, controlApplied, controlFailed = false, false, false
            cast('amf_test_success',1000); elapsed=0; stage=10
        elseif stage == 10 and elapsed > 3 then
            if not check(controlReleased and controlApplied and not controlFailed,
                'successful casting did not resume after Silence expired') then return end
            print('AMF_SMOKE_SUCCESS_AFTER_SILENCE')
            print('AMF_SMOKE_PASS'); core.quit(); stage=99
        end
    end},
}
