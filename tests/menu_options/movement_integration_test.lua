-- Real Trust receiver wiring; native sender and takeover engine are separate tests.
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
local block=assert(root:match('(    if movement_receiver then movement_receiver:close%(%) end.-movement_receiver:tick%(true%))'))
local Feedback=require('cylibs/util/command_feedback')
local Receiver=require('cylibs/ui/input/movement_receiver')
local events,sent,takeovers,chat={}, {}, {}, {}
local settings={policy='Send',enabled=true,quiet=true,stop_on_movement=true,start_others=true,assist_others=false}
local menu=false
local env=setmetatable({action_queue={},addon_enabled={},player={trust={main_job={}}},
 addon_settings={getSettings=function()return{movement=settings}end},hud={trustMenu={isVisible=function()return menu end}},state={IpcMode={value='All'}},
 addon_system_message=function(s)chat[#chat+1]=s end,
 shortcuts={follow={get_receipt_recipients=function()return{'Cioara','Clairvaux'}end}},
 IpcRelay={shared=function()return{send_message=function(_,m)sent[#sent+1]=m end}end},
 windower={addon_path='addon/',trust={},has_focus=function()return true end,create_dir=function()end,unregister_event=function()end,
 register_event=function(n,fn)events[n]=fn;return n end,ffxi={get_info=function()return{logged_in=true}end,get_player=function()return{name='Myrr',status=0}end}},
 io={open=function()return{write=function()end,close=function()end}end},
 require=function(n)
  if n=='socket'then return{gettime=function()return 1 end}end
  if n=='cylibs/ui/input/movement_receiver'then return Receiver end
  if n=='cylibs/util/command_feedback'then return Feedback end
  if n=='cylibs/messages/command_message'then return{new=function(c,target)return{command=c,target=target}end}end
  if n=='cylibs/movement/takeover'then return{apply=function(_,_,_,pause)takeovers[#takeovers+1]=pause end}end
  error(n)
 end},{__index=_G})
assert(load(block,'actual root movement','t',env))()
local function gesture(key)events.keyboard(key or 0x7B,true);events.keyboard(key or 0x7B,false)end
gesture();assert(#takeovers==1 and #sent==2 and #chat==0)
assert(sent[1].command=='trust movementhandoff Myrr 1 0 1' and sent[1].target=='Cioara')
gesture();assert(#takeovers==2 and #sent==4,'fresh neutral gesture sends again')
settings.assist_others=true;settings.start_others=false;settings.quiet=false
gesture();assert(sent[#sent].command=='trust movementhandoff Myrr 0 1 0' and #chat==1)
settings.enabled=false;settings.stop_on_movement=false
local count=#sent;gesture();assert(#sent==count and takeovers[#takeovers]==false,'follow off retains local takeover')
menu=true;count=#takeovers;gesture();assert(#takeovers==count,'menu navigation blocked')
menu=false;env.action_queue.parked=true;gesture();assert(#takeovers==count,'parked source cannot auto-unpark')
env.action_queue.parked=false;env.state.IpcMode.value='Receive';gesture(0x79)
assert(#takeovers==count+1,'local takeover independent of IPC send')
print('PASS production movement wiring: independent Follow/Assist/Act/quiet flags, local takeover and guards')
