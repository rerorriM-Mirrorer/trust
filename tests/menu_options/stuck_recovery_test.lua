local Detector=require('cylibs/movement/stuck_detector')
local now=0;local clock=function()return now end
local settings={mode='Detour',interval=2,min_movement=.5,detour_distance=2,attempts=2}
local d=Detector.new(clock)
local function tick(pos,goal,blocked)
    now=now+.1;return d:sample('mob',pos or {0,0,0},goal or {10,0,0},1,settings,blocked)
end
for i=1,20 do assert(tick()=='normal') end
local decision,offset,started=tick();assert(decision=='detour' and started and offset[2]>0)
-- Reaching a detour returns to the current goal, retaining the attempt budget.
assert(tick(offset)=='normal')
for i=1,20 do decision,offset,started=tick({.65,1.88,0}) end
if decision~='detour' then decision,offset,started=tick({.65,1.88,0}) end
assert(decision=='detour' and d.context.attempts==2)
-- Immovable offset times out, retries the original, and eventually gives up.
for i=1,45 do decision=tick({.65,1.88,0}) end
assert(decision=='failed')
d:reset();now=100
for i=1,100 do assert(tick({i*.1,0,0},{100+i*.2,0,0})=='normal') end
-- Moving goal doesn't hide lack of displacement.
d:reset();for i=1,23 do decision=tick({0,0,0},{10+i*.2,0,0}) end
assert(decision=='detour')
-- Casting/menu time neither counts as stuck nor runs a detour.
for i=1,40 do assert(tick(nil,nil,true)=='hold') end
assert(tick()=='normal')
-- Gaps between movement requests are excluded.
d:reset();tick();now=now+10;assert(tick()=='normal')
settings.mode='Pause';d:reset();for i=1,22 do decision=tick() end;assert(decision=='failed')
settings.mode='Off';assert(tick()=='normal' and d.context==nil)
settings.mode='Detour';assert(d:sample('near',{9.5,0,0},{10,0,0},1,settings,false)=='normal')
print('PASS detector: progress, moving goals, finite alternating offsets/timeouts, pause, guards, inactivity and arrival')

-- Exercise the actual adapter and its zone-local temporary skip authority.
package.preload['socket']=function()return{gettime=clock}end
local config={mode='Pause',interval=.5,min_movement=.5,detour_distance=2,attempts=2,pull_cooldown=5,diagnostics=false}
addon_settings={getSettings=function()return{movement={recovery=config}}end}
local position={x=0,y=0,z=0,id=1};local goal={x=10,y=0,z=0,id=42}
local character={id=1,status=0,target_index=2,buffs={}}
local info={zone=100,logged_in=true};local runs,follows,cancelled=0,0,0
windower={ffxi={get_info=function()return info end,get_player=function()return character end,
 get_mob_by_id=function(id)return id==1 and position or goal end,
 get_mob_by_index=function()return goal end,
 follow=function()follows=follows+1 end,run=function()runs=runs+1 end},send_command=function()end}
