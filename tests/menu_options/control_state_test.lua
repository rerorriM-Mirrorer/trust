-- Real control transitions and command methods; game/IPC/native actions mocked.
local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function methods(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 assert(load(s:sub(a,b-1),'actual control commands','t',env))()
end
local function list(t)return{it=function()local i=0;return function()i=i+1;return t[i]end end}end
string.color=function(s)return s end
local Control=require('cylibs/trust/control_state')
local Feedback=require('cylibs/util/command_feedback')
local G,F={},{}
local character={name='Cioara',id=1,status=1,main_job_id=15}
local sent,chat,native={}, {}, {}
local changes,stops,starts,clears=0,0,0,0
local q={is_enabled=true,control_state='Active'}
local following='Old';local enabled_value=true
local follower={distance=4,fan_out=true,manual_pause=false,
 get_follow_target=function()return following end,
 set_follow_target=function(_,v)following=v;clears=clears+1 end,
 stop_following=function()stops=stops+1 end,start_following=function()starts=starts+1 end}
local enabled={getValue=function()return enabled_value end,setValue=function(_,v)
 -- Prove the ownership gate was established before cancellation callbacks.
 check(q.control_state==(v and 'Active' or q.control_state),'gate set before relay')
 enabled_value=v;q.is_enabled=v;changes=changes+1
 follower:stop_following();if not follower.manual_pause then follower:start_following()end
end}
local function member(name,id)
 return{get_name=function()return name end,get_id=function()return id end,get_mob=function()return{id=id,hpp=100}end,get_zone_id=function()return 1 end}
end
local cioara,myrr=member('Cioara',1),member('Myrr',2)
local assist,party_leader=myrr,cioara
local party={get_assist_target=function()return assist end,get_party_leader=function()return party_leader end,
 get_player=function()return character.name=='Cioara' and cioara or myrr end,
 get_party_member_named=function(_,n)return n=='Cioara' and cioara or n=='Myrr' and myrr or nil end}
local trust={role_with_type=function(_,kind)if kind=='follower'then return follower end end,get_party=function()return party end}
local env=setmetatable({GeneralTrustCommands=G,Follower=F,Control=Control,
 state={IpcMode={value='All'},AutoFollowMode={value='Always'}},
 party_util={is_alter_ego=function(n)return n=='Shantotto'end,get_party_member_names=function()return list({'Cioara','Myrr','Myrr','Shantotto','Bad;name'})end},
 IpcRelay={shared=function()return{send_message=function(_,m)sent[#sent+1]=m end}end},
 CommandMessage={new=function(c,n)return{command=c,target=n}end},
 windower={ffxi={get_player=function()return character end,get_info=function()return{zone=1}end,get_mob_by_target=function()return{id=5}end,
 follow=function()native[#native+1]='unfollow'end,run=function(v)check(v==false,'release run');native[#native+1]='run off'end},
 send_command=function(c)native[#native+1]=c end,add_to_chat=function(_,s)chat[#chat+1]=s end},
 require=function(n)if n=='cylibs/util/command_feedback'then return Feedback elseif n=='chat'then return{} elseif n=='cylibs/movement/recovery'then return{reset=function()end}end error(n)end,
 shortcuts={follow={get_follower=function()return follower end,handle_follow_party_member=function(_,n)
  if n=='Unavailable'then return false,'not in range'end
  following=n;follower.manual_pause=false;return true
 end}},
},{__index=_G})
methods('commands/GeneralCommands.lua','-- Pause is local','-- // trust reload',env)
methods('commands/GeneralCommands.lua','-- // trust start\n','-- // trust startall',env)
methods('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_party_request','function GeneralTrustCommands:request_party_state',env)
methods('cylibs/trust/roles/follower.lua','function Follower:get_distance()','function Follower:get_conditions()',env)
local c=setmetatable({action_queue=q,addon_enabled=enabled,trust=trust},{__index=G})
check(c:handle_pause() and not enabled_value and q.control_state=='Paused','Pause changes job state')
check(#native==0 and following=='Old' and follower.fan_out,'Pause preserves engagement/follow/preferences')
local before=changes;local beforestops=stops
c:handle_pause();check(changes==before and stops==beforestops,'repeated Pause idempotent')
c:handle_start();check(enabled_value and q.control_state=='Active','Act resumes')
check(c:handle_stop(),'Stop dispatch succeeds')
check(not enabled_value and q.control_state=='Retreat' and following=='Myrr','Stop disables actions and follows assist leader')
check(#sent==1 and sent[1].target=='Myrr' and sent[1].command=='trust partyrequest retreat Myrr','one bounded request; no NPC/duplicate/unrelated recipients')
local found_attack,found_pet=false,false
for _,command in ipairs(native)do found_attack=found_attack or command=='input /attack off';found_pet=found_pet or command=='input /pet "Retreat" <me>' end
check(found_attack and found_pet,'player and avatar disengage requested')
local f=setmetatable({action_queue=q,distance=4},{__index=F})
check(f:get_distance()==0.3 and follower.distance==4,'retreat uses temporary 0.3y without editing saved distance')
local oldclears=clears;c:handle_stop();check(clears==oldclears,'repeat retreat keeps established follow destination')
check(chat[#chat]:find('[Trust] Retreat!',1,true) and chat[#chat]:find('unconfirmed',1,true),'truthful labeled retreat acknowledgment')
-- Receiving anchor applies locally and does not broadcast or follow itself.
character.name='Myrr';character.id=2;local oldsent=#sent
check(c:handle_party_request(nil,'retreat','Myrr'),'anchor accepts retreat')
check(following==nil and #sent==oldsent and not follower.manual_pause,'anchor free to move, no rebroadcast')
check(not c:handle_party_request(nil,'retreat','Outsider'),'nonparty destination rejected')
check(not c:handle_party_request(nil,'retreat','Myrr','extra'),'extra payload rejected')
-- Pause releases retreat without starting combat. Toggle never invokes Stop.
c:handle_pause();check(q.control_state=='Paused' and not enabled_value and f:get_distance()==4,'Pause restores formation distance while keeping job actions paused')
c.handle_stop=function()error('Toggle invoked retreat')end
c:handle_toggle();check(q.control_state=='Active' and enabled_value,'Toggle Paused to Act')
c:handle_toggle();check(q.control_state=='Paused' and not enabled_value,'Toggle Act to Pause')
c.handle_stop=nil
-- Partial destination failure leaves retreat in force, never restores actions.
local ok,message=c:apply_retreat('Unavailable')
check(not ok and message:find('Retreat active',1,true) and q.control_state=='Retreat' and not enabled_value,'failed follow leaves combat stopped')
-- Local-only Stop works with IPC disabled and reports that scope.
character.name='Cioara';character.id=1;character.status=0;env.state.IpcMode.value='Off';oldsent=#sent
check(c:handle_stop() and #sent==oldsent,'IPC Off still retreats locally')
check(chat[#chat]:find('local retreat only',1,true),'IPC Off does not imply remote success')
env.state.IpcMode.value='All';oldsent=#sent
c:handle_all(nil,'pause','party')
check(#sent==oldsent+1 and sent[#sent].command=='trust pause' and sent[#sent].target=='Myrr','Pauseall party scopes/deduplicates without retreat')
check(q.control_state=='Paused','Pauseall stays Pause')
check(not c:handle_stop_all(nil,'everyone'),'invalid Stop scope rejected')
-- Invalid/synthetic assist falls back to party leader, then self.
assist={get_name=function()return'the Party and lock onto the battle target'end,get_mob=function()return nil end}
check(c:get_retreat_leader()=='Cioara','synthetic assist falls back to party leader')
party_leader=false;check(c:get_retreat_leader()=='Cioara','missing leader falls back to current player')
q.control_state='Retreat'
-- Lifecycle guards must not downgrade an established retreat to fanned Pause.
local globals={action_queue=q,handle_pause=function()error('lifecycle released retreat')end}
setmetatable(globals,{__index=_G})
methods('Trust.lua','function handle_stop(cancel_follow)','function handle_tic',globals)
globals.handle_stop();check(q.control_state=='Retreat','lifecycle preserves retreat')
-- Actual path timer callback freezes the waypoint cursor while automation is paused.
local path_tick,position_reads,position_sets=nil,0,0
local path_queue={is_enabled=false}
local path_target={current_index=3,get_position=function()position_reads=position_reads+1;return{0,0,0}end,
 set_position=function()position_sets=position_sets+1 end,
 timer={onTimeChange=function()return{addAction=function(_,fn)path_tick=fn end}end}}
local pathenv={self={action_queue=path_queue,path_target=path_target},state={AutoPullMode={value='Off'}},
 player_util={distance=function()return 0 end,get_player_position=function()return{0,0,0}end}}
setmetatable(pathenv,{__index=_G})
local pathsrc=source('cylibs/trust/roles/pather.lua')
local pa=assert(pathsrc:find('    self.path_target.timer:onTimeChange():addAction(function()',1,true))
local pb=assert(pathsrc:find('    self.path_target.timer:start()',pa,true))
assert(load(pathsrc:sub(pa,pb-1),'actual path tick','t',pathenv))()
path_tick();check(path_target.current_index==3 and position_reads==0 and position_sets==0,'Pause freezes path cursor and movement updates')
path_queue.is_enabled=true;path_tick()
check(path_target.current_index==4 and position_sets==1,'Act allows existing path progression')
-- Conflicting old follow/receipt requests cannot steal the retreat destination.
local follow_methods={}
local followenv=setmetatable({FollowTrustCommands=follow_methods},{__index=env})
methods('commands/FollowCommands.lua','function FollowTrustCommands:handle_follow_party_member','-- // trust follow distance',followenv)
methods('commands/FollowCommands.lua','function FollowTrustCommands:check_follow_receipts()','-- // trust follow me',followenv)
q.retreat_leader='Myrr'
local follow_commands=setmetatable({action_queue=q,pending_follow={}}, {__index=follow_methods})
check(not follow_commands:handle_follow_party_member('Cioara'),'retreat rejects conflicting follow target before any side effects')
follow_commands:check_follow_receipts()
check(follow_commands.pending_follow==nil,'retreat retires old receipt retry')
-- Every control command stays reachable while an editor is open.
local Policy=require('cylibs/ui/menu/menu_command_policy')
for _,cmd in ipairs({'act','actall','pause','pauseall','stop','stopall','toggle','ready','standdown','partyrequest'})do
 check(Policy.effect(cmd,{})=='immediate','menu allows '..cmd)
end
print('PASS '..checks..' control-state/retreat assertions; native actions and IPC simulated')
