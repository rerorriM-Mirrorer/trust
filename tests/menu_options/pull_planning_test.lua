local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local s=source('cylibs/trust/roles/puller.lua')
local methods={};local list={}
function list:it()local i=0;return function()i=i+1;return self[i]end end
function list:filter(fn)local t=L{};for _,v in ipairs(self)do if fn(v)then t[#t+1]=v end end;return t end
L=function(t)return setmetatable(t or {},{__index=list})end
local mode={AutoPullMode={value='All'},PullActionMode={value='Auto'}}
local now,queued,chosen=100,0,nil
local mob={id=20,index=2,name='Crab',distance=40^2};local target={get_mob=function()return mob end}
local captured
local env=setmetatable({Puller=methods,state=mode,
 UnclaimedCondition={new=function()return{is_satisfied=function()return true end}end},
 PartyClaimedCondition={new=function()return{is_satisfied=function()return false end}end},
 player={trust={main_job={role_with_type=function()return nil end}}},
 windower={ffxi={get_mob_by_index=function()return mob end}},
 Gambiter={check_gambits=function()return 'legacy'end},
 require=function(name)
  if name=='socket' then return{gettime=function()return now end}end
  if name=='cylibs/actions/pull_attempt' then return{new=function(o)captured=o;return{getpriority=function()return 3 end}end}end
  if name=='cylibs/movement/recovery' then return{tag=function()end}end
  error(name)
 end},{__index=_G})
for _,name in ipairs({'planning_gambit','check_gambits','queue_pull','get_cooldown'})do
 local body=assert(s:match('(function Puller:'..name..'%(.-)\nfunction Puller:'))
 assert(load(body,'actual '..name,'t',env))()
end
local function condition(kind,editable)
 return{getCondition=function()return{__class=kind}end,is_editable=function()return editable end}
end
local available=true
local ability={__class='Spell',get_range=function()return 20 end,is_valid=function()return available end,
 get_conditions=function()return L{}end}
local dia={conditions=L{condition('IsStandingCondition',false),condition('MaxDistanceCondition',false)},
 getAbility=function()return ability end,isEnabled=function()return true end}
local custom={conditions=L{condition('IsStandingCondition',true)}}
local plan=methods.planning_gambit({},dia);assert(#plan.conditions==1 and #dia.conditions==2)
assert(#methods.planning_gambit({},custom).conditions==1,'explicit user condition lost')
local qlist={}
function qlist:it()local i=0;return function()i=i+1;return self[i]end end
function qlist:push(v)self[#self+1]=v end
env.Q=function()return setmetatable({},{__index=qlist})end
local busy=false
local q={is_enabled=true,max_size=5,current_action=nil,queue=L{},length=function()return 0 end,
 has_action=function()return busy end,push_action=function(_,a)queued=queued+1 end}
local self=setmetatable({action_queue=q,job={},is_enabled=function()return true end,
 get_target=function()return target end,is_valid_target=function()return true end,
 get_action_identifier=function()return 'puller_action'end,get_player=function()return{}end,
 get_all_gambits=function()return L{dia}end,report_pull=function()end,
 is_gambit_satisfied=function(_,g)return #g.conditions==1 end},{__index=methods})
self:check_gambits();assert(queued==1 and captured.range==19.5 and not captured.melee)
assert(captured.eligible() and not captured.ready(),'planning must differ from execution readiness')
assert(self:get_cooldown()==0)
available=false;self:check_gambits();assert(queued==1);available=true
busy=true;self:check_gambits();assert(queued==1);busy=false
self.pull_retry={[20]=102};self:check_gambits();assert(queued==1);now=103;self:check_gambits();assert(queued==2)
-- Full queue: discard only queued lower-priority routine work.
local retired=false
q.max_size=1;q.length=function()return #q.queue end
q.queue=L{{getpriority=function()return 1 end,destroy=function()retired=true end}}
self:check_gambits();assert(retired and #q.queue==0)
local urgent={getpriority=function()return 999 end}
q.queue=L{urgent};self:check_gambits();assert(q.queue[1]==urgent,'urgent action evicted')
mode.PullActionMode.value='Approach';assert(not captured.active(),'queued action survived mode change')
mode.AutoPullMode.value='Aggroed';assert(self:check_gambits()=='legacy')
print('PASS production pull planning/queue wiring: out-of-range Dia, execution readiness, preserved custom conditions, cooldown, duplicates, availability, retry and mode invalidation')
