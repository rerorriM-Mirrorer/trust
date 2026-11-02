-- Execute the production coordinated commands, with an IPC bus and two clients.
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function methods(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 assert(load(s:sub(a,b-1),'production commands','t',env))()
end
string.color=function(s,c)return '['..c..']'..s end
local Feedback=require('cylibs/util/command_feedback')
local methodsTable={};local current,receiving,mode='Cioara',false,'All'
local messages,acks={},{}
local clients={}
local function list(values)return{it=function()local i=0;return function()i=i+1;return values[i]end end}end
local env=setmetatable({GeneralTrustCommands=methodsTable,select=select,
 state={IpcMode={value='All'}},
 party_util={get_party_member_names=function()return list({'Cioara','Myrr','Myrr','','Bad;command'})end},
 windower={ffxi={get_player=function()return{name=current}end},add_to_chat=function(c,s)assert(c==0);acks[#acks+1]=s end},
 CommandMessage={new=function(c,n)return{command=c,target=n}end},
 IpcRelay={shared=function()return{send_message=function(_,m)assert(not receiving,'receiver rebroadcast');messages[#messages+1]=m end}end},
 require=function(n)if n=='cylibs/util/command_feedback' then return Feedback elseif n=='chat' then return{} end error(n)end,
 shortcuts={},
},{__index=_G})
methods('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_party_request','-- // trust startall',env)
methods('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_stop(_,','-- // trust stopall',env)
for _,name in ipairs({'Cioara','Myrr'})do
 local c={name=name,enabled=false,changes=0,assist='Other',follow='Other',followChanges=0,canFollow=true}
 c.addon_enabled={getValue=function()return c.enabled end,setValue=function(_,v)c.enabled=v;c.changes=c.changes+1 end}
 c.trust={get_party=function()return{get_party_member_named=function(_,n)return (n=='Cioara' or n=='Myrr') and {} end}end}
 c.follower={get_follow_target=function()return c.follow end,set_follow_target=function(_,t)c.follow=t end}
 clients[name]=setmetatable(c,{__index=methodsTable})
end
local function use(name)
 current=name;local c=clients[name]
 env.shortcuts.assist={handle_assist_player=function(_,n)assert(Feedback.is_quiet());c.assist=n;return true end}
 env.shortcuts.follow={get_follower=function()return c.follower end,handle_follow_party_member=function(_,n)
  assert(Feedback.is_quiet());if not c.canFollow then return false,'Follow leader unavailable' end
  if c.follow~=n then c.followChanges=c.followChanges+1;c.follow=n end;return true
 end}
 return c
end
local c=use('Cioara');assert(c:handle_ready('ready'))
assert(not c.enabled and c.assist=='Cioara' and c.changes==0,'Ready started its initiating client')
assert(#messages==1 and messages[1].target=='Myrr' and messages[1].command=='trust partyrequest ready Cioara')
assert(#acks==1 and acks[1]:find('[167]Party standing ready',1,true) and acks[1]:find('unconfirmed',1,true))
local m=use('Myrr');receiving=true;assert(m:handle_party_request('partyrequest','ready','Cioara'));receiving=false
assert(m.enabled and m.assist=='Cioara' and #acks==1)
local changes=m.changes;receiving=true;assert(m:handle_party_request('partyrequest','ready','Cioara'));receiving=false
assert(m.changes==changes,'repeated Start fired relay')
use('Cioara');assert(c:handle_standdown('standdown'));assert(not c.enabled and c.follow==nil)
use('Myrr');receiving=true;assert(m:handle_party_request('partyrequest','standdown','Cioara'));receiving=false
assert(not m.enabled and m.follow=='Cioara')
local walks=m.followChanges;changes=m.changes
receiving=true;assert(m:handle_party_request('partyrequest','standdown','Cioara'));receiving=false
assert(m.followChanges==walks and m.changes==changes,'repeat Standdown disrupted following')
assert(#acks==2 and acks[2]:find('Party standing down',1,true))
assert(not m:handle_party_request('partyrequest','ready','Bad;command'))
assert(not m:handle_party_request('partyrequest','ready','Outsider'))
assert(not m:handle_party_request('partyrequest','ready','Cioara','extra'))
m.enabled=true;m.canFollow=false
local ok,message=m:handle_party_request('partyrequest','standdown','Cioara')
assert(not ok and not m.enabled and message:find('Trust stopped',1,true),'failed follow must not leave actions running')
use('Cioara');env.state.IpcMode.value='Receive';local count=#messages
assert(not c:handle_ready('ready'));assert(#messages==count and #acks==2)
assert(not c:handle_ready('ready','extra') and not c:handle_standdown('standdown','extra'))
assert(not Feedback.is_quiet(),'feedback scope leaked')
-- Ready preserves both possible initiating states, without firing its relay.
env.state.IpcMode.value='All';use('Cioara')
local localChanges=c.changes;c.enabled=true;assert(c:handle_ready('ready'))
assert(c.enabled and c.changes==localChanges)
c.enabled=false;assert(c:handle_ready('ready'));assert(not c.enabled and c.changes==localChanges)

-- Real Follow handler must not reset a live destination/formation on same leader.
local FollowTrustCommands={};local resets,starts,sets=0,0,0
local followenv=setmetatable({FollowTrustCommands=FollowTrustCommands,state={AutoFollowMode={value='Always'}},
 command_feedback=Feedback,require=function()return{reset=function()resets=resets+1 end}end},{__index=_G})
methods('commands/FollowCommands.lua','function FollowTrustCommands:handle_follow_party_member','-- // trust follow distance',followenv)
local follower={manual_pause=false,recovery_paused=false,is_valid_target=function()return true end,
 get_follow_target=function()return{get_name=function()return'Cioara'end}end,
 follow_target_named=function()starts=starts+1 end}
local f=setmetatable({get_follower=function()return follower end,handle_set_mode=function()sets=sets+1 end},{__index=FollowTrustCommands})
assert(f:handle_follow_party_member('Cioara'));assert(resets==0 and starts==0 and sets==0)
follower.manual_pause=true;assert(f:handle_follow_party_member('Cioara'));assert(starts==1 and resets==1 and sets==1 and not follower.manual_pause)
local Policy=require('cylibs/ui/menu/menu_command_policy')
for _,command in ipairs({'ready','standdown','partyrequest'})do assert(Policy.effect(command,{})=='immediate') end
print('PASS production Ready/Standdown IPC ordering/scope, single request acknowledgment, invalid/partial failure, repeated Start/Follow state preservation')

-- Actual bare-command routing and travel: release even when already stopped,
-- send quietly, acknowledge once, preserve named Follow Me path.
local travelCalls={};local function call(v)travelCalls[#travelCalls+1]=v end
string.color=function(s)return s end
followenv.handle_stop=function(manual)assert(manual);call('stop')end
followenv.state.IpcMode={value='All'}
followenv.windower={ffxi={follow=function()call('unfollow')end,run=function(v)assert(v==false);call('run off')end},
 add_to_chat=function(_,s)assert(s:find('requested',1,true));call('ack')end}
followenv.require=function(n)if n=='chat' then return{} end return{reset=function()end}end
methods('commands/FollowCommands.lua','function FollowTrustCommands:handle_travel()','-- // trust follow me',followenv)
f.handle_follow_me=function()assert(Feedback.is_quiet());call('request');return true end
assert(f:handle_follow_party_member(nil));assert(table.concat(travelCalls,',')=='stop,unfollow,run off,request,ack')
travelCalls={};assert(f:handle_travel());assert(#travelCalls==5,'already-stopped release skipped')
followenv.state.IpcMode.value='Receive';travelCalls={};assert(not f:handle_travel());assert(#travelCalls==0)
print('PASS bare travel route, explicit local release, quiet Follow Me request, one acknowledgment and IPC guard')
