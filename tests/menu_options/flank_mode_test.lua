-- Flank combat mode: production flanking_util geometry and FlankPositionCondition decisions
-- against game doubles. Host simulation only; no live FFXI claim.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local function near(a, b) return math.abs(a - b) < 0.01 end

S = function(t) local s = {}; for _, v in ipairs(t or {}) do s[v] = true end; return s end
state = { AutoTankMode = { value = 'Off' } }
package.loaded['cylibs/conditions/condition'] = (function()
    local C = {}; C.__index = C; C.TargetType = { Enemy = 'Enemy' }
    function C.new() return setmetatable({ editable = true }, C) end
    function C:is_editable() return self.editable end
    return C
end)()
_raw = {}
package.loaded['vectors'] = true

local fu = require('cylibs/util/flanking_util')
local FPC = require('cylibs/conditions/flank_position')
local fs = require('cylibs/movement/flank_state')
local now = 1000
fs.clock = function() return now end

-- Facing convention: player_util.face turns to -atan2(dy, dx), so a mob facing +x (east)
-- has facing 0 and one facing +y (north) has facing -pi/2.
local east = { x = 0, y = 0, facing = 0 }
local bx, by = fu.flank_point(east, fu.Back, 3)
check('back of east-facing mob is west', near(bx, -3) and near(by, 0))
local north = { x = 10, y = 10, facing = -math.pi / 2 }
bx, by = fu.flank_point(north, fu.Back, 2)
check('back of north-facing mob is south', near(bx, 10) and near(by, 8))
local lx, ly = fu.flank_point(north, fu.Left, 2)
check('left of north-facing mob is west', near(lx, 8) and near(ly, 10))
local rx, ry = fu.flank_point(north, fu.Right, 2)
check('right of north-facing mob is east', near(rx, 12) and near(ry, 10))

check('angle 0 when directly behind', near(fu.angle_off(east, { x = -3, y = 0 }, fu.Back), 0))
check('angle 180 when in front', near(fu.angle_off(east, { x = 3, y = 0 }, fu.Back), 180))
check('angle 90 at the side', near(fu.angle_off(east, { x = 0, y = 3 }, fu.Back), 90))

local function needed(me, radius) return (fu.flank_needed(east, me, fu.Back, radius or 3)) end
check('in front -> move', needed({ x = 3, y = 0, index = 1 }) == true)
check('behind -> stay', needed({ x = -3, y = 0, index = 1 }) == false)
check('60 degrees off -> stay (66-degree tolerance)', needed({ x = -3 * math.cos(math.rad(60)), y = 3 * math.sin(math.rad(60)), index = 1 }) == false)
check('72 degrees off -> move', needed({ x = -3 * math.cos(math.rad(72)), y = 3 * math.sin(math.rad(72)), index = 1 }) == true)
check('behind but too far -> move', needed({ x = -6, y = 0, index = 1 }) == true)
local targeted = { x = 0, y = 0, facing = 0, target_index = 1 }
check('mob targeting me -> no flank move', (fu.flank_needed(targeted, { x = 3, y = 0, index = 1 }, fu.Back, 3)) == false)

-- Condition against windower doubles.
local mob = { index = 50, x = 0, y = 0, facing = 0, target_index = 7 }
local me = { index = 1, x = 3, y = 0 }
windower = { ffxi = {
    get_player = function() return { index = 1 } end,
    get_mob_by_index = function(i) if i == 50 then return mob elseif i == 1 then return me end end,
} }
local radius = function() return 3 end
local move, hold = FPC.new('move', radius), FPC.new('hold', radius)
check('cond: front, mob on tank -> move', move:is_satisfied(50) == true and hold:is_satisfied(50) == false)
me.x = -3
check('cond: behind -> no move', move:is_satisfied(50) == false)
me.x = 3; mob.target_index = 1
check('cond: mob on me -> hold, not move', move:is_satisfied(50) == false and hold:is_satisfied(50) == true)
mob.target_index = 7; state.AutoTankMode.value = 'Auto'
check('cond: AutoTankMode Auto -> hold, not move', move:is_satisfied(50) == false and hold:is_satisfied(50) == true)
state.AutoTankMode.value = 'Off'

-- Flank2 timing (flank_state) through the condition.
fs.reset(); me.x, me.y = 3, 0  -- in front
check('t: out of position, fresh -> move', move:is_satisfied(50) == true)
fs.on_start(now)
check('t: while running -> no new move, no hold', move:is_satisfied(50) == false and hold:is_satisfied(50) == false)
now = now + 1; fs.on_arrive(now)
me.x = -3 * math.cos(math.rad(80)); me.y = 3 * math.sin(math.rad(80))  -- 80 degrees off
now = now + 1
check('t: 2s after start -> wait for 3s check interval', move:is_satisfied(50) == false)
now = now + 1.5
check('t: 3.5s after start but settling (80 deg) -> no move', move:is_satisfied(50) == false)
me.x, me.y = 3, 0  -- now in front (180 deg > 135)
check('t: settling but in front -> move', move:is_satisfied(50) == true)
me.x, me.y = -8, 0  -- behind but too far
check('t: settling but too far -> move', move:is_satisfied(50) == true)

fs.reset(); now = 2000
fs.on_start(now); now = now + 3.5
fs.on_fail(now, 'could not reach the back in 3s')
me.x, me.y = 3, 0
check('t: failed reach -> paused: no move, hold (act like Auto)', move:is_satisfied(50) == false and hold:is_satisfied(50) == true)
now = now + 9.1
check('t: after 9s pause -> move again, hold off', move:is_satisfied(50) == true and hold:is_satisfied(50) == false)

fs.reset(); now = 3000
for i = 1, 3 do fs.on_start(now); now = now + 1; fs.on_arrive(now); now = now + 2 end
check('t: 3 moves in 9s -> paused', fs.is_paused(now) and move:is_satisfied(50) == false and hold:is_satisfied(50) == true)
fs.reset(); now = 4000
fs.on_start(now); now = now + 1; fs.on_arrive(now); now = now + 9
fs.on_start(now); now = now + 1; fs.on_arrive(now)
check('t: 2 moves 10s apart -> not paused', not fs.is_paused(now))
fs.reset(); now = 5000; fs.on_start(now); now = now + 6
check('t: run that never reported back is released', (fs.can_start(now, 180, false)) == true)
check('t: status text', fs.status(now):find('Flank:') ~= nil)
check('cond: editable (kept by CombatMode filter)', move:is_editable() == true)

print(string.format('flank_mode_test: %d pass, %d fail', pass, fail))
if fail > 0 then os.exit(1) end
