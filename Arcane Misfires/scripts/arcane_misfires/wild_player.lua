local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local debug = require('openmw.debug')
local ui = require('openmw.ui')

local function arrive(data)
    if not self.cell or self.cell.id ~= data.cellId
        or types.Actor.stats.dynamic.health(self).current <= 0 then return end
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
    arrive=arrive,
    fail=function(data)
        ui.showMessage(data.disabled and core.getGMST('sTeleportDisabled')
            or core.l10n('ArcaneMisfires')('WildInterventionFailed'))
    end,
}
