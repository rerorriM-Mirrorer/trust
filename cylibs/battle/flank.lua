---------------------------
-- Fork addition: gambit action for CombatMode Flank. Runs to the spot behind the enemy at
-- the Combat Distance, then turns to face it. Built in code by CombatMode only.
-- @class module
-- @name Flank

local flanking_util = require('cylibs/util/flanking_util')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local flank_state = require('cylibs/movement/flank_state')
local Renderer = require('cylibs/ui/views/render')

-------
-- Flank2: a RunToLocation that reports to flank_state. It records the start when the run
-- really begins (not when it is queued, so the queue's last-moment validate still sees
-- the move as allowed), faces the target on arrival, and gives up after ReachTimeout
-- seconds (a wall or obstruction), which pauses flanking for PauseTime seconds.
local FlankRunAction = setmetatable({}, { __index = RunToLocationAction })
FlankRunAction.__index = FlankRunAction

function FlankRunAction.new(x, y, z, distance, target_index)
    local self = setmetatable(RunToLocationAction.new(x, y, z, distance, 'Flank'), FlankRunAction)
    self.target_index = target_index
    return self
end

function FlankRunAction:perform()
    self.flank_start = flank_state.clock()
    flank_state.on_start(self.flank_start)
    RunToLocationAction.perform(self)
    if self:is_completed() then
        return
    end
    self.dispose_bag:add(Renderer.shared():onPrerender():addAction(function()
        if self:is_completed() or self:is_cancelled() then
            return
        end
        if flank_state.clock() - self.flank_start > flank_state.ReachTimeout then
            self.flank_timed_out = true
            self:cancel()
        end
    end), Renderer.shared():onPrerender())
end

function FlankRunAction:complete(success)
    if self:is_completed() then
        return
    end
    if self.flank_start ~= nil then
        local now = flank_state.clock()
        if success then
            flank_state.on_arrive(now)
            local mob = windower.ffxi.get_mob_by_index(self.target_index)
            if mob then player_util.face(mob) end
        elseif self.flank_timed_out then
            flank_state.on_fail(now, 'could not reach the back in ' .. flank_state.ReachTimeout .. 's')
        else
            flank_state.on_fail(now, 'run interrupted')
        end
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

-- How close to the flank spot counts as arrived. Small, because the condition only asks
-- for a new move once the character has drifted about 66 degrees around the mob.
Flank.ArriveDistance = 0.6

-------
-- @tparam function get_radius Returns the current Combat Distance (read live)
function Flank.new(get_radius)
    local self = setmetatable({}, Flank)
    self.get_radius = get_radius or function() return 3 end
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
    return 'Move behind target'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to move behind the target
function Flank:to_action(target_index, _)
    local mob = windower.ffxi.get_mob_by_index(target_index)
    if mob == nil then
        -- Gambiter assigns action.validate before checking for nil, so never return nil.
        return BlockAction.new(function() end, self.__class..'_flank')
    end
    local x, y = flanking_util.flank_point(mob, flanking_util.Back, self.get_radius())
    local action = FlankRunAction.new(x, y, mob.z, Flank.ArriveDistance, target_index)
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
