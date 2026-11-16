-- Tanker role wiring with game and Trust doubles: production tanker.lua + tank_util.lua.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local list = {}; function list:it() local i = 0; return function() i = i + 1; return self[i] end end
L = function(t) return setmetatable(t or {}, { __index = list }) end
state = { AutoTankMode = { value = 'Auto' } }
ActionPriority = { medium = 2, high = 3 }
logger = { isEnabled = false }
Condition = { check_conditions = function() return true end }
local now = 100
os.clock = function() return now end

local G = {}; G.__index = G
function G.new(queue, _, vars) return setmetatable({ action_queue = queue, state_vars = vars, last_gambit_time = -10 }, G) end
function G:is_enabled() return self.state_vars[1].value ~= 'Off' end
function G:get_action_identifier() return self:get_type() .. '_action' end
function G:get_player() return { player = true } end
package.loaded['cylibs/trust/roles/gambiter'] = G

local known = { Banishga = true, Flash = true, Provoke = false, ['Banish II'] = true, Banish = true }
local function ability(name, spell)
    return { is_valid = function() return known[name] end, get_conditions = function() return {} end,
             get_spell = spell and function() return { mp_cost = 10 } end or nil,
             to_action = function(_, index) return { name = name, target_index = index } end }
end
Spell = { new = function(name) return ability(name, true) end }
JobAbility = { new = function(name) return ability(name, false) end }

local player = { index = 1, status = 1, vitals = { mp = 100 } }
local mobs = {
    [10] = { id = 10, index = 10, x = 3, y = 0, spawn_type = 16, hpp = 100, status = 1, target_index = 1, claim_id = 101 },
    [11] = { id = 11, index = 11, x = 8, y = 0, spawn_type = 16, hpp = 100, status = 1, target_index = 2, claim_id = 101, name = 'Crab' },
}
local me = { index = 1, x = 0, y = 0 }
windower = { ffxi = {
    get_player = function() return player end,
    get_mob_by_index = function(i) if i == 1 then return me elseif i == 5 then return { index = 5, id = 105, hpp = 80 } end return mobs[i] end,
    get_party = function() return { p0 = { hpp = 100, mob = { index = 1, id = 101 } }, p1 = { hpp = 50, mob = { index = 2, id = 102, pet_index = 5 } } } end,
    get_mob_array = function() return mobs end,
} }

local pushed = {}
local queue = { has_action = function() return #pushed > 0 end, push_action = function(_, a) pushed[#pushed + 1] = a end }
local Tanker = require('cylibs/trust/roles/tanker')
local t = Tanker.new(queue)

player.status = 0
t:check_gambits()
check('idle -> nothing', #pushed == 0)
player.status = 1
t:check_gambits()
local a = pushed[1]
check('engaged, loose crab on Myrr -> Flash queued', a and a.name == 'Flash' and a.target_index == 11)
check('queued with tanker identifier and high priority', a and a.identifier == 'tanker_action' and a.priority == 3)
check('validate true while crab still on Myrr', a and a.validate() == true)
mobs[11].target_index = 1
check('validate false once crab is on the tank', a and a.validate() == false)
mobs[11].target_index = 2
pushed = {}; now = 102
t:check_gambits()
check('same crab within retry delay -> nothing', #pushed == 0)
state.AutoTankMode.value = 'Off'; now = 120
t:check_gambits()
check('AutoTankMode Off -> nothing', #pushed == 0)
state.AutoTankMode.value = 'Auto'; player.vitals.mp = 5
t:check_gambits()
check('no MP for any spell and no Provoke -> nothing', #pushed == 0)
player.vitals.mp = 100; now = 140; pushed = {}
mobs[11] = nil
mobs[12] = { id = 12, index = 12, x = 6, y = 0, spawn_type = 16, hpp = 100, status = 1, target_index = 5, claim_id = 102, name = 'Bat' }
t:check_gambits()
check('enemy on a party member pet is loose -> Flash', pushed[1] and pushed[1].name == 'Flash' and pushed[1].target_index == 12)
known.Flash = false; pushed = {}; now = 160
t:check_gambits()
check('Flash unknown, no WAR -> Banish II', pushed[1] and pushed[1].name == 'Banish II')

print(string.format('tanker_role_test: %d pass, %d fail', pass, fail))
if fail > 0 then os.exit(1) end
