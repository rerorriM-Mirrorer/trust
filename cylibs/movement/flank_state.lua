---------------------------
-- Fork addition (Flank3): decisions and bookkeeping for CombatMode Flank, shared by the
-- flank condition, the flank run action, CombatMode's action listener and
-- `//trust flank status`. One instance per client.
--
-- Flank3 is event-driven instead of timed (replaces Flank2's 3 s check, 5 s settle,
-- 9 s pause and 3-moves-in-9-s rules):
--   - It watches the enemy's auto-attacks (action category 1) to learn whom it is
--     fighting. Until it auto-attacks an ally other than this character, Flank acts
--     like Auto.
--   - The flank spot is opposite that ally, at the Combat Distance from the enemy's
--     centre (not behind the enemy's facing, which swings whenever it turns).
--   - It moves only when a trigger happens and it is outside the rear cone (120
--     degrees, 60 each side of the spot): the first ally hit, or a hit on a different
--     ally. It also moves (to the spot) when outside the Distance band.
--   - When a party member announces Auto Tank Mode, hits on other allies are ignored:
--     only the enemy returning to the tank is a trigger.
--   - The enemy hitting this character, or this character tanking: act like Auto.
--   - A spot it cannot reach: after 1 s without progress it settles if it is within
--     the rear half (180 degrees); otherwise it tries once standing against the enemy
--     (edge to edge 0), then settles. Settled, it stays until it moves on its own
--     (stick), a new trigger needs a move, or the enemy gets well out of reach.
-- @class module
-- @name flank_state

local flank_state = {
    RearCone = 120,      -- degrees; a trigger only moves us when outside this cone
    RearHalf = 180,      -- degrees; an unreachable spot settles if within this half
    StuckTime = 1,       -- seconds without progress before giving up on a spot
    Progress = 0.1,      -- yalms of progress that count while running
    MaxRun = 9,          -- seconds; a run longer than this is treated as stuck (the queue's limit is 10)
    SelfMove = 1,        -- yalms; settled, moving this far on your own re-arms Flank
    FarMargin = 3,       -- yalms beyond Distance + 1 that re-arms a settled flanker
}

flank_state.clock = function() return os.clock() end

-- Per-enemy record of whom it auto-attacked: [mob_id] = { last, seq, tank, tank_seq }.
flank_state.enemies = {}
-- Characters that announced Auto Tank Mode on (lower-case name -> true).
flank_state.tanks = {}

function flank_state.reset()
    flank_state.enemies = {}
    flank_state.pos = {}
    flank_state.running = false
    flank_state.last_event = 'idle'
    flank_state.last_event_time = nil
    flank_state.moves = 0
    flank_state.settles = 0
end
flank_state.reset()

local function note(now, text)
    flank_state.last_event = text
    flank_state.last_event_time = now
end
flank_state.note = note

-------
-- Records an auto-attack round. `allies` maps entity id -> { name = ..., is_pet = bool }
-- for this character's party/alliance members (trusts included) and their pets.
-- Only the enemy's melee rounds (category 1) count; spells and TP moves never trigger.
function flank_state.on_auto_attack(enemy_id, target_id, allies)
    local ally = allies and allies[target_id]
    if enemy_id == nil or ally == nil then
        return
    end
    local e = flank_state.enemies[enemy_id]
    if e == nil then
        e = { seq = 0, tank_seq = 0 }
        flank_state.enemies[enemy_id] = e
    end
    if e.last ~= target_id then
        e.seq = e.seq + 1
        -- The enemy returning to the tank after hitting someone else is a tank trigger.
        if not ally.is_pet and flank_state.tanks[(ally.name or ''):lower()] then
            e.tank = target_id
            e.tank_seq = e.tank_seq + 1
        end
    end
    e.last = target_id
end

-------
-- Feeds one parsed action packet (WindowerEvents.Action). Only an enemy's melee round
-- (category 1) counts. `allies` is called lazily so ordinary packets stay cheap.
function flank_state.on_action(act, get_allies, is_enemy)
    if act == nil or act.category ~= 1 or not act.targets or not act.targets[1] then
        return
    end
    if not is_enemy(act.actor_id) then
        return
    end
    local count = 0
    for _ in pairs(flank_state.enemies) do count = count + 1 end
    if count > 100 then flank_state.enemies = {} end
    flank_state.on_auto_attack(act.actor_id, act.targets[1].id, get_allies())
end

-------
-- Quietly tells the other Trust clients whether this character has Auto Tank Mode on.
-- Sent when the mode changes, when Trust loads, and on Act.
function flank_state.announce_tank()
    local ok = pcall(function()
        if state == nil or state.AutoTankMode == nil or state.IpcMode == nil then return end
        if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then return end
        local player = windower.ffxi.get_player()
        if player == nil or player.name == nil then return end
        local CommandMessage = require('cylibs/messages/command_message')
        local on = state.AutoTankMode.value == 'Auto'
        IpcRelay.shared():send_message(CommandMessage.new('trust flank tank '..player.name..' '..(on and 'on' or 'off')..' --quiet'))
    end)
    return ok
end

function flank_state.forget_enemy(enemy_id)
    flank_state.enemies[enemy_id] = nil
end

function flank_state.set_tank(name, on)
    if type(name) ~= 'string' or name == '' then
        return
    end
    flank_state.tanks[name:lower()] = on and true or nil
end

local function angle_between(ax, ay, bx, by)
    local la = math.sqrt(ax * ax + ay * ay)
    local lb = math.sqrt(bx * bx + by * by)
    if la < 0.01 or lb < 0.01 then
        return 180
    end
    local c = (ax * bx + ay * by) / (la * lb)
    return math.deg(math.acos(math.max(-1, math.min(1, c))))
end

-------
-- Degrees between where `me` stands around the enemy and the spot opposite `ally`
-- (0 = exactly opposite the ally, 180 = on the ally's side).
function flank_state.rear_angle(mob, ally, me)
    return angle_between(mob.x - ally.x, mob.y - ally.y, me.x - mob.x, me.y - mob.y)
end

-------
-- The point opposite `ally` at `radius` from the enemy's centre.
function flank_state.spot(mob, ally, radius)
    local dx, dy = mob.x - ally.x, mob.y - ally.y
    local l = math.sqrt(dx * dx + dy * dy)
    if l < 0.01 then
        dx, dy, l = 1, 0, 1
    end
    return mob.x + dx / l * radius, mob.y + dy / l * radius
end

local function out_of_band(d, radius)
    if d > radius + 1 then
        return 'too far'
    end
    if radius >= 4 and d < radius - 1 then
        return 'too close'
    end
end

-------
-- Decides what Flank should do now, without changing any state (the run commits).
-- @tparam table ctx { mob, me, radius, now, i_am_tank, tank_present, get_ally(id) -> mob }
-- @treturn string 'hold' (act like Auto), 'move' (run to the spot), or 'stay'
-- @treturn table details: anchor, seq, x, y, reason
function flank_state.decide(ctx)
    local mob, me, radius = ctx.mob, ctx.me, ctx.radius
    if ctx.i_am_tank then
        return 'hold', { reason = 'tanking' }
    end
    local e = flank_state.enemies[mob.id] or {}
    if (me.index ~= nil and mob.target_index == me.index) or (e.last ~= nil and e.last == me.id) then
        return 'hold', { reason = 'enemy on me' }
    end
    local anchor_id, seq
    if ctx.tank_present then
        anchor_id, seq = e.tank, e.tank_seq
    else
        anchor_id, seq = e.last, e.seq
    end
    local ally = anchor_id and ctx.get_ally(anchor_id)
    if ally == nil then
        return 'hold', { reason = ctx.tank_present and 'waiting for the enemy to hit the tank' or 'waiting for the enemy to hit an ally' }
    end
    local x, y = flank_state.spot(mob, ally, radius)
    local details = { anchor = anchor_id, seq = seq, x = x, y = y }
    local p = flank_state.pos
    local same_mob = p.mob == mob.id
    local angle = flank_state.rear_angle(mob, ally, me)
    local dx, dy = me.x - mob.x, me.y - mob.y
    local d = math.sqrt(dx * dx + dy * dy)
    if flank_state.running then
        details.reason = 'moving'
        return 'stay', details
    end
    local trigger = not same_mob or p.seq ~= seq
    local outside = angle > flank_state.RearCone / 2
    if same_mob and p.settled then
        local sx, sy = me.x - p.settled_x, me.y - p.settled_y
        local moved = math.sqrt(sx * sx + sy * sy) >= flank_state.SelfMove
        local gone = d > radius + 1 + flank_state.FarMargin
        if not moved and not gone and not (trigger and outside) then
            details.reason = 'settled'
            return 'stay', details
        end
    end
    if trigger and outside then
        details.reason = 'enemy turned to another ally'
        return 'move', details
    end
    local band = out_of_band(d, radius)
    if band then
        details.reason = band
        return 'move', details
    end
    details.reason = 'in position'
    return 'stay', details
end

-------
-- A flank run started toward the spot for this enemy/trigger.
function flank_state.on_start(now, mob_id, seq, reason)
    flank_state.running = true
    flank_state.run_start = now
    flank_state.pos = { mob = mob_id, seq = seq }
    flank_state.moves = flank_state.moves + 1
    note(now, 'moving (' .. (reason or 'out of position') .. ')')
end

function flank_state.on_arrive(now)
    flank_state.running = false
    note(now, 'in position')
end

-------
-- Gave up on a spot: stay where we are until a trigger, our own movement, or the
-- enemy getting well out of reach.
function flank_state.on_settle(now, x, y, why)
    flank_state.running = false
    flank_state.pos.settled = true
    flank_state.pos.settled_x, flank_state.pos.settled_y = x, y
    flank_state.settles = flank_state.settles + 1
    note(now, 'settled: ' .. why)
end

function flank_state.on_stop(now, why)
    flank_state.running = false
    note(now, 'stopped: ' .. why)
end

function flank_state.status(now)
    local parts = { 'Flank: ' .. flank_state.last_event }
    if flank_state.last_event_time then
        parts[#parts + 1] = string.format('(%.0fs ago)', now - flank_state.last_event_time)
    end
    local names = {}
    for name in pairs(flank_state.tanks) do names[#names + 1] = name end
    table.sort(names)
    parts[#parts + 1] = '- tanks: ' .. (#names > 0 and table.concat(names, ', ') or 'none')
    parts[#parts + 1] = string.format('- %d moves, %d settles since load', flank_state.moves, flank_state.settles)
    return table.concat(parts, ' ')
end

return flank_state
