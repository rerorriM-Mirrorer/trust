---------------------------
-- Fork addition: decision logic for the Tanker role (Auto Tank Mode helping party members).
-- Pure functions over plain mob tables so they can be tested without the game. The role
-- (cylibs/trust/roles/tanker.lua) gathers the game data and performs the chosen action.
--
-- A "loose" enemy is a live monster whose current target is a party member other than
-- the tank. FFXI does not expose enmity directly; the mob's target_index (who it is
-- attacking right now) is the clue Trust already uses in party_util.party_targeted.
-- @class module
-- @name tank_util

local tank_util = {}

-- Seconds to leave a mob alone after acting on it, so hate has time to move.
tank_util.RetryDelay = 6
-- Ranges in yalms, measured centre to centre (mob.distance), kept a little under the
-- game's limits so a cast is not refused as out of range.
tank_util.FlashRange = 19
tank_util.ProvokeRange = 16
tank_util.BanishRange = 19
-- Single-target order after the AoE check. Provoke (a WAR subjob ability) comes before the
-- Banishes because it builds far more hate; Banish II/Banish are the PLD-native fallbacks
-- when Flash is on cooldown.
-- Holy (PLD 55) is the last resort (user request, 2026-11-19).
tank_util.SingleOrder = { 'Flash', 'Provoke', 'Banish II', 'Banish', 'Holy' }
tank_util.Ranges = { Flash = 19, Provoke = 16, ['Banish II'] = 19, Banish = 19, Holy = 19 }
tank_util.BanishgaRange = 19
-- Banishga: loose mobs within ClusterRadius of the centre mob count as caught; any
-- uninvolved monster within SafetyRadius of the centre blocks the cast (it would be
-- pulled into the fight). SafetyRadius is deliberately larger than ClusterRadius.
tank_util.ClusterRadius = 7
tank_util.SafetyRadius = 11
tank_util.MinClusterSize = 2

local function dist2d(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function is_live_monster(mob)
    return mob ~= nil and mob.spawn_type == 16 and (mob.hpp or 0) > 0
        and (mob.status == 0 or mob.status == 1) and mob.valid_target ~= false
end

-------
-- @tparam table ctx Fields:
--   me          the tank's mob table (needs index, x, y)
--   mobs        list of mob tables (windower.ffxi.get_mob_array values)
--   party       map index -> { id, hpp } of everyone the tank protects: party members
--               (alter egos/trusts are party members) and their pets, the tank included
--   max_range   ignore mobs further than this from the tank
-- @treturn list Loose mobs, the one attacking the lowest-HP party member first, then nearest.
function tank_util.loose_enemies(ctx)
    local party_ids = {}
    for _, member in pairs(ctx.party) do party_ids[member.id] = true end
    local result = {}
    for _, mob in ipairs(ctx.mobs) do
        if is_live_monster(mob) and mob.target_index ~= nil and mob.target_index ~= ctx.me.index
                and ctx.party[mob.target_index] ~= nil
                and (mob.claim_id == nil or mob.claim_id == 0 or party_ids[mob.claim_id])
                and dist2d(mob, ctx.me) <= ctx.max_range then
            result[#result + 1] = mob
        end
    end
    table.sort(result, function(a, b)
        local ha, hb = ctx.party[a.target_index].hpp or 100, ctx.party[b.target_index].hpp or 100
        if ha ~= hb then return ha < hb end
        return dist2d(a, ctx.me) < dist2d(b, ctx.me)
    end)
    return result
end

-------
-- True when a monster would be dragged in by an AoE: alive and neither attacking the
-- party nor claimed by it.
local function is_uninvolved(mob, ctx, party_ids)
    if not is_live_monster(mob) then return false end
    if mob.target_index ~= nil and ctx.party[mob.target_index] ~= nil then return false end
    if mob.claim_id ~= nil and mob.claim_id ~= 0 and party_ids[mob.claim_id] then return false end
    return true
end

-------
-- Picks a Banishga centre: the loose mob (within range of the tank) that catches the most
-- loose mobs, with no uninvolved monster nearby. Returns centre, list_of_caught or nil.
function tank_util.aoe_center(ctx, loose)
    local party_ids = {}
    for _, member in pairs(ctx.party) do party_ids[member.id] = true end
    local best, best_caught
    for _, center in ipairs(loose) do
        if dist2d(center, ctx.me) <= tank_util.BanishgaRange then
            local caught = {}
            for _, other in ipairs(loose) do
                if dist2d(other, center) <= tank_util.ClusterRadius then caught[#caught + 1] = other end
            end
            if #caught >= tank_util.MinClusterSize and (best_caught == nil or #caught > #best_caught) then
                local safe = true
                for _, mob in ipairs(ctx.mobs) do
                    if is_uninvolved(mob, ctx, party_ids) and dist2d(mob, center) <= tank_util.SafetyRadius then
                        safe = false
                        break
                    end
                end
                if safe then best, best_caught = center, caught end
            end
        end
    end
    return best, best_caught
end

-------
-- Chooses what to do. `ready` maps 'Banishga'/'Flash'/'Provoke'/'Banish II'/'Banish'/'Holy' to true when that action
-- is known and ready; `recent` maps mob id -> time last acted on; `now` is the clock.
-- @treturn table|nil { name = action name, target = mob, marks = list of mobs to mark }
function tank_util.choose(ctx, ready, recent, now)
    local fresh = {}
    for _, mob in ipairs(tank_util.loose_enemies(ctx)) do
        local last = recent[mob.id]
        if last == nil or now - last >= tank_util.RetryDelay then fresh[#fresh + 1] = mob end
    end
    if #fresh == 0 then return nil end
    if ready.Banishga then
        local center, caught = tank_util.aoe_center(ctx, fresh)
        if center then return { name = 'Banishga', target = center, marks = caught } end
    end
    for _, mob in ipairs(fresh) do
        local d = dist2d(mob, ctx.me)
        for _, name in ipairs(tank_util.SingleOrder) do
            if ready[name] and d <= tank_util.Ranges[name] then
                return { name = name, target = mob, marks = { mob } }
            end
        end
    end
    return nil
end

return tank_util
