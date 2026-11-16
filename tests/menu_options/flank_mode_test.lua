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
check('40 degrees off -> stay (hysteresis)', needed({ x = -3 * math.cos(math.rad(40)), y = 3 * math.sin(math.rad(40)), index = 1 }) == false)
check('60 degrees off -> move', needed({ x = -3 * math.cos(math.rad(60)), y = 3 * math.sin(math.rad(60)), index = 1 }) == true)
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
check('cond: editable (kept by CombatMode filter)', move:is_editable() == true)

print(string.format('flank_mode_test: %d pass, %d fail', pass, fail))
if fail > 0 then os.exit(1) end
