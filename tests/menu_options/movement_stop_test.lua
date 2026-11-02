-- Execute production methods with small synchronous event/queue doubles.
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function method(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 assert(load(s:sub(a,b-1),'production method','t',env))()
end
local calls={};local function note(s)calls[#calls+1]=s end
local main={is_enabled=true,enable=function(s)s.is_enabled=true;note('enable')end,
 disable=function(s)s.is_enabled=false;note('disable')end}
local follower={stop_following=function()note('walking stopped')end,start_following=function()note('walking resumed')end}
local reaction={react_action_queue={disable=function()note('reaction stopped')end}}
local job={role_with_type=function(_,t)return t=='follower' and follower or reaction end}
local callback
local env=setmetatable({action_queue=main,player={player={monitor=function()end},trust={main_job=job}},
 require=function(name)if name=='cylibs/movement/recovery' then return{reset=function()end}end return require(name)end,
 ValueRelay={new=function()return{onValueChanged=function()return{addAction=function(_,fn)callback=fn end}end}end},
 windower={ffxi={run=function(v)assert(v==false);note('run stopped')end,follow=function()note('native follow stopped')end}}},{__index=_G})
local root=source('Trust.lua');local a=assert(root:find('\taddon_enabled = ValueRelay.new(false)',1,true));local b=assert(root:find('\n\tmain_job_id =',a,true))
assert(load(root:sub(a,b-1),'actual stop relay','t',env))()
callback(nil,false)
assert(table.concat(calls,',')=='disable,walking stopped,reaction stopped,run stopped,native follow stopped')
callback(nil,true);assert(main.is_enabled and calls[#calls]=='walking resumed')
-- Every path that can rearm walking is gated while the parent queue is stopped.
local Follower={};local e=setmetatable({Follower=Follower},{__index=_G})
method('cylibs/trust/roles/follower.lua','function Follower:start_following(override)','function Follower:stop_following',e)
method('cylibs/trust/roles/follower.lua','function Follower:check_distance()','function Follower:on_player_status_change',e)
method('cylibs/trust/roles/follower.lua','function Follower:can_zone(zone_id)','function Follower:zone(',e)
local f=setmetatable({action_queue={is_enabled=false},get_party=function()return{get_player=function()return{}end}end},{__index=Follower})
f:start_following(true);f:check_distance();assert(f:can_zone(1)==false)
-- Current child cancellation can synchronously call perform again. It must not
-- progress to the next child, including partial-failure sequences.
local SequenceAction={};e={SequenceAction=SequenceAction}
method('cylibs/actions/sequence.lua','function SequenceAction:cancel()','function SequenceAction:getactions',e)
local seq=setmetatable({queue={it=function()return function()end end},
 complete=function(s,ok)assert(not ok);s.completed=true end},{__index=SequenceAction})
local cancelled=0
seq.current_action={cancel=function()cancelled=cancelled+1;assert(seq.cancelled);seq:complete(false)end}
seq:cancel();assert(cancelled==1 and seq.completed)
-- Queue completion cannot advance work after disable flips its gate.
local ActionQueue={};local qe={ActionQueue=ActionQueue}
method('cylibs/actions/action_queue.lua','function ActionQueue:perform_next_action()','function ActionQueue:handle_action_completed',qe)
ActionQueue.perform_next_action({is_enabled=false}) -- no queue access permitted
-- Receiver ordering, validation, and failure: no Start after failed setup.
local GeneralTrustCommands={};local order={};local fail=false
local g=setmetatable({handle_start=function()order[#order+1]='start';return true end},{__index=GeneralTrustCommands})
e={GeneralTrustCommands=GeneralTrustCommands,windower={ffxi={get_player=function()return{name='Myrr'}end}},
 shortcuts={follow={handle_follow_party_member=function(_,name)assert(name=='Cioara');order[#order+1]='follow';return not fail,'invalid target'end},
 assist={handle_assist_player=function()order[#order+1]='assist';return true end}}}
setmetatable(e,{__index=_G})
method('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_handoff','-- // trust start\n',e)
assert(g:handle_handoff(nil,'Cioara'));assert(table.concat(order,',')=='follow,assist,start')
order={};fail=true;assert(g:handle_handoff(nil,'Cioara')==false and #order==1)
assert(g:handle_handoff(nil,'Myrr')==false and g:handle_handoff(nil,'bad;command')==false)
-- Execute lock-on guard for both preferences and cursor-only actions.
local engage=source('cylibs/actions/engage.lua');local lock=assert(engage:match('(                local movement = addon_settings.-\n                end)'))
local locked=0;e={addon_settings={getSettings=function()return{movement={auto_lockon=false}}end},self={},
 windower={ffxi={get_player=function()return{target_locked=false}end},send_command=function()locked=locked+1 end}}
local fn=assert(load(lock,'actual lock-on guard','t',e));fn();assert(locked==0)
e.addon_settings.getSettings=function()return{movement={auto_lockon=true}}end;fn();assert(locked==1)
e.self.cursor_only=true;fn();assert(locked==1)
print('PASS actual Stop relay, stopped follower gates, sequence active-child cancellation, handoff ordering/failure and lock-on preference')
