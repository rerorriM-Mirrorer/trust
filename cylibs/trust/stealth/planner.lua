-- One-shot planning only. Observed buffs, not successful dispatch, satisfy a goal.
local Planner = {}
Planner.methods = {
    as = {effect='sneak', kind='area', spell='Sneak', rank=1},
    ai = {effect='invisible', kind='area', spell='Invisible', rank=1},
    s = {effect='sneak', kind='spell', spell='Sneak', rank=2},
    i = {effect='invisible', kind='spell', spell='Invisible', rank=2},
    m = {effect='sneak', kind='self', spell='Monomi: Ichi', rank=3},
    t2 = {effect='invisible', kind='self', spell='Tonko: Ni', rank=3},
    t1 = {effect='invisible', kind='self', spell='Tonko: Ichi', rank=4},
    j = {effect='both', kind='jig', ability='Spectral Jig', rank=5},
    o = {effect='sneak', kind='item', item='Silent Oil', rank=6},
    p = {effect='invisible', kind='item', item='Prism Powder', rank=6},
}

function Planner.distance(a, b)
    if not a or not b or not a.x or not b.x or a.zone ~= b.zone then return math.huge end
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2)
end

function Planner.missing(members, effect)
    local result = {}
    for _, member in ipairs(members) do
        if not member[effect] then result[#result+1] = member.name end
    end
    return result
end

function Planner.key(provider, code, target)
    return provider..':'..code..':'..target
end

function Planner.next(members, effect, attempted)
    local choices = {}
    local missing = Planner.missing(members, effect)
    for _, provider in ipairs(members) do
        for code, method in pairs(Planner.methods) do
            if provider.ready and provider.caps[code] and (method.effect == effect or method.effect == 'both') then
                for _, target in ipairs(members) do
                    local own = target.name == provider.name
                    local eligible = not target.aborted and not target[effect] and not provider.invisible
                    if method.kind == 'spell' then
                        eligible = eligible and Planner.distance(provider, target) <= 20
                    elseif method.kind == 'area' then
                        -- Cast on self only when every remaining target is nearby.
                        -- In particular, do not invis the caster before remote work.
                        eligible = not provider.invisible and not target.aborted and own and #missing > 1
                        for _, other in ipairs(members) do
                            if other.aborted then eligible = false end
                            if not other[effect] and Planner.distance(provider, other) > 9 then eligible = false end
                        end
                    else eligible = eligible and own end
                    -- Spectral Jig does not reapply either effect with Sneak up.
                    if method.kind == 'jig' and provider.sneak then eligible = false end
                    local key = Planner.key(provider.name, code, target.name)
                    if eligible and not attempted[key] then
                        choices[#choices+1] = {provider=provider.name, code=code, target=target.name,
                            rank=method.rank, own=own, key=key, effect=effect, wait=provider.caps[code] == 'wait'}
                    end
                end
            end
        end
    end
    table.sort(choices, function(a,b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        -- Each caster covers other people before themselves.
        if effect == 'invisible' and a.own ~= b.own then return not a.own end
        if a.wait ~= b.wait then return not a.wait end
        if a.provider ~= b.provider then return a.provider < b.provider end
        if a.target ~= b.target then return a.target < b.target end
        return a.code < b.code
    end)
    return choices[1]
end

return Planner
