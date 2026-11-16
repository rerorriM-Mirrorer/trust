---------------------------
-- Fork addition (Flank2): timing rules for CombatMode Flank, shared by the flank
-- condition, the flank run action and `//trust flank status`. One instance per client.
--   - Starts a new flank move at most every CheckInterval seconds.
--   - After arriving, settles for SettleTime seconds (only a target that has turned so we
--     are nearly in front of it, more than FrontAngle off, or a target that moved away
--     cuts the settle short).
--   - Gives up for PauseTime seconds when a move does not arrive within ReachTimeout
--     (wall or obstruction), or after BurstCount moves started within BurstWindow
--     (the back keeps swinging as hate changes). While paused, Flank acts like Auto.
-- @class module
-- @name flank_state

local flank_state = {
    CheckInterval = 3,
    SettleTime = 5,
    FrontAngle = 135,
    ReachTimeout = 3,
    PauseTime = 9,
    BurstCount = 3,
    BurstWindow = 9,
}

flank_state.clock = function() return os.clock() end

function flank_state.reset()
    flank_state.last_start = nil
    flank_state.settle_until = 0
    flank_state.pause_until = 0
    flank_state.starts = {}
    flank_state.running = false
    flank_state.last_event = 'idle'
    flank_state.last_event_time = nil
    flank_state.moves = 0
    flank_state.pauses = 0
end
flank_state.reset()

local function note(now, text)
    flank_state.last_event = text
    flank_state.last_event_time = now
end

function flank_state.is_paused(now)
    return now < flank_state.pause_until
end

-------
-- @tparam number now Clock
-- @tparam number angle Degrees off the back spot
-- @tparam boolean too_far Further than Distance + 1 from the target
-- @treturn boolean, string Whether a new flank move may start, and why not
function flank_state.can_start(now, angle, too_far)
    if flank_state.running then
        -- Safety net: a run that never reported back is treated as over.
        if flank_state.last_start ~= nil and now - flank_state.last_start > flank_state.ReachTimeout + 2 then
            flank_state.running = false
        else
            return false, 'moving'
        end
    end
    if flank_state.is_paused(now) then
        return false, 'paused'
    end
    if flank_state.last_start ~= nil and now - flank_state.last_start < flank_state.CheckInterval then
        return false, 'waiting'
    end
    if now < flank_state.settle_until and not too_far and angle <= flank_state.FrontAngle then
        return false, 'settling'
    end
    return true, 'ok'
end

function flank_state.on_start(now, reason)
    flank_state.last_start = now
    flank_state.running = true
    flank_state.moves = flank_state.moves + 1
    local kept = {}
    for _, t in ipairs(flank_state.starts) do
        if now - t < flank_state.BurstWindow then kept[#kept + 1] = t end
    end
    kept[#kept + 1] = now
    flank_state.starts = kept
    note(now, 'moving (' .. (reason or 'out of position') .. ')')
end

function flank_state.pause(now, why)
    flank_state.pause_until = now + flank_state.PauseTime
    flank_state.pauses = flank_state.pauses + 1
    flank_state.starts = {}
    note(now, 'paused ' .. flank_state.PauseTime .. 's: ' .. why)
end

function flank_state.on_arrive(now)
    flank_state.running = false
    flank_state.settle_until = now + flank_state.SettleTime
    if #flank_state.starts >= flank_state.BurstCount then
        flank_state.pause(now, flank_state.BurstCount .. ' moves in ' .. flank_state.BurstWindow .. 's')
    else
        note(now, 'arrived, settling ' .. flank_state.SettleTime .. 's')
    end
end

function flank_state.on_fail(now, why)
    flank_state.running = false
    flank_state.pause(now, why)
end

function flank_state.status(now)
    local parts = { 'Flank: ' .. flank_state.last_event }
    if flank_state.last_event_time then
        parts[#parts + 1] = string.format('(%.0fs ago)', now - flank_state.last_event_time)
    end
    if flank_state.is_paused(now) then
        parts[#parts + 1] = string.format('- acting like Auto for %.0fs more', flank_state.pause_until - now)
    elseif now < flank_state.settle_until then
        parts[#parts + 1] = string.format('- settling %.0fs more', flank_state.settle_until - now)
    end
    parts[#parts + 1] = string.format('- %d moves, %d pauses since load', flank_state.moves, flank_state.pauses)
    return table.concat(parts, ' ')
end

return flank_state
