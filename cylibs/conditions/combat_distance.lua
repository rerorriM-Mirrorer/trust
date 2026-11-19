---------------------------
-- Fork addition: condition used by CombatMode (Auto, and Flank when it acts like Auto).
-- Satisfied when this character is out of the combat distance band for the target,
-- measured centre to centre or from body edges (see cylibs/util/combat_distance.lua).
-- Replaces the fixed DistanceCondition pair so the target's size is read each check.
-- Not offered in the gambit editor; CombatMode builds it in code.
-- @class module
-- @name CombatDistanceCondition

local combat_distance = require('cylibs/util/combat_distance')

local Condition = require('cylibs/conditions/condition')
local CombatDistanceCondition = setmetatable({}, { __index = Condition })
CombatDistanceCondition.__index = CombatDistanceCondition
CombatDistanceCondition.__type = "CombatDistanceCondition"
CombatDistanceCondition.__class = "CombatDistanceCondition"

-------
-- @tparam function get_distance Returns the configured Combat Distance
-- @tparam function get_edge Returns true to measure from body edges
function CombatDistanceCondition.new(get_distance, get_edge)
    local self = setmetatable(Condition.new(), CombatDistanceCondition)
    self.get_distance = get_distance
    self.get_edge = get_edge or function() return false end
    return self
end

function CombatDistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target == nil or target.distance == nil then
        return false
    end
    local distance = self.get_distance()
    local effective = combat_distance.effective(distance, target, self.get_edge())
    return combat_distance.out_of_band(math.sqrt(target.distance), distance, effective)
end

function CombatDistanceCondition:tostring()
    return string.format("Outside combat distance (%s yalms, %s)", tostring(self.get_distance()),
        self.get_edge() and 'body edges' or 'centres')
end

function CombatDistanceCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function CombatDistanceCondition:serialize()
    return "CombatDistanceCondition.new()"
end

function CombatDistanceCondition:__eq(otherItem)
    return otherItem.__class == CombatDistanceCondition.__class
end

return CombatDistanceCondition
