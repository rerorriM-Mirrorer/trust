---------------------------
-- Engages a target.
-- @class module
-- @name EngageAction

local alter_ego_util = require('cylibs/util/alter_ego_util')
local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local packets = require('packets')
local Timer = require('cylibs/util/timers/timer')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

local Action = require('cylibs/actions/action')
local EngageAction = setmetatable({}, {__index = Action })
EngageAction.__index = EngageAction

function EngageAction.new(target_index, cursor_only)
    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
        MaxDistanceCondition.new(30),
    }
    local alliance = player.alliance
    if alliance then
        conditions:append(ConditionalCondition.new(L{ ClaimedCondition.new(alliance:get_alliance_member_ids()), UnclaimedCondition.new() }, Condition.LogicalOperator.Or))
    end
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), EngageAction)
    self.cursor_only = cursor_only
    self.dispose_bag = DisposeBag.new()
    return self
end

function EngageAction:destroy()
    self.dispose_bag:destroy()

    Action.destroy(self)
end

function EngageAction:can_perform()
    local target=windower.ffxi.get_mob_by_index(self.target_index)
    return target and not require('cylibs/movement/recovery').is_skipped(target.id)
        and Action.can_perform(self)
end

-- A: engagement is idempotent. Read the current client state as well as
-- events so an unchanged target never needs to change again to unblock the queue.
function EngageAction:is_ready()
    local character=windower.ffxi.get_player()
    if not character or character.target_index~=self.target_index then return false end
    return self.cursor_only or character.status==1
end

function EngageAction:finish_ready()
    local movement=addon_settings and addon_settings:getSettings().movement or {}
    if movement.auto_lockon==true and not self.cursor_only and not windower.ffxi.get_player().target_locked then
        windower.send_command('input /lockon')
    end
    self:complete(true)
end

function EngageAction:perform()
    local target=windower.ffxi.get_mob_by_index(self.target_index)
    if not target or not self:can_perform() then self:complete(false);return end
    if self:is_ready() then self:finish_ready();return end

    local started=os.time()
    local request_sent=false
    local function observe()
        if not request_sent or self.completed or self:is_cancelled() then return end
        if not self:can_perform() then self:complete(false)
        elseif self:is_ready() then self:finish_ready()
        elseif os.time()-started>=5 then self:complete(false) end
    end
    -- Subscribe before requesting a change; a synchronous acknowledgement must
    -- not be missed, nor should we allocate/start a timer after completion.
    self.dispose_bag:add(WindowerEvents.TargetIndexChanged:addAction(function(mob_id)
        local character=windower.ffxi.get_player()
        if character and character.id==mob_id then observe() end
    end),WindowerEvents.TargetIndexChanged)
    self.timer=Timer.scheduledTimer(.1)
    self.timer:onTimeChange():addAction(observe)
    self.dispose_bag:addAny(L{self.timer})

    local character=windower.ffxi.get_player()
    request_sent=self.cursor_only==true
    packets.inject(packets.new('incoming',0x058,{
        ['Player']=character.id,['Target']=target.id,['Player Index']=character.index,
    }))
    if not self.cursor_only and not self.completed then
        character=windower.ffxi.get_player()
        local switching=character.status==1
        self:log_target(target,switching and 'switch_target' or 'engage')
        request_sent=true
        packets.inject(packets.new('outgoing',0x01A,{
            ['Target']=target.id,['Target Index']=target.index,
            ['Category']=switching and 0x0F or 0x02,['Param']=0,
            ['X Offset']=0,['Z Offset']=0,['Y Offset']=0,
        }))
    end
    if not self.completed then observe() end
    if not self.completed then self.timer:start() end
end

function EngageAction:log_target(target, action)
    local MobFilter = require('cylibs/battle/monsters/mob_filter')
    local PartyClaimedCondition = require('cylibs/conditions/party_claimed')

    local mob_filter = MobFilter.new(player.alliance, 25)
    local aggroed_mobs = mob_filter:get_nearby_mobs(L{ MobFilter.Type.PartyClaimed }):filter(function(mob)
        return mob.hpp > 0 and not L{ 2, 3 }:contains(mob.status) and mob.index ~= target.index
    end)

    logger.notice('EngageAction', 'perform', action, 'num_party_aggroed_mobs', aggroed_mobs:length() or 0)

    for mob in aggroed_mobs:it() do
        logger.notice('EngageAction', 'perform', action, 'party_aggroed_mobs', mob.name, mob.hpp, mob.status, mob.claim_id, mob.index, Condition.check_conditions(L{ PartyClaimedCondition.new(true) }, mob.index))
    end

    if windower.ffxi.get_player().target_index then
        local current_mob = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index)
        if current_mob then
            logger.notice('EngageAction', 'perform', action, player.status, 'current', current_mob.name, current_mob.index, current_mob.hpp, current_mob.status, current_mob.claim_id or 'unclaimed', current_mob.distance:sqrt(),
                    'new', target.name, target.index, target.hpp, target.status, target.claim_id or 'unclaimed', target.distance:sqrt())
        end
        if player.status == 'Engaged' and windower.ffxi.get_player().target_index ~= self.target_index then
            logger.error('EngageAction', 'perform', action, 'engaged to', windower.ffxi.get_player().target_index or 'none', 'but trying to engage', self.target_index or 'none')
        end
    end
end

function EngageAction:gettype()
    return "engageaction"
end

function EngageAction:getrawdata()
    local res = {}
    return res
end

function EngageAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if self.cursor_only then
        return 'Targeting → '..target.name
    else
        return 'Engaging → '..target.name
    end
end

function EngageAction:debug_string()
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    return "EngageAction: %s (%d)":format(mob.name, mob.id)
end

return EngageAction



