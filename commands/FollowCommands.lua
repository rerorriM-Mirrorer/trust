local CommandMessage = require('cylibs/messages/command_message')
local command_feedback = require('cylibs/util/command_feedback')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local FollowTrustCommands = setmetatable({}, {__index = TrustCommands })
FollowTrustCommands.__index = FollowTrustCommands
FollowTrustCommands.__class = "FollowTrustCommands"

function FollowTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), FollowTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    -- A: Follow receipts are session-only; saved follow settings do not change.
    self.follow_request_sequence = 0
    self.pending_follow = nil
    self.follow_receipt_timer = windower.register_event('time change', function()
        self:check_follow_receipts()
    end)

    local party_member_names = trust:get_party():get_party_members(true):map(function(p) return p:get_name() end)

    self:add_command('default', self.handle_follow_party_member, 'Follow a player; bare //trust follow takes over travel', L{ PickerConfigItem.new('party_member_name', party_member_names[1], party_member_names, nil, "Party Member Name"), })

    trust:get_party():on_party_members_changed():addAction(function(party_members)
        local party_member_names = party_members:map(function(p) return p:get_name() end)

        self:add_command('default', self.handle_follow_party_member, 'Follow a player; bare //trust follow takes over travel', L{ PickerConfigItem.new('party_member_name', party_member_names[1], party_member_names, nil, "Party Member Name") })
    end)

    self:add_command('me', self.handle_follow_me, 'Make all players follow me')
    self:add_command('receipt', self.handle_follow_receipt, 'Internal follow confirmation request')
    self:add_command('ack', self.handle_follow_ack, 'Internal follow confirmation reply')
    self:add_command('start', self.handle_start, 'Resume following')
    self:add_command('stopall', self.handle_stop_all, 'Pause following for all players')
    self:add_command('stop', self.handle_stop, 'Pause following')
    self:add_command('clear', self.handle_clear, 'Clear the follow target')
    self:add_command('distance', self.handle_set_follow_distance, 'Set the follow distance', L{ ConfigItem.new('distance', 0, 50, 1, function(value) return value.." yalms" end, "Target Distance"), })

    return self
end

function FollowTrustCommands:get_command_name()
    return 'follow'
end

function FollowTrustCommands:get_follower()
    return self.trust:role_with_type("follower")
end

-- Bare //trust follow takes over local travel, then gathers the others.
function FollowTrustCommands:handle_travel()
    if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then
        return false, 'IpcMode must be All or Send to request travel following'
    end
    handle_pause(true)
    -- Explicit release is also required when Trust was already paused.
    windower.ffxi.follow()
    windower.ffxi.run(false)
    local ok,message = command_feedback.run(true, function()
        return self:handle_follow_me(true)
    end)
    if ok == false then return false,message end
    return true
end

