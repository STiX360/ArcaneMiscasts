local types = require('openmw.types')
local world = require('openmw.world')
local gear = {'common_shirt_01', 'common_pants_01', 'common_shoes_01', 'common_ring_01', 'iron dagger'}
local departure

local function player(target)
    return target and target:isValid() and types.Player.objectIsInstance(target)
end

return {eventHandlers={
AMF_WildIntervention=function(data)
    local target = data.target
    if data.critical and player(target) and target.cell then
        departure = {cellId=target.cell.id, position=target.position, rotation=target.rotation}
    end
end,
AMFT_ReturnToDeparture=function(data)
    local target = data.target
    if not player(target) then return end
    local cell = departure and world.getCellById(departure.cellId)
    if not cell then
        target:sendEvent('AMFT_ReturnNotice', {message='No critical teleport departure recorded yet.'})
        return
    end
    target:teleport(cell, departure.position, {onGround=false, rotation=departure.rotation})
    target:sendEvent('AMFT_ReturnNotice', {message='Returned to the last critical teleport departure point.'})
end,
AMFT_CriticalKit=function(data)
    local target = data.target
    if not player(target) then return end
    local inventory = types.Actor.inventory(target)
    for _, id in ipairs(gear) do
        if #inventory:findAll(id) == 0 then world.createObject(id, 1):moveInto(inventory) end
    end
    target:sendEvent('AMFT_EquipCriticalKit', {})
end}, engineHandlers={
    onSave=function() return {departure=departure} end,
    onLoad=function(data) departure = data and data.departure or nil end,
}}
