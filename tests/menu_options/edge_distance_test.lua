-- Combat Config "Measure from body edges" (2026-11-19): Auto's band, RunTo and Flank
-- use Distance + both model sizes as the centre distance when on; unchanged when off.
-- Host simulation only.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local function near(a, b) return math.abs(a - b) < 0.01 end
S = function(t) local s = {}; for _, v in ipairs(t or {}) do s[v] = true end; return s end
L = function(t) return t or {} end
state = { AutoTankMode = { value = 'Off' }, IpcMode = { value = 'Off' } }
package.loaded['vectors'] = true
debug.setmetatable(0, { __index = math }) -- Windower numbers support n:sqrt()
package.loaded['cylibs/conditions/condition'] = (function()
    local C = {}; C.__index = C; C.TargetType = { Enemy = 'Enemy' }
    function C.new() return setmetatable({ editable = true }, C) end
    function C:is_editable() return self.editable end
    return C
end)()

-- A big enemy (size 3) and me (size 0.5), 6 yalms apart centre to centre (2.5 edge to edge).
local dragon = { id = 900, index = 50, x = 6, y = 0, z = 0, model_size = 3, distance = 36, target_index = 0 }
local me = { id = 1, index = 1, x = 0, y = 0, z = 0, model_size = 0.5, hpp = 100 }
local ally = { id = 2, index = 2, x = 6, y = 4, hpp = 100 }
windower = { ffxi = {
    get_player = function() return { index = 1 } end,
    get_mob_by_index = function(i) if i == 50 then return dragon elseif i == 1 then return me elseif i == 2 then return ally end end,
    get_mob_by_id = function(i) if i == 2 then return ally elseif i == 900 then return dragon end end,
    get_party = function() return { p0 = { name = 'Me', mob = me }, p1 = { name = 'Cioara', mob = ally } } end,
} }

local cd = require('cylibs/util/combat_distance')
check('sizes add both bodies', near(cd.sizes(dragon, me), 3.5))
check('edge off: unchanged', cd.effective(3, dragon, false, me) == 3)
check('edge on: Distance + sizes', near(cd.effective(1, dragon, true, me), 4.5))

local CDC = require('cylibs/conditions/combat_distance')
local edge = false
local distance = 3
local cond = CDC.new(function() return distance end, function() return edge end)
check('centres: 6 yalms with Distance 3 is too far', cond:is_satisfied(50) == true)
edge = true
check('edges: 2.5 yalm gap with Distance 3 is fine', cond:is_satisfied(50) == false)
distance = 1
check('edges: 2.5 yalm gap with Distance 1 is too far', cond:is_satisfied(50) == true)
distance = 5; dragon.distance = 4 * 4 -- 0.5 yalm gap, band 5 +/- 1 from edges
check('edges, Distance 5: too close is out of band', cond:is_satisfied(50) == true)
dragon.distance = 8.5 * 8.5 -- 5 yalm gap
check('edges, Distance 5: 5 yalm gap is in band', cond:is_satisfied(50) == false)
check('condition is editable (kept by CombatMode filter)', cond:is_editable() == true)

-- RunTo turns Distance into the centre distance for the run.
local runs = {}
SequenceAction = { new = function(list) return { list = list } end }
BlockAction = { new = function() return {} end }
RunToAction = { new = function(_, d) runs[#runs + 1] = { kind = 'to', d = d }; return {} end }
RunAwayAction = { new = function(_, d) runs[#runs + 1] = { kind = 'away', d = d }; return {} end }
player_util = { face = function() end }
package.loaded['cylibs/movement/recovery'] = { tag = function() end }
package.loaded['cylibs/util/serializer_util'] = {}
local RunTo = require('cylibs/battle/run_to')
dragon.distance = 36
RunTo.new(1, nil, nil, function() return true end):to_action(50)
check('RunTo with edges: runs to Distance + sizes', runs[1].kind == 'to' and near(runs[1].d, 4.5))
RunTo.new(1, nil, nil, function() return false end):to_action(50)
check('RunTo with centres: runs to Distance', runs[2].kind == 'to' and near(runs[2].d, 1))
RunTo.new(3):to_action(50)
check('saved gambit RunTo (no edge function): centres', near(runs[3].d, 3))
dragon.distance = 4 * 4
RunTo.new(1, nil, nil, function() return true end):to_action(50)
check('RunTo with edges: inside the gap -> backs away to Distance + sizes', runs[4].kind == 'away' and near(runs[4].d, 4.5))
check('copy keeps the edge function', RunTo.new(1, setmetatable({}, { __index = { it = function() return function() end end } }), nil, function() return true end):copy().get_edge() == true)

-- Flank: the spot opposite the ally is Distance + sizes from the enemy's centre.
local fs = require('cylibs/movement/flank_state')
fs.reset()
fs.on_auto_attack(900, 2, { [2] = { name = 'Cioara' } })
local FPC = require('cylibs/conditions/flank_position')
dragon.distance = 36
local d, det = FPC.decide(50, 1, true)
check('Flank with edges: spot at Distance + sizes opposite the ally', d == 'move' and near(det.x, 6) and near(det.y, -4.5))
d, det = FPC.decide(50, 1, false)
check('Flank with centres: spot at Distance', d == 'move' and near(det.y, -1))

print(string.format('edge_distance_test: %d pass, %d fail', pass, fail))
if fail > 0 then error('edge_distance_test failed') end
