-- Flank3 decisions: production flank_state (event-driven triggers, rear cone, tank,
-- settle) and FlankPositionCondition against game doubles. Host simulation only; no
-- live FFXI claim. (Replaces the Flank2 timer tests.)
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local function near(a, b) return math.abs(a - b) < 0.01 end

S = function(t) local s = {}; for _, v in ipairs(t or {}) do s[v] = true end; return s end
state = { AutoTankMode = { value = 'Off' }, IpcMode = { value = 'All' } }
package.loaded['cylibs/conditions/condition'] = (function()
    local C = {}; C.__index = C; C.TargetType = { Enemy = 'Enemy' }
    function C.new() return setmetatable({ editable = true }, C) end
    function C:is_editable() return self.editable end
    return C
end)()
package.loaded['vectors'] = true

local fs = require('cylibs/movement/flank_state')
local FPC = require('cylibs/conditions/flank_position')
local now = 1000
fs.clock = function() return now end

-- World: enemy at the origin; Cioara (id 2) west of it; Myrr (id 3) north; me (id 1).
local mob = { id = 900, index = 50, x = 0, y = 0, z = 0, target_index = 0, model_size = 1, spawn_type = 16 }
local me = { id = 1, index = 1, x = -3, y = 0, z = 0, model_size = 0.5, hpp = 100 }
local cioara = { id = 2, index = 2, x = -3, y = 0, hpp = 100 }
local myrr = { id = 3, index = 3, x = 0, y = 3, hpp = 100 }
local pet = { id = 33, index = 33, x = 0, y = -3, hpp = 100 }
myrr.pet_index = 33
local by_id = { [1] = me, [2] = cioara, [3] = myrr, [33] = pet, [900] = mob }
local by_index = { [1] = me, [2] = cioara, [3] = myrr, [33] = pet, [50] = mob }
local party = {
    p0 = { name = 'Clairvaux', mob = me },
    p1 = { name = 'Cioara', mob = cioara },
    p2 = { name = 'Myrr', mob = myrr },
}
local sent = {}
windower = { ffxi = {
    get_player = function() return { index = 1, name = 'Clairvaux' } end,
    get_party = function() return party end,
    get_mob_by_index = function(i) return by_index[i] end,
    get_mob_by_id = function(i) return by_id[i] end,
} }
IpcRelay = { shared = function() return { send_message = function(_, m) sent[#sent + 1] = m end } end }
package.loaded['cylibs/messages/command_message'] = { new = function(c) return { command = c } end }

local radius = function() return 3 end
local move, hold = FPC.new('move', radius), FPC.new('hold', radius)
local function decision() return (FPC.decide(50, 3)) end
local function hit(target_id, category)
    fs.on_action({ category = category or 1, actor_id = 900, targets = { { id = target_id } } },
        FPC.allies, function(id) return by_id[id] and by_id[id].spawn_type == 16 end)
end
local function run_to_spot()
    local d, det = FPC.decide(50, 3)
    fs.on_start(now, 900, det.seq, det.reason)
    me.x, me.y = det.x, det.y
    fs.on_arrive(now)
    return det
end

-- Geometry helpers.
local sx, sy = fs.spot(mob, cioara, 3)
check('spot is opposite the ally', near(sx, 3) and near(sy, 0))
check('rear angle 0 opposite the ally', near(fs.rear_angle(mob, cioara, { x = 3, y = 0 }), 0))
check('rear angle 180 on the ally side', near(fs.rear_angle(mob, cioara, { x = -3, y = 0 }), 180))

-- 1) No hits yet: act like Auto.
fs.reset()
check('no ally hit yet -> hold (Auto)', decision() == 'hold' and hold:is_satisfied(50) and not move:is_satisfied(50))
-- Spells and TP moves never count.
hit(2, 4); hit(2, 11)
check('spell/TP move does not count', decision() == 'hold')
-- 2) Enemy auto-attacks Cioara; I stand next to her: move to the spot opposite her.
hit(2)
local d, det = FPC.decide(50, 3)
check('first ally hit, outside cone -> move', d == 'move' and move:is_satisfied(50) and not hold:is_satisfied(50))
check('move goes opposite Cioara', near(det.x, 3) and near(det.y, 0))
run_to_spot()
check('arrived -> stay (in position)', decision() == 'stay' and not move:is_satisfied(50) and not hold:is_satisfied(50))
-- More hits on the same ally: nothing.
hit(2); hit(2)
check('same ally again -> stay', decision() == 'stay')
-- 3) Enemy switches to Myrr (north). Opposite Myrr is south; I'm east: 90 degrees off -> move.
hit(3)
d, det = FPC.decide(50, 3)
check('new ally hit, outside 120-degree cone -> move', d == 'move' and near(det.x, 0) and near(det.y, -3))
run_to_spot()
-- Back to Cioara: opposite her is east; I'm south: 90 off -> move. Then Myrr again, but
-- first stand 50 degrees off the spot opposite Myrr: inside the cone, no move.
hit(2); run_to_spot()
me.x, me.y = 3 * math.sin(math.rad(50)), -3 * math.cos(math.rad(50))
hit(3)
check('new ally hit but inside the cone (50 deg) -> stay', decision() == 'stay')
-- Distance band still applies: too far -> move to the spot.
me.x, me.y = 0, -6
check('too far -> move', decision() == 'move')
me.x, me.y = 0, -3
-- 4) Enemy on me: Auto.
hit(1)
check('enemy hits me -> hold (Auto)', decision() == 'hold')
mob.target_index = 1
check('enemy targeting me -> hold', decision() == 'hold')
mob.target_index = 0
-- I'm the tank: Auto.
hit(2); state.AutoTankMode.value = 'Auto'
check('my Auto Tank Mode -> hold', decision() == 'hold')
state.AutoTankMode.value = 'Off'

