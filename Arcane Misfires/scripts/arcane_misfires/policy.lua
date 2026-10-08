local M = {}
M.schools = {'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration'}
M.defaults = {alteration='burden', conjuration='silence', destruction='fatigue',
    illusion='blind', mysticism='magicka', restoration='fatigue'}
M.specific = {firedamage='fire', frostdamage='frost', shockdamage='shock',
    nighteye='blind', light='blind', chameleon='blind', invisibility='blind',
    levitate='burden', feather='burden', jump='burden', slowfall='burden',
    shield='weakness', spellabsorption='weakness', reflect='weakness',
    restoremagicka='magicka', drainmagicka='magicka', absorbmagicka='magicka'}

function M.number(value, fallback, low, high)
    if type(value) ~= 'number' or value ~= value then return fallback end
    return math.max(low, math.min(high, value))
end

function M.choose(spell, school, cap)
    local outcome, weight = M.defaults[school], -1
    for _, effect in ipairs(spell.effects) do
        if effect.effect.school == school and M.specific[effect.id] then
            local score = effect.effect.baseCost * math.max(1, effect.duration)
                * math.max(1, (effect.magnitudeMin + effect.magnitudeMax) / 2)
            if score > weight then outcome, weight = M.specific[effect.id], score end
        end
    end
    local tier = spell.cost < 15 and 1 or (spell.cost < 40 and 2 or 3)
    return outcome, math.min(tier, math.floor(M.number(cap, 3, 1, 3)))
end

-- A failure must belong to a released cast, not a stale sound or interrupted animation.
function M.detector()
    local pending
    return {
        start = function(spell, now, sounds)
            pending = spell and {spell=spell, start=now, sounds=sounds or {}} or nil
        end,
        release = function(now)
            if pending and not pending.release then pending.release = now end
        end,
        success = function() pending = nil end,
        reset = function() pending = nil end,
        active = function() return pending ~= nil end,
        poll = function(now, sounds)
            if not pending then return end
            if now - pending.start > 4 then pending = nil; return end
            for _, school in ipairs(M.schools) do
                local playing = sounds[school] == true
                if playing and not pending.sounds[school] then pending.failure = school end
                pending.sounds[school] = playing
            end
            if pending.release and now - pending.release >= 0.08 then
                if pending.failure then
                    local spell, school = pending.spell, pending.failure
                    pending = nil
                    return spell, school
                elseif now - pending.release > 0.6 then pending = nil end
            end
        end,
    }
end
return M
