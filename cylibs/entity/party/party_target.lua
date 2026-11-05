local AggroTarget = require('cylibs/entity/party/aggro_target')
local socket = require('socket')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local IpcRelay = require('cylibs/messages/ipc/ipc_relay')
local TargetChangeMessage = require('cylibs/messages/target_change_message')

local PartyTarget = {}
PartyTarget.__index = PartyTarget
PartyTarget.__type = "PartyTarget"
PartyTarget.__class = "PartyTarget"

-- Event called when the party member's target changes.
function PartyTarget:on_target_change()
    return self.target_change
end

function PartyTarget.new(target_tracker, ignore_assist_target, party)
    local self = setmetatable({}, PartyTarget)

    self.target_tracker = target_tracker
    self.aggro = party and AggroTarget.new(party, target_tracker)
    self.ignore_assist_target = ignore_assist_target
    self.action_events = {}
    self.assist_target_dispose_bag = DisposeBag.new()
    self.dispose_bag = DisposeBag.new()
    self.target_change = Event.newEvent()

    self.action_events.zone_change = windower.register_event('zone change', function(_, _)
        if self.aggro then self.aggro:reset() end
        self.auto_defense_id = nil
        self.aggro_target_id = nil
        self.aggro_active = false
        self:set_target_index(nil)
    end)

    return self
end

function PartyTarget:destroy()
    for _, event in pairs(self.action_events) do
        windower.unregister_event(event)
    end

    self:on_target_change():removeAllActions()

    self.assist_target_dispose_bag:destroy()
    self.dispose_bag:destroy()
end

function PartyTarget:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true
    if self.aggro then
        self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
            if state.AutoEngageMode and state.AutoEngageMode.value == 'Aggro'
                    and (not addon_enabled or addon_enabled:getValue()) then
                self.aggro:observe(action, os.time())
            end
        end), WindowerEvents.Action)
        self.dispose_bag:add(WindowerEvents.MobKO:addAction(function(id)
            self.aggro.evidence[id] = nil
            if self.aggro.selected_id == id then self.aggro.selected_id = nil end
        end), WindowerEvents.MobKO)
        self.action_events.aggro_tick = windower.register_event('prerender', function()
            local now = socket.gettime()
            if now < (self.next_aggro_check or 0) then return end
            self.next_aggro_check = now + 0.5
            self:update_aggro_target()
        end)
    end
end

function PartyTarget:set_assist_target(assist_target)
    self.assist_target_dispose_bag:dispose()
    self.assist_target = assist_target
    self.auto_defense_id = nil
    if self.aggro then self.aggro:reset() end

    if assist_target then
        self.assist_target_dispose_bag:add(assist_target:on_target_change():addAction(function(p, new_target_index, old_target_index)
            logger.notice(self.__class, 'set_assist_target', 'on_target_change', p:get_name(), new_target_index)
            if assist_target and assist_target:is_valid() and p:get_name() == assist_target:get_name() then
                logger.notice(self.__class, 'set_assist_target', 'on_party_target_change', p:get_name(), new_target_index)
                if not self:should_ignore_assist_target() then
                    if not self:update_aggro_target() then self:set_target_index(new_target_index) end
                end
            end
        end), assist_target:on_target_change())
        if not self:update_aggro_target() then self:set_target_index(assist_target:get_target_index()) end
    end
end

-- Keep the existing party-target event path so roles and action queues agree on one enemy.
function PartyTarget:update_aggro_target()
    if not self.aggro then return false end
    local enabled = state.AutoEngageMode and state.AutoEngageMode.value == 'Aggro'
            and (not addon_enabled or addon_enabled:getValue())
    if self:should_ignore_assist_target() or (state.AutoPullMode and state.AutoPullMode.value ~= 'Off') then
        self.aggro:reset()
        self.aggro_active = false
        self.aggro_decision = 'puller-owned'
        return false -- puller owns the target, including its deliberate nil target
    end
    local assist_index = self.assist_target and self.assist_target:is_valid() and self.assist_target:get_target_index() or nil
    if not enabled then
        if self.aggro_active then self:set_target_index(assist_index) end
        self.aggro:reset()
        self.aggro_active = false
        self.aggro_decision = 'inactive'
        self.auto_defense_id = nil
        return false
    end
    -- Our own automatic targeting must not become fresh assist evidence on the next tick.
    -- A different manually selected enemy still wins; a remote assist leader always wins.
    local assist_mob = assist_index and windower.ffxi.get_mob_by_index(assist_index)
    if self.assist_target and self.assist_target:get_id() == windower.ffxi.get_player().id
            and assist_mob and assist_mob.id == self.auto_defense_id then
        assist_index = nil
    end
    self.aggro_active = true
    -- Seed live target observations through the established tracker, including alter egos.
    local party_util = require('cylibs/util/party_util')
    for index in party_util.get_mobs_targeting_party():it() do self.target_tracker:add_mob_by_index(index) end
    local index, reason = self.aggro:select(assist_index, os.time())
    local decision = reason .. ':' .. tostring(index)
    if self.aggro_decision ~= decision then
        logger.notice(self.__class, 'Aggro', decision, 'previous_id', self.aggro_target_id or 'nil')
        self.aggro_decision = decision
    end
    local mob = index and windower.ffxi.get_mob_by_index(index)
    if reason == 'defense' then self.auto_defense_id = mob and mob.id end
    if index == self.target_index and mob and self.aggro_target_id and mob.id ~= self.aggro_target_id then
        self:set_target_index(nil) -- reused index must invalidate old role/action targets
    end
    self.aggro_target_id = mob and mob.id
    self:set_target_index(index)
    return true
end

function PartyTarget:log_target_changed(old_target_index, new_target_index)
    local old_target = old_target_index and windower.ffxi.get_mob_by_index(old_target_index)
    local new_target = new_target_index and windower.ffxi.get_mob_by_index(new_target_index)
    logger.notice(
            self.__class,
            'old_target', old_target and old_target.name, old_target and old_target.index, old_target and old_target.hpp, old_target and old_target.status, old_target and old_target.claim_id, old_target and old_target.distance:sqrt(),
            'new_target', new_target and new_target.name, new_target and new_target.index, new_target and new_target.hpp, new_target and new_target.status, new_target and new_target.claim_id, new_target and new_target.distance:sqrt()
    )
end

function PartyTarget:set_target_index(target_index)
    if windower.ffxi.get_mob_by_target('st') then return end
    if self.target_index == target_index then
        return
    end
    self.target_tracker:add_mob_by_index(target_index)
    local old_target_index = self.target_index
    self.target_index = target_index
    self:log_target_changed(old_target_index, self.target_index)
    self:on_target_change():trigger(self, self.target_index, old_target_index)
end

function PartyTarget:get_target_index()
    return self.target_index
end

function PartyTarget:get_target()
    if self.target_index then
        return self:get_alliance():get_target_by_index(self.target_index)
    end
    return nil
end

function PartyTarget:set_should_ignore_assist_target(ignore_assist_target)
    self.ignore_assist_target = ignore_assist_target
end

function PartyTarget:should_ignore_assist_target()
    return self.ignore_assist_target
end


return PartyTarget
