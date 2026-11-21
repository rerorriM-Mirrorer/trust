-- A: Act is Trust fully running, but the main action queue only accepts actions
-- while a fight trigger is live. Following uses its own walk queue and is never
-- gated here. Pause, Stop and Retreat still disable the queue as before.
--
-- Triggers (any one opens the gate):
--   1. this character is engaged
--   2. the assist target is engaged
--   3. AutoEngageMode is Defensive or Aggressive and a party member is engaged,
--      or the threat tracker has fresh evidence against the party ('defense')
local M = {}

local function engaged(mob)
    return mob ~= nil and mob.status == 1
end

function M.trigger(party)
    if engaged(windower.ffxi.get_player()) then return 'self' end
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

-- Returns true when the queue may accept a new action. Closing the gate clears
-- actions that were queued for the fight that just ended.
function M.open(queue, party)
    if queue.control_state ~= 'Act' then
        queue.act_open = nil
        return true
    end
    local reason = M.trigger(party)
    local is_open = reason ~= nil
    if queue.act_open and not is_open and queue.clear then queue:clear() end
    queue.act_open = is_open
    queue.act_reason = reason
    return is_open
end

return M
