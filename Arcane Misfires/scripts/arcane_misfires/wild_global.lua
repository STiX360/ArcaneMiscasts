local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')

local Door = types.Door
local function exteriorOrigin(start)
    local frontier, seen = {start}, {[start.id]=true}
    for depth = 0, 10 do
        local nextLayer = {}
        for _, cell in ipairs(frontier) do
            if cell.isExterior then return cell end
            if depth < 10 then
                for _, door in ipairs(cell:getAll(Door)) do
                    local destination = Door.isTeleport(door) and Door.destCell(door)
                    if destination and not seen[destination.id] then
                        seen[destination.id] = true
                        nextLayer[#nextLayer+1] = destination
                    end
                end
            end
        end
        frontier = nextLayer
        if #frontier == 0 then return end
    end
end

local offsets = {}
for x = -6, 6 do
    for y = -6, 6 do
        local squared = x*x + y*y
        if squared >= 4 and squared <= 36 then offsets[#offsets+1] = {x, y} end
    end
end

local function dryPoint(cell)
    local size = (cell.worldSpaceId and cell.worldSpaceId ~= 'sys::default') and 4096 or 8192
    for _ = 1, 16 do
        local point = util.vector3((cell.gridX+math.random())*size,
            (cell.gridY+math.random())*size, 0)
        local height = core.land.getHeightAt(point, cell)
        if cell.waterLevel == nil or height >= cell.waterLevel then
            return util.vector3(point.x, point.y, height)
        end
    end
end

local function destinationFor(target)
    local origin = target.cell and exteriorOrigin(target.cell)
    if not origin then return end
    local order = {}
    for i = 1, #offsets do order[i] = i end
    local rotation = target.rotation * util.transform.rotateZ(math.random()*2*math.pi)
    -- Partial Fisher-Yates samples distinct cells uniformly without removing entries.
    for i = 1, math.min(20, #order) do
        local j = math.random(i, #order)
        order[i], order[j] = order[j], order[i]
        local offset = offsets[order[i]]
        local cell = world.getExteriorCell(origin.gridX+offset[1], origin.gridY+offset[2], origin)
        local position = cell and cell.region ~= nil and dryPoint(cell)
        if position then
            if math.random() < 0.2 then
                local chosen, eligible = nil, 0
                for _, door in ipairs(cell:getAll(Door)) do
                    if Door.isTeleport(door) and not Door.record(door).mwscript
                        and not types.Lockable.isLocked(door) then
                        eligible = eligible + 1
                        if math.random(eligible) == 1 then chosen = door end
                    end
                end
                if chosen then
                    cell, position, rotation = Door.destCell(chosen), Door.destPosition(chosen), Door.destRotation(chosen)
                    if math.random() < 0.2 then rotation = rotation * util.transform.rotateZ(math.pi) end
                end
            end
            return cell, position, rotation
        end
    end
end

local function livePlayer(target)
    return target and target:isValid() and types.Player.objectIsInstance(target)
        and types.Actor.stats.dynamic.health(target).current > 0
end

local function validDropPlan(target, plan)
    if not plan or not target.cell or plan.cellId ~= target.cell.id
        or not plan.origin or not plan.positions or #plan.positions == 0 then return false end
    local position = target.position
    return (position.x-plan.origin.x)^2 + (position.y-plan.origin.y)^2
        + (position.z-plan.origin.z)^2 <= 32^2
end

return {
    eventHandlers = {
        AMF_WildIntervention = function(data)
            local target = data.target
            if not livePlayer(target) then return end
            if not types.Player.isTeleportingEnabled(target) then
                target:sendEvent('AMF_WildFailure', {disabled=true})
                return
            end
            local cell, position, rotation = destinationFor(target)
            if not cell then
                target:sendEvent('AMF_WildFailure', {})
                return
            end
            local dropItems = data.critical == true and data.dropItems == true
                and validDropPlan(target, data.dropPlan)
            if dropItems then
                local items = {}
                for _, item in ipairs(types.Actor.inventory(target):getAll()) do
                    items[#items+1] = item
                end
                local positions = data.dropPlan.positions
                local origin = target.cell
                for index, item in ipairs(items) do
                    item:teleport(origin, positions[(index-1) % #positions+1], {onGround=false})
                end
            end
            target:teleport(cell, position, {onGround=true, rotation=rotation})
            target:sendEvent('AMF_WildArrival', {cellId=cell.id, critical=data.critical == true,
                droppedItems=dropItems, immersion=data.immersion == true})
        end,
        AMF_WildLanding = function(data)
            local target = data.target
            if not livePlayer(target) or not target.cell or target.cell.id ~= data.cellId
                or not types.Player.isTeleportingEnabled(target) then return end
            target:teleport(target.cell, data.position, {onGround=false})
        end,
    },
}
