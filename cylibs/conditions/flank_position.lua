---------------------------
-- Fork addition: condition used by CombatMode's Flank setting.
--   FlankPositionCondition.new('move') is satisfied when this character should run to
--     its flank spot (Flank3: opposite the ally the enemy is auto-attacking; see
--     cylibs/movement/flank_state.lua for the triggers).
--   FlankPositionCondition.new('hold') is satisfied when Flank should behave like Auto
--     instead: this character is tanking, the enemy is on this character, or the enemy
--     hasn't auto-attacked an ally yet (or, with a tank announced, the tank).
-- Neither is satisfied while Flank stays put (in position, settled, or mid-run).
-- Not offered in the gambit editor; CombatMode builds it in code.
-- @class module
-- @name FlankPositionCondition

local flank_state = require('cylibs/movement/flank_state')

local Condition = require('cylibs/conditions/condition')
local FlankPositionCondition = setmetatable({}, { __index = Condition })
FlankPositionCondition.__index = FlankPositionCondition
FlankPositionCondition.__type = "FlankPositionCondition"
FlankPositionCondition.__class = "FlankPositionCondition"

-------
-- @tparam string mode 'move' or 'hold'
-- @tparam function get_radius Returns the current Combat Distance (read live so Config changes apply)
-- @tparam function get_edge Returns true when Combat Config measures from body edges
function FlankPositionCondition.new(mode, get_radius, get_edge)
    local self = setmetatable(Condition.new(), FlankPositionCondition)
    self.mode = mode or 'move'
    self.get_radius = get_radius or function() return 3 end
    self.get_edge = get_edge or function() return false end
    return self
end

local function is_tanking()
    return state.AutoTankMode ~= nil and state.AutoTankMode.value == 'Auto'
end

local alliance_slots = { 'p0', 'p1', 'p2', 'p3', 'p4', 'p5',
    'a10', 'a11', 'a12', 'a13', 'a14', 'a15', 'a20', 'a21', 'a22', 'a23', 'a24', 'a25' }

-------
-- Party/alliance members (alter egos included) and their pets, by entity id.
-- Shared with CombatMode's action listener.
function FlankPositionCondition.allies()
    local result = {}
    local party = windower.ffxi.get_party()
    if party == nil then
        return result
    end
    for _, slot in ipairs(alliance_slots) do
        local member = party[slot]
        local mob = member and member.mob
        if mob and mob.id then
            result[mob.id] = { name = member.name, is_pet = false }
            if mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(mob.pet_index)
                if pet and pet.id and (pet.hpp or 0) > 0 then
                    result[pet.id] = { name = member.name, is_pet = true }
                end
            end
        end
    end
    return result
end

-------
-- Whether an announced tank is in this party/alliance and loaded nearby.
function FlankPositionCondition.tank_present(allies)
    for _, ally in pairs(allies) do
        if not ally.is_pet and flank_state.tanks[(ally.name or ''):lower()] then
            return true
        end
    end
    return false
end

-------
-- Builds the context and asks flank_state what to do for this enemy.
function FlankPositionCondition.decide(target_index, radius, edge)
    local mob = windower.ffxi.get_mob_by_index(target_index)
    local player = windower.ffxi.get_player()
    local me = player and windower.ffxi.get_mob_by_index(player.index)
    if mob == nil or me == nil then
        return 'none'
    end
    -- With body edges, the spot and the distance band use the centre distance that
    -- leaves `radius` between the two bodies.
    radius = require('cylibs/util/combat_distance').effective(radius, mob, edge, me)
    local allies = FlankPositionCondition.allies()
    return flank_state.decide({
        mob = mob, me = me, radius = radius, now = flank_state.clock(),
        i_am_tank = is_tanking(),
        tank_present = FlankPositionCondition.tank_present(allies),
        get_ally = function(id)
            if allies[id] == nil then return nil end
            local ally = windower.ffxi.get_mob_by_id(id)
            if ally == nil or (ally.hpp or 0) <= 0 then return nil end
            return ally
        end,
    })
end

function FlankPositionCondition:is_satisfied(target_index)
    local decision = FlankPositionCondition.decide(target_index, self.get_radius(), self.get_edge())
    if self.mode == 'hold' then
        return decision == 'hold'
    end
    return decision == 'move'
end

function FlankPositionCondition:tostring()
    if self.mode == 'hold' then
        return "Flank: tanking, enemy on me, or no ally hit yet"
    end
    return "Flank: move opposite the ally the enemy is fighting"
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
