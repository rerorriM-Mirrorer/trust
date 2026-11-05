-- A: a bounded pull owns approach until claim. Spell pulls cast first
-- so drawing weapons cannot compete with the opening spell.
local Action=require('cylibs/actions/action')
local Timer=require('cylibs/util/timers/timer')
local Engage=require('cylibs/actions/engage')
local Recovery=require('cylibs/movement/recovery')
local clock=require('socket').gettime
local Pull=setmetatable({}, {__index=Action})
Pull.__index=Pull
Pull.__type='PullAttempt'
function Pull.new(options)
    local self=setmetatable(Action.new(0,0,0,options.index),Pull)
    self.options=options;self.priority=ActionPriority.high
    self.identifier='puller_action';self.recovery_timeout=45
    self.display_name='Pulling '..options.name..' with '..options.ability:get_name()
    return self
end
function Pull:gettype()return 'pullattempt' end
function Pull:tostring()return self.display_name end
function Pull:note(reason, diagnostic)
    if self.reason==reason then return end
    self.reason=reason;self.options.report(reason, diagnostic)
end
function Pull:stop_motion()
    windower.ffxi.follow();windower.ffxi.run(false);self.moving=false
end
function Pull:finish(success,reason,diagnostic)
    if self.completed then return end
    self:note(reason,diagnostic);self:stop_motion()
    if self.options.queue.pull_action==self then self.options.queue.pull_action=nil end
    self.options.finished(success)
    if self.timer then self.timer:cancel() end
    self:complete(success)
end
function Pull:perform()
    self.started=clock();self.options.queue.pull_action=self
    self.options.start()
    self.timer=Timer.scheduledTimer(.1)
    self.timer:onTimeChange():addAction(function()self:step()end)
    self.timer:start();self:step()
end
function Pull:step()
    if self.completed or self.cancelled then return end
    local o=self.options;local now=clock()
    local mob=windower.ffxi.get_mob_by_index(self.target_index)
    if not mob or mob.id~=o.id or mob.hpp<=0 or not o.active() or Recovery.is_skipped(o.id) then
        self:finish(false,'pull cancelled: target or mode changed');return
    end
    if now-self.started>45 then self:finish(false,'pull timed out');return end
    -- Do not interrupt a running cast/ability. Higher-priority healing can
    -- preempt approach/settling immediately and the next attempt rechecks state.
    if not self.child then
        for queued in o.queue.queue:it() do
            if queued:getpriority()>self.priority then
                self:finish(false,'yielding to higher-priority action');return
            end
        end
    end
    local claimed=o.claimed(mob)
    if mob.claim_id and mob.claim_id~=0 and not claimed then
        self:finish(false,'target claimed by another party');return
    end
    if claimed and not self.child then
        if not Recovery.suspended() then self:engage(mob,now) end
        self:finish(true,'party claim confirmed; combat takes over');return
    end
    if self.child then
        self:note('performing '..o.ability:get_name());return
    end
    if self.await_claim then
        self:note('confirming party claim')
        if now-self.await_claim>2 then self:finish(false,'claim not confirmed; reassessing') end
        return
    end
    local blocked, blocker = Recovery.suspended()
    if blocked then
        if self.moving then self:stop_motion() end
        self.blocked_since = self.blocked_since or now
        local detail = string.format('%s (%.1fy away, %.1fy pull range)', blocker or 'unknown readiness blocker',
            math.sqrt(mob.distance), o.range)
        if now - self.blocked_since >= 3 then
            self:finish(false, 'pull released after 3s blocked: '..(blocker or 'unknown readiness blocker'), detail)
        else
            self:note('waiting: '..(blocker or 'unknown readiness blocker'), detail)
        end
        return
    end
    self.blocked_since = nil
    if not o.eligible() then self:finish(false,'pull action no longer available');return end
    if o.melee then self:engage(mob,now) end
    local distance=math.sqrt(mob.distance)
    if distance>o.range then
        self.settled=nil
        self:note('approaching '..o.ability:get_name()..' range')
        local p=windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
        if not p then self:finish(false,'player unavailable');return end
        if Recovery.step(self,{p.x,p.y,p.z},{mob.x,mob.y,mob.z},o.range) then return end
        windower.ffxi.follow()
        windower.ffxi.run(-math.atan2(mob.y-p.y,mob.x-p.x))
        self.moving=true;return
    end
    if self.moving then self:stop_motion() end
    self.settled=self.settled or now
    if o.melee then
        self:note('in melee range; waiting for claim');return
    end
    if os.clock()<(o.queue.forced_delay_time or 0) then
        self:note('waiting for action recovery');return
    end
    if not o.ready() then
        self:note('waiting for '..o.ability:get_name()..' readiness')
        if now-self.settled>8 then self:finish(false,'action readiness timed out') end
        return
    end
    if now<(self.retry_at or 0) then return end
    local child=o.ability:to_action(self.target_index,o.player,nil,true)
    if not child then self:finish(false,'pull action could not be created');return end
    Recovery.tag(child,'pulling',o.id,nil,self)
    if not child:can_perform() then
        child:destroy();self.retry_at=now+.5
        self:note('waiting for action prerequisites')
        if now-self.settled>8 then self:finish(false,'action prerequisites timed out') end
        return
    end
    self.child=child
    child:on_action_complete():addAction(function(a,success)
        self.child=nil;a:destroy()
        if self.cancelled or self.completed then return end
        if not success then self:finish(false,'pull action failed; reassessing')
        else self:note('action completed; confirming claim');self.await_claim=clock() end
    end)
    require('cylibs/util/player_util').face(mob)
    child:set_start_time(os.time());self:note('performing '..o.ability:get_name())
    child:perform()
end
function Pull:engage(mob,now)
    local p=windower.ffxi.get_player()
    if p.status==1 and p.target_index==mob.index then return end
    if self.engagement or now<(self.engage_retry or 0) or math.sqrt(mob.distance)>29 then return end
    local action=Engage.new(mob.index)
    if not action:can_perform() then action:destroy();return end
    self.engagement=action
    action:on_action_complete():addAction(function(a)
        self.engagement=nil;self.engage_retry=clock()+2;a:destroy()
    end)
    action:perform()
end
function Pull:cancel()
    self.cancelled=true
    if self.child then self.child:cancel() end
    self:finish(false,'pull stopped')
end
function Pull:destroy()
    if self.timer then self.timer:destroy() end
    if self.child then self.child:destroy();self.child=nil end
    if self.engagement then self.engagement:destroy();self.engagement=nil end
    if self.options.queue.pull_action==self then self.options.queue.pull_action=nil end
    Action.destroy(self)
end
return Pull
