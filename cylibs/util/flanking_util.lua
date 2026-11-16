---------------------------
-- Utility functions for getting vector positions around a target
-- @class module
-- @name FlankingUtil

_libs = _libs or {}

require("math")
require('vectors')

local flanking_util = {}

_raw = _raw or {}

_libs.flanking_util = flanking_util

flanking_util.Back = "back"
flanking_util.Left = "left"
flanking_util.Right = "right"

-------
-- Gets a relative location around a target, given a string back/left/right gets a point at
-- the given distance and angle. Note this does not check who the mob is targeting, so
-- there is a potential edge case if someone were to attempt to move to the back of a mob that
-- is targeting them and will turn to them
-- @tparam number mob_id ID of a mob to retrieve locations for
-- @tparam string angle One of "back", "left", "right", to determine which relative location to return
-- @tparam number distance Distance from the mob to calculate points for
-- @treturn vector A vector location relative to the mob at a given distance or nil
function flanking_util.get_relative_location_for_target(mob_id, angle, distance)
    -- get mob, should have location and facing
    local mob = windower.ffxi.get_mob_by_id(mob_id)
    if not mob then return nil end -- If we can't get the mob, return nil
    -- if not not battle_util.is_valid_target(mob_id) then return nil end -- If not valid target, ignore, may not need

    -- Get the unit vector for the mob, due to a FFXI angle quirk, use negative angles
    local u = V{math.cos(-mob.facing), math.sin(-mob.facing), mob.z}

    -- Get a distance relative to mob size
    local my_size = windower.ffxi.get_mob_by_target('me').model_size or 0
    local d = mob.model_size + my_size + distance

    local locations = {
        back = V{ mob.x - d * u[1], mob.y - d * u[2], mob.z },
        left = V{ mob.x - d * u[2], mob.y + d * u[1], mob.z },
        right = V{ mob.x + d * u[2], mob.y - d * u[1], mob.z },
    }

    -- since we calculated them all, can just return, and it'll return nil in other cases, easy!
    return locations[angle]

end

-------
-- Fork addition (Flank combat mode). The helpers below take mob tables instead of ids so
-- they can be tested without the game, and they measure centre-to-centre distance like
-- CombatMode Auto does (mob.distance), so the Combat > Config "Distance" slider means the
-- same thing in Auto and Flank. The upstream function above adds model sizes on top,
-- which would put a flanker further out than the same Distance in Auto.

-- How far (degrees) a flanker may drift around the mob before it repositions. A wide
-- margin keeps characters from shuffling every time the mob turns a little.
flanking_util.ReturnAngle = 50

-------
-- Returns the mob's facing direction as a unit vector {x, y}. FFXI's facing angle runs
-- the opposite way to math.atan2 (player_util.face turns to -atan2), hence -facing.
function flanking_util.forward(mob)
    return math.cos(-mob.facing), math.sin(-mob.facing)
end

-------
-- Returns the x, y of the spot `radius` yalms from the mob's centre on the given side
-- ("back", "left" or "right"; anything else means back).
function flanking_util.flank_point(mob, side, radius)
    local ux, uy = flanking_util.forward(mob)
    if side == flanking_util.Left then
        return mob.x - radius * uy, mob.y + radius * ux
    elseif side == flanking_util.Right then
        return mob.x + radius * uy, mob.y - radius * ux
    end
    return mob.x - radius * ux, mob.y - radius * uy
end

-------
-- Returns the angle in degrees (0-180) between where `me` stands around the mob and
-- where the flank spot is.
function flanking_util.angle_off(mob, me, side)
    local fx, fy = flanking_util.flank_point(mob, side, 1)
    local ax, ay = fx - mob.x, fy - mob.y
    local bx, by = me.x - mob.x, me.y - mob.y
    local blen = math.sqrt(bx * bx + by * by)
    if blen < 0.01 then
        return 180 -- standing inside the mob's centre: treat as fully out of position
    end
    local cos = (ax * bx + ay * by) / blen
    cos = math.max(-1, math.min(1, cos))
    return math.deg(math.acos(cos))
end

-------
-- Decides whether a flanker should move. Returns true plus a short reason when it should.
-- `radius` is the target distance from the mob's centre (the Combat Distance setting).
-- It does not move while the mob is targeting `me`: the mob would turn to face us and
-- "behind" would keep moving, so CombatMode handles that case like Auto instead.
function flanking_util.flank_needed(mob, me, side, radius)
    if mob == nil or me == nil or mob.facing == nil then
        return false, 'no mob'
    end
    if me.index ~= nil and mob.target_index == me.index then
        return false, 'mob targeting me'
    end
    local dx, dy = me.x - mob.x, me.y - mob.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > radius + 1 then
        return true, 'too far'
    end
    if flanking_util.angle_off(mob, me, side) > flanking_util.ReturnAngle then
        return true, 'off angle'
    end
    return false, 'in position'
end

-------
-- Gets the closest point to a target within a given radius not overlapped by a given radius from
-- a second target
-- @tparam number target_1_id ID of the first target, which will be the center of the inclusion area
-- @tparam number distance_1 Radius of the first target's inclusion range
-- @tparam number target_2_id ID of the second target, which will be the center of the exclusion area
-- @tparam number distance_2 Radius of the second target's exclusion range
-- @treturn vector An (x,y,z) vector location that is within distance_1 of target_1 and not within distance_2 of target_2
function flanking_util.get_closest_point_relative_to_two_targets(target_1_id, distance_1, target_2_id, distance_2)
    notice("Not yet implemented function")
end



return flanking_util
