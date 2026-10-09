local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local settings = storage.playerSection('SettingsPlayerArcaneMisfires')
local schools = {'alteration','conjuration','destruction','illusion','mysticism','restoration'}
local spells = {'fire','frost','shock','burden','blind','silence','magicka','weakness','fatigue','success','power'}
local prepared, elapsed, readyAt = false, 0, nil

I.SkillProgression.addSkillUsedHandler(function(skill, options)
    if not prepared or not types.NPC.stats.skills[skill] then return end
    for _, school in ipairs(schools) do
        if skill == school then
            local message = string.format('Test XP: %s +%.2f use points', skill, options.skillGain)
            ui.showMessage(message)
            print('[Arcane Misfires Test] '..message)
            return
        end
    end
end)

local function refill()
    for name, value in pairs({health=500,magicka=2000,fatigue=1000}) do
        local stat = types.Actor.stats.dynamic[name](self)
        stat.base = value
        stat.current = value
    end
end

local function update(dt)
    if dt <= 0 then return end
    elapsed = elapsed + dt
    if not prepared and elapsed > 0.5 then
        for _, school in ipairs(schools) do types.NPC.stats.skills[school](self).base = 0 end
        types.Actor.stats.attributes.willpower(self).base = 0
        types.Actor.stats.attributes.luck(self).base = 0
        refill()
        for _, id in ipairs(spells) do types.Actor.spells(self):add('amft_'..id) end
        settings:set('enabled',true); settings:set('chance',100)
        settings:set('severity',1); settings:set('messages',true)
        settings:set('failedCastExperience',true)
        settings:set('experienceOnlyMisfires',true)
        settings:set('useMisfireSchool',true)
        types.Actor.setSelectedSpell(self, core.magic.spells.records.amft_fire)
        readyAt = elapsed + 0.3
        prepared = true
        ui.showMessage('Arcane Misfires test character ready.')
        print('[Arcane Misfires Test] Fresh character prepared; isolated test profile.')
    end
    if readyAt and elapsed >= readyAt then
        types.Actor.setStance(self, types.Actor.STANCE.Spell)
        readyAt = nil
    end
end

return {
    engineHandlers={
        onUpdate=update,
        onSave=function() return {prepared=prepared} end,
        onLoad=function(data)
            prepared = data and data.prepared == true or false
            elapsed, readyAt = 0, nil
        end,
        onKeyPress=function(key)
            if not prepared or I.UI.getMode() ~= nil or key.withCtrl or key.withAlt
                or key.withShift or key.withSuper then return end
            if key.code == input.KEY.F10 then
                refill(); ui.showMessage('Test resources refilled.')
            elseif key.code == input.KEY.F9 then
                types.Actor.stats.dynamic.magicka(self).current = 0
                ui.showMessage('Test magicka emptied.')
            end
        end,
    },
}
