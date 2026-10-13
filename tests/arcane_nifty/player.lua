local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local settings = storage.playerSection('SettingsPlayerArcaneMisfires')
local installed = core.contentFiles.has('NiftySpellPack.omwaddon')
local elapsed, stage, teleports = 0, 0, 0
local niftyTeleports, standaloneTeleports = 0, 0
local pendingUse, origin, originCell, minFatigue
local spells = {'amf_nifty_recall', 'amf_nifty_divine', 'amf_nifty_almsivi'}
local function check(value, message)
    if value then return true end
    print('AMF_NIFTY_FAIL: '..message)
    stage = 99
    core.quit()
end
local function cast(id)
    types.Actor.stats.dynamic.fatigue(self).base = 1000
    types.Actor.stats.dynamic.fatigue(self).current = 1000
    types.Actor.stats.dynamic.magicka(self).base = 1000
    types.Actor.stats.dynamic.magicka(self).current = 1000
    types.Actor.setSelectedSpell(self, core.magic.spells.records[id])
    types.Actor.setStance(self, types.Actor.STANCE.Spell)
    origin, originCell, minFatigue = self.position, self.cell.id, 1000
    pendingUse, elapsed = true, 0
end
return {
    eventHandlers = {
        NSP_EffectEvent = function(data)
            if data.type=='onTeleport' and data.effectId=='nsp_wildintervention' then
                teleports = teleports + 1
                niftyTeleports = niftyTeleports + 1
            end
        end,
        AMF_WildArrival = function()
            teleports = teleports + 1
            standaloneTeleports = standaloneTeleports + 1
        end,
    },
    engineHandlers = {onFrame = function(dt)
        if dt <= 0 or stage==99 then return end
        elapsed = elapsed + dt
        minFatigue = math.min(minFatigue or 1000, types.Actor.stats.dynamic.fatigue(self).current)
        if stage>=1 and stage<=3 and elapsed>4 then
            -- Recover from the verified fatigue loss before requesting the next cast.
            types.Actor.stats.dynamic.fatigue(self).current = 1000
        end
        self.controls.use = self.ATTACK_TYPE.NoAttack
        if pendingUse and elapsed > 0.2 then types.Actor.setStance(self, types.Actor.STANCE.Spell) end
        if pendingUse and elapsed > 0.8 then
            self.controls.use = self.ATTACK_TYPE.Any
            pendingUse = false
        end
        if stage==0 and elapsed > 2 then
            if not check(core.sound.isEnabled() and I.ArcaneMisfires, 'missing detector prerequisites') then return end
            I.Controls.overrideCombatControls(true)
            settings:set('chance',100)
            settings:set('severity',1)
            settings:set('failedCastExperience',false)
            if not check(settings:get('niftyWildIntervention')==true, 'toggle is not on by default') then return end
            types.NPC.stats.skills.mysticism(self).base = 0
            types.Actor.stats.attributes.willpower(self).base = 0
            types.Actor.stats.attributes.luck(self).base = 0
            for _, id in ipairs(spells) do types.Actor.spells(self):add(id) end
            cast(spells[1]); stage=1
        elseif stage>=1 and stage<=3 and elapsed > 7 then
            if not check(I.ArcaneMisfires.getBackfireCount()==stage, 'failed cast count at stage '..stage
                ..': '..I.ArcaneMisfires.getBackfireCount()) then return end
            do
                if not check(teleports==stage, 'Wild Intervention did not emit arrival at stage '..stage) then return end
                if not check(niftyTeleports==(installed and stage or 0)
                    and standaloneTeleports==(installed and 0 or stage), 'wrong intervention provider') then return end
                if not check(originCell~=self.cell.id or (self.position-origin):length()>8192,
                    'Wild Intervention did not move player at stage '..stage) then return end
                if not check(minFatigue<=5, 'Wild Intervention fatigue loss missing at stage '..stage) then return end
            end
            print('AMF_NIFTY_CAST_PASS: '..spells[stage]..' installed='..tostring(installed))
            stage=stage+1
            if stage<=3 then cast(spells[stage])
            else settings:set('niftyWildIntervention',false); cast(spells[1]) end
        elseif stage==4 and elapsed > 4 then
            if not check(I.ArcaneMisfires.getBackfireCount()==4
                and teleports==3
                and types.Actor.activeSpells(self):isSpellActive('amf_magicka_1'), 'toggle-off fallback failed') then return end
            print('AMF_NIFTY_TOGGLE_OFF_PASS')
            settings:set('niftyWildIntervention',true)
            settings:set('chance',0)
            cast(spells[1]); stage=5
        elseif stage==5 and elapsed > 4 then
            if not check(I.ArcaneMisfires.getBackfireCount()==4 and teleports==3,
                'zero chance triggered miscast') then return end
            print('AMF_NIFTY_ZERO_CHANCE_PASS')
            settings:set('chance',100)
            types.Player.setTeleportingEnabled(self,false)
            cast(spells[1]); stage=6
        elseif stage==6 and elapsed > 4 then
            if not check(I.ArcaneMisfires.getBackfireCount()==5 and teleports==3
                and self.cell.id==originCell and (self.position-origin):length()<100
                and minFatigue>5, 'teleport-disabled protection failed') then return end
            types.Player.setTeleportingEnabled(self,true)
            print('AMF_NIFTY_TELEPORT_DISABLED_PASS')
            print('AMF_NIFTY_PASS')
            stage=99; core.quit()
        end
    end},
}