-- 5) Tank announced (Cioara): other allies' hits are ignored.
fs.reset(); fs.set_tank('Cioara', true); me.x, me.y = 0, 3.5
hit(3)
check('tank present, enemy on Myrr only -> hold until it hits the tank', decision() == 'hold')
hit(2)
d, det = FPC.decide(50, 3)
check('enemy hits the tank -> move opposite the tank', d == 'move' and near(det.x, 3) and near(det.y, 0))
run_to_spot()
hit(3)
check('tank present: hit on Myrr ignored', decision() == 'stay')
me.x, me.y = 0, 3
hit(2)
check('back to the tank after Myrr, outside cone -> move', decision() == 'move')
-- A pet sharing the tank's name is never the tank.
fs.reset(); fs.set_tank('Myrr', true)
hit(33)
check('pet of an announced tank is not the tank', fs.enemies[900].tank == nil)
fs.set_tank('Myrr', false); fs.set_tank('Cioara', false)

-- 6) Settled (spot unreachable) stays put until own movement, a trigger needing a move,
-- or the enemy getting well away.
fs.reset(); me.x, me.y = -1, 2.5
hit(2)
d, det = FPC.decide(50, 3)
fs.on_start(now, 900, det.seq, det.reason)
fs.on_settle(now, me.x, me.y, 'spot blocked; in the rear half')
check('settled -> stay even outside the band', decision() == 'stay')
me.x, me.y = -1.5, 2.6
check('settled, small drift -> still stay', decision() == 'stay')
me.x, me.y = -1, 4
check('settled, I moved 1.5 yalms on my own -> may move again', decision() == 'move')
me.x, me.y = -1, 2.5
hit(3)
check('settled, new trigger outside cone -> move', decision() == 'move')

-- 7) Running: no second move.
fs.reset(); hit(2); d, det = FPC.decide(50, 3); fs.on_start(now, 900, det.seq)
check('mid-run -> stay', decision() == 'stay')
fs.on_stop(now, 'test')

-- 8) Tank announcement and status.
sent = {}
state.AutoTankMode.value = 'Auto'; fs.announce_tank()
check('announce: quiet flank tank on', sent[1] and sent[1].command == 'trust flank tank Clairvaux on --quiet')
state.AutoTankMode.value = 'Off'; fs.announce_tank()
check('announce: off', sent[2] and sent[2].command == 'trust flank tank Clairvaux off --quiet')
state.IpcMode.value = 'Off'; fs.announce_tank()
check('announce: nothing when IPC is off', #sent == 2)
state.IpcMode.value = 'All'
fs.set_tank('Cioara', true)
check('status lists tanks', fs.status(now):find('tanks: cioara', 1, true) ~= nil)
check('cond: editable (kept by CombatMode filter)', move:is_editable() == true)

print(string.format('flank_mode_test: %d pass, %d fail', pass, fail))
if fail > 0 then error('flank_mode_test failed') end
