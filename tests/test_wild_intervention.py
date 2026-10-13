"""Deterministic destination-rule and arrival tests for the standalone intervention."""
from pathlib import Path
import sys
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOD = ROOT / 'Arcane Misfires/scripts/arcane_misfires'
MOCK = '''
local vectorMt={__add=function(a,b) return vector(a.x+b.x,a.y+b.y,a.z+b.z) end}
function vector(x,y,z) return setmetatable({x=x,y=y,z=z},vectorMt) end
local rotationMt={__mul=function(a,b) return rotate(a.angle+b.angle) end}
function rotate(angle) return setmetatable({angle=angle},rotationMt) end
util={vector3=vector,transform={rotateZ=rotate}}
math.random=function(a,b) if a then return b and a or 1 end return real or 0.5 end
events={}; moves={}; candidates={}; landCalls=0; rays=0; messages={}
function cell(id,exterior,gridX,gridY)
    return {id=id,isExterior=exterior,gridX=gridX or 0,gridY=gridY or 0,
        region='region',worldSpaceId='sys::default',waterLevel=0,doors={},
        getAll=function(c) return c.doors end}
end
origin=cell('origin',true,10,20)
destination=cell('destination',true,4,20)
health={current=100}; fatigue={current=100}; enabled=true
player={cell=origin,position=vector(0,0,0),rotation=rotate(0),
    isValid=function() return not invalid end,
    sendEvent=function(_,name,data) table.insert(events,{name=name,data=data}) end,
    teleport=function(p,c,pos,options)
        table.insert(moves,{cell=c,position=pos,options=options}); p.cell=c; p.position=pos
    end}
types={Player={objectIsInstance=function() return not npc end,
    isTeleportingEnabled=function() return enabled end},
    Actor={stats={dynamic={health=function() return health end,fatigue=function() return fatigue end}}},
    Door={isTeleport=function(d) return d.teleport~=false end,
        destCell=function(d) return d.cell end, destPosition=function(d) return d.position end,
        destRotation=function(d) return d.rotation end, record=function(d) return {mwscript=d.script} end},
    Lockable={isLocked=function(d) return d.locked end}}
core={land={getHeightAt=function(pos,c)
        landCalls=landCalls+1; landPosition=pos; return height or 10
    end},
    sendGlobalEvent=function(name,data) table.insert(events,{name=name,data=data}) end,
    getGMST=function() return 'Teleport disabled' end,
    l10n=function() return function() return 'No destination' end end}
world={getExteriorCell=function(x,y,c)
    table.insert(candidates,{x=x,y=y,origin=c}); return destination
end}
nearby={COLLISION_TYPE={Default=15,Actor=4},castRay=function(a,b,options)
    rays=rays+1; lastRay={a=a,b=b,options=options}
    return rayHits and rayHits[rays] and {hitPos=rayHits[rays]} or nil
end}
package.preload['openmw.core']=function() return core end
package.preload['openmw.types']=function() return types end
package.preload['openmw.util']=function() return util end
package.preload['openmw.world']=function() return world end
package.preload['openmw.self']=function() return player end
package.preload['openmw.nearby']=function() return nearby end
package.preload['openmw.debug']=function() return {isGodMode=function() return god end} end
package.preload['openmw.ui']=function() return {showMessage=function(m) table.insert(messages,m) end} end
function intervene() global.eventHandlers.AMF_WildIntervention({target=player}) end
function arrive() localPlayer.arrive({cellId=player.cell.id}) end
'''


class WildTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute(MOCK)
        self.lua.globals()['global'] = self.lua.execute((MOD/'wild_global.lua').read_text())
        self.lua.globals().localPlayer = self.lua.execute((MOD/'wild_player.lua').read_text())

    def runlua(self, code):
        self.lua.execute(code)

    def test_exterior_distance_dry_ground_and_arrival_dispatch(self):
        self.runlua('''intervene(); assert(#moves==1 and #candidates==1)
            local c=candidates[1]; local d=(c.x-origin.gridX)^2+(c.y-origin.gridY)^2
            assert(d>=4 and d<=36 and c.origin==origin)
            assert(moves[1].position.z==10 and moves[1].options.onGround)
            assert(events[1].name=='AMF_WildArrival' and events[1].data.cellId==destination.id)''')

    def test_blocked_teleport_does_not_plan_or_move(self):
        self.runlua("enabled=false; intervene(); assert(#moves==0 and #candidates==0); assert(events[1].name=='AMF_WildFailure' and events[1].data.disabled)")

    def test_invalid_nonplayer_and_dead_targets_are_ignored(self):
        for state in ('invalid=true', 'npc=true', 'health.current=0'):
            with self.subTest(state=state):
                self.setUp()
                self.runlua(state+'; intervene(); assert(#moves==0 and #events==0)')

    def test_connected_interiors_cycles_and_nearest_exterior(self):
        self.runlua('''local first=cell('first',false); local next=cell('next',false)
            first.doors={{cell=next},{cell=origin}}; next.doors={{cell=first}}
            player.cell=first; intervene(); assert(#moves==1 and candidates[1].origin==origin)''')

    def test_interior_search_accepts_ten_edges_but_not_eleven(self):
        for edges in (10, 11):
            with self.subTest(edges=edges):
                self.setUp()
                self.lua.globals().edges = edges
                self.runlua('''local last=origin
                    for i=1,edges do local c=cell('c'..i,false); c.doors={{cell=last}}; last=c end
                    player.cell=last; intervene()
                    assert(#moves==(edges==10 and 1 or 0))
                    if edges==11 then assert(events[1].name=='AMF_WildFailure') end''')

    def test_disconnected_cycle_fails_without_hang(self):
        self.runlua("local c=cell('isolated',false); c.doors={{cell=c}}; player.cell=c; intervene(); assert(#moves==0 and events[1].name=='AMF_WildFailure')")

    def test_water_search_is_bounded_and_cells_do_not_repeat(self):
        self.runlua('''height=-1; intervene(); assert(#moves==0 and #candidates==20 and landCalls==320)
            local visited={}
            for _,c in ipairs(candidates) do
                local key=c.x..','..c.y; assert(not visited[key]); visited[key]=true
                local d=(c.x-origin.gridX)^2+(c.y-origin.gridY)^2; assert(d>=4 and d<=36)
            end''')

    def test_regionless_cells_are_excluded(self):
        self.runlua('destination.region=nil; intervene(); assert(#moves==0 and #candidates==20 and landCalls==0)')

    def test_land_at_water_level_is_valid_and_esm4_grid_uses_4096(self):
        self.runlua("height=0; destination.worldSpaceId='other'; intervene(); assert(#moves==1 and moves[1].position.x==(destination.gridX+0.5)*4096)")

    def test_door_detour_excludes_locked_scripted_and_nonteleport_doors(self):
        self.runlua('''real=0; local interior=cell('interior',false)
            destination.doors={{locked=true},{script='script'},{teleport=false},
                {cell=interior,position=vector(1,2,3),rotation=rotate(2)}}
            intervene(); assert(moves[1].cell==interior and moves[1].position.z==3)
            assert(moves[1].options.rotation.angle==2+math.pi)''')

    def test_no_eligible_door_keeps_exterior_destination(self):
        self.runlua('real=0; destination.doors={{locked=true},{script="script"},{teleport=false}}; intervene(); assert(moves[1].cell==destination)')

    def test_arrival_prefers_lowest_dry_collision_and_ignores_actors(self):
        self.runlua('''rayHits={vector(0,0,-10),vector(1,1,30),vector(2,2,20)}
            arrive(); assert(fatigue.current==-15 and rays==81 and #events==1)
            assert(events[1].data.position.z==20 and events[1].name=='AMF_WildLanding')
            assert(lastRay.options.collisionType==11 and lastRay.options.radius==0)
            assert(lastRay.a.z-lastRay.b.z==100000)''')

    def test_arrival_all_wet_and_no_hit_cases(self):
        self.runlua('rayHits={vector(0,0,-5),vector(1,1,-10)}; arrive(); assert(events[1].data.position.z==-10)')
        self.setUp()
        self.runlua('arrive(); assert(rays==81 and #events==0 and fatigue.current==-15)')

    def test_airborne_probability_boundary_and_height_range(self):
        for roll, expected in ((0.049, 10+250+0.049*750), (0.05, 10)):
            with self.subTest(roll=roll):
                self.setUp()
                self.lua.globals().real = roll
                self.lua.globals().expected = expected
                self.runlua('rayHits={vector(0,0,10)}; arrive(); assert(math.abs(events[1].data.position.z-expected)<0.001)')

    def test_interior_arrival_fatigue_and_god_mode_exemption(self):
        self.runlua("player.cell.isExterior=false; arrive(); assert(rays==0 and fatigue.current==-15)")
        self.setUp()
        self.runlua('god=true; arrive(); assert(fatigue.current==100)')

    def test_stale_arrival_and_landing_cannot_move_changed_cell(self):
        self.runlua("localPlayer.arrive({cellId='old'}); assert(rays==0 and fatigue.current==100); global.eventHandlers.AMF_WildLanding({target=player,cellId='old',position=vector(1,2,3)}); assert(#moves==0)")

    def test_landing_preserves_air_height_and_rechecks_teleport_permission(self):
        self.runlua("global.eventHandlers.AMF_WildLanding({target=player,cellId=origin.id,position=vector(1,2,800)}); assert(#moves==1 and not moves[1].options.onGround and moves[1].position.z==800); enabled=false; global.eventHandlers.AMF_WildLanding({target=player,cellId=origin.id,position=vector(0,0,0)}); assert(#moves==1)")

    def test_failure_messages(self):
        self.runlua("localPlayer.fail({disabled=true}); localPlayer.fail({}); assert(messages[1]=='Teleport disabled' and messages[2]=='No destination')")


if __name__ == '__main__':
    unittest.main()
