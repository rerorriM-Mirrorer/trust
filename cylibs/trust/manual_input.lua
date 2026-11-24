---------------------------
-- Fork addition (Manual1): A's own actions come first.
-- Every spell, ability, weapon skill, ranged attack or item use the player sends (typed,
-- xivcrossbar, the game menu with a subtarget, console, other addons) is seen here as the
-- outgoing game packet, with the target already chosen.
--   Trust idle            -> the packet goes through untouched; Trust waits HoldSeconds
--                            before its own next action.
--   Trust walking         -> the walk is cancelled and the packet goes through.
--   Trust busy with its own action -> the packet is held back and the action is queued at
--                            the front of Trust's queue (one manual slot: the newest press
--                            replaces an older waiting one; the rest of the queue stays).
--   The packet is Trust's own (matches the running action) -> untouched.
-- Decisions are pure functions (decide/describe) so host tests can run them.
-- @class module
-- @name manual_input

local res = require('resources')

local manual_input = {}

-- Tunables
manual_input.Enabled = true      -- on/off: //trust manual on|off (default on)
manual_input.HoldSeconds = 1.0   -- seconds Trust waits after your action goes straight through (default 1.0)

local CATEGORY = { [0x03] = 'spell', [0x09] = 'ability', [0x07] = 'weaponskill', [0x10] = 'ranged' }

local function quoted(prefix, name, target_id)
    return string.format('%s "%s" %d', prefix, name, target_id)
end

-------
-- Turns an outgoing packet into { kind, name, command, target_id, target_index, target_name },
-- or nil for packets that are not actions (engage, target change, ...).
-- @tparam number id packet id (0x01A or 0x037)
-- @tparam table p parsed packet fields
-- @tparam table lookups optional overrides for tests: { items = function(bag, slot) -> item_id }
function manual_input.describe(id, p, lookups)
    local spec
    if id == 0x01A then
        local kind = CATEGORY[p['Category']]
        if kind == nil then return nil end
        local param, target_id = p['Param'], p['Target']
        if target_id == nil then return nil end
        if kind == 'spell' then
            local r = res.spells[param]
            if r == nil then return nil end
            spec = { kind = kind, name = r.en, command = quoted(r.prefix or '/ma', r.en, target_id) }
        elseif kind == 'ability' then
            local r = res.job_abilities[param]
            if r == nil then return nil end
            spec = { kind = kind, name = r.en, command = quoted(r.prefix or '/ja', r.en, target_id) }
        elseif kind == 'weaponskill' then
            local r = res.weapon_skills[param]
            if r == nil then return nil end
            spec = { kind = kind, name = r.en, command = quoted('/ws', r.en, target_id) }
        else
            spec = { kind = kind, name = 'Ranged Attack', command = string.format('/ra %d', target_id) }
        end
        spec.target_id, spec.target_index = target_id, p['Target Index']
    elseif id == 0x037 then
        local bag, slot, target_id = p['Bag'], p['Slot'], p['Player']
        if bag == nil or slot == nil or target_id == nil then return nil end
        local item_id
        if lookups and lookups.items then
            item_id = lookups.items(bag, slot)
        else
            local item = windower.ffxi.get_items(bag, slot)
            item_id = item and item.id
        end
        local r = item_id and res.items[item_id]
        if r == nil then return nil end
        spec = { kind = 'item', name = r.en, command = quoted('/item', r.en, target_id),
                 target_id = target_id, target_index = p['Player Index'] }
    end
    return spec
end

-- Names of the abilities an action (or a sequence of them) will send.
local function action_names(action, out)
    if action == nil then return out end
    if action.queue and action.queue.it then
        for child in action.queue:it() do action_names(child, out) end
    end
    if action.current_action then action_names(action.current_action, out) end
    if action.spell_id and res.spells[action.spell_id] then out[res.spells[action.spell_id].en] = true end
    for _, field in ipairs({ 'job_ability_name', 'weapon_skill_name', 'blood_pact_name' }) do
        if type(action[field]) == 'string' then out[action[field]] = true end
    end
    if action.spec and action.spec.name then out[action.spec.name] = true end
    if action.__type == 'RangedAttack' then out['Ranged Attack'] = true end
    return out
end
manual_input.action_names = action_names

-------
-- @treturn string 'ignore' (Trust off, or not ours to judge), 'own' (Trust sent it),
--   'pass' (Trust idle: let it through and hold), 'pass_cancel' (cancel Trust's walk, let it
--   through), or 'queue' (hold the packet, queue it first).
function manual_input.decide(queue, spec, is_movement)
    if not manual_input.Enabled or spec == nil or queue == nil or queue.is_enabled == false then
        return 'ignore'
    end
    local current = queue.current_action
    if current == nil then return 'pass' end
    local names = action_names(current, {})
    if names[spec.name] then return 'own' end
    if is_movement and is_movement(current) then return 'pass_cancel' end
    -- A running action whose abilities we can't read: leave the packet alone rather than
    -- risk holding back Trust's own command.
    if next(names) == nil then return 'ignore' end
    return 'queue'
end

local function say(text)
    if addon_system_message then addon_system_message(text) else windower.add_to_chat(122, text) end
end

-------
-- Outgoing chunk handler. Returns true to block the packet.
function manual_input.on_outgoing(queue, id, data, blocked)
    if blocked or (id ~= 0x01A and id ~= 0x037) then return end
    local ok, spec = pcall(function()
        return manual_input.describe(id, require('packets').parse('outgoing', data))
    end)
    if not ok or spec == nil then return end
    local takeover = require('cylibs/movement/takeover')
    local decision = manual_input.decide(queue, spec, takeover.is_movement)
    if decision == 'pass' then
        queue:hold(manual_input.HoldSeconds)
    elseif decision == 'pass_cancel' then
        queue:hold(manual_input.HoldSeconds)
        queue.current_action:cancel()
    elseif decision == 'queue' then
        local target = spec.target_index and windower.ffxi.get_mob_by_index(spec.target_index)
        spec.target_name = target and target.name
        local ManualAction = require('cylibs/actions/manual')
        local replaced = queue:push_manual(ManualAction.new(spec))
        say('Trust: '..spec.name..(spec.target_name and (' -> '..spec.target_name) or '')
            ..(replaced and ' is next (replaces '..replaced..').' or ' is next.'))
        return true
    end
end

local registered

function manual_input.attach(queue)
    manual_input.detach()
    registered = windower.register_event('outgoing chunk', function(id, data, modified, injected, blocked)
        return manual_input.on_outgoing(queue, id, data, blocked)
    end)
end

function manual_input.detach()
    if registered then windower.unregister_event(registered); registered = nil end
end

-------
-- //trust manual [on|off|hold <seconds>|status]. Returns success, message.
function manual_input.command(option, value)
    option = type(option) == 'string' and option:lower() or option
    if option == 'on' then
        manual_input.Enabled = true
    elseif option == 'off' then
        manual_input.Enabled = false
    elseif option == 'hold' and tonumber(value) then
        manual_input.HoldSeconds = math.max(0, math.min(5, tonumber(value)))
    elseif option ~= nil and option ~= 'status' then
        return false, 'Usage: //trust manual [on|off|hold <seconds>|status]'
    end
    return true, string.format('Manual input first: %s, hold %.1f s',
        manual_input.Enabled and 'ON' or 'OFF', manual_input.HoldSeconds)
end

return manual_input
