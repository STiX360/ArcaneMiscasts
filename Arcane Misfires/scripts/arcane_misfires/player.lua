local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')
local policy = require('scripts.arcane_misfires.policy')

local group = 'SettingsPlayerArcaneMisfires'
local defaults = {enabled=true, chance=15, severity=3, messages=true,
    failedCastExperience=true, experienceOnlyMisfires=true, useMisfireSchool=true}
I.Settings.registerPage {key='ArcaneMisfires', l10n='ArcaneMisfires', name='PageName'}
I.Settings.registerGroup {
    key=group, page='ArcaneMisfires', l10n='ArcaneMisfires', name='Backfires',
    permanentStorage=false,
    settings={
        {key='enabled', renderer='checkbox', name='Enabled', default=true},
        {key='chance', renderer='number', name='Chance', default=15, argument={min=0,max=100}},
        {key='severity', renderer='number', name='Severity', default=3, argument={min=1,max=3}},
        {key='messages', renderer='checkbox', name='Messages', default=true},
        {key='failedCastExperience', renderer='checkbox', name='FailedCastExperience',
            description='FailedCastExperienceDescription', default=true},
        {key='experienceOnlyMisfires', renderer='checkbox', name='ExperienceOnlyMisfires',
            description='ExperienceOnlyMisfiresDescription', default=true},
        {key='useMisfireSchool', renderer='checkbox', name='UseMisfireSchool',
            description='UseMisfireSchoolDescription', default=true},
    },
}
local settings = storage.playerSection(group)
local detector = policy.detector()
local initialised, saved, selectedId
local count = 0
local awardingExperience = false
local function gainExperience(school, misfireSchool)
    if settings:get('failedCastExperience') == false then return end
    if not misfireSchool and settings:get('experienceOnlyMisfires') ~= false then return end
    if misfireSchool and settings:get('useMisfireSchool') ~= false then school = misfireSchool end
    -- Use the normal progression handlers, without treating our award as a real cast success.
    awardingExperience = true
    I.SkillProgression.skillUsed(school, {useType=I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success})
    awardingExperience = false
end
local function number(key, low, high)
    return policy.number(settings:get(key), defaults[key], low, high)
end
local function sounds()
    local result = {}
    if not core.sound.isEnabled() then return result end
    for _, school in ipairs(policy.schools) do
        local data = core.stats.Skill.records[school].school
        result[school] = data and data.failureSound ~= ''
            and core.sound.isSoundPlaying(data.failureSound, self) or false
    end
    return result
end
local function selected()
    if types.Actor.getSelectedEnchantedItem(self) then return end
    local spell = types.Actor.getSelectedSpell(self)
    if spell and spell.type == core.magic.SPELL_TYPE.Spell then return spell end
end
I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    if groupname ~= 'spellcast' or options.skip or not initialised then return end
    local startKey = options.startKey or options.startkey
    if startKey ~= 'self start' and startKey ~= 'touch start' and startKey ~= 'target start' then return end
    local track = settings:get('enabled') ~= false or
        (settings:get('failedCastExperience') ~= false and settings:get('experienceOnlyMisfires') == false)
    local spell = track and selected() or nil
    selectedId = spell and spell.id
    detector.start(spell, core.getSimulationTime(), sounds())
end)
I.AnimationController.addTextKeyHandler('spellcast', function(_, key)
    if key:sub(-7) ~= 'release' then return end
    local spell = selected()
    if not spell or spell.id ~= selectedId then detector.reset(); return end
    detector.release(core.getSimulationTime())
end)
I.SkillProgression.addSkillUsedHandler(function(skill, options)
    if not awardingExperience and policy.defaults[skill]
        and options.useType == I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success then
        detector.success()
    end
end)

local function update(dt)
    if not initialised then
        for key, default in pairs(defaults) do
            local value = saved and saved.settings and saved.settings[key]
            if value == nil then value = default end
            settings:set(key, value)
        end
        initialised = true
    end
    if dt <= 0 then return end
    if not detector.active() then return end
    local spell, school = detector.poll(core.getSimulationTime(), sounds())
    if not spell then return end
    if types.Actor.stats.dynamic.health(self).current <= 0 then return end
    if settings:get('enabled') == false or math.random() * 100 >= number('chance', 0, 100) then
        gainExperience(school)
        return
    end
    local outcome, tier = policy.choose(spell, school, number('severity', 1, 3))
    if not outcome then gainExperience(school); return end
    local id = 'amf_' .. outcome .. '_' .. tier
    local record = core.magic.spells.records[id]
    if not record then
        print('[Arcane Misfires] Missing '..id..'; enable ArcaneMisfires.esp.')
        gainExperience(school)
        return
    end
    types.Actor.activeSpells(self):add {id=id, effects={0}, caster=self,
        stackable=false, ignoreReflect=true, ignoreSpellAbsorption=true}
    local effect = core.magic.effects.records[record.effects[1].id]
    gainExperience(school, effect.school)
    local staticId = effect.hitStatic
    if not staticId or staticId == '' then staticId = 'vfx_defaulthit' end
    local visual = types.Static.records[staticId]
    if visual then
        animation.addVfx(self, visual.model, {loop=false,
            particleTextureOverride=effect.particle, vfxId='ArcaneMisfires_Hit'})
    end
    local hitSound = effect.hitSound or core.stats.Skill.records[school].school.hitSound
    if type(hitSound) == 'string' and hitSound ~= '' then core.sound.playSound3d(hitSound, self) end
    if settings:get('messages') ~= false then ui.showMessage('Miscast: '..record.name) end
    count = count + 1
end

return {
    interfaceName='ArcaneMisfires',
    interface={version=1, getBackfireCount=function() return count end},
    engineHandlers={
        onUpdate=update,
        onLoad=function(data)
            saved, initialised, selectedId, count = data, false, nil, 0
            detector.reset()
        end,
        onSave=function()
            if not initialised then return saved end
            local values = {enabled=settings:get('enabled') ~= false,
                messages=settings:get('messages') ~= false, chance=number('chance',0,100),
                failedCastExperience=settings:get('failedCastExperience') ~= false,
                experienceOnlyMisfires=settings:get('experienceOnlyMisfires') ~= false,
                useMisfireSchool=settings:get('useMisfireSchool') ~= false,
                severity=number('severity',1,3)}
            return {version=2, settings=values}
        end,
    },
}
