-- A: native FFXI autorun awareness for Trust's stick-movement takeover.
--
-- Background: when the stick sender fires, takeover.lua hands the character
-- back to manual control. The only native call it makes when Trust owns no
-- movement is windower.ffxi.follow() with no argument, which may also drop the
-- player's own autorun (not yet confirmed in game). FFXI lets a player steer slightly left/right while
-- autorunning, so the optional "keep autorun" setting skips that call when
-- the player is autorunning on their own.
--
-- Windower documents get_player().autorun as a table {x, y, z}: the direction
-- the character is auto-running in. (The first version of this module expected
-- a boolean, so in game it always read as "unavailable" and did nothing.) The
-- documentation does not say whether the field is absent or zeroed when no
-- autorun is active, so both count as "not autorunning". Whether a stopped
-- autorun can leave its last direction behind is not documented; Movement >
-- Status prints the raw numbers so that can be checked in game.
local M = {}

local function component(value)
    value = tonumber(value) or 0
    return math.abs(value) > 1e-6 and value or 0
end

-- Returns the autorun direction as x, y, z (all 0 when idle), or nil when there
-- is no player to ask.
function M.vector()
    local player = windower.ffxi.get_player()
    if not player then return nil end
    local autorun = player.autorun
    if type(autorun) ~= 'table' then return 0, 0, 0 end
    return component(autorun.x), component(autorun.y), component(autorun.z)
end

-- Returns true/false for native autorun, or nil when Windower has no player to
-- report on. Native /follow of another character also moves the player, but it
-- is not autorun the player asked to keep, so an active follow target reads false.
-- A plain boolean is still accepted in case a Windower build reports one.
function M.read()
    local player = windower.ffxi.get_player()
    if not player then return nil end
    if type(player.follow_index) == 'number' and player.follow_index > 0 then return false end
    if type(player.autorun) == 'boolean' then return player.autorun end
    local x, y, z = M.vector()
    return x ~= 0 or y ~= 0 or z ~= 0
end

-- True only when the setting is on, Trust is not itself running (a Trust run
-- action must still be released), and autorun is positively detected.
function M.should_preserve(enabled, owned)
    return enabled == true and not owned and M.read() == true
end

-- Reports autorun transitions the player causes, for the optional
-- "Autorun on/off messages" setting. options:
--   clock()    seconds, any monotonic-enough clock
--   enabled()  whether messages are wanted right now
--   read()     M.read, injectable for tests
--   owned()    true while Trust itself is running the character
--   notify(on) called with true/false for a confirmed transition
--   unavailable() called once per enabling when the state cannot be read
-- A change must be seen on two samples before it is reported, and the first
-- sample after enabling is only a baseline, so toggling the setting or
-- switching characters never announces the state that already existed.
function M.monitor(options)
    local self = { last = nil, pending = nil, count = 0, next = 0, warned = false }
    function self:reset()
        self.last, self.pending, self.count, self.warned = nil, nil, 0, false
    end
    function self:update()
        if not options.enabled() then
            if self.last ~= nil or self.warned then self:reset() end
            return
        end
        local now = options.clock()
        if now < self.next then return end
        self.next = now + 0.25
        -- Trust's own run actions also read as autorun; they are not news.
        if options.owned() then self.pending, self.count = nil, 0; return end
        local state = options.read()
        if state == nil then
            if not self.warned then self.warned = true; options.unavailable() end
            return
        end
        if self.last == nil then self.last = state; return end
        if state == self.last then self.pending, self.count = nil, 0; return end
        if self.pending ~= state then self.pending, self.count = state, 1
        else self.count = self.count + 1 end
        if self.count >= 2 then
            self.last, self.pending, self.count = state, nil, 0
            options.notify(state)
        end
    end
    return self
end

return M
