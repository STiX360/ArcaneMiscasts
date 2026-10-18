local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local pending

local function recordId(item)
    return item.recordId:match('^gold_%d+$') and 'gold_001' or item.recordId
end

return {
    eventHandlers={
        AMFT_DropSeed=function(data)
            local inventory = types.Actor.inventory(data.target)
            for id, count in pairs({common_shirt_01=1, common_pants_01=1,
                ['iron dagger']=1, gold_001=1000, p_restore_health_s=3}) do
                world.createObject(id, count):moveInto(inventory)
            end
            data.target:sendEvent('AMFT_DropSeeded', {})
        end,
        AMFT_DropArm=function(data)
            local expected = {}
            local entries = 0
            for _, item in ipairs(types.Actor.inventory(data.target):getAll()) do
                local id = recordId(item)
                expected[id] = (expected[id] or 0)+item.count
                entries = entries+1
            end
            pending = {target=data.target, origin=data.target.cell, expected=expected,
                entries=entries, height=data.plan.positions[1].z, ticks=0}
            core.sendGlobalEvent('AMF_WildIntervention', {target=data.target, critical=true,
                dropItems=true, dropPlan=data.plan, immersion=true})
        end,
    },
    engineHandlers={onUpdate=function()
        if not pending then return end
        pending.ticks = pending.ticks+1
        if pending.ticks < 10 then return end
        local result = pending
        pending = nil
        local ok, message = pcall(function()
            assert(result.target.cell.id ~= result.origin.id, 'player did not teleport')
            assert(#types.Actor.inventory(result.target):getAll()==0, 'inventory not empty')
            local found = {}
            local entries = 0
            for _, item in ipairs(result.origin:getAll()) do
                local id = recordId(item)
                if result.expected[id] then
                    assert(math.abs(item.position.z-result.height)<0.01, 'items not on a common plane')
                    found[id] = (found[id] or 0)+item.count
                    entries = entries+1
                end
            end
            assert(entries==result.entries, 'item stack count changed: expected '..result.entries..', found '..entries)
            for id, count in pairs(result.expected) do
                assert(found[id]==count, 'lost items: '..id)
            end
            return tostring(entries)..' original stacks left on one plane in '..result.origin.name
        end)
        result.target:sendEvent('AMFT_DropResult', {ok=ok, message=tostring(message)})
    end},
}
