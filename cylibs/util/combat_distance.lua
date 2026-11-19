---------------------------
-- Fork addition: combat positioning distances, measured either centre to centre (the
-- original behaviour) or from body edges (Combat Config "Measure from body edges").
-- Edge to edge adds both model sizes (Windower's model_size, a rough body radius) to
-- the configured Distance, so the same setting leaves the same gap on a crab and on a
-- dragon. Used by Auto and Flank, which compare and run on centre distances; Mirror
-- (distance from the assist target) is unchanged.
-- @class module
-- @name combat_distance

local combat_distance = {}

local function my_mob()
    local player = windower.ffxi.get_player()
    return player and windower.ffxi.get_mob_by_index(player.index)
end

-------
-- Both bodies' sizes added together (0 for a missing entity).
function combat_distance.sizes(target, me)
    me = me or my_mob()
    return ((target and target.model_size) or 0) + ((me and me.model_size) or 0)
end

-------
-- The centre-to-centre distance that keeps `distance` between this character and
-- `target` (edge to edge when `edge`, otherwise unchanged).
function combat_distance.effective(distance, target, edge, me)
    if not edge then
        return distance
    end
    return distance + combat_distance.sizes(target, me)
end

-------
-- Auto's band: under 4 yalms only "too far" moves; from 4 up, more than 1 yalm too far
-- or too close. `distance` is the configured value (which band applies); `effective`
-- is what it means for this target in centre distance.
function combat_distance.out_of_band(d, distance, effective)
    if distance < 4 then
        return d > effective
    end
    return d > effective + 1 or d < effective - 1
end

return combat_distance
