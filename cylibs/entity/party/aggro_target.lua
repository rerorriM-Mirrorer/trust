-- Defensive target evidence is local, bounded and keyed by entity ID, never name/index alone.
local AggroTarget = {}
AggroTarget.__index = AggroTarget

function AggroTarget.new(party, tracker)
    return setmetatable({ party = party, tracker = tracker, evidence = {}, ttl = 8, range = 30 }, AggroTarget)
end

function AggroTarget:reset()
    self.evidence = {}
    self.selected_id = nil
end

function AggroTarget:members()
    local ids, claim_ids = {}, {}
    for member in self.party:get_party_members(true):it() do
        local mob = member:get_mob()
        if mob then claim_ids[mob.id] = true end
        if mob and mob.hpp and mob.hpp > 0 then ids[mob.id] = true end
    end
    return ids, claim_ids
end

function AggroTarget:valid(mob, members)
    if not mob or mob.spawn_type ~= 16 or not mob.valid_target or not mob.hpp or mob.hpp <= 0
            or mob.status == 2 or mob.status == 3 or not mob.distance or mob.distance > self.range * self.range then
        return false, 'invalid'
    end
    -- Unknown nonzero claim owners are foreign too; failure to resolve them is not permission.
    local allowed = mob.claim_id == 0 or (mob.claim_id ~= nil and members[mob.claim_id] == true)
    if allowed then return true end
    return false, 'foreign-claim'
end

-- Category meanings follow cylibs/conditions/action.lua and Cylibs-Windower-Events.lua.
local categories = { [1]=true, [2]=true, [3]=true, [4]=true, [7]=true, [8]=true, [11]=true, [12]=true }
function AggroTarget:observe(action, now)
    if not action or not categories[action.category] then return end
    local members, claim_ids = self:members()
    local mob = windower.ffxi.get_mob_by_id(action.actor_id)
    if not self:valid(mob, claim_ids) then return end
    for _, target in pairs(action.targets or {}) do
        if members[target.id] then
            self.evidence[mob.id] = { time = now, index = mob.index, victim = target.id }
            self.tracker:add_mob(mob.id)
            return
        end
    end
end

function AggroTarget:select(assist_index, now)
    local members, claim_ids = self:members()
    for id, evidence in pairs(self.evidence) do
        if now - evidence.time > self.ttl or not members[evidence.victim] then self.evidence[id] = nil end
    end
    self.rejected = nil
    local assist = assist_index and windower.ffxi.get_mob_by_index(assist_index)
    if self:valid(assist, claim_ids) then
        self.selected_id = nil
        return assist.index, 'assist'
    end
    -- A tracker prune must not discard still-fresh observable threat memory.
    for id, evidence in pairs(self.evidence) do
        local mob = windower.ffxi.get_mob_by_id(id)
        if mob and mob.index == evidence.index and self:valid(mob, claim_ids) then self.tracker:add_mob(id) end
    end
    local candidates = {}
    self.rejected = { invalid = 0, foreign = 0, unrelated = 0 }
    -- Existing tracker includes combat-event actors and party-selected entities. Merely being
    -- tracked, claimed, nearby or engaged never proves that an enemy threatens this party.
    for monster in self.tracker:get_targets():it() do
        local mob = monster:get_mob()
        local valid, rejection = self:valid(mob, claim_ids)
        if valid then
            local victim = mob.target_index and windower.ffxi.get_mob_by_index(mob.target_index)
            local evidence = self.evidence[mob.id]
            if (mob.status == 1 and victim and members[victim.id]) or
                    (evidence and evidence.index == mob.index and now - evidence.time <= self.ttl and members[evidence.victim]) then
                candidates[mob.id] = mob
            else
                self.rejected.unrelated = self.rejected.unrelated + 1
            end
        else
            local key = rejection == 'foreign-claim' and 'foreign' or 'invalid'
            self.rejected[key] = self.rejected[key] + 1
        end
    end
    local selected = candidates[self.selected_id]
    if not selected then
        for id, mob in pairs(candidates) do
            if not selected or id < selected.id then selected = mob end
        end
    end
    self.selected_id = selected and selected.id
    return selected and selected.index, selected and 'defense' or 'no-threat'
end

return AggroTarget
