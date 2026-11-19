---------------------------
-- Fork addition: gambit action for CombatMode Flank. Runs to the spot opposite the ally the
-- enemy is fighting, at the Combat Distance, then turns to face it (Flank3). Built in code
-- by CombatMode only.
-- @class module
-- @name Flank

local FlankPositionCondition = require('cylibs/conditions/flank_position')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local flank_state = require('cylibs/movement/flank_state')
local Renderer = require('cylibs/ui/views/render')

-------
-- Flank3: a RunToLocation to the spot opposite the ally the enemy is fighting, reporting
-- to flank_state. It commits the trigger when the run really begins (not when queued),
-- faces the enemy when done, and handles a spot it cannot reach: after StuckTime
-- seconds without Progress it settles if within the rear half; otherwise it tries once
-- standing against the enemy (edge to edge 0), then settles wherever that ends.
-- No stuck-recovery detours here: Flank settles instead (see flank_state).
local FlankRunAction = setmetatable({}, { __index = RunToLocationAction })
FlankRunAction.__index = FlankRunAction

function FlankRunAction.new(x, y, z, distance, target_index, details)
    local self = setmetatable(RunToLocationAction.new(x, y, z, distance, 'Flank'), FlankRunAction)
    self.target_index = target_index
    self.details = details or {}
    return self
end

local function my_mob()
    local player = windower.ffxi.get_player()
    return player and windower.ffxi.get_mob_by_index(player.index)
end

function FlankRunAction:retarget(x, y)
    self.x, self.y = x, y
    self.vector_location = V{ x, y, self.z }
end

-- Called every frame while running: watch progress toward the spot.
function FlankRunAction:watch(now)
    local me = my_mob()
    if me == nil then
        return
    end
    local dx, dy = self.x - me.x, self.y - me.y
    local remaining = math.sqrt(dx * dx + dy * dy)
    if self.best == nil or remaining < self.best - flank_state.Progress then
        self.best, self.since = remaining, now
        return
    end
    if now - self.since < flank_state.StuckTime and now - self.flank_start < flank_state.MaxRun then
        return
    end
    -- No progress: settle if already in the rear half of the ally being fought.
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    local ally = self.details.anchor and windower.ffxi.get_mob_by_id(self.details.anchor)
    local in_rear_half = mob and ally and flank_state.rear_angle(mob, ally, me) <= flank_state.RearHalf / 2
    if in_rear_half or self.close_tried or mob == nil or ally == nil then
        self.settle_why = in_rear_half and 'spot blocked; in the rear half' or 'spot blocked'
        self:settle(me)
        return
    end
    -- One try standing against the enemy: edge to edge 0, opposite the same ally.
    self.close_tried = true
    local touching = math.max(0.5, (mob.model_size or 0) + (me.model_size or 0))
    local x, y = flank_state.spot(mob, ally, touching)
    self:retarget(x, y)
    -- The 1 s clock for this try starts now, from where we stand.
    local cx, cy = x - me.x, y - me.y
    self.best, self.since = math.sqrt(cx * cx + cy * cy), now
    flank_state.note(now, 'spot blocked; trying against the enemy')
end

function FlankRunAction:settle(me)
    self.settled = true
    windower.ffxi.run(false)
    self:complete(true)
end

function FlankRunAction:perform()
    local now = flank_state.clock()
    self.flank_start = now
    self.since = now
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    flank_state.on_start(now, mob and mob.id, self.details.seq, self.details.reason)
    RunToLocationAction.perform(self)
    if self:is_completed() then
        return
    end
    self.dispose_bag:add(Renderer.shared():onPrerender():addAction(function()
        if self:is_completed() or self:is_cancelled() then
            return
        end
        self:watch(flank_state.clock())
    end), Renderer.shared():onPrerender())
end

function FlankRunAction:complete(success)
    if self:is_completed() then
        return
    end
    if self.flank_start ~= nil then
        local now = flank_state.clock()
        local me = my_mob()
        if self.settled and me then
            flank_state.on_settle(now, me.x, me.y, self.settle_why or 'spot blocked')
        elseif success then
            flank_state.on_arrive(now)
        else
            flank_state.on_stop(now, 'run interrupted')
        end
        local mob = windower.ffxi.get_mob_by_index(self.target_index)
        if mob and (success or self.settled) then player_util.face(mob) end
    end
    RunToLocationAction.complete(self, success)
end

-- The queue can destroy a running action without completing it (queue cleared, Trust
-- paused): release the "moving" flag so flanking does not stall.
function FlankRunAction:destroy()
    if self.flank_start ~= nil and not self:is_completed() then
        flank_state.running = false
    end
    RunToLocationAction.destroy(self)
end

function FlankRunAction:gettype()
    return "flankrunaction"
end

local Flank = {}
Flank.__index = Flank
Flank.__type = "Flank"
Flank.__class = "Flank"

-- How close to the flank spot counts as arrived.
Flank.ArriveDistance = 0.6

-------
-- @tparam function get_radius Returns the current Combat Distance (read live)
function Flank.new(get_radius, get_edge)
    local self = setmetatable({}, Flank)
    self.get_radius = get_radius or function() return 3 end
    self.get_edge = get_edge or function() return false end
    self.conditions = L{}
    return self
end

function Flank:destroy()
end

function Flank:get_conditions()
    return self.conditions
end

function Flank:get_range()
    return 999
end

function Flank:get_name()
    return 'Flank'
end

function Flank:get_localized_name()
    return 'Flank'
end

function Flank:get_display_name()
    return 'Move opposite the ally the target is fighting'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to move behind the target
function Flank:to_action(target_index, _)
    local mob = windower.ffxi.get_mob_by_index(target_index)
    local decision, details = 'none', nil
    if mob ~= nil then
        decision, details = FlankPositionCondition.decide(target_index, self.get_radius(), self.get_edge())
    end
    if decision ~= 'move' then
        -- Gambiter assigns action.validate before checking for nil, so never return nil.
        return BlockAction.new(function() end, self.__class..'_flank')
    end
    local action = FlankRunAction.new(details.x, details.y, mob.z, Flank.ArriveDistance, target_index, details)
    action.identifier = self.__class..'_flank'
    return action
end

function Flank:serialize()
    return "Flank.new()"
end

function Flank:copy()
    return Flank.new(self.get_radius)
end

function Flank:__eq(otherItem)
    return otherItem.__type == self.__type
end

function Flank:is_valid()
    return true
end

Flank.FlankRunAction = FlankRunAction

return Flank
