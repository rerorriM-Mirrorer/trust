-- Flank3 fix batch (2026-11-19): the tank announcement as it really arrives through
-- TrustCommands (verb passed as the first argument; --quiet prints nothing), a full
-- priority queue making room for a higher-priority action, and Holy as the tank
-- helper's last resort. Host simulation only.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end

-- 1) //trust flank tank <name> <on|off> --quiet through the real dispatcher.
T = function(t)
    t = t or {}
    return setmetatable(t, { __index = { unpack = function(self) return unpack(self) end } })
end
L = function(t) return t or {} end
local printed, errors = {}, {}
addon_message = function(_, m) printed[#printed + 1] = m end
addon_system_error = function(m) errors[#errors + 1] = m end
package.loaded['cylibs/util/command_feedback'] = {
    is_quiet = function() return false end,
    run = function(_, fn) return fn() end,
}
local fs = require('cylibs/movement/flank_state')
local FlankCommands = require('commands/FlankCommands')
local commands = FlankCommands.new()
commands:handle_command('tank', 'Clairvaux', 'on', '--quiet')
check('announcement registers the tank', fs.tanks.clairvaux == true)
check('announcement prints nothing (no usage error, no message)', #errors == 0 and #printed == 0)
commands:handle_command('tank', 'Clairvaux', 'off', '--quiet')
check('off removes the tank', fs.tanks.clairvaux == nil and #errors == 0)
commands:handle_command('tank', 'Clairvaux', 'on')
check('typed (not quiet) reports the change', fs.tanks.clairvaux == true and printed[1] and printed[1]:find('tank on', 1, true))
commands:handle_command('tank', 'Clairvaux')
check('missing on/off -> usage error', #errors == 1)

-- 2) A full priority queue makes room for a higher-priority action.
local ActionQueue = (function()
    -- Load only the push/evict methods against a minimal queue double.
    local f = assert(io.open('cylibs/actions/action_queue.lua')); local src = f:read('*a'); f:close()
    local function method(name, nxt)
        local a = assert(src:find('function ActionQueue:' .. name, 1, true))
        local b = assert(src:find(nxt, a + 1, true))
        return src:sub(a, b - 1)
    end
    local env = setmetatable({ ActionQueue = {}, require = function()
        return { is_movement = function() return false end }
    end }, { __index = _G })
    local chunk = method('push_action', '-- Fork: removes the lowest') .. method('evict_lower_than', '-- Pushes the given actions')
    -- Lua 5.1 (Windower): loadstring + setfenv; Lua 5.2+: load with an environment.
    local fn
    if setfenv then fn = assert(loadstring(chunk, 'action_queue methods')); setfenv(fn, env)
    else fn = assert(load(chunk, 'action_queue methods', 't', env)) end
    fn()
    return env.ActionQueue
end)()
local function Q()
    local items = {}
    return {
        push = function(_, v) items[#items + 1] = v end,
        pop = function() return table.remove(items, 1) end,
        clear = function() items = {} end,
        length = function() return #items end,
        it = function() local i = 0; return function() i = i + 1; return items[i] end end,
        sort = function(_, cmp) table.sort(items, cmp) end,
        items = function() return items end,
    }
end
local function action(name, priority)
    return { name = name, priority = priority, getpriority = function(s) return s.priority end,
        destroy = function(s) s.destroyed = true end }
end
local q = setmetatable({ queue = Q(), is_enabled = true, max_size = 5, is_priority_queue = true,
    current_action = { name = 'casting' },
    cleanup = function() end, contains = function() return false end,
    on_action_queued = function() return { trigger = function() end } end,
    length = function(s) return s.queue:length() end }, { __index = ActionQueue })
local buffs = {}
for i = 1, 5 do buffs[i] = action('buff' .. i, 1); q:push_action(buffs[i]) end
local banish = action('Banish II', 3)
q:push_action(banish)
local names = {}
for a in q.queue:it() do names[#names + 1] = a.name end
check('full queue: high-priority action is queued first', names[1] == 'Banish II' and #names == 5 and not banish.destroyed)
local dropped = 0
for i = 1, 5 do if buffs[i].destroyed then dropped = dropped + 1 end end
check('one lowest-priority action made room', dropped == 1)
local low = action('debuff', 1)
q:push_action(low)
check('equal or lower priority is still dropped when full', low.destroyed and q.queue:length() == 5)
check('the running action is never evicted', q.current_action.name == 'casting')

-- 3) Holy is the last resort in the single-target order.
local tu = require('cylibs/util/tank_util')
check('Holy last in the order', tu.SingleOrder[#tu.SingleOrder] == 'Holy' and tu.Ranges.Holy == 19)
local ctx = { me = { index = 1, x = 0, y = 0 },
    party = { [1] = { id = 101, hpp = 100 }, [2] = { id = 102, hpp = 40 } },
    mobs = { { id = 11, index = 11, x = 8, y = 0, spawn_type = 16, hpp = 100, status = 1, target_index = 2, claim_id = 101 } },
    max_range = 20 }
local c = tu.choose(ctx, { Holy = true }, {}, 100)
check('only Holy ready -> Holy', c and c.name == 'Holy')
c = tu.choose(ctx, { Holy = true, Banish = true }, {}, 100)
check('Banish ready -> Banish before Holy', c and c.name == 'Banish')

print(string.format('tank_announce_queue_test: %d pass, %d fail', pass, fail))
if fail > 0 then error('tank_announce_queue_test failed') end
