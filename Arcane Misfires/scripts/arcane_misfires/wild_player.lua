local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local debug = require('openmw.debug')
local ui = require('openmw.ui')

local function dropPlan()
    if not self.cell then return end
    local origin = self.position
    local options = {radius=0, collisionType=nearby.COLLISION_TYPE.Default-nearby.COLLISION_TYPE.Actor}
    local ground = nearby.castRay(origin + util.vector3(0, 0, 16),
        origin + util.vector3(0, 0, -64), options)
    if not ground or not ground.hit or not ground.hitPos then return end
    local floor = ground.hitPos
    local positions = {util.vector3(origin.x, origin.y, floor.z+1)}
    local start = util.vector3(origin.x, origin.y, floor.z+16)
    for x = -2, 2 do
        for y = -2, 2 do
            if x ~= 0 or y ~= 0 then
                local point = util.vector3(origin.x+x*24, origin.y+y*24, floor.z+16)
                local support = nearby.castRay(point, point + util.vector3(0, 0, -32), options)
                local wall = nearby.castRay(start, point, options)
                if support and support.hit and support.hitPos and math.abs(support.hitPos.z-floor.z) < 0.5
                    and not (wall and wall.hit) then
                    positions[#positions+1] = util.vector3(point.x, point.y, floor.z+1)
                end
            end
        end
    end
    return {cellId=self.cell.id, origin=origin, positions=positions}
end

local function arrive(data)
    if not self.cell or self.cell.id ~= data.cellId
        or types.Actor.stats.dynamic.health(self).current <= 0 then return end
    if data.critical then
        types.Actor.setEquipment(self, {})
        local npc = data.immersion and types.NPC.record(self) or nil
        local voiceAllowed = not data.immersion or (npc and npc.isMale and npc.race == 'high elf')
        if core.sound.isEnabled() and voiceAllowed then
            core.sound.say('sound/vo/h/m/idl_hm001.mp3', self)
        end
    end
    if not debug.isGodMode() then
        types.Actor.stats.dynamic.fatigue(self).current = math.random(-15, 5)
    end
    if not self.cell.isExterior then return end
    local wet, dry
    -- Inspect the loaded collision scene after the first teleport, including buildings.
    for sample = 0, 80 do
        local x = self.position.x - 500 + (sample % 9)*125
        local y = self.position.y - 500 + math.floor(sample/9)*125
        local hit = nearby.castRay(util.vector3(x, y, self.position.z+50000),
            util.vector3(x, y, self.position.z-50000),
            {radius=0, collisionType=nearby.COLLISION_TYPE.Default-nearby.COLLISION_TYPE.Actor})
        local point = hit and hit.hitPos
        if point then
            if not wet or point.z < wet.z then wet = point end
            if (self.cell.waterLevel == nil or point.z >= self.cell.waterLevel)
                and (not dry or point.z < dry.z) then dry = point end
        end
    end
    local landing = dry or wet
    if not landing then return end
    if math.random() < 0.05 then
        landing = landing + util.vector3(0, 0, 250+math.random()*750)
    end
    core.sendGlobalEvent('AMF_WildLanding', {target=self, cellId=self.cell.id, position=landing})
end

return {
    dropPlan=dropPlan,
    arrive=arrive,
    fail=function(data)
        ui.showMessage(data.disabled and core.getGMST('sTeleportDisabled')
            or core.l10n('ArcaneMisfires')('WildInterventionFailed'))
    end,
}
