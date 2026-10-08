"""Independent Lua regression tests and generated TES3 record checks."""
from pathlib import Path
import json
import struct
import sys
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.test-tools'))
sys.path.insert(0, str(ROOT / 'tools'))
from lupa.lua51 import LuaRuntime
import build_arcane_misfires as builder

MOD = builder.MOD
MOCK = '''
now=0; playing={}; values={}; applied={}; messages={}; audio=true
player={}; mana={current=100}; health={current=100}
spell={id='test',type=0,cost=20,effects={{id='feather',duration=10,
    magnitudeMin=10,magnitudeMax=10,effect={school='alteration',baseCost=1}}}}
selected=spell
local schools={'alteration','conjuration','destruction','illusion','mysticism','restoration'}
core={getSimulationTime=function() return now end, stats={Skill={records={}}},
    sound={isEnabled=function() return audio end,
        isSoundPlaying=function(path,actor) assert(actor==player); return playing[path] or false end,
        playSound3d=function() end},
    magic={SPELL_TYPE={Spell=0},effects={records=setmetatable({}, {__index=function() return {hitSound=''} end})},
        spells={records=setmetatable({}, {__index=function(_,id)
        return {name=id,effects={{id='burden',effect={hitSound=''}}}}
    end})}}}
for _,school in ipairs(schools) do core.stats.Skill.records[school]={school={failureSound=school}} end
types={Static={records={}},Actor={getSelectedSpell=function() return selected end,
    getSelectedEnchantedItem=function() return enchanted end,
    stats={dynamic={health=function() return health end}},
    activeSpells=function() return {add=function(_,options) table.insert(applied,options) end} end}}
settings={get=function(_,key) return values[key] end, set=function(_,key,value) values[key]=value end}
I={Settings={registerPage=function() end,registerGroup=function() end},
    AnimationController={addPlayBlendedAnimationHandler=function(fn) startHandler=fn end,
        addTextKeyHandler=function(_,fn) releaseHandler=fn end},
    SkillProgression={SKILL_USE_TYPES={Spellcast_Success=0},addSkillUsedHandler=function(fn) successHandler=fn end}}
package.preload['openmw.core']=function() return core end
package.preload['openmw.self']=function() return player end
package.preload['openmw.types']=function() return types end
package.preload['openmw.storage']=function() return {playerSection=function() return settings end} end
package.preload['openmw.ui']=function() return {showMessage=function(msg) table.insert(messages,msg) end} end
package.preload['openmw.interfaces']=function() return I end
package.preload['openmw.animation']=function() return {addVfx=function(actor,model,options)
    visual={actor=actor,model=model,options=options}
end} end
function start() startHandler('spellcast',{startKey='self start'}) end
function release() releaseHandler('spellcast','spellcast: self release') end
function tick(dt) now=now+dt; mod.engineHandlers.onUpdate(dt) end
function fail()
    start(); release(); playing.alteration=true; tick(0.1)
end
'''


class ArcaneTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        policy = self.lua.execute((MOD/'scripts/arcane_misfires/policy.lua').read_text())
        self.lua.globals().policy = policy
        self.lua.execute("package.preload['scripts.arcane_misfires.policy']=function() return policy end")
        self.lua.globals().mod = self.lua.execute((MOD/'scripts/arcane_misfires/player.lua').read_text())
        self.lua.execute('tick(0.1); values.chance=100')

    def runlua(self, code):
        self.lua.execute(code)

    def test_failed_cast_applies_once(self):
        self.runlua("fail(); assert(#applied==1); assert(applied[1].id=='amf_burden_2'); release(); tick(0.1); assert(#applied==1)")

    def test_success_cancels_before_release(self):
        self.runlua("start(); successHandler('alteration',{useType=0}); release(); playing.alteration=true; tick(0.1); assert(#applied==0)")

    def test_success_cancels_after_release(self):
        self.runlua("start(); release(); playing.alteration=true; tick(0.01); successHandler('alteration',{useType=0}); tick(0.1); assert(#applied==0)")

    def test_interrupted_animation(self):
        self.runlua('start(); playing.alteration=true; tick(4.1); release(); tick(0.1); assert(#applied==0)')

    def test_no_sound_no_backfire(self):
        self.runlua('start(); release(); tick(0.7); assert(#applied==0)')

    def test_stale_sound_excluded(self):
        self.runlua('playing.alteration=true; fail(); assert(#applied==0)')

    def test_stale_sound_can_stop_then_restart(self):
        self.runlua('playing.alteration=true; start(); playing.alteration=false; tick(0.1); release(); playing.alteration=true; tick(0.1); assert(#applied==1)')

    def test_enchanted_items_excluded(self):
        self.runlua('enchanted={}; fail(); assert(#applied==0)')

    def test_powers_excluded(self):
        self.runlua('spell.type=2; fail(); assert(#applied==0)')

    def test_changed_selection_excluded(self):
        self.runlua("start(); selected={id='other',type=0}; release(); playing.alteration=true; tick(0.1); assert(#applied==0)")

    def test_pause_does_not_trigger(self):
        self.runlua('start(); release(); playing.alteration=true; tick(0); assert(#applied==0); tick(0.1); assert(#applied==1)')

    def test_consecutive_failures_have_independent_rolls(self):
        self.runlua('values.chance=15; math.random=function() return 0.14 end; fail(); playing.alteration=false; tick(0.1); fail(); assert(#applied==2)')

    def test_disabled_and_zero_chance(self):
        self.runlua('values.enabled=false; fail(); assert(#applied==0); values.enabled=true; values.chance=0; playing.alteration=false; tick(0.1); fail(); assert(#applied==0)')

    def test_load_discards_pending_cast(self):
        self.runlua('start(); release(); local data=mod.engineHandlers.onSave(); mod.engineHandlers.onLoad(data); playing.alteration=true; tick(0.1); assert(#applied==0); assert(values.chance==100)')

    def test_old_cooldown_is_ignored_on_load(self):
        self.runlua('mod.engineHandlers.onLoad({version=1,remaining=120,settings={chance=100,cooldown=120}}); tick(0.1); fail(); assert(#applied==1); local data=mod.engineHandlers.onSave(); assert(data.version==2 and data.remaining==nil and data.settings.cooldown==nil)')

    def test_severity_and_effect_priority(self):
        self.runlua("spell.cost=100; spell.effects[1].id='levitate'; values.severity=1; fail(); assert(applied[1].id=='amf_burden_1')")

    def test_all_school_fallbacks(self):
        self.runlua("for _,school in ipairs(policy.schools) do local outcome,tier=policy.choose({cost=0,effects={}},school,3); assert(outcome and tier==1) end")

    def test_nan_and_bounds(self):
        self.runlua('assert(policy.number(0/0,15,0,100)==15); assert(policy.number(200,15,0,100)==100); assert(policy.number(-5,15,0,100)==0)')

    def test_elemental_backfire(self):
        self.runlua("spell.effects[1].id='firedamage'; spell.effects[1].effect.school='destruction'; start(); release(); playing.destruction=true; tick(0.1); assert(applied[1].id=='amf_fire_2')")

    def test_no_audio_fails_closed(self):
        self.runlua('audio=false; fail(); assert(#applied==0)')

    def test_equip_animation_does_not_reset_cast(self):
        self.runlua("start(); release(); startHandler('spellcast',{startKey='equip start'}); playing.alteration=true; tick(0.1); assert(#applied==1)")

    def test_vanilla_vfx_and_protections(self):
        self.runlua("types.Static.records.vfx_defaulthit={model='meshes/vanilla.nif'}; fail(); assert(visual.model=='meshes/vanilla.nif' and visual.options.loop==false); assert(applied[1].ignoreReflect and applied[1].ignoreSpellAbsorption and not applied[1].stackable); assert(not applied[1].ignoreResistances)")

    def test_dead_player_excluded(self):
        self.runlua('health.current=0; fail(); assert(#applied==0)')


class PackageTests(unittest.TestCase):
    def test_temporary_penalties_outlast_cast_recovery(self):
        entries = {entry['key']:entry for entry in json.loads((MOD/'outcomes.json').read_text())}
        expected = {'silence':[6,9,12], 'burden':[6,9,12], 'blind':[8,12,16],
            'magicka':[8,12,16], 'weakness':[10,15,20]}
        for key, durations in expected.items():
            self.assertEqual(entries[key]['duration'],durations)
            self.assertGreaterEqual(durations[0]-2,4)

    def test_damage_budgets_unchanged(self):
        entries = {entry['key']:entry for entry in json.loads((MOD/'outcomes.json').read_text())}
        for key in ('fire','frost','shock'):
            entry = entries[key]
            self.assertEqual([a*b for a,b in zip(entry['magnitude'],entry['duration'])],[2,6,12])
        fatigue = entries['fatigue']
        self.assertEqual([a*b for a,b in zip(fatigue['magnitude'],fatigue['duration'])],[10,30,60])

    @classmethod
    def setUpClass(cls):
        builder.build()

    def test_records(self):
        data = (MOD/'ArcaneMisfires.esp').read_bytes()
        cursor, spells = 0, {}
        while cursor < len(data):
            tag, size, _, _ = struct.unpack_from('<4sIII',data,cursor)
            end = cursor+16+size
            fields, offset = {}, cursor+16
            while offset < end:
                key, length = struct.unpack_from('<4sI',data,offset)
                fields[key] = data[offset+8:offset+8+length]
                offset += 8+length
            self.assertEqual(offset,end)
            if tag == b'SPEL': spells[fields[b'NAME'][:-1].decode()] = fields
            cursor = end
        entries = json.loads((MOD/'outcomes.json').read_text())
        self.assertEqual(len(spells),27)
        for entry in entries:
            for i in range(3):
                fields = spells[f"amf_{entry['key']}_{i+1}"]
                self.assertEqual(struct.unpack('<iii',fields[b'SPDT']),(0,0,0))
                self.assertEqual(struct.unpack('<hbbiiiii',fields[b'ENAM']),
                    (entry['effect'],-1,-1,0,0,entry['duration'][i],entry['magnitude'][i],entry['magnitude'][i]))

    def test_archive_matches_source(self):
        with ZipFile(ROOT/f'dist/Arcane-Misfires-{builder.VERSION}.zip') as archive:
            for path in MOD.rglob('*'):
                if path.is_file(): self.assertEqual(archive.read(path.relative_to(MOD).as_posix()),path.read_bytes())
            self.assertFalse(any(n.startswith(('meshes/','textures/','sound/')) for n in archive.namelist()))


if __name__ == '__main__':
    unittest.main()
