-- A: Act is Trust fully running, but the main action queue only accepts actions
-- while a fight trigger is live. Following uses its own walk queue and is never
-- gated here. Pause, Stop and Retreat still disable the queue as before.
--
-- Triggers (any one opens the gate):
--   1. this character is engaged
--   2. the assist target is engaged
--   3. AutoEngageMode is Defensive or Aggressive and a party member is engaged,
--      or the threat tracker has fresh evidence against the party ('defense')
--   4. the last mob this client pulled successfully is alive and claimed
--      ('pull'), so a puller in any engage mode can fight what it pulled
--
-- Pulling starts fights, so pull actions (action.act_exempt, set by the Puller
-- role) always pass the gate, and a fight ending does not clear them (A,
-- 2026-11-23: in Act a puller could not start the first pull).
local M = {}

function M.exempt(action)
    return action ~= nil and action.act_exempt == true
end

-- Gate closing: drop the fight's leftovers, keep pull actions.
local function clear_fight(queue)
    local keep = false
    for queued in queue.queue:it() do
        if M.exempt(queued) then keep = true; break end
    end
    if not keep and not M.exempt(queue.current_action) then queue:clear(); return end
    if queue.current_action and not M.exempt(queue.current_action) then queue.current_action:cancel() end
    local kept = {}
    for queued in queue.queue:it() do
        if M.exempt(queued) then kept[#kept + 1] = queued else queued:destroy() end
    end
    queue.queue:clear()
    for _, queued in ipairs(kept) do queue.queue:push(queued) end
end

local function engaged(mob)
    return mob ~= nil and mob.status == 1
end

function M.trigger(party, queue)
    if engaged(windower.ffxi.get_player()) then return 'self' end
    local pulled_id = queue and queue.act_pulled_id
    if pulled_id then
        local mob = windower.ffxi.get_mob_by_id(pulled_id)
        if not mob or (mob.hpp or 0) <= 0 then queue.act_pulled_id = nil
        elseif (mob.claim_id or 0) ~= 0 then return 'pull' end
    end
    if not party then return nil end
    local assist = party.get_assist_target and party:get_assist_target()
    if assist and engaged(assist:get_mob()) then return 'assist' end
    local engage = state.AutoEngageMode and state.AutoEngageMode.value
    if engage == 'Defensive' or engage == 'Aggressive' then
        for member in party:get_party_members(true):it() do
            if engaged(member:get_mob()) then return 'party' end
        end
        local target = party.party_target
        if target and target.aggro_active and type(target.aggro_decision) == 'string'
                and target.aggro_decision:match('^defense:') then
            return 'threat'
        end
    end
    return nil
end

-- Returns true when the queue may accept `action` (optional). Closing the gate
-- clears actions that were queued for the fight that just ended.
function M.open(queue, party, action)
    if queue.control_state ~= 'Act' then
        queue.act_open = nil
        return true
    end
    local reason = M.trigger(party, queue)
    local is_open = reason ~= nil
    if queue.act_open and not is_open and queue.clear then
        if queue.queue then clear_fight(queue) else queue:clear() end
    end
    queue.act_open = is_open
    queue.act_reason = reason
    return is_open or M.exempt(action)
end

return M
