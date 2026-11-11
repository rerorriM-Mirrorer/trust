-- Party preparation is a bounded transaction, not a persistent travel mode.
-- The issuer serializes work. Receivers own their queue and actual buff checks.
local Planner = require('cylibs/trust/stealth/planner')
local Control = require('cylibs/trust/control_state')
local Timer = require('cylibs/util/timers/timer')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')
local WaitAction = require('cylibs/actions/wait')
local ActionQueue = require('cylibs/actions/action_queue')
local Spell = require('cylibs/battle/spell')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local UseItem = require('cylibs/battle/use_item')
local spell_util = require('cylibs/util/spell_util')
local job_util = require('cylibs/util/job_util')
local inventory_util = require('cylibs/util/inventory_util')
local party_util = require('cylibs/util/party_util')
local logger = require('cylibs/logger/logger')
local Stealth = {}
Stealth.__index = Stealth
local prefix = 'trust_stealth_v1'
local buff_ids = {sneak=71, invisible=69}
local current

function Stealth.attach(trust, queue, enabled)
    if current then current:destroy() end
    current = Stealth.new(trust, queue, enabled)
    return current
end

function Stealth.current() return current end

function Stealth.detach()
    if current then current:destroy(); current = nil end
end

local function has(buff)
    for _, id in ipairs(windower.ffxi.get_player().buffs or {}) do
        if id == buff then return true end
    end
    return false
end

