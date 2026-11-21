-- Act: real Control.set, act_gate, ActionQueue push gate source, and the actual
-- Act / partyrequest act command methods. Game, IPC and roles are mocked.
local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function methods(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 assert(load(s:sub(a,b-1),'actual act commands','t',env))()
end
local function list(t)return{it=function()local i=0;return function()i=i+1;return t[i]end end}end

local player_mob={id=1,status=0}
local mobs={}
windower={ffxi={get_player=function()return player_mob end}}
state={AutoEngageMode={value='Mirror'},IpcMode={value='All'}}
local Control=require('cylibs/trust/control_state')
local Gate=require('cylibs/trust/act_gate')

-- Control.set: Act is a running state (queue enabled) with its own name.
local enabled_value=false
local q={control_state='Paused',is_enabled=false}
local enabled={getValue=function()return enabled_value end,setValue=function(_,v)
 check(q.control_state=='Act' or q.control_state=='Active' or not v,'state named before relay')
 enabled_value=v;q.is_enabled=v end}
Control.set(q,enabled,nil,'Act')
check(q.control_state=='Act' and enabled_value,'Act enables Trust')
Control.set(q,enabled,nil,'Active')
check(q.control_state=='Active' and enabled_value,'Act -> Start keeps Trust enabled')
Control.set(q,enabled,nil,'Act')
check(q.control_state=='Act' and enabled_value,'Start -> Act keeps Trust enabled')
Control.set(q,enabled,nil,'Paused')
check(q.control_state=='Paused' and not enabled_value,'Act -> Pause disables')
q.parked=true;Control.set(q,enabled,nil,'Act')
check(not q.parked and q.movement_suspended and q.control_state=='Act','Act un-parks like Start')

-- act_gate triggers.
local function member(mob)return{get_mob=function()return mob end}end
local assist_mob,other_mob={id=2,status=0},{id=3,status=0}
local party={get_assist_target=function()return member(assist_mob)end,
 get_party_members=function()return list({member(player_mob),member(assist_mob),member(other_mob)})end,
 party_target={aggro_active=false}}
local cleared=0
local gq={control_state='Active',clear=function()cleared=cleared+1 end}
check(Gate.open(gq,party),'Start is never gated')
gq.control_state='Act'
check(not Gate.open(gq,party),'Act holds with no fight')
player_mob.status=1;check(Gate.open(gq,party) and gq.act_reason=='self','self engaged opens')
player_mob.status=0;check(not Gate.open(gq,party) and cleared==1,'fight end closes and clears queued actions')
check(not Gate.open(gq,party) and cleared==1,'staying closed does not clear again')
assist_mob.status=1;check(Gate.open(gq,party) and gq.act_reason=='assist','assist target engaged opens')
assist_mob.status=0;Gate.open(gq,party)
other_mob.status=1;check(not Gate.open(gq,party),'party member engaged ignored outside Aggro')
state.AutoEngageMode.value='Defensive'
check(Gate.open(gq,party) and gq.act_reason=='party','Aggro: party member engaged opens')
other_mob.status=0;Gate.open(gq,party)
party.party_target={aggro_active=true,aggro_decision='defense:42'}
check(Gate.open(gq,party) and gq.act_reason=='threat','Aggro: threat evidence opens')
party.party_target={aggro_active=true,aggro_decision='assist:42'}
check(not Gate.open(gq,party),'Aggro: assist merely targeting does not open')
check(not Gate.open(gq,nil),'no party: only self can open')
state.AutoEngageMode.value='Mirror'

-- ActionQueue consults the gate on both push paths.
local aq=source('cylibs/actions/action_queue.lua')
local _,n=aq:gsub('%(self%.gate and not self%.gate%(%)%)','')
check(n==2,'push_action and push_actions both gated')
local tl=source('Trust.lua')
check(tl:find("if action_queue.control_state ~= 'Act' then action_queue.control_state = 'Active' end",1,true),'enable relay keeps Act')
check(tl:find("act_gate').open(action_queue, player.party)",1,true),'tic notices a fight ending')

-- Actual command methods.
local G={}
local assisted={}
local follower={manual_pause=true,recovery_paused=true,start_following=function()end,stop_following=function()end}
local trust={role_with_type=function(_,k)if k=='follower'then return follower end end,
 get_party=function()return{get_party_member_named=function(_,n)return n=='Cioara' and {} or nil end}end}
local env=setmetatable({GeneralTrustCommands=G,Control=Control,state=state,
 require=function(n)
  if n=='cylibs/util/command_feedback'then return{run=function(_,f)return f()end}
  elseif n=='cylibs/movement/recovery'then return{reset=function()end} end
  error(n)
 end,
 shortcuts={assist={handle_assist_player=function(_,n)assisted[#assisted+1]=n;return true end}},
},{__index=_G})
methods('commands/GeneralCommands.lua','-- Pause is local','-- // trust reload',env)
methods('commands/GeneralCommands.lua','-- Shared by Start (Active) and Act','-- // trust startall',env)
methods('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_party_request','function GeneralTrustCommands:request_party_state',env)
local cq={control_state='Paused',is_enabled=false,movement_suspended=true}
enabled_value=false
q=cq
local c=setmetatable({action_queue=cq,addon_enabled=enabled,trust=trust},{__index=G})
local ok,msg=c:handle_act()
check(ok and cq.control_state=='Act' and enabled_value and msg=='Act - waiting for a fight','act command')
check(cq.movement_suspended==false and follower.manual_pause==false,'Act lifts stick takeover like Start')
check(c:handle_act(nil,'extra')==false,'act rejects arguments')
c:handle_pause();check(cq.control_state=='Paused','Act -> Pause')
cq.control_state='Retreat'
check(c:handle_party_request(nil,'act','Cioara'),'partyrequest act accepted')
check(cq.control_state=='Act' and assisted[#assisted]=='Cioara','receiver assists the sender and Acts')
check(c:handle_party_request(nil,'nonsense','Cioara')==false,'unknown operation rejected')
check(c:handle_party_request(nil,'act','Stranger')==false,'request from someone outside the party ignored')
local gc=source('commands/GeneralCommands.lua')
check(gc:find("self:add_command('act', self.handle_act",1,true) and gc:find("self:add_command('actall', self.handle_act_all",1,true),'act/actall registered')
check(gc:find("self:add_command('start', self.handle_start",1,true) and gc:find("self:add_command('startall', self.handle_start_all",1,true),'start/startall unchanged')

-- Sender side of actall (request_party_state). Windower quoted-string methods
-- are normalized the same way check_syntax.lua does.
local sent,chat={},{}
local follower2={get_follow_target=function()return nil end,set_follow_target=function()end}
env.windower={ffxi={get_player=function()return{name='Cioara'}end},add_to_chat=function(_,t)chat[#chat+1]=t end}
env.party_util={is_alter_ego=function(n)return n=='Shantotto'end,get_party_member_names=function()return list({'Cioara','Myrr','Myrr','Shantotto','Kaiu'})end}
env.IpcRelay={shared=function()return{send_message=function(_,m)sent[#sent+1]=m end}end}
env.CommandMessage={new=function(c,n)return{command=c,target=n}end}
env.shortcuts.follow={get_follower=function()return follower2 end}
string.color=function(t)return t end
local rs=source('commands/GeneralCommands.lua')
local a=assert(rs:find('function GeneralTrustCommands:request_party_state',1,true))
local b=assert(rs:find('function GeneralTrustCommands:handle_standdown',a,true))
local a=assert(rs:find('function GeneralTrustCommands:broadcast_party_request',1,true))
local chunk=rs:sub(a,b-1):gsub("('[^'\n]*'):(%a+)%(",function(q,m)return '('..q..'):'..m..'(' end)
assert(load(chunk,'actual request_party_state','t',env))()
local old=env.require
env.require=function(n)if n=='chat'then return{} end return old(n) end
assisted={};cq.control_state='Paused';enabled_value=false
check(c:handle_act_all(),'actall succeeds')
check(assisted[1]=='Cioara' and cq.control_state=='Act','actall: sender assists self and Acts')
check(#sent==1 and sent[1].command=='trust partyrequest act Cioara' and sent[1].target==nil,'actall: one broadcast to all clients, like startall')
check(chat[#chat]:find('Act!',1,true) and chat[#chat]:find('on all clients',1,true),'actall heading')
check(c:handle_act_all(nil,'party')==false,'actall rejects arguments')
local notes={}
env.addon_system_message=function(t)notes[#notes+1]=t end
c.apply_park=function()cq.control_state='Parked';return true end
sent={}
c:handle_stop()
check(#sent==1 and sent[1].command=='trust partyrequest park Cioara' and sent[1].target==nil,'stop: one park broadcast to all clients')
check(notes[#notes]:find('requested on all clients',1,true),'stop message')
local parked=0
c.apply_park=function()parked=parked+1;return true end
check(c:handle_party_request(nil,'park','Stranger')==false and parked==0,'park from outside the party ignored')
check(c:handle_party_request(nil,'park','Cioara') and parked==1,'park from the party leader applied')
local gs=source('commands/GeneralCommands.lua')
local _,n=gs:gsub("party_util%.get_party_member_names",'')
check(n==1,'only the optional [party] scope of startall/pauseall still reads the party list')
print('PASS act_state_test: '..checks..' assertions')
