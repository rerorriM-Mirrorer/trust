-- Execute the production takeover engine and public handoff/Assist handlers.
local Control=require('cylibs/trust/control_state')
local Feedback=require('cylibs/util/command_feedback')
local function src(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local function method(p,first,last,env)local s=src(p);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true));assert(load(s:sub(a,b-1),'production','t',env))()end
local releases,unfollow,walks=0,0,0
local queue={is_enabled=true,control_state='Active'}
local follower={target='Remembered',manual_pause=false,walk_action_queue={}}
local enabled={value=true,getValue=function(s)return s.value end,setValue=function(s,v)s.value=v end}
local trust={role_with_type=function()return follower end}
local env=setmetatable({windower={ffxi={run=function(v)assert(v==false);releases=releases+1 end,follow=function()unfollow=unfollow+1 end}},
 require=function(p)if p=='cylibs/trust/control_state'then return Control end return{reset=function()end}end},{__index=_G})
local function clear()
 assert(queue.movement_suspended and follower.manual_pause,'gates precede cancellation')
 env.windower.ffxi.run(false);env.windower.ffxi.run(false)
 queue.current_action=nil
end
queue.disable=function(s)s.is_enabled=false;clear()end
queue.enable=function(s)s.is_enabled=true end
follower.stop_following=function()walks=walks+1;clear()end
follower.start_following=function()error('manual takeover restarted follow')end
local M=assert(loadfile('cylibs/movement/takeover.lua','t',env))()
queue.current_action={gettype=function()return'runtolocationaction'end}
M.apply(trust,queue,enabled,true,false)
assert(releases==1 and unfollow==1 and follower.target=='Remembered' and not enabled.value,'owned movement released once, target remembered')
M.apply(trust,queue,enabled,true,false)
assert(releases==1 and unfollow==2,'repeat gesture does not fight native stick')
queue.is_enabled=true;enabled.value=true;queue.control_state='Active'
M.apply(trust,queue,enabled,false,false)
assert(queue.is_enabled and enabled.value,'Pause option off retains action permission')
M.apply(trust,queue,enabled,true,true)
assert(queue.parked and queue.control_state=='Parked' and not enabled.value)
Control.set(queue,enabled,trust,'Paused')
assert(not queue.parked and queue.movement_suspended and follower.manual_pause,'explicit Pause releases park but needs fresh follow')
local beforeDiscard=releases
M.discard({destroy=function()env.windower.ffxi.run(false)end})
assert(releases==beforeDiscard,'unstarted discarded action never releases native input')
local G={};local followed,assisted,acted=0,0,0
local handenv=setmetatable({GeneralTrustCommands=G,require=function()return Feedback end,
 shortcuts={follow={handle_follow_party_member=function(_,n)assert(n=='Leader');followed=followed+1;return true end},
 assist={handle_assist_player=function()assisted=assisted+1;return true end}}},{__index=_G})
method('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_movement_handoff','function GeneralTrustCommands:apply_park',handenv)
local c=setmetatable({action_queue={},addon_enabled={getValue=function()return false end},handle_start=function()acted=acted+1 end},{__index=G})
assert(c:handle_movement_handoff(nil,'Leader','0','0','1'));assert(followed==1 and assisted==0 and acted==0)
assert(c:handle_movement_handoff(nil,'Leader','1','1','1'));assert(followed==2 and assisted==1 and acted==1)
c.action_queue.parked=true
assert(c:handle_movement_handoff(nil,'Leader','1','1','1'));assert(followed==2 and acted==1,'park discards automatic Act too')
local A={};local status=33;local heals=0
local ae=setmetatable({AssistTrustCommands=A,windower={ffxi={get_player=function()return{status=status}end},send_command=function(cmd)assert(cmd=='input /heal');heals=heals+1 end}},{__index=_G})
method('commands/AssistCommands.lua','function AssistTrustCommands:handle_wake_assist','-- // trust assist me',ae)
local a=setmetatable({handle_assist_player=function()return true end},{__index=A})
a:handle_wake_assist(nil,'Leader');status=0;a:handle_wake_assist(nil,'Leader');assert(heals==1,'heal toggled only if resting')
local queueenv=setmetatable({ActionQueue={},require=function()return M end},{__index=_G})
method('cylibs/actions/action_queue.lua','function ActionQueue:push_action(action, check_duplicates)','-- Pushes the given actions onto the queue',queueenv)
local rejected=0
queueenv.ActionQueue.push_action({movement_suspended=true},{gettype=function()return 'runtoaction'end,destroy=function()rejected=rejected+1;env.windower.ffxi.run(false)end})
assert(rejected==1 and releases==beforeDiscard,'actual queue rejects future run actions without stopping manual input')
print('PASS takeover cancellation ownership, target preservation, parked transitions, independent handoff and resting-only Assist wake')
