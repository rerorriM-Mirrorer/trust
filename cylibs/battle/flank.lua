---------------------------
-- Fork addition: gambit action for CombatMode Flank. Runs to the spot behind the enemy at
-- the Combat Distance, then turns to face it. Built in code by CombatMode only.
-- @class module
-- @name Flank

local flanking_util = require('cylibs/util/flanking_util')
local RunToLocationAction = require('cylibs/actions/runtolocation')

local Flank = {}
Flank.__index = Flank
Flank.__type = "Flank"
Flank.__class = "Flank"

-- How close to the flank spot counts as arrived. Small, because the condition only asks
-- for a new move once the character has drifted about 50 degrees around the mob.
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
    return SequenceAction.new(L{
        RunToLocationAction.new(x, y, mob.z, Flank.ArriveDistance, 'Flank'),
        BlockAction.new(function()
            local current = windower.ffxi.get_mob_by_index(target_index)
            if current then player_util.face(current) end
        end),
    }, self.__class..'_flank')
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

return Flank
