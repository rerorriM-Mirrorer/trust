local CommandMessage = require('cylibs/messages/command_message')
local party_util = require('cylibs/util/party_util')
local Control = require('cylibs/trust/control_state')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local GeneralTrustCommands = setmetatable({}, {__index = TrustCommands })
GeneralTrustCommands.__index = GeneralTrustCommands
GeneralTrustCommands.__class = "GeneralTrustCommands"

function GeneralTrustCommands.new(trust, action_queue, addon_enabled, trust_mode_settings, main_trust_settings, sub_trust_settings)
    local self = setmetatable(TrustCommands.new(), GeneralTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.addon_enabled = addon_enabled
    self.trust_mode_settings = trust_mode_settings
    self.main_trust_settings = main_trust_settings
    self.sub_trust_settings = sub_trust_settings
    self.hud = hud

    -- General
    self:add_command('version', self.handle_version, 'Trust version')
    self:add_command('help', self.handle_help, 'Learn more on the wiki')
    self:add_command('commands', self.handle_command_list, 'See all Trust commands')
    self:add_command('aggro', self.handle_aggro_status, 'Show defensive targeting diagnostics: //trust aggro')
    self:add_command('debug', self.handle_debug, 'Show debug info')
    self:add_command('timeout', self.handle_timeout, 'Unload Trust after a specified number of minutes, // trust timeout num_minutes or // trust timeout clear')
    self:add_command('item', self.handle_use_item, 'Use an item by name, // trust item item_name')

    -- State
    self:add_command('start', self.handle_start, 'Start Trust')
    self:add_command('act', self.handle_start, 'Activate Trust job automation (alias for start)')
    self:add_command('ready', self.handle_ready, 'Assist and follow me; Act on other party clients: //trust ready')
    self:add_command('standdown', self.handle_standdown, 'Pause everyone and follow me with configured Fan Out: //trust standdown')
    self:add_command('partyrequest', self.handle_party_request, 'Internal coordinated party request')
    self:add_command('handoff', self.handle_handoff, 'Follow and assist a party member, then start: //trust handoff <name>')
    self:add_command('startall', self.handle_start_all, 'Start Trust on all characters, or only party members with // trust startall party')
    self:add_command('actall', self.handle_start_all, 'Activate all Trust clients, or only party members with //trust actall party')
    self:add_command('stop', self.handle_stop, 'Party retreat: disengage and close-follow the assist/party leader')
    self:add_command('pause', self.handle_pause, 'Pause job actions; keep following and configured Fan Out')
    self:add_command('stopall', self.handle_stop_all, 'Party retreat (alias for stop): //trust stopall [party]')
    self:add_command('pauseall', self.handle_pause_all, 'Pause all Trust clients, or only party members with //trust pauseall party')
    self:add_command('toggle', self.handle_toggle, 'Toggle local Act and Pause')
    self:add_command('reload', self.handle_reload, 'Reload job settings files')
    self:add_command('status', self.handle_status, 'View Trust status')
    self:add_command('fan', self.handle_fan, 'Toggle Fan Out, or set it explicitly: //trust fan [on|off]')
    self:add_command('fanall', self.handle_fan_all, 'Set Fan Out on all receiving clients: //trust fanall [on|off]')
    self:add_command('combat', self.handle_combat, 'Show or set combat positioning: //trust combat [auto|mirror|off]')
    self:add_command('widget', self.handle_widget, 'Set widget appearance: // trust widget [full|compact|toggle] [all|trust|party|target]')
    self:add_command('menuperf', self.handle_menuperf, 'Measure CPU time opening Trust menu: // trust menuperf [on|off]')

    -- Modes
    self:add_command('set', self.handle_set_mode, 'Set a mode to a given value, // trust set mode_name mode_value')
    self:add_command('cycle', self.handle_cycle_mode, 'Cycle the value of a mode, // trust cycle mode_name')
    self:add_command('load', self.handle_load_set, 'Load a mode set, // trust load mode_set_name')
    self:add_command('save', self.handle_save_set, 'Save changes to the current mode set or new set, // trust save mode_set_name (optional)')

    return self
end

function GeneralTrustCommands:handle_fan(_, value, quiet, ...)
    if (quiet ~= nil and quiet ~= '--quiet') or (quiet and value == nil) or select('#', ...) > 0 or (value ~= nil and
            (type(value) ~= 'string' or not ({on=true,off=true})[value:lower()])) then
        return false, 'Usage: //trust fan [on|off]'
    end
    local owner = addon_settings
    local follow = owner:getSettings().follow
    local enabled = value == nil and follow.fan_out == false or
        (type(value) == 'string' and value:lower() == 'on')
    if follow.fan_out ~= enabled then
        follow.fan_out = enabled
        owner:saveSettings(true)
    end
    if quiet ~= '--quiet' then self:show_fan_feedback(enabled) end
    return true
end

function GeneralTrustCommands:show_fan_feedback(enabled, detail)
    require('chat')
    local label = enabled and 'ON' or 'OFF'
    local suffix = detail and ' - '..detail or ''
    windower.add_to_chat(0, '[Trust] ':color(200)..'Fan Out ':color(167)
        ..label:color(enabled and 158 or 167)..suffix:color(0))
end

function GeneralTrustCommands:handle_fan_all(_, value, ...)
    if select('#', ...) > 0 or (value ~= nil and
            (type(value) ~= 'string' or not ({on=true,off=true})[value:lower()])) then
        return false, 'Usage: //trust fanall [on|off]'
    end
    local enabled = value == nil and addon_settings:getSettings().follow.fan_out == false or
        (type(value) == 'string' and value:lower() == 'on')
    local setting = enabled and 'on' or 'off'
    local success, message = self:handle_fan(_, setting, '--quiet')
    if not success then return success, message end
    if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then
        self:show_fan_feedback(enabled, 'Local only. IPC sending unavailable.')
        return true
    end
    -- Relay the issuer's chosen state so clients with different settings agree.
    IpcRelay.shared():send_message(CommandMessage.new('trust fan '..setting..' --quiet'))
    self:show_fan_feedback(enabled, 'Requested on all clients.')
    return true
end

function GeneralTrustCommands:handle_combat(_, mode)
    if not state.CombatMode then return false,'CombatMode is unavailable' end
    if mode==nil then return true,'CombatMode: '..state.CombatMode.value end
    local selected=type(mode)=='string' and ({auto='Auto',mirror='Mirror',off='Off'})[mode:lower()]
    if not selected then return false,'Usage: //trust combat [auto|mirror|off]' end
    handle_set('CombatMode',selected)
    return true,'CombatMode: '..state.CombatMode.value
end

function GeneralTrustCommands:get_command_name()
    return 'default'
end

function GeneralTrustCommands:get_all_commands()
    local result = L{}
    for command_name, command in pairs(self.commands) do
        result:append('// trust '..command_name)
    end
    return result
end

-- // trust version
function GeneralTrustCommands:handle_version()
    local success = true
    local message

    addon_system_message("Trust v".._addon.version..".")

    return success, message
end

-- // trust help
function GeneralTrustCommands:handle_help()
    local success = true
    local message

    local jobNameShort = self.trust:get_job().jobNameShort
    if jobNameShort then
        local job = res.jobs:with('ens', jobNameShort)
        local url_suffix = job.en:gsub(" ", "-")
        windower.open_url(addon_settings:getSettings().help.wiki_base_url..'/'..url_suffix)
    else
        windower.open_url(addon_settings:getSettings().help.wiki_base_url)
    end

    return success, message
end

-- // trust version
function GeneralTrustCommands:handle_command_list()
    local success = true
    local message

    hud:openMenu(hud:getMainMenuItem():getChildMenuItem('Commands'))

    return success, message
end

-- // trust status
function GeneralTrustCommands:handle_status()
    local success = true
    local message

    addon_message(207, 'Control: '..(self.action_queue.control_state or (self.addon_enabled:getValue() and 'Active' or 'Paused')))
    local statuses = L{}
    for key,var in pairs(state) do
        statuses:append(key..': '..var.value)
    end
    statuses:sort()

    for status in statuses:it() do
        addon_message(207, status)
    end

    if player.party:get_assist_target() then
        addon_message(209, 'Assisting '..player.party:get_assist_target():get_name())
    end

    return success, message
end

-- // trust widget [full|compact|toggle] [all|trust|party|target]
-- The visual mode is independent of automation; Target.expanded still controls
-- debuff rows in Full mode, so use compactMode for all three widgets.
function GeneralTrustCommands:handle_widget(_, mode, scope)
    mode = mode or 'toggle'
    scope = scope or 'all'
    if type(mode) ~= 'string' or type(scope) ~= 'string' then
        return false, 'Usage: // trust widget [full|compact|toggle] [all|trust|party|target]'
    end
    mode, scope = mode:lower(), scope:lower()
    if not S{ 'full', 'compact', 'toggle' }:contains(mode)
            or not S{ 'all', 'trust', 'party', 'target' }:contains(scope) then
        return false, 'Usage: // trust widget [full|compact|toggle] [all|trust|party|target]'
    end

    local names = scope == 'all' and L{ 'trust', 'party', 'target' } or L{ scope }
    -- All-mode toggle follows Trust's current presentation so it reunifies
    -- widgets even if individual icon clicks expanded just one of them.
    local reference = windower.trust.ui.get_widget(scope == 'all' and 'trust' or scope)
    local compact = mode == 'compact' or (mode == 'toggle' and reference and not reference.compactMode)
    for name in names:it() do
        local widget = windower.trust.ui.get_widget(name)
        if not widget or not widget.setCompactMode then
            return false, name..' widget is unavailable'
        end
        widget:setCompactMode(compact)
    end
    return true, 'Widget appearance: '..mode..' ('..scope..')'
end

-- // trust menuperf [on|off]
-- Lightweight opt-in timing only. No work or chat output on ordinary opens.
-- os.clock() reports CPU time, not presentation latency; graphics stalls may
-- occur after this timing ends and should be tracked separately in live tests.
function GeneralTrustCommands:handle_menuperf(_, mode)
    if mode == nil then
        return true, 'Menu CPU timings '..(windower.trust.menu_perf_enabled and 'ON' or 'OFF')
    end
    if type(mode) ~= 'string' then
        return false, 'Usage: //trust menuperf [on|off]'
    end
    mode = mode:lower()
    if mode ~= 'on' and mode ~= 'off' then
        return false, 'Usage: //trust menuperf [on|off]'
    end
    windower.trust.menu_perf_enabled = mode == 'on'
    return true, 'Menu CPU timings '..(windower.trust.menu_perf_enabled and 'ON' or 'OFF')
end

-- A: one receiver-side operation preserves handoff ordering on each client.
-- Failed target setup never starts a stopped client; normal command feedback
-- reports the reason on that receiver (subject to the existing quiet option).
function GeneralTrustCommands:handle_handoff(_, name)
    if type(name) ~= 'string' or not name:match('^%a+$') then
        return false, 'Usage: //trust handoff <party member name>'
    end
    if name:lower() == windower.ffxi.get_player().name:lower() then
        return false, 'Handoff must name another party member'
    end
    if self.action_queue and self.action_queue.control_state == 'Retreat' then self:handle_pause() end
    local ok,message=shortcuts.follow:handle_follow_party_member(name)
    if ok==false then return false,message end
    ok,message=shortcuts.assist:handle_assist_player(name)
    if ok==false then return false,message end
    return self:handle_start()
end

-- A: receivers apply one ordered operation locally, with no rebroadcast and
-- no success chatter. Errors still return through normal command feedback.
function GeneralTrustCommands:handle_party_request(_, operation, leader, ...)
    if select('#', ...) > 0 or (operation ~= 'ready' and operation ~= 'standdown' and operation ~= 'retreat')
            or type(leader) ~= 'string' or not leader:match('^%a+$') then
        return false, 'Invalid coordinated party request'
    end
    local member = self.trust:get_party():get_party_member_named(leader, true)
    if not member then return false, 'Party leader '..leader..' is unavailable' end
    return require('cylibs/util/command_feedback').run(true, function()
        if operation == 'ready' then
            if self.action_queue.control_state == 'Retreat' then self:handle_pause() end
            local ok,message = shortcuts.assist:handle_assist_player(leader)
            if ok == false then return false,message end
            ok,message = shortcuts.follow:handle_follow_party_member(leader)
            if ok == false then return false,message end
            self:handle_start()
        elseif operation == 'retreat' then
            return self:apply_retreat(leader)
        else
            -- Pause still applies if distance/zone prevents following.
            self:handle_pause()
            local ok,message = shortcuts.follow:handle_follow_party_member(leader)
            if ok == false then return false,'Trust paused; '..message end
        end
        return true
    end)
end

function GeneralTrustCommands:request_party_state(operation)
    if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then
        return false, 'IpcMode must be All or Send to send party requests'
    end
    local leader = windower.ffxi.get_player().name
    local feedback = require('cylibs/util/command_feedback')
    local ok,message = feedback.run(true, function()
        if operation == 'ready' then
            -- Keep the initiator's Act/Pause state; only receivers Act.
            local assisted,reason = shortcuts.assist:handle_assist_player(leader)
            if assisted == false then return false,reason end
        else
            self:handle_pause()
            local follower = shortcuts.follow:get_follower()
            if follower:get_follow_target() then follower:set_follow_target(nil) end
        end
        return true
    end)
    if ok == false then return false,message end
    -- The issuer is the anchor; do not let an old follow target create a loop.
    shortcuts.follow.pending_follow = nil
    local local_follower = shortcuts.follow:get_follower()
    if local_follower:get_follow_target() then local_follower:set_follow_target(nil) end
    local sent,seen = 0,{}
    for name in party_util.get_party_member_names(false):it() do
        if type(name) == 'string' and name:match('^%a+$')
                and name:lower() ~= leader:lower() and not seen[name:lower()] and not party_util.is_alter_ego(name) then
            seen[name:lower()] = true
            IpcRelay.shared():send_message(CommandMessage.new(
                'trust partyrequest '..operation..' '..leader, name))
            sent = sent + 1
        end
    end
    require('chat')
    local heading = operation == 'ready' and 'Stand ready!' or 'Stand down!'
    local detail = sent > 0 and (operation == 'ready' and 'assist, follow and Act requested; remote state unconfirmed' or 'Pause and follow requested; remote state unconfirmed')
        or (operation == 'ready' and 'no other party clients; local Act/Pause unchanged'
            or 'local only; no other party members')
    windower.add_to_chat(0, '[Trust] ':color(200)..heading:color(167)
        ..' -> ':color(200)..detail:color(0))
    return true
end

function GeneralTrustCommands:handle_ready(_, ...)
    if select('#', ...) > 0 then return false, 'Usage: //trust ready' end
    return self:request_party_state('ready')
end

function GeneralTrustCommands:handle_standdown(_, ...)
    if select('#', ...) > 0 then return false, 'Usage: //trust standdown' end
    return self:request_party_state('standdown')
end

-- // trust start
function GeneralTrustCommands:handle_start(_, include_party)
    local success = true
    local message

    Control.set(self.action_queue, self.addon_enabled, self.trust, 'Active')

    if include_party then
        if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then
            return true, 'Trust active locally; IPC sending unavailable'
        end
        message = "Trust Act requested on all clients"
        IpcRelay.shared():send_message(CommandMessage.new('trust start'))
    else
        message = "Trust active"
    end

    return success, message
end

-- // trust startall [party]
function GeneralTrustCommands:handle_start_all(_, ...)
    return self:handle_all(_, 'start', ...)
end

-- Pause is local unless an explicit all variant is used. It never disengages.
function GeneralTrustCommands:handle_pause(_, include_party)
    Control.set(self.action_queue, self.addon_enabled, self.trust, 'Paused')
    if include_party then
        if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then
            return true, 'Trust paused locally; IPC sending unavailable'
        end
        IpcRelay.shared():send_message(CommandMessage.new('trust pause'))
        return true, 'Trust Pause requested on all clients'
    end
    return true, 'Trust paused'
end

function GeneralTrustCommands:handle_pause_all(_, ...)
    return self:handle_all(_, 'pause', ...)
end

-- Apply once per receiving client; never rebroadcast from this operation.
function GeneralTrustCommands:apply_retreat(leader)
    shortcuts.follow.pending_follow = nil -- retire pre-retreat follow retries
    local follower = shortcuts.follow:get_follower()
    local repeated = self.action_queue.control_state == 'Retreat' and self.action_queue.retreat_leader == leader
    Control.set(self.action_queue, self.addon_enabled, self.trust, 'Retreat', not repeated)
    self.action_queue.retreat_leader = leader
    if not repeated then
        require('cylibs/movement/recovery').reset()
        -- Changing the follow destination also disposes any live path through Pather.
        if follower:get_follow_target() then follower:set_follow_target(nil) end
        windower.ffxi.follow()
        windower.ffxi.run(false)
    end
    local character = windower.ffxi.get_player()
    if character.status == 1 then windower.send_command('input /attack off') end
    local pet = windower.ffxi.get_mob_by_target('pet')
    if pet and (character.main_job_id == 15 or character.sub_job_id == 15) then
        windower.send_command('input /pet "Retreat" <me>')
    elseif pet and (character.main_job_id == 9 or character.sub_job_id == 9) then
        windower.send_command('input /pet "Heel" <me>')
    end
    -- The anchor itself must stay free to run; followers resume after disengage.
    if leader:lower() == character.name:lower() then
        if follower:get_follow_target() then follower:set_follow_target(nil) end
        follower.manual_pause = false
        return true
    end
    local ok,message = shortcuts.follow:handle_follow_party_member(leader)
    if ok == false then return false, 'Retreat active; unable to follow: '..message end
    return true
end

function GeneralTrustCommands:get_retreat_leader()
    local party = self.trust:get_party()
    for _, member in ipairs({party:get_assist_target() or false, party:get_party_leader() or false, party:get_player() or false}) do
        if member then
            local name, mob = member:get_name(), member:get_mob()
            -- Exclude synthetic target locks, alter egos and stale cross-zone members.
            if name and name:match('^%a+$') and not party_util.is_alter_ego(name)
                    and mob and mob.hpp > 0 and member:get_zone_id() == windower.ffxi.get_info().zone then
                return name
            end
        end
    end
    return windower.ffxi.get_player().name
end

-- Bare Stop is intentionally party-wide. Only partyrequest retreat is local.
function GeneralTrustCommands:handle_stop(_, ...)
    if select('#', ...) > 0 then return false, 'Usage: //trust stop' end
    local leader = self:get_retreat_leader()
    local feedback = require('cylibs/util/command_feedback')
    local ok,message = feedback.run(true, function() return self:apply_retreat(leader) end)
    local sent,seen = 0,{}
    if state.IpcMode.value == 'All' or state.IpcMode.value == 'Send' then
        local own_name = windower.ffxi.get_player().name:lower()
        for name in party_util.get_party_member_names(false):it() do
            if type(name) == 'string' and name:match('^%a+$') and name:lower() ~= own_name
                    and not seen[name:lower()] and not party_util.is_alter_ego(name) then
                seen[name:lower()] = true
                IpcRelay.shared():send_message(CommandMessage.new('trust partyrequest retreat '..leader, name))
                sent = sent + 1
            end
        end
    end
    require('chat')
    local detail = 'close-follow '..leader..'; '..(sent > 0 and 'retreat requested; remote state unconfirmed' or 'local retreat only; no remote requests sent')
    windower.add_to_chat(0, ('[Trust] '):color(200)..('Retreat!'):color(167)..(' -> '):color(200)..detail:color(0))
    return ok,message
end

function GeneralTrustCommands:handle_stop_all(_, scope, ...)
    if select('#', ...) > 0 or (scope ~= nil and (type(scope) ~= 'string' or scope:lower() ~= 'party')) then
        return false, 'Usage: //trust stopall [party]'
    end
    return self:handle_stop()
end

function GeneralTrustCommands:handle_all(_, command, ...)
    local scope = select(1, ...)
    local argument_count = select('#', ...)
    if argument_count > 1 or (argument_count == 1 and (type(scope) ~= 'string' or scope:lower() ~= 'party')) then
        return false, 'Usage: // trust '..command..'all [party]'
    end

    local handler = self['handle_'..command]
    if argument_count == 0 then
        return handler(self, _, true)
    end

    local success, message = handler(self, _)
    if state.IpcMode.value ~= 'All' and state.IpcMode.value ~= 'Send' then
        return success, message..'; local only (IPC sending unavailable)'
    end
    local player_name = windower.ffxi.get_player().name:lower()
    local seen = {}
    for name in party_util.get_party_member_names(false):it() do
        if type(name) == 'string' and name:match('^%a+$') and name:lower() ~= player_name
                and not seen[name:lower()] and not party_util.is_alter_ego(name) then
            seen[name:lower()] = true
            IpcRelay.shared():send_message(CommandMessage.new('trust '..command, name))
        end
    end

    return success, message..' on party members'
end

-- // trust toggle
function GeneralTrustCommands:handle_toggle(_)
    local success = true
    local message = "Trust paused"

    if self.addon_enabled:getValue() then
        success, message = self:handle_pause(_)
    else
        success, message = self:handle_start(_)
    end

    return success, message
end

-- // trust reload
function GeneralTrustCommands:handle_reload(_)
    local success = true
    local message

    self.main_trust_settings:loadSettings()
    self.sub_trust_settings:loadSettings()

    return success, message
end

-- // trust set mode_name mode_value
function GeneralTrustCommands:handle_set_mode(_, mode_name, mode_value)
    local success = true
    local message

    handle_set(mode_name, mode_value)

    return success, message
end

-- // trust cycle mode_name
function GeneralTrustCommands:handle_cycle_mode(_, mode_name)
    local success = true
    local message

    handle_cycle(mode_name)

    return success, message
end

-- // trust load mode_set_name
function GeneralTrustCommands:handle_load_set(_, mode_set_name)
    local success
    local message

    if not mode_set_name then
        success = false
        message = "Invalid mode set name"
    else
        success = true

        state.TrustMode:set(mode_set_name)
    end

    return success, message
end

-- // trust save or // trust save mode_set_name
function GeneralTrustCommands:handle_save_set(_, mode_set_name)
    local success = true
    local message

    trust_mode_settings:saveSettings(mode_set_name or state.TrustMode.value)

    addon_system_message(string.format("Saved profile %s.", mode_set_name or state.TrustMode.value))

    return success, message
end

-- // trust timeout num_minutes or // trust timeout clear
function GeneralTrustCommands:handle_timeout(_, num_minutes)
    local success
    local message

    if num_minutes == nil then
        success = false
        message = string.format("Valid options are clear or number of minutes")
    else
        success = true
        if num_minutes == 'clear' then
            _addon.timeout = nil
            message = "Timeout cleared"
        else
            _addon.timeout = tonumber(num_minutes)
            message = string.format("Trust will unload after %d minutes", num_minutes)
        end
    end

    return success, message
end

-- // trust item item_name
function GeneralTrustCommands:handle_use_item(_, ...)
    local item_name = table.concat({...}, " ") or ""
    item_name = windower.convert_auto_trans(item_name)
    if item_name == nil then
        return false, "Invalid item name"
    end

    local CommandAction = require('cylibs/actions/command')
    self.action_queue:push_action(CommandAction.new(0, 0, 0, '/item "' .. item_name .. '" <me>'), true)

    return true, "Using " .. item_name
end

-- Read-only: mode selection remains the standard set command / Modes menu.
function GeneralTrustCommands:handle_aggro_status()
    local target = player.party and player.party.party_target
    local evidence_count = 0
    for _ in pairs(target and target.aggro and target.aggro.evidence or {}) do evidence_count = evidence_count + 1 end
    local mob = target and target:get_target_index() and windower.ffxi.get_mob_by_index(target:get_target_index())
    local detail = string.format('Test 1; mode=%s; decision=%s; target=%s (%s); event memories=%d; range=30y; memory=8s',
            state.AutoEngageMode.value, target and target.aggro_decision or 'inactive',
            mob and mob.name or 'none', mob and tostring(mob.id) or 'nil', evidence_count)
    local rejected = target and target.aggro and target.aggro.rejected
    if rejected then
        detail = detail .. string.format('; rejected foreign=%d invalid=%d unrelated=%d', rejected.foreign, rejected.invalid, rejected.unrelated)
    end
    windower.add_to_chat(0, ('[Trust] '):color(200)..('Aggro '):color(167)..('-> '):color(200)..detail:color(0))
    return true, nil
end

-- // trust debug
function GeneralTrustCommands:handle_debug()
    local mob = windower.ffxi.get_mob_by_name("Pulse Martello")
    print(mob.name, mob.is_npc, mob.entity_type, mob.in_party, mob.in_alliance, mob.valid_target)



    --local EquipSetAction = require('cylibs/actions/equip_set')
    --local EquipSet = require('cylibs/inventory/equipment/equip_set')
    --local EquipSet = require('cylibs/battle/equip_set')
    --local EquipSets = require('settings/settings').EquipSet

    --local equipSet = EquipSet.new('test_set')
    --if Condition.check_conditions(equipSet:get_conditions(), windower.ffxi.get_player().index) then
    --print('is valid')
    --local action_queue = ActionQueue.new(nil, false, 5)
    --action_queue:push_action(equipSet:to_action(windower.ffxi.get_player().index), true)
    --else
    --print('is not valid')
    --end

    --[[local Inventory = require('cylibs/inventory/inventory')
    local inventory = Inventory.new()

    local bag, index = inventory:find(22062)

    print(res.bags:with('api', bag.name).id, index)]]

    --print(inventory:find(22062))
    --print(inventory:find(23691))

    return true, nil
end

return GeneralTrustCommands