-- Human party clients are eligible for receipts; summoned alter egos are not
-- Windower IPC clients. Keep the existing broadcast for other participating
-- clients and for backward compatibility with older Trust installations.
function FollowTrustCommands:get_receipt_recipients()
    local recipients, seen = {}, {}
    local party = windower.ffxi.get_party()
    local self_name = windower.ffxi.get_player().name:lower()
    for i = 0, 5 do
        local member = party and party['p'..i]
        local name = member and member.name
        if type(name) == 'string' and name:match('^%a+$')
                and name:lower() ~= self_name and not seen[name:lower()]
                and not (member.mob and member.mob.is_npc) then
            seen[name:lower()] = true
            recipients[#recipients + 1] = name
        end
    end
    table.sort(recipients)
    return recipients
end

function FollowTrustCommands:send_follow_receipt(recipient, pending)
    IpcRelay.shared():send_message(CommandMessage.new(
        'trust follow receipt '..pending.leader..' '..pending.request_id..' --quiet', recipient))
end

-- Confirm recipient acceptance, not physical movement: an engaged character
-- may accept its leader while staying in battle. Unanswered requests are never
-- counted as successful.
function FollowTrustCommands:finish_follow_receipts()
    local pending = self.pending_follow
    if not pending then return end
    self.pending_follow = nil
    local accepted, rejected, missing = {}, {}, {}
    for name, result in pairs(pending.targets) do
        if result == 'accepted' then
            accepted[#accepted + 1] = name
        elseif result == 'failed' then
            rejected[#rejected + 1] = name
        else
            missing[#missing + 1] = name
        end
    end
    table.sort(accepted)
    table.sort(rejected)
    table.sort(missing)
    local detail = #accepted..'/'..pending.total
    if #rejected > 0 then detail = detail..' - rejected: '..table.concat(rejected, ', ') end
    if #missing > 0 then detail = detail..' - unconfirmed: '..table.concat(missing, ', ') end
    require('chat')
    windower.add_to_chat(0, '[Trust] ':color(200)..'Following: ':color(167)..detail:color(0))
end

function FollowTrustCommands:check_follow_receipts()
    if self.action_queue.control_state == 'Retreat' then self.pending_follow = nil; return end
    local pending = self.pending_follow
    if not pending then return end
    local elapsed = os.time() - pending.started_at
    if elapsed >= 2 and not pending.retried then
        pending.retried = true
        for name, result in pairs(pending.targets) do
            if result == 'pending' then self:send_follow_receipt(name, pending) end
        end
    end
    if elapsed >= 5 then self:finish_follow_receipts() end
end

-- // trust follow me
function FollowTrustCommands:handle_follow_me(response_only)
    if not L{'All', 'Send'}:contains(state.IpcMode.value) then
        return false, 'IpcMode must be set to All or Send to use this command'
    end
    self:get_follower():set_follow_target(nil)
    local leader = windower.ffxi.get_player().name
    local quiet_flag = command_feedback.is_quiet() and ' --quiet' or ''
    -- The original broadcast remains effective even with an older recipient.
    IpcRelay.shared():send_message(CommandMessage.new('trust follow '..leader..quiet_flag))

    -- Only All can receive the confirmations. Send retains ordinary following
    -- and reports that the remote state cannot be verified.
    if state.IpcMode.value ~= 'All' then
        self.pending_follow = nil
        if response_only == true then
            require('chat')
            windower.add_to_chat(0, '[Trust] ':color(200)..'Following: ':color(167)
                ..'unconfirmed (IpcMode Send)':color(0))
            return true
        end
        return true, 'Follow request sent; confirmations require IpcMode All'
    end
    local recipients = self:get_receipt_recipients()
    if #recipients == 0 then
        self.pending_follow = nil
        if response_only == true then
            require('chat')
            windower.add_to_chat(0, '[Trust] ':color(200)..'Following: ':color(167)..'0/0':color(0))
            return true
        end
        return true, 'Follow request sent; no other player clients to confirm'
    end
    self.follow_request_sequence = self.follow_request_sequence + 1
    local pending = {
        leader = leader,
        request_id = tostring(os.time())..tostring(self.follow_request_sequence),
        started_at = os.time(),
        retried = false,
        targets = {},
        total = #recipients,
    }
    self.pending_follow = pending
    for _, name in ipairs(recipients) do pending.targets[name] = 'pending' end
    for _, name in ipairs(recipients) do self:send_follow_receipt(name, pending) end
    return true, 'Follow requested; awaiting '..#recipients..' confirmation(s)'
end

-- The targeted receipt request retries the named follow action idempotently,
-- so it can recover a dropped initial broadcast without restarting formation.
function FollowTrustCommands:handle_follow_receipt(_, leader, request_id)
    if type(leader) ~= 'string' or not leader:match('^%a+$')
            or type(request_id) ~= 'string' or not request_id:match('^%d+$') then
        return false, 'Invalid follow receipt request'
    end
    local success, message = self:handle_follow_party_member(leader)
    if L{'All', 'Send'}:contains(state.IpcMode.value) then
        local response = success == false and 'failed' or 'accepted'
        local member = windower.ffxi.get_player().name
        IpcRelay.shared():send_message(CommandMessage.new(
            'trust follow ack '..leader..' '..request_id..' '..member..' '..response..' --quiet',
            leader))
    end
    return success, message
end

-- Replies are bounded to the current request and a known expected party name.
-- Duplicate/late replies are harmless, including after a focus switch.
function FollowTrustCommands:handle_follow_ack(_, leader, request_id, member, result)
    local pending = self.pending_follow
    if not pending or type(leader) ~= 'string' or type(request_id) ~= 'string'
            or type(member) ~= 'string' then return true end
    if leader:lower() ~= pending.leader:lower() or request_id ~= pending.request_id
            or not pending.targets[member] or pending.targets[member] ~= 'pending'
            or (result ~= 'accepted' and result ~= 'failed') then
        return true
    end
    pending.targets[member] = result
    for _, state_name in pairs(pending.targets) do
        if state_name == 'pending' then return true end
    end
    self:finish_follow_receipts()
    return true
end

-- // trust follow party_member_name
function FollowTrustCommands:handle_follow_party_member(party_member_name)
    if party_member_name == nil then return self:handle_travel() end
    if self.action_queue and self.action_queue.control_state == 'Retreat'
            and (not self.action_queue.retreat_leader or party_member_name:lower() ~= self.action_queue.retreat_leader:lower()) then
        return false, 'Retreat active; use Act or Pause before changing the follow leader'
    end
    local success
    local message

    party_member_name = party_member_name:gsub("^%l", string.upper)

    if self:get_follower():is_valid_target(party_member_name) then
        local follower = self:get_follower()
        local current = follower:get_follow_target()
        if state.AutoFollowMode.value == 'Always' and current
                and current:get_name():lower() == party_member_name:lower()
                and not follower.manual_pause and not follower.recovery_paused then
            return true, 'Already following '..party_member_name
        end
        self:handle_set_mode('AutoFollowMode', 'Always', command_feedback.is_quiet())

        require('cylibs/movement/recovery').reset()
        self:get_follower().manual_pause=false
        self:get_follower().recovery_paused=false
        local error_message = self:get_follower():follow_target_named(party_member_name)
        if error_message then
            success = false
            message = error_message
        else
            success = true
            message = 'Now following '..party_member_name
        end
    else
        success = false
        message = party_member_name..' is not a valid party member or is not in range'
    end

    return success, message
end

-- // trust follow distance number
function FollowTrustCommands:handle_set_follow_distance(_, distance)
    local success
    local message

    if type(distance)=='string' and distance:match("^%d+$") and tonumber(distance)<=50 then
        distance = tonumber(distance)
        self:get_follower():set_distance(distance)
        -- Follow targets/pause are session-only; distance is an existing option.
        if require('cylibs/ui/menu/menu_preferences').get('save_on_exit') then
            addon_settings:getSettings().follow.distance = distance
        end
        success = true
        message = 'Follow distance set to '..distance
    else
        success = false
        message = 'Invalid distance '..tostring(distance)..' (expected 0-50)'
    end

    return success, message
end

-- // trust follow start
function FollowTrustCommands:handle_start()
    require('cylibs/movement/recovery').reset()
    self:get_follower().manual_pause=false
    self:get_follower().recovery_paused=false
    local success = true
    local message = 'Following resumed'

    self:get_follower():start_following()

    return success, message
end

-- // trust follow stop
function FollowTrustCommands:handle_stop()
    local success = true
    local message = 'Following paused'

    self:get_follower().manual_pause=true
    self:get_follower():stop_following()

    return success, message
end

-- // trust follow clear
function FollowTrustCommands:handle_clear()
    local success = true
    local message = 'Follow target cleared'

    self:get_follower():set_follow_target(nil)

    return success, message
end

-- // trust follow stopall
function FollowTrustCommands:handle_stop_all()
    local success
    local message

    if L{'All', 'Send'}:contains(state.IpcMode.value) then
        IpcRelay.shared():send_message(CommandMessage.new('trust set AutoFollowMode Off'))
        success = true
        message = 'Follow disabled on everyone else'
    else
        success = false
        message = 'IpcMode must be set to All or Send to use this command'
    end

    return success, message
end

return FollowTrustCommands
