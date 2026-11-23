-- A: compact Trust widget look, one layer stack for every control state.
--   Book is always the background.
--   Stop   : hourglass (steady) + red tint over the book.
--   Pause  : hourglass fades in and out; no tint.
--   Act    : crystal fades in and out; green halo while an action plays.
--   Start  : crystal steady; green halo while an action plays.
-- Layers cross-fade toward their targets instead of switching instantly.
-- Pure Lua (no Windower calls) so the host tests can drive it.
local Look = {}

-- Tunables (alpha is 0-255; times in seconds).
Look.tunables = {
    book_alpha = 230,        -- open book background, every state
    hourglass_alpha = 220,   -- hourglass at full strength (Stop, top of Pause pulse)
    crystal_alpha = 220,     -- crystal at full strength (Start, top of Act pulse)
    pulse_floor = 0.11,      -- lowest point of a pulse, as a share of full alpha (24/220 as before)
    pulse_period = 2.4,      -- seconds per fade-out-and-in cycle (unchanged from the old crystal)
    red_alpha = 70,          -- Stop tint strength
    red_rgb = { 170, 30, 30 },
    green_outer_alpha = 18,  -- action halo, unchanged from the old look
    green_inner_alpha = 24,
    fade = 0.25,             -- cross-fade between states; 0 = instant (//trust widget fade <ms>)
    tick = 0.05,             -- redraw interval while compact
}

-- Trust control_state -> look name. Retreat looks like Pause (actions off, still moving).
Look.state_names = { Parked = 'stop', Paused = 'pause', Retreat = 'pause', Act = 'act', Active = 'start' }

function Look.name_for(control_state, enabled)
    return Look.state_names[control_state] or (enabled and 'start' or 'pause')
end

-- Target strength (0..1) per layer and which layers pulse.
function Look.targets(name, acting)
    local running = name == 'act' or name == 'start'
    return {
        hourglass = (name == 'stop' or name == 'pause') and 1 or 0,
        crystal = running and 1 or 0,
        red = name == 'stop' and 1 or 0,
        green = (running and acting) and 1 or 0,
    }, {
        hourglass = name == 'pause',
        crystal = name == 'act',
    }
end

-- Move each current strength toward its target by dt/fade.
function Look.step(current, targets, dt, fade)
    local rate = (fade and fade > 0) and (dt / fade) or math.huge
    for key, target in pairs(targets) do
        local value = current[key] or target
        if value < target then value = math.min(target, value + rate)
        elseif value > target then value = math.max(target, value - rate) end
        current[key] = value
    end
    return current
end

-- Pulse multiplier: starts at the floor and rises, like the old crystal,
-- so a new pulse never pops in at full strength.
function Look.pulse(t, period, floor)
    local wave = (1 - math.cos(t * 2 * math.pi / period)) / 2
    return floor + (1 - floor) * wave
end

-- Final alphas for one frame.
function Look.alphas(current, pulsing, t, tun)
    tun = tun or Look.tunables
    local p = Look.pulse(t, tun.pulse_period, tun.pulse_floor)
    local function a(full, key)
        local s = current[key] or 0
        if pulsing[key] then s = s * p end
        return math.floor(full * s + 0.5)
    end
    return {
        book = tun.book_alpha,
        hourglass = a(tun.hourglass_alpha, 'hourglass'),
        crystal = a(tun.crystal_alpha, 'crystal'),
        red = a(tun.red_alpha, 'red'),
        green_outer = a(tun.green_outer_alpha, 'green'),
        green_inner = a(tun.green_inner_alpha, 'green'),
    }
end

return Look