local messages={};addon_system_message=function(t)messages[#messages+1]=t end
local R=require('cylibs/movement/recovery')
local function action()
 return {is_cancelled=function(s)return s.cancelled end,cancel=function(s)s.cancelled=true;cancelled=cancelled+1 end}
end
local a=action();R.tag(a,'pulling',42)
for i=1,8 do now=now+.1;R.step(a,{0,0,0},{10,0,0},1) end
assert(a.cancelled and R.is_skipped(42) and cancelled==1 and #messages==1)
for i=1,5 do now=now+.1;R.step(a,{0,0,0},{10,0,0},1) end
assert(cancelled==1 and #messages==1,'failure must not report/cancel repeatedly')
info.zone=101;assert(not R.is_skipped(42));info.zone=100;assert(R.is_skipped(42))
now=now+6;assert(not R.is_skipped(42),'cooldown must expire')
local b=action();R.tag(b,'pulling',42);assert(not R.step(b,{0,0,0},{10,0,0},1),'expiry must permit a fresh observation window')
-- Off and individual scope switches bypass steering and exclusions.
config.mode='Off';assert(not R.step(b,{0,0,0},{10,0,0},1))
config.mode='Detour';config.pulling=false;assert(not R.step(b,{0,0,0},{10,0,0},1));config.pulling=true
R.reset();character.status=4;assert(R.step(b,{0,0,0},{10,0,0},1));character.status=0
-- A paused follower keeps its target, disables walking, and is cancelled once.
config.mode='Pause';R.reset();local stopped=0
local follower={stop_following=function()stopped=stopped+1 end}
player={trust={main_job={role_with_type=function()return follower end}}}
local f=action();R.tag(f,'paths',nil,'waypoint:7')
for i=1,8 do now=now+.1;R.step(f,{0,0,0},{10,0,0},1) end
assert(f.cancelled and follower.recovery_paused and stopped==1)
-- Recursive tags preserve one root owner across nested sequences.
local child=action();local root=action();root.queue={it=function()local done=false;return function()if not done then done=true;return child end end end}
R.tag(root,'pulling',42);assert(child.recovery.root==root and child.recovery.id==42)
print('PASS adapter: local ID/zone cooldown, expiry, cancellation, scope/Off bypass, event guard and retained path pause')
-- Engaged failure disengages immediately through the existing action, before
-- root cancellation can expose the next action. Guards share the ID cooldown.
local order={}
package.loaded['cylibs/actions/disengage']={new=function()return{
 perform=function()order[#order+1]='disengage'end,destroy=function()end}end}
R.reset(true);character.status=1;config.mode='Pause'
local engaged=action();engaged.cancel=function(s)s.cancelled=true;order[#order+1]='cancel'end
R.tag(engaged,'pulling',42)
for i=1,8 do now=now+.1;R.step(engaged,{0,0,0},{10,0,0},1)end
assert(table.concat(order,',')=='disengage,cancel' and R.is_skipped(42))
local function method(path,first,last,env)
 local file=assert(io.open(path));local s=file:read('*a');file:close()
 local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 assert(load(s:sub(a,b-1),'actual recovery exclusion gate','t',setmetatable(env,{__index=_G})))()
end
local Puller={};method('cylibs/trust/roles/puller.lua','function Puller:is_valid_target','function Puller:get_pull_target', {Puller=Puller})
assert(Puller.is_valid_target({},goal)==false)
local EngageAction={};method('cylibs/actions/engage.lua','function EngageAction:can_perform()','function EngageAction:perform()',
 {EngageAction=EngageAction,Action={can_perform=function()error('blocked engagement reached base performer')end}})
assert(not EngageAction.can_perform({target_index=2}))
local Gambiter={};method('cylibs/trust/roles/gambiter.lua','function Gambiter:perform_gambit','function Gambiter:allows_duplicates',
 {Gambiter=Gambiter,logger={isEnabled=false}})
Gambiter.perform_gambit({},nil,{get_mob=function()return goal end}) -- must return before ability access
-- Fresh tag grants enough action lifetime for the configured finite attempts.
config.mode='Detour';local timed=action();timed.gettype=function()return'followaction'end
R.tag(timed,'pulling',43);assert(timed.recovery_timeout>=12)
-- Player spell event binding suspends the detector and is disposed on rebind.
local callbacks={};local disposed=0
package.loaded['cylibs/events/dispose_bag']={new=function()return{add=function()end,destroy=function()disposed=disposed+1 end}end}
local actor={}
for _,name in ipairs({'on_spell_begin','on_spell_finish','on_spell_finish_no_effect','on_spell_interrupted','on_unable_to_cast'})do
 actor[name]=function()return{addAction=function(_,fn)callbacks[name]=fn end}end
end
R.bind(actor);callbacks.on_spell_begin();assert(R.casting_until>now)
callbacks.on_spell_interrupted();assert(R.casting_until==0)
callbacks.on_spell_begin();callbacks.on_spell_finish();assert(R.casting_until==0)
R.bind(actor);assert(disposed==1);R.close();assert(disposed==2 and not R.is_skipped(42))
print('PASS engaged failure ordering, actual pull/engage/gambit exclusion gates, action timeout budget and spell-event lifecycle')

-- Verbose messages show detour/retry transitions; Off keeps them quiet.
config.mode='Detour';config.verbose=true;config.diagnostics=false;character.status=0;R.reset(true)
local startMessages=#messages;local trial=action();R.tag(trial,'pulling',43)
for i=1,30 do now=now+.1;R.step(trial,{0,0,0},{10,0,0},1)end
assert(#messages>=startMessages+2 and messages[startMessages+1]:find('detour',1,true))
assert(messages[startMessages+2]:find('retrying original',1,true))
config.verbose=false;R.reset(true);trial=action();R.tag(trial,'pulling',44)
startMessages=#messages
for i=1,8 do now=now+.1;R.step(trial,{0,0,0},{10,0,0},1)end
assert(#messages==startMessages)
local originalColor=string.color;local colored
string.color=function(s,n)return '<'..n..'>'..s end
windower.add_to_chat=function(mode,text)assert(mode==0);colored=text end
require('cylibs/ui/chat/status_message').show('Recovery','path detour')
assert(colored=='<200>[Trust] <167>Recovery <200>-> <0>path detour')
string.color=originalColor
print('PASS verbose detour/retry messages, opt-out and BattleStations fragment colors')

-- Idle follow ignores input overlays and honors the existing cast pause setting.
local follow_settings={auto_pause=false}
addon_settings.getSettings=function()return{movement={recovery=config},follow=follow_settings}end
character.status=0;character.buffs={}
info.chat_open=true
assert(not R.suspended(true,true))
assert(R.suspended(false,false))
info.chat_open=false
hud={trustMenu={isVisible=function()return true end}}
assert(not R.suspended(true,true))
assert(R.suspended(false,false))
hud=nil
R.casting_until=now+10
assert(not R.suspended(true,true))
follow_settings.auto_pause=true
assert(R.suspended(true,true))
follow_settings.auto_pause=false
assert(R.suspended(false,false))
character.status=1
assert(R.suspended(true,true))
R.casting_until=0
character.status=0
print('PASS idle follow chat/menu bypass and opt-in casting pause with other movement guards retained')
