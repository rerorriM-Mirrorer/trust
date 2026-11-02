-- Production Approach chain, engagement state machine and explicit name matching.
L=function(t)return setmetatable(t or {},{__index={append=function(s,v)s[#s+1]=v end,it=function(s)local i=0;return function()i=i+1;return s[i]end end}})end
debug.setmetatable(0,{__index={sqrt=math.sqrt}})
local function method(path,first,last,env)
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 assert(load(s:sub(a,b-1),'actual production methods','t',setmetatable(env,{__index=_G})))()
end
local Approach={};local distance=100
local env={Approach=Approach,windower={ffxi={get_mob_by_index=function()return{distance=distance,name='Test'}end}},
 RunToAction={new=function(i,r)return{kind='run',index=i,radius=r}end},
 EngageAction={new=function(i)return{kind='engage',index=i}end},
 FollowAction={new=function(i)return{kind='follow',index=i}end},ClaimedCondition={new=function()return{}end},
 WaitAction={new=function()error('fixed Approach wait returned')end},
 SequenceAction={new=function(actions)return{actions=actions}end}}
method('cylibs/battle/approach.lua','function Approach:to_action','function Approach:serialize',env)
local a=Approach.to_action({__class='Approach'},2);assert(#a.actions==2 and a.actions[1].kind=='engage' and a.actions[2].kind=='follow')
distance=1600;a=Approach.to_action({__class='Approach'},2);assert(#a.actions==3 and a.actions[1].kind=='run' and a.actions[1].radius==25)
local state={id=1,index=1,status=1,target_index=2,target_locked=false};local callbacks={};local tick;local packets={};local started=0
local target={id=42,index=2};local now=0;local explicitLock=false;local lockCount=0
local packetModule={new=function(direction,id,fields)return{direction=direction,id=id,fields=fields}end,
 inject=function(p)
  packets[#packets+1]=p
  -- Incoming selection can fire synchronously, before the battle request.
  if p.direction=='incoming' then state.target_index=2;if callbacks.target then callbacks.target(1,2)end end
 end}
package.loaded['packets']=packetModule
package.loaded['cylibs/actions/action']={can_perform=function(s)return not s.cancelled end}
for _,name in ipairs({'cylibs/util/alter_ego_util','cylibs/conditions/claimed','cylibs/conditions/conditional','cylibs/conditions/unclaimed'})do package.loaded[name]={}end
package.loaded['cylibs/events/dispose_bag']={}
package.loaded['cylibs/util/timers/timer']={scheduledTimer=function()return{onTimeChange=function()return{addAction=function(_,fn)tick=fn end}end,start=function()started=started+1 end}end}
package.loaded['cylibs/movement/recovery']={is_skipped=function()return false end}
windower={ffxi={get_player=function()return state end,get_mob_by_index=function()return target end},send_command=function()lockCount=lockCount+1 end}
addon_settings={getSettings=function()return{movement={auto_lockon=explicitLock}}end}
WindowerEvents={TargetIndexChanged={addAction=function(_,fn)callbacks.target=fn end}}
local E=require('cylibs/actions/engage')
local real_time=os.time;os.time=function()return now end
local function action(cursor)
 return setmetatable({target_index=2,cursor_only=cursor,dispose_bag={add=function()end,addAny=function()end},
 is_cancelled=function(s)return s.cancelled end,complete=function(s,ok)s.completed=true;s.success=ok end,log_target=function()end},{__index=E})
end
local same=action();same:perform();assert(same.success and #packets==0 and started==0 and lockCount==0)
-- Correct selected cursor while idle does not mean engagement completed.
state.status=0;local idle=action();idle:perform();assert(not idle.completed and packets[#packets].fields.Category==2)
state.status=1;tick();assert(idle.success)
-- Incoming selection alone must not suppress the outgoing switch request.
packets={};state.target_index=3;local switch=action();switch:perform()
assert(#packets==2 and packets[2].fields.Category==15 and switch.success)
-- Selection-only action neither attacks nor requests automatic lock-on.
packets={};state.status=0;state.target_index=3;local cursor=action(true);cursor:perform()
assert(cursor.success and #packets==1)
-- Invalid/lost targets and absent acknowledgement fail in finite time.
state.target_index=3;state.status=0;local waiting=action();waiting:perform();now=6;tick();assert(waiting.completed and waiting.success==false)
local cancelled=action();cancelled.cancelled=true;packets={};cancelled:perform();assert(not cancelled.success and #packets==0)
explicitLock=true;state.status=1;state.target_index=2;local locked=action();locked:perform();assert(locked.success and lockCount==1)
os.time=real_time
local match=require('cylibs/util/name_match')
assert(match.contains(L{'Goblin Weaver'},'gObLiN wEaVeR'))
assert(match.index_of(L{'Crab','Goblin Weaver'},'goblin weaver')==2)
assert(not match.contains(L{'Goblin'},'Goblin Weaver') and not match.contains(L{'Goblin.*'},'Goblin Weaver'))
local TargetNames={};local mob={name='Goblin Weaver'}
method('cylibs/conditions/target_names.lua','function TargetNamesCondition:is_satisfied','function TargetNamesCondition:tostring',
 {TargetNamesCondition=TargetNames,windower={ffxi={get_mob_by_index=function()return mob end}}})
assert(TargetNames.is_satisfied({names=L{'goblin weaver'}},2))
print('PASS immediate Approach, idempotent engage, subscription-before-request race, status confirmation, timeout/cancel and case-insensitive literal names')
