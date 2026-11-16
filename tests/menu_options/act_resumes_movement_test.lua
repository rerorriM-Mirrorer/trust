-- Act lifts the stick-takeover gate: combat positioning and following resume.
local src=assert(io.open('commands/GeneralCommands.lua')):read('*a')
local body=assert(src:match('(function GeneralTrustCommands:handle_start%(.-\nend)\n'))
local resets,started=0,0
local GeneralTrustCommands={}
local Control={set=function(queue,enabled,trust,mode)
    queue.control_state=mode
    if queue.parked then queue.parked=false;queue.movement_suspended=true end
end}
local env=setmetatable({GeneralTrustCommands=GeneralTrustCommands,Control=Control,
    require=function(name)
        assert(name=='cylibs/movement/recovery');return {reset=function()resets=resets+1 end}
    end},{__index=_G})
assert(load(body,'handle_start','t',env))()
local function new(parked)
    local follower={manual_pause=true,recovery_paused=true,start_following=function()started=started+1 end}
    local queue={movement_suspended=true,parked=parked,control_state='Paused'}
    return setmetatable({action_queue=queue,addon_enabled={},
        trust={role_with_type=function(_,t)return t=='follower' and follower or nil end}},
        {__index=GeneralTrustCommands}),queue,follower
end
-- After a stick takeover (Paused, gate on), Act reopens movement and following.
local c,q,f=new(false)
assert(c:handle_start())
assert(q.movement_suspended==false,'combat/camp run actions accepted again')
assert(f.manual_pause==false and f.recovery_paused==false and started==1 and resets==1,'following resumes')
-- Act releases a park too; Control.set re-arms the gate, Act then lifts it.
c,q,f=new(true)
assert(c:handle_start())
assert(q.parked==false and q.movement_suspended==false and f.manual_pause==false and started==2)
-- If Control.set did not reach Active, the gate stays.
local held,hq=new(false)
Control.set=function(queue) queue.control_state='Retreat' end
assert(held:handle_start())
assert(hq.movement_suspended==true and started==2,'non-Active result leaves the gate alone')
print('PASS Act lifts the stick-takeover gate and resumes following')
