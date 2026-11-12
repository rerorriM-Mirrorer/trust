-- Session-only control state. Tactical modes and saved follow preferences stay intact.
local Control = {}

function Control.set(queue, enabled, trust, mode, manual)
    assert(mode == 'Active' or mode == 'Paused' or mode == 'Retreat' or mode == 'Parked', 'Invalid control state')
    -- Temporary operations restore state only if no later user control superseded it.
    queue.control_revision = (queue.control_revision or 0) + 1
    if queue.parked and (mode=='Active' or (mode=='Paused' and not manual)) then
        queue.parked=false
        queue.movement_suspended=true
    end
    local follower = trust and trust:role_with_type('follower')
    local changed = queue.control_state ~= mode
    local was_enabled = enabled:getValue()
    -- Set gates before relay/cancellation callbacks can requeue movement.
    queue.control_state = mode
    if follower then
        if mode == 'Active' or mode == 'Retreat' then follower.recovery_paused = false end
        if manual then follower.manual_pause = true
        elseif mode == 'Active' and not queue.movement_suspended then follower.manual_pause = false end
    end
    if was_enabled ~= (mode == 'Active') then
        enabled:setValue(mode == 'Active')
    elseif follower and (changed or manual) then
        -- Paused -> Retreat and already-paused manual takeover have no relay edge.
        follower:stop_following()
        if not manual and not queue.movement_suspended then follower:start_following() end
    end
    return changed
end

return Control
