-- A: BRD song note + re-sing timer inside the compact Trust widget.
-- The timer counts to Trust's re-sing point (soonest song expiry minus the
-- singer's expiring_duration), shown like the game's status icon timers:
-- 59s..0s under a minute, otherwise whole minutes (Xm, rounded down).
-- Pure Lua so the host tests can drive it.
local Song = {}

Song.tunables = {
    x = 4,            -- px from the widget's left edge to the note icon
    y = 13,           -- px from the widget's top (party count sits at 0)
    icon = 10,        -- note icon size, px
    gap = 1,          -- px between note and timer text
    lit_alpha = 255,  -- note while Trust is singing
    dim_alpha = 110,  -- note while idle (the old Bard widget used 100)
    poll = 0.5,       -- seconds between song reads
}

function Song.format(remaining)
    if remaining == nil then return '' end
    if remaining < 60 then
        return string.format('%ds', math.max(0, math.floor(remaining)))
    end
    return string.format('%dm', math.floor(remaining / 60))
end

-- songs: list of expire times (os.time seconds); returns seconds to re-sing or nil.
function Song.remaining(expire_times, expiring_duration, now)
    local soonest
    for _, t in ipairs(expire_times) do
        if soonest == nil or t < soonest then soonest = t end
    end
    if soonest == nil then return nil end
    return soonest - (expiring_duration or 0) - now
end

return Song
