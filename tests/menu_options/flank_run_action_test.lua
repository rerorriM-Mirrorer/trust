-- Flank3: production FlankRunAction (cylibs/battle/flank.lua) reporting to flank_state,
-- with a minimal RunToLocationAction / Renderer double. Host simulation only.
-- (Replaces the Flank2 reach-timeout tests.)
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local function near(a, b) return math.abs(a - b) < 0.01 end
L = function(t) return t or {} end
V = function(t) return t end
S = function(t) return t end
package.loaded['vectors'] = true
local frames = {}
package.loaded['cylibs/ui/views/render'] = { shared = function() return {
    onPrerender = function() return { addAction = function(_, fn) frames[#frames + 1] = fn; return fn end } end } end }
local Base = {}; Base.__index = Base
function Base.new(x, y, z) return setmetatable({ x = x, y = y, z = z, dispose_bag = { add = function() end } }, Base) end
function Base:perform() self.performed = true end
function Base:complete(success) if self.completed then return end self.completed = true; self.success = success end
function Base:cancel() self.cancelled = true; self:complete(false) end
function Base:is_completed() return self.completed end
function Base:is_cancelled() return self.cancelled end
function Base:destroy() self.destroyed = true end
package.loaded['cylibs/actions/runtolocation'] = Base
package.loaded['cylibs/conditions/condition'] = (function()
    local C = {}; C.__index = C; C.TargetType = { Enemy = 'Enemy' }
    function C.new() return setmetatable({}, C) end
    return C
end)()
local faced, stops = 0, 0
player_util = { face = function() faced = faced + 1 end }
local mob = { id = 900, index = 50, x = 0, y = 0, model_size = 1.2 }
local me = { id = 1, index = 1, x = -2, y = 0, model_size = 0.4 }
local ally = { id = 2, x = -3, y = 0, hpp = 100 }
windower = { ffxi = {
    get_player = function() return { index = 1 } end,
    get_mob_by_index = function(i) if i == 50 then return mob elseif i == 1 then return me end end,
    get_mob_by_id = function(i) if i == 2 then return ally elseif i == 900 then return mob end end,
    run = function(v) if v == false then stops = stops + 1 end end,
} }

local fs = require('cylibs/movement/flank_state')
local now = 100
fs.clock = function() return now end
local Flank = require('cylibs/battle/flank')
local Run = Flank.FlankRunAction
local function tick() for _, fn in ipairs(frames) do fn() end end
local details = { anchor = 2, seq = 1, reason = 'test' }

fs.reset()
local a = Run.new(3, 0, 0, 0.6, 50, details)
a:perform()
check('perform records start (running) and commits the trigger', fs.running == true and fs.moves == 1 and fs.pos.mob == 900 and fs.pos.seq == 1)
now = 101; a:complete(true)
check('arrive -> in position, faces target', fs.running == false and fs.last_event == 'in position' and faced == 1)

-- Blocked while still on the ally's side: one try against the enemy, then settle.
fs.reset(); frames = {}; now = 200; me.x, me.y = -2, 0
local b = Run.new(3, 0, 0, 0.6, 50, details)
b:perform(); tick()
now = 200.5; tick()
check('0.5 s without progress -> still running', not b:is_completed())
now = 201.1; tick()
check('1 s blocked outside rear half -> tries against the enemy', b.close_tried and not b:is_completed()
    and near(b.x, 1.6) and near(b.y, 0) and fs.last_event:find('against the enemy') ~= nil)
now = 201.5; tick(); now = 202.2; tick()
check('blocked again -> settles where it stands', b:is_completed() and b.settled and fs.pos.settled
    and near(fs.pos.settled_x, -2) and fs.last_event:find('settled') ~= nil and stops > 0)

-- Blocked inside the rear half: settles at once.
fs.reset(); frames = {}; now = 300; me.x, me.y = 1, 1.5
local c = Run.new(3, 0, 0, 0.6, 50, details)
c:perform(); tick(); now = 301.1; tick()
check('1 s blocked in the rear half -> settles without the close try', c:is_completed() and c.settled and not c.close_tried
    and fs.last_event:find('rear half') ~= nil)

-- Progress keeps it running.
fs.reset(); frames = {}; now = 400; me.x, me.y = -2, 0
local e = Run.new(3, 0, 0, 0.6, 50, details)
e:perform()
for i = 1, 15 do now = now + 0.1; me.x = me.x + 0.15; tick() end
check('steady progress -> no settle', not e:is_completed())

-- Destroyed mid-run (queue cleared): running released.
fs.reset(); frames = {}; now = 500
local f = Run.new(3, 0, 0, 0.6, 50, details)
f:perform(); f:destroy()
check('destroyed mid-run -> running released', fs.running == false)

-- Never performed (already there): no state change.
fs.reset(); now = 600
local g = Run.new(3, 0, 0, 0.6, 50, details)
g:complete(false)
check('never performed -> no state change', fs.moves == 0)

print(string.format('flank_run_action_test: %d pass, %d fail', pass, fail))
if fail > 0 then error('flank_run_action_test failed') end
