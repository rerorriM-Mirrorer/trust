---------------------------
-- Fork addition: condition used by CombatMode's Flank setting.
--   FlankPositionCondition.new('move') is satisfied when this character should run to
--     its flank spot behind the enemy (out of position, mob not targeting us, not tanking).
--   FlankPositionCondition.new('hold') is satisfied when Flank should behave like Auto
--     instead: the mob is targeting us (it would turn and "behind" would keep moving) or
--     AutoTankMode is Auto (a tank stays in front).
-- Not offered in the gambit editor; CombatMode builds it in code.
-- @class module
-- @name FlankPositionCondition

local flanking_util = require('cylibs/util/flanking_util')

local Condition = require('cylibs/conditions/condition')
local FlankPositionCondition = setmetatable({}, { __index = Condition })
FlankPositionCondition.__index = FlankPositionCondition
FlankPositionCondition.__type = "FlankPositionCondition"
FlankPositionCondition.__class = "FlankPositionCondition"

-------
-- @tparam string mode 'move' or 'hold'
-- @tparam function get_radius Returns the current Combat Distance (read live so Config changes apply)
function FlankPositionCondition.new(mode, get_radius)
    local self = setmetatable(Condition.new(), FlankPositionCondition)
    self.mode = mode or 'move'
    self.get_radius = get_radius or function() return 3 end
    return self
end

local function is_tanking()
    return state.AutoTankMode ~= nil and state.AutoTankMode.value == 'Auto'
end

function FlankPositionCondition:is_satisfied(target_index)
    local mob = windower.ffxi.get_mob_by_index(target_index)
    local player = windower.ffxi.get_player()
    local me = player and windower.ffxi.get_mob_by_index(player.index)
    if mob == nil or me == nil then
        return false
    end
    local targeting_me = mob.target_index ~= nil and mob.target_index == me.index
    if self.mode == 'hold' then
        return is_tanking() or targeting_me
    end
    if is_tanking() then
        return false
    end
    local needed, _ = flanking_util.flank_needed(mob, me, flanking_util.Back, self.get_radius())
    return needed
end

function FlankPositionCondition:tostring()
    if self.mode == 'hold' then
        return "Flank: tanking or mob targeting me"
    end
    return "Flank: out of position behind mob"
end

function FlankPositionCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function FlankPositionCondition:serialize()
    return "FlankPositionCondition.new(" .. string.format("%q", self.mode) .. ")"
end

function FlankPositionCondition:__eq(otherItem)
    return otherItem.__class == FlankPositionCondition.__class and otherItem.mode == self.mode
end

return FlankPositionCondition
