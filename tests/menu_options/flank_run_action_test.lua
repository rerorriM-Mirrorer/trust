-- Flank2: production FlankRunAction (cylibs/battle/flank.lua) reporting to flank_state,
-- with a minimal RunToLocationAction / Renderer double. Host simulation only.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
L = function(t) return t or {} end
package.loaded['vectors'] = true
local frames = {}
package.loaded['cylibs/ui/views/render'] = { shared = function() return {
    onPrerender = function() return { addAction = function(_, fn) frames[#frames + 1] = fn; return fn end } end } end }
local Base = {}; Base.__index = Base
function Base.new() return setmetatable({ dispose_bag = { add = function() end } }, Base) end
function Base:perform() self.performed = true end
function Base:complete(success) if self.completed then return end self.completed = true; self.success = success end
function Base:cancel() self.cancelled = true; self:complete(false) end
function Base:is_completed() return self.completed end
function Base:is_cancelled() return self.cancelled end
function Base:destroy() self.destroyed = true end
package.loaded['cylibs/actions/runtolocation'] = Base
local faced = 0
player_util = { face = function() faced = faced + 1 end }
windower = { ffxi = { get_mob_by_index = function() return { x = 0, y = 0 } end } }

local fs = require('cylibs/movement/flank_state')
local now = 100
fs.clock = function() return now end
local Flank = require('cylibs/battle/flank')
local Run = Flank.FlankRunAction
local function tick() for _, fn in ipairs(frames) do fn() end end

fs.reset()
local a = Run.new(1, 2, 0, 0.6, 50)
a:perform()
check('perform records start (running)', fs.running == true and fs.moves == 1)
now = 101; a:complete(true)
check('arrive -> settling, faces target', fs.running == false and fs.settle_until == 106 and faced == 1)

fs.reset(); frames = {}; now = 200
local b = Run.new(1, 2, 0, 0.6, 50)
b:perform(); now = 202; tick()
check('2s in -> still running', not b:is_completed())
now = 203.2; tick()
check('over 3s -> cancelled, paused 9s', b:is_cancelled() and fs.is_paused(now) and fs.pause_until == 212.2 and fs.last_event:find('could not reach') ~= nil)

fs.reset(); frames = {}; now = 300
local c = Run.new(1, 2, 0, 0.6, 50)
c:perform(); c:destroy()
check('destroyed mid-run (queue cleared) -> running released, no pause', fs.running == false and not fs.is_paused(now))

fs.reset(); now = 400
local d = Run.new(1, 2, 0, 0.6, 50)
d:complete(false)
check('never performed (already there) -> no state change', fs.moves == 0 and not fs.is_paused(now))

print(string.format('flank_run_action_test: %d pass, %d fail', pass, fail))
if fail > 0 then os.exit(1) end
