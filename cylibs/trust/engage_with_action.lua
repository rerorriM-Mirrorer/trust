---------------------------
-- Fork addition (EngageWith1): engage together with Trust's next action.
-- Just before the main queue starts an action whose target is a party-claimed monster
-- (a spell, ability, weapon skill, a run toward it, your own queued press), if this
-- character is not engaged and AutoEngageMode is Always, Defensive or Aggressive, Trust
-- sends the engage at the same moment instead of waiting for its separate Engage gambit.
-- It keeps trying with each action (at most once per MinInterval) until engaged.
-- The game accepts engage + action together (A tested, 2026-11-24).
-- Pulls are not included yet (pull logic review is its own batch).
-- @class module
-- @name engage_with_action

local engage_with_action = {}

-- Tunables
engage_with_action.Enabled = true     -- on/off: //trust engagewith on|off (default on)
engage_with_action.MinInterval = 1.0  -- seconds between engage attempts (default 1.0)

local MODES = { Always = true, Defensive = true, Aggressive = true }
local SKIP_TYPES = { engageaction = true, disengageaction = true }

local last_attempt = -math.huge

-- First monster target found in an action or the actions inside it.
local function target_index_of(action, depth)
    depth = depth or 0
    if action == nil or depth > 4 then return nil end
    if action.gettype and SKIP_TYPES[action:gettype()] then return false end
    if action.queue and action.queue.it then
        for child in action.queue:it() do
            local index = target_index_of(child, depth + 1)
            if index ~= nil then return index end
        end
    end
    return action.target_index
end
engage_with_action.target_index_of = target_index_of

-------
-- Pure decision. env = { player, mob(index), party_ids (set of ids), mode, now }.
-- @treturn number|nil the monster to engage
function engage_with_action.decide(action, env)
    if not engage_with_action.Enabled or not MODES[env.mode] then return nil end
    local player = env.player
    if player == nil or player.status ~= 0 then return nil end
    if env.now - last_attempt < engage_with_action.MinInterval then return nil end
    local index = target_index_of(action)
    if not index or index == player.index then return nil end
    local mob = env.mob(index)
    if mob == nil or not mob.valid_target or mob.spawn_type ~= 16 or (mob.hpp or 0) <= 0 then return nil end
    if not mob.claim_id or mob.claim_id == 0 or not env.party_ids[mob.claim_id] then return nil end
    return mob
end

function engage_with_action.reset()
    last_attempt = -math.huge
end

local function party_ids()
    local ids = {}
    local party = windower.ffxi.get_party() or {}
    for key, member in pairs(party) do
        if type(member) == 'table' and member.mob and member.mob.id then
            ids[member.mob.id] = true
            if member.mob.pet_index then
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index)
                if pet then ids[pet.id] = true end
            end
        end
    end
    return ids
end

-------
-- ActionQueue before_perform hook.
function engage_with_action.before_perform(action)
    local player = windower.ffxi.get_player()
    local mob = engage_with_action.decide(action, {
        player = player,
        mob = windower.ffxi.get_mob_by_index,
        party_ids = party_ids(),
        mode = state.AutoEngageMode and state.AutoEngageMode.value,
        now = os.clock(),
    })
    if mob == nil then return end
    last_attempt = os.clock()
    local packets = require('packets')
    packets.inject(packets.new('incoming', 0x058, {
        ['Player'] = player.id, ['Target'] = mob.id, ['Player Index'] = player.index,
    }))
    packets.inject(packets.new('outgoing', 0x01A, {
        ['Target'] = mob.id, ['Target Index'] = mob.index,
        ['Category'] = 0x02, ['Param'] = 0,
        ['X Offset'] = 0, ['Z Offset'] = 0, ['Y Offset'] = 0,
    }))
end

-------
-- //trust engagewith [on|off|status]. Returns success, message.
function engage_with_action.command(option)
    option = type(option) == 'string' and option:lower() or option
    if option == 'on' then
        engage_with_action.Enabled = true
    elseif option == 'off' then
        engage_with_action.Enabled = false
    elseif option ~= nil and option ~= 'status' then
        return false, 'Usage: //trust engagewith [on|off|status]'
    end
    return true, 'Engage with first action: '..(engage_with_action.Enabled and 'ON' or 'OFF')
end

return engage_with_action
