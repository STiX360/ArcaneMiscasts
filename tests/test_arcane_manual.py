"""Check manual-test setup, controls, save lifecycle and package isolation."""
from pathlib import Path
import struct
import sys
import unittest
from zipfile import ZipFile

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.test-tools'))
sys.path.insert(0,str(ROOT/'tools'))
from lupa.lua51 import LuaRuntime
import build_arcane_test as builder

MOCK='''
stats={health={base=20,current=20},magicka={base=20,current=20},fatigue={base=20,current=20},
    willpower={base=40},luck={base=40}}
skills={}; learned={}; values={}; selected=nil; stance=nil; mode=nil
settings={set=function(_,k,v) values[k]=v end,get=function(_,k) return values[k] end}
local function stat(name) return function() return stats[name] end end
local function skill(name) return function() skills[name]=skills[name] or {}; return skills[name] end end
types={Actor={stats={dynamic={},attributes={willpower=stat('willpower'),luck=stat('luck')}},
    STANCE={Spell=2},spells=function() return {add=function(_,id) learned[id]=true end} end,
    setSelectedSpell=function(_,spell) selected=spell end,setStance=function(_,value) stance=value end},
    NPC={stats={skills={}}}}
for _,name in ipairs({'health','magicka','fatigue'}) do types.Actor.stats.dynamic[name]=stat(name) end
for _,name in ipairs({'alteration','conjuration','destruction','illusion','mysticism','restoration'}) do types.NPC.stats.skills[name]=skill(name) end
package.preload['openmw.core']=function() return {magic={spells={records={amft_fire={id='amft_fire'}}}}} end
package.preload['openmw.self']=function() return {} end
package.preload['openmw.types']=function() return types end
package.preload['openmw.input']=function() return {KEY={F9=9,F10=10}} end
package.preload['openmw.storage']=function() return {playerSection=function() return settings end} end
package.preload['openmw.ui']=function() return {showMessage=function() end} end
package.preload['openmw.interfaces']=function() return {UI={getMode=function() return mode end},
    SkillProgression={addSkillUsedHandler=function(fn) experienceHandler=fn end}} end
function tick(dt) fixture.engineHandlers.onUpdate(dt) end
function key(code) fixture.engineHandlers.onKeyPress({code=code}) end
'''


class ManualTests(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        self.lua.globals().fixture=self.lua.execute((ROOT/'tests/arcane_manual/scripts/arcane_test/player.lua').read_text())

    def test_setup_and_ready(self):
        self.lua.execute("tick(0.6); assert(stats.health.current==500 and stats.magicka.current==2000); assert(values.chance==100 and values.cooldown==nil and values.severity==1); assert(selected.id=='amft_fire'); local n=0; for _ in pairs(learned) do n=n+1 end; assert(n==11); tick(0.4); assert(stance==2)")

    def test_empty_and_refill(self):
        self.lua.execute('tick(0.6); key(9); assert(stats.magicka.current==0); stats.health.current=1; key(10); assert(stats.magicka.current==2000 and stats.health.current==500)')

    def test_controls_ignore_menus_and_modifiers(self):
        self.lua.execute('tick(0.6); mode="menu"; key(9); assert(stats.magicka.current==2000); mode=nil; fixture.engineHandlers.onKeyPress({code=9,withCtrl=true}); assert(stats.magicka.current==2000)')

    def test_load_does_not_reset_test_save(self):
        self.lua.execute('tick(0.6); local data=fixture.engineHandlers.onSave(); values.chance=15; stats.magicka.current=17; fixture.engineHandlers.onLoad(data); tick(1); assert(values.chance==15 and stats.magicka.current==17)')

    def test_pause_does_not_prepare(self):
        self.lua.execute('tick(0); assert(selected==nil and values.chance==nil)')

    def test_new_game_reprepares(self):
        self.lua.execute('tick(0.6); values.chance=0; fixture.engineHandlers.onLoad(nil); tick(1); assert(values.chance==100)')

    def test_experience_defaults_and_readout(self):
        self.lua.execute("tick(0.6); assert(values.failedCastExperience and values.experienceOnlyMisfires and values.useMisfireSchool); experienceHandler('destruction',{skillGain=1})")


class BundleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        builder.build()

    def test_spell_records(self):
        data=(ROOT/'tests/arcane_manual/ArcaneMisfiresTest.esp').read_bytes()
        cursor=0; spells={}
        while cursor<len(data):
            tag,size,_,_=struct.unpack_from('<4sIII',data,cursor)
            offset=cursor+16; end=offset+size; fields={}
            while offset<end:
                name,length=struct.unpack_from('<4sI',data,offset)
                fields[name]=data[offset+8:offset+8+length]; offset+=8+length
            if tag==b'SPEL': spells[fields[b'NAME'][:-1].decode()]=struct.unpack('<iii',fields[b'SPDT'])
            cursor=end
        self.assertEqual(len(spells),11)
        self.assertEqual(spells.pop('amft_success'),(0,0,4))
        self.assertEqual(spells.pop('amft_power'),(2,0,4))
        self.assertTrue(all(value==(0,200,0) for value in spells.values()))

    def test_test_zip_contains_launcher_and_fixture(self):
        with ZipFile(ROOT/f'dist/Arcane-Misfires-Test-{builder.VERSION}.zip') as archive:
            for name in ('Test-Arcane-Misfires.cmd','tools/start-arcane-test.ps1',
                'tests/arcane_manual/ArcaneMisfiresTest.esp','Arcane Misfires/ArcaneMisfires.esp'):
                self.assertEqual(archive.read(name),(ROOT/name).read_bytes())
            self.assertFalse(any(n.startswith('.runtime/') for n in archive.namelist()))

    def test_regular_zip_has_no_test_fixture(self):
        with ZipFile(ROOT/f'dist/Arcane-Misfires-{builder.VERSION}.zip') as archive:
            self.assertFalse(any('arcane_test' in n or 'ArcaneMisfiresTest' in n for n in archive.namelist()))


if __name__=='__main__': unittest.main()
