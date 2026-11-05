-- Production pull state machine with game/event doubles; no native delivery claim.
local function event()
 local e={callbacks={}}
 function e:addAction(fn)self.callbacks[#self.callbacks+1]=fn end
 function e:trigger(...)local c={table.unpack(self.callbacks)};for _,fn in ipairs(c)do fn(...)end end
 function e:removeAllActions()self.callbacks={}end
 return e
end
local list={};function list:it()local i=0;return function()i=i+1;return self[i]end end
L=function(t)return setmetatable(t or {},{__index=list})end
ActionPriority={high=3,default=1}
local A={}
function A.new(_,_,_,index)return{target_index=index,event=event()}end
function A:on_action_complete()return self.event end
function A:complete(ok)if self.completed then return end;self.completed=true;self.success=ok;self.event:trigger(self,ok)end
function A:destroy()self.is_destroyed=true;self.event:removeAllActions()end
function A:getpriority()return self.priority end
package.loaded['cylibs/actions/action']=A
local now,blocked,skipped,claimed,active,eligible,ready=100,false,false,false,true,true,true
local char={id=1,index=1,status=1,target_index=2}
local mob={id=20,index=2,hpp=100,claim_id=0,distance=40^2,x=40,y=0,z=0}
local p={x=0,y=0,z=0}
local runs,engages,created,finished,notes={},0,0,{},{}
windower={ffxi={get_player=function()return char end,get_mob_by_index=function()return mob end,
 get_mob_by_id=function()return p end,follow=function()end,run=function(v)runs[#runs+1]=v end}}
package.loaded['cylibs/util/player_util']={face=function()end}
package.loaded.socket={gettime=function()return now end}
package.loaded['cylibs/util/timers/timer']={scheduledTimer=function()return{onTimeChange=function()return event()end,start=function()end,cancel=function()end,destroy=function()end}end}
package.loaded['cylibs/movement/recovery']={suspended=function()return blocked end,is_skipped=function()return skipped end,
 step=function()return false end,tag=function()end}
package.loaded['cylibs/actions/engage']={new=function()
 return{can_perform=function()return true end,on_action_complete=function()return event()end,
 perform=function()engages=engages+1 end,destroy=function()end}
end}
local children={}
local ability={get_name=function()return 'Dia'end,to_action=function(_,index,player,jobs,pulling)
 assert(index==2 and pulling==true);created=created+1
 local c=setmetatable(A.new(0,0,0,index),{__index=A})
 c.can_perform=function()return true end;c.perform=function()end;c.set_start_time=function()end
 c.cancel=function(self)self.cancelled=true;self:complete(false)end
 children[#children+1]=c;return c
end}
local Pull=require('cylibs/actions/pull_attempt')
local function new(melee)
 local queue={queue=L{},forced_delay_time=0}
 local o={queue=queue,index=2,id=20,name='Crab',ability=ability,range=melee and 2 or 19.5,melee=melee,
 active=function()return active end,eligible=function()return eligible end,ready=function()return ready end,
 claimed=function()return claimed end,start=function()end,report=function(s)notes[#notes+1]=s end,
 finished=function(ok)finished[#finished+1]=ok end}
 return Pull.new(o),queue
end
local a,q=new();a:perform();assert(type(runs[#runs])=='number' and not a.completed and q.pull_action==a)
assert(engages==0,'far target must move before engage request')
mob.distance=23.7^2;char.status=0;a:step();assert(engages==0 and type(runs[#runs])=='number' and created==0)
-- Spell pulling approaches without requesting engagement before Dia.
mob.distance=19^2;ready=false;now=101;a:step();assert(runs[#runs]==false and created==0)
ready=true;a:step();assert(created==1 and a.child==children[1])
-- Claim during casting must not interrupt the running action.
claimed=true;mob.claim_id=1;a:step();assert(not a.completed)
children[1]:complete(true);a:step();assert(a.success and not q.pull_action and runs[#runs]==false)
a:destroy()
-- A failed action is released for reassessment; no next action starts on cancel.
claimed=false;mob.claim_id=0;char.status=1;mob.distance=10^2
local b=new();b:perform();assert(b.child);b:cancel();assert(b.completed and not b.success and not b.child)
local count=created;b:step();assert(created==count)
-- Higher-priority healing yields approach promptly; ordinary work does not.
mob.distance=30^2;local c,cq=new();c:perform();cq.queue=L{{getpriority=function()return 999 end}};c:step();assert(c.completed and not c.success)
local d,dq=new();d:perform();dq.queue=L{{getpriority=function()return 1 end}};d:step();assert(not d.completed)
blocked=true;d:step();assert(runs[#runs]==false)
now=now+3;d:step();assert(d.completed and not dq.pull_action)
assert(notes[#notes]:find('pull released after 3s blocked',1,true))
blocked=false
mob.distance=9^2
local near=new();blocked=true;near:perform();assert(not near.child)
blocked=false;now=now+0.5;near:step();assert(near.child,'Dia should cast immediately when a brief blocker clears')
near:cancel()
active=false;d:step();assert(d.completed);active=true
-- Melee approach remains active until claim, never creates a spell child.
char.status=1;char.target_index=2;mob.distance=1.5^2;local e=new(true);count=created;e:perform();assert(not e.completed and created==count)
claimed=true;mob.claim_id=1;e:step();assert(e.success)
-- Invalid identity/foreign claim/timeout cannot retain movement ownership.
claimed=false;mob.claim_id=99;local f,fq=new();f:perform();assert(f.completed and not f.success and not fq.pull_action)
mob.claim_id=0;mob.distance=35^2;local g=new();g:perform();now=now+46;g:step();assert(g.completed and not g.success)
-- Existing post-action recovery is observed before starting a new cast.
now=200;mob.distance=10^2;local h,hq=new();hq.forced_delay_time=os.clock()+10;count=created;h:perform();assert(created==count);hq.forced_delay_time=0;h:step();assert(created==count+1)
h:cancel()
print('PASS actual pull lifecycle: range/engage concurrency, cast/claim handoff, Stop, priority, guards, foreign claim, timeout and action recovery')