function Stealth.new(trust, queue, enabled)
    local self = setmetatable({trust=trust, main_queue=queue, enabled=enabled, serial=0, events={}, completed={}}, Stealth)
    self.queue = ActionQueue.new(nil, false, 2, false, false, false)
    self.timer = Timer.scheduledTimer(0.25, 0.25)
    self.timer:onTimeChange():addAction(function() self:tick() end)
    self.events[#self.events+1] = windower.register_event('ipc message', function(message) self:receive(message) end)
    self.events[#self.events+1] = windower.register_event('zone change', function() self:cancel('Zone changed') end)
    self.events[#self.events+1] = windower.register_event('job change', function() self:cancel('Job changed') end)
    self.events[#self.events+1] = windower.register_event('action', function(action)
        local p = windower.ffxi.get_player()
        if not p or action.actor_id ~= p.id then return end
        if action.category == 8 then
            self.casting_until = action.param == 28787 and 0 or os.time()+30
        elseif action.category == 4 then
            self.casting_until = 0
            self.ready_after = os.time()+2
        end
    end)
    self.events[#self.events+1] = windower.register_event('unload', function() self:destroy() end)
    self.timer:start()
    return self
end

function Stealth:name() return windower.ffxi.get_player().name end
function Stealth:member(name) return self.trust:get_party():get_party_member_named(name, true) end
function Stealth:duplex() return state.IpcMode.value == 'All' end
function Stealth:log(message) logger.notice('PartyStealth', message) end
function Stealth:say(message) addon_system_message('Stealth: '..message) end

function Stealth:send(target, token, verb, args)
    if target == self:name() then
        self:handle(self:name(), token, verb, args or {})
    elseif self:duplex() then
        windower.send_ipc_message(table.concat({self:name(), prefix, target, token, verb, unpack(args or {})}, ' '))
    end
end

function Stealth:receive(message)
    if self.destroyed or not self:duplex() then return end
    local words = {}
    for word in message:gmatch('%S+') do words[#words+1] = word end
    if words[2] ~= prefix or words[3] ~= self:name() then return end
    local sender, token, verb = words[1], words[4], words[5]
    if not sender or not self:member(sender) or not token or not token:match('^%d+_%d+$') then return end
    local args = {}
    for i=6,#words do args[#args+1] = words[i] end
    self:handle(sender, token, verb, args)
end

function Stealth:capable(code, allow_wait)
    local method = Planner.methods[code]
    local p = windower.ffxi.get_player()
    if not method or p.status ~= 0 or has(69) or os.time() < (self.casting_until or 0)
            or os.time() < (self.ready_after or 0) then return false end
    if method.item then return inventory_util.get_item_count(method.item) > 0 end
    if method.ability then
        local id = job_util.job_ability_id(method.ability)
        return not has(71) and job_util.knows_job_ability(id) and job_util.can_use_job_ability(method.ability)
    end
    local spell = res.spells:with('en', method.spell)
    if not spell or not spell_util.knows_spell(spell.id) or p.vitals.mp < spell.mp_cost then return false end
    if not spell_util.can_cast_spell(spell.id) then
        local recast = (windower.ffxi.get_spell_recasts() or {})[spell.id]
        if not allow_wait or not recast or recast > 30*60 then return false end
    end
    if method.kind == 'self' then
        local tool = code == 'm' and 'Sanjaku-Tenugui' or 'Shinobi-Tabi'
        if inventory_util.get_item_count(tool) == 0 and not
                (p.main_job_id == 13 and inventory_util.get_item_count('Shikanofuda') > 0) then return false end
    end
    if method.kind == 'area' then
        -- Accession is available in Light Arts/Addendum: White. Do not change
        -- arts or consume a charge unless the area plan can cover everyone.
        return (has(358) or has(401)) and job_util.knows_job_ability(job_util.job_ability_id('Accession'))
            and job_util.can_use_job_ability('Accession') and p.vitals.mp >= spell.mp_cost * 2
    end
    return true
end

function Stealth:snapshot()
    local caps, waiting = {}, {}
    for code in pairs(Planner.methods) do
        if self:capable(code) then caps[#caps+1] = code
        elseif self:capable(code, true) then waiting[#waiting+1] = code end
    end
    table.sort(caps)
    table.sort(waiting)
    return {has(71) and '1' or '0', has(69) and '1' or '0', #caps > 0 and table.concat(caps, ',') or '-',
        (os.time() < (self.casting_until or 0) or os.time() < (self.ready_after or 0)) and '1' or '0',
        #waiting > 0 and table.concat(waiting, ',') or '-'}
end

function Stealth:hold(owner, token)
    local issued = tonumber(token:match('^(%d+)_'))
    if not issued or os.time()-issued > 180 or issued > os.time()+5 then return false end
    if self.completed[owner..':'..token] then return false end
    if self.lease then return self.lease.owner == owner and self.lease.token == token end
    local p = windower.ffxi.get_player()
    if not p or p.status ~= 0 or self.main_queue.control_state == 'Retreat' then return false end
    local follower = self.trust:role_with_type('follower')
    local lease = {owner=owner, token=token, expires=os.time()+190,
        mode=self.main_queue.control_state or (self.enabled:getValue() and 'Active' or 'Paused'),
        manual=follower and follower.manual_pause}
    self.lease = lease
    if follower then
        follower.stealth_hold = true
        follower:stop_following()
    end
    Control.set(self.main_queue, self.enabled, self.trust, 'Paused')
    lease.revision = self.main_queue.control_revision
    windower.ffxi.run(false)
    windower.ffxi.follow()
    self.queue:enable()
    return true
end

function Stealth:release(restore)
    local lease = self.lease
    if not lease then return end
    self.completed[lease.owner..':'..lease.token] = os.time()
    self.lease = nil
    self.work = nil
    self.queue:disable()
    local follower = self.trust:role_with_type('follower')
    if follower then follower.stealth_hold = nil end
    if restore then
        if self.main_queue.control_revision == lease.revision then
            Control.set(self.main_queue, self.enabled, self.trust, lease.mode, lease.manual)
            if follower then follower.manual_pause = lease.manual end
        end
        -- A new control command owns its own state; only remove our hold.
        if follower and not follower.manual_pause then follower:start_following() end
    end
end

function Stealth:handle(sender, token, verb, args)
    if verb == 'hold' then
        if self:hold(sender, token) then self:send(sender, token, 'state', self:snapshot())
        else self:send(sender, token, 'abort') end
        return
    end
    local session = self.session
    if verb == 'state' and session and token == session.token and session.members[sender] then
        local member = session.members[sender]
        if member.aborted then return end
        member.ready = true
        member.busy = args[4] == '1'
        member.sneak, member.invisible = args[1] == '1', args[2] == '1'
        member.caps = {}
        for code in (args[3] or ''):gmatch('[^,]+') do if Planner.methods[code] then member.caps[code] = true end end
        for code in (args[5] or ''):gmatch('[^,]+') do if Planner.methods[code] then member.caps[code] = 'wait' end end
        member.updated = os.time()
        return
    elseif verb == 'done' and session and token == session.token and session.pending
            and sender == session.pending.provider and args[1] == tostring(session.pending.sequence) then
        session.pending = nil
        session.refresh_until = os.time()+2
        self:log(sender..' completed attempt '..args[1])
        return
    elseif verb == 'abort' and session and token == session.token and session.members[sender] then
        session.members[sender].ready = false
        session.members[sender].aborted = true
        self:log(sender..' preparation interrupted')
        if session.pending and session.pending.provider == sender then session.pending = nil end
        return
    end
    local lease = self.lease
    if not lease or sender ~= lease.owner or token ~= lease.token then return end
    if verb == 'release' then self:release(true)
    elseif verb == 'query' then self:send(sender, token, 'state', self:snapshot())
    elseif verb == 'action' then
        local sequence = tonumber(args[1])
        if not sequence or sequence <= (lease.sequence or 0) or self.work then return end
        lease.sequence = sequence
        self:execute(args[2], args[3], args[4], sequence)
    end
end

function Stealth:execute(code, target_name, effect, sequence)
    local lease = self.lease
    local method = Planner.methods[code]
    local target = target_name and self:member(target_name)
    local mob = target and target:get_mob()
    local p = windower.ffxi.get_player()
    if not method or (method.effect ~= effect and method.effect ~= 'both') or (effect ~= 'sneak' and effect ~= 'invisible') or not mob or not self:capable(code)
            or self.main_queue.control_revision ~= lease.revision
            or (method.kind ~= 'spell' and target_name ~= self:name())
            or (method.kind == 'spell' and (mob.distance or math.huge) > 400) then
        self:log(self:name()..' skipped stale/unavailable method '..tostring(code)..' -> '..tostring(target_name))
        self:send(lease.owner, lease.token, 'done', {tostring(sequence)})
        return
    end
    local ability
    if method.spell then ability = Spell.new(method.spell)
    elseif method.ability then ability = JobAbility.new(method.ability)
    else ability = UseItem.new(method.item) end
    local action
    if method.kind == 'area' then
        action = SequenceAction.new(L{
            require('cylibs/actions/strategem').new('Accession'),
            WaitAction.new(0,0,0,1),
            SpellAction.new(0,0,0,res.spells:with('en',method.spell).id,p.index,player.player),
        }, 'party_stealth_area')
    else action = ability:to_action(mob.index, player.player) end
    action.recovery_timeout = 15
    action.max_duration = 15
    self.work = {sequence=sequence, expires=os.time()+15, effect=effect, target=target_name}
    self:log(self:name()..' '..(method.spell or method.ability or method.item)..' -> '..target_name)
    self.queue:push_action(action, true)
end

function Stealth:start(mode)
    if self.session or self.lease then return false, 'Stealth preparation is already running; //trust stealth cancel' end
    if mode ~= 'sneak' and mode ~= 'invisible' and mode ~= 'stealth' then return false, 'Invalid stealth request' end
    local list, members = {}, {}
    for member in self.trust:get_party():get_party_members(true):it() do
        if not party_util.is_alter_ego(member:get_name()) then
            local entry = {name=member:get_name(), caps={}}
            list[#list+1], members[entry.name] = entry, entry
        end
    end
    table.sort(list, function(a,b) return a.name < b.name end)
    if #list > 1 and not self:duplex() then return false, 'Party preparation requires IpcMode All on participating clients' end
    self.serial = self.serial + 1
    local session = {token=tostring(os.time())..'_'..tostring(self.serial), mode=mode,
        list=list, members=members, attempted={}, sequence=0, starts=os.time(), collect_until=os.time()+3}
    self.session = session
    for _,member in ipairs(list) do self:send(member.name, session.token, 'hold') end
    if not self.lease then self:cancel('Issuer cannot prepare while engaged, mounted, or retreating'); return false, 'Stealth preparation could not start' end
    self:say('Preparing '..({stealth='Sneak and Invisible',sneak='Sneak',invisible='Invisible'})[mode]..'.')
    return true
end

function Stealth:update_positions(session)
    for _, entry in ipairs(session.list) do
        local member = self:member(entry.name)
        local mob = member and member:get_mob()
        entry.x, entry.y, entry.z = mob and mob.x, mob and mob.y, mob and mob.z
        entry.zone = member and member:get_zone_id()
        if not member or entry.aborted or (entry.updated and os.time()-entry.updated > 4) then entry.ready = false end
        if not entry.ready then
            -- Non-participating party members may receive spells. Their tracked
            -- buffs can confirm coverage but they cannot perform local actions.
            entry.sneak, entry.invisible = false, false
            if member and mob then
                for _,id in ipairs(member:get_buff_ids() or {}) do
                    if id == 71 then entry.sneak=true elseif id == 69 then entry.invisible=true end
                end
            end
        end
    end
end

function Stealth:tick()
    if self.destroyed then return end
    local now = os.time()
    for key, time in pairs(self.completed) do if now-time > 240 then self.completed[key]=nil end end
    local lease = self.lease
    if lease and (now > lease.expires or self.main_queue.control_revision ~= lease.revision
            or not self:member(lease.owner) or windower.ffxi.get_player().status ~= 0) then
        self:send(lease.owner, lease.token, 'abort')
        self:release(true)
        if self.session then self:finish('Interrupted') end
    end
    lease = self.lease
    if lease and self.work then
        local work = self.work
        local target = self:member(work.target)
        local observed = false
        for _,id in ipairs(target and target:get_buff_ids() or {}) do
            if id == buff_ids[work.effect] then observed = true end
        end
        if work.target == self:name() then observed = has(buff_ids[work.effect]) end
        if now >= work.expires or (observed and not self.queue.current_action and self.queue:length() == 0) then
            self:log(work.target..' '..work.effect..(observed and ' observed' or ' not observed before timeout'))
            self.work = nil
            self.ready_after = now+2
            self.queue:disable()
            self.queue:enable()
            self:send(lease.owner, lease.token, 'state', self:snapshot())
            self:send(lease.owner, lease.token, 'done', {tostring(work.sequence)})
        end
    end
    local session = self.session
    if not session then return end
    if not self:duplex() and #session.list > 1 then self:finish('IPC interrupted'); return end
    if now-session.starts > 180 then self:finish('Timed out'); return end
    if not session.last_query or now > session.last_query then
        session.last_query = now
        for _,member in ipairs(session.list) do self:send(member.name,session.token,'query') end
    end
    self:update_positions(session)
    if now < session.collect_until or (session.refresh_until and now < session.refresh_until) then return end
    if session.pending then
        if now > session.pending.expires then
            -- Do not overlap a slow or unresponsive worker with a new action.
            self:finish('Action timed out: '..session.pending.provider)
        end
        return
    end
    local effect = session.mode == 'invisible' and 'invisible' or 'sneak'
    if session.stage == 'invisible' then effect = 'invisible' end
    for _,member in ipairs(session.list) do
        if member.ready and member.busy then return end
    end
    local choice = Planner.next(session.list, effect, session.attempted)
    if not choice and session.mode == 'stealth' and effect == 'sneak' then
        session.stage = 'invisible'
        choice = Planner.next(session.list, 'invisible', session.attempted)
    end
    if not choice then self:finish(); return end
    -- Preserve magic-first behavior across normal spell recasts; a cooldown
    -- is not evidence that a party member must consume an item.
    if choice.wait then return end
    session.sequence = session.sequence+1
    session.attempted[choice.key] = true
    choice.sequence, choice.expires = session.sequence, now+20
    session.pending = choice
    self:send(choice.provider, session.token, 'action', {tostring(choice.sequence),choice.code,choice.target,choice.effect})
end

function Stealth:finish(reason)
    local session = self.session
    if not session then return end
    self:update_positions(session)
    self.session = nil
    for _,member in ipairs(session.list) do self:send(member.name,session.token,'release') end
    local missing = {}
    for _, member in ipairs(session.list) do
        local effects = {}
        if session.mode ~= 'invisible' and not member.sneak then effects[#effects+1]='Sneak' end
        if session.mode ~= 'sneak' and not member.invisible then effects[#effects+1]='Invisible' end
        if #effects > 0 then missing[#missing+1]=member.name..' ('..table.concat(effects,', ')..')' end
    end
    self:say((reason and reason..'. ' or '')..'Covered '..tostring(#session.list-#missing)..'/'..tostring(#session.list)
        ..(#missing > 0 and ' - Missing: '..table.concat(missing,'; ') or '.'))
end

function Stealth:cancel(reason)
    if self.destroyed then return end
    self:finish(reason or 'Cancelled')
    if self.lease then
        self:send(self.lease.owner,self.lease.token,'abort')
        self:release(true)
    end
end

function Stealth:status()
    if self.session then
        local pending = self.session.pending
        return 'Preparing '..self.session.mode..(pending and (' - '..pending.provider..' -> '..pending.target) or '')
    end
    if self.lease then return 'Preparing for '..self.lease.owner end
    return 'Idle (one-shot preparation)'
end

function Stealth:destroy()
    if self.destroyed then return end
    self.destroyed = true
    -- Do not resume local automation during addon/job teardown.
    if self.lease then self.main_queue.control_revision = (self.main_queue.control_revision or 0)+1 end
    self:finish('Unloaded')
    self:release(false)
    self.timer:destroy()
    self.queue:disable()
    self.queue:destroy()
    for _,event in ipairs(self.events) do windower.unregister_event(event) end
end

return Stealth
