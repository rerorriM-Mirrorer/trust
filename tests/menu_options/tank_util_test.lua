-- Tanker decisions: production tank_util against plain mob tables. Host simulation only.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local tu = require('cylibs/util/tank_util')

-- Tank (index 1) at origin; Myrr (index 2, 40% HP) and Cioara (index 3, 90% HP).
local function ctx(mobs)
    return {
        me = { index = 1, x = 0, y = 0 },
        party = { [1] = { id = 101, hpp = 100 }, [2] = { id = 102, hpp = 40 }, [3] = { id = 103, hpp = 90 } },
        mobs = mobs, max_range = 20,
    }
end
local function mob(id, x, y, target_index, extra)
    local m = { id = id, index = id, x = x, y = y, spawn_type = 16, hpp = 100, status = 1,
                target_index = target_index, claim_id = 101 }
    for k, v in pairs(extra or {}) do m[k] = v end
    return m
end
local all = { Banishga = true, Flash = true, Provoke = true }

-- Loose detection
local main = mob(10, 3, 0, 1)                         -- on the tank: not loose
local onMyrr = mob(11, 8, 0, 2)
local onCioara = mob(12, 5, 5, 3)
local otherParty = mob(13, 4, 0, 2, { claim_id = 999 }) -- claimed by another party
local dead = mob(14, 4, 0, 2, { hpp = 0 })
local far = mob(15, 30, 0, 2)
local npc = mob(16, 4, 0, 2, { spawn_type = 2 })
local loose = tu.loose_enemies(ctx({ main, onMyrr, onCioara, otherParty, dead, far, npc }))
check('only party-attacking, live, in-range monsters are loose', #loose == 2)
check('enemy on lowest-HP member first', loose[1] and loose[1].id == 11)

-- Single loose enemy -> Flash
local c = tu.choose(ctx({ main, onMyrr }), all, {}, 100)
check('single loose -> Flash on it', c and c.name == 'Flash' and c.target.id == 11)
c = tu.choose(ctx({ main, onMyrr }), { Provoke = true }, {}, 100)
check('Flash not ready -> Provoke', c and c.name == 'Provoke')
c = tu.choose(ctx({ main, onMyrr }), { Provoke = true, ['Banish II'] = true, Banish = true }, {}, 100)
check('Flash not ready, WAR sub -> Provoke before Banishes', c and c.name == 'Provoke')
c = tu.choose(ctx({ main, onMyrr }), { ['Banish II'] = true, Banish = true }, {}, 100)
check('Flash and Provoke not ready -> Banish II', c and c.name == 'Banish II')
c = tu.choose(ctx({ main, onMyrr }), { Banish = true }, {}, 100)
check('only Banish ready -> Banish', c and c.name == 'Banish')
c = tu.choose(ctx({ main, mob(11, 18, 0, 2) }), { Provoke = true }, {}, 100)
check('Provoke out of range -> nothing', c == nil)
c = tu.choose(ctx({ main }), all, {}, 100)
check('nothing loose -> nothing', c == nil)

-- Retry delay
c = tu.choose(ctx({ main, onMyrr }), all, { [11] = 97 }, 100)
check('acted 3s ago -> wait', c == nil)
c = tu.choose(ctx({ main, onMyrr }), all, { [11] = 90 }, 100)
check('acted 10s ago -> act again', c and c.name == 'Flash')

-- Banishga
local a = mob(20, 8, 0, 2)
local b = mob(21, 10, 2, 3)
c = tu.choose(ctx({ main, a, b }), all, {}, 100)
check('two loose close together -> Banishga', c and c.name == 'Banishga' and #c.marks == 2)
local idle = mob(30, 12, 6, nil, { claim_id = 0, status = 0 })
c = tu.choose(ctx({ main, a, b, idle }), all, {}, 100)
check('uninvolved monster near cluster -> no Banishga, Flash instead', c and c.name == 'Flash')
local spread = mob(21, 8, 15, 3)
c = tu.choose(ctx({ main, a, spread }), all, {}, 100)
check('two loose far apart -> Flash', c and c.name == 'Flash')
c = tu.choose(ctx({ main, a, b }), { Flash = true }, {}, 100)
check('Banishga not ready -> Flash', c and c.name == 'Flash')

print(string.format('tank_util_test: %d pass, %d fail', pass, fail))
if fail > 0 then os.exit(1) end
