-- Loading Trust while a character is in a cutscene (status Event) must not fail:
-- the early startup call to handle_status_change runs before player.trust.main_job exists.
local function src(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local text=src('Trust.lua')
local a=assert(text:find('function handle_status_change(',1,true))
local b=assert(text:find('function handle_unload(',a,true))
local cleared={}
local function queue(name)return{clear=function()cleared[#cleared+1]=name end}end
local env=setmetatable({
    res={statuses={[0]={english='Idle'},[4]={english='Event'},[3]={english='Dead'}}},
    state={AutoUnloadOnDeathMode={value='Off'}},
    player={},action_queue=queue('main'),
    handle_stop=function()end,handle_unload=function()end,
},{__index=_G})
assert(load(text:sub(a,b-1),'handle_status_change','t',env))()
local function run(status)cleared={};env.handle_status_change(status,0)end

-- Startup: player.trust exists but no job trust yet (the reported crash), and the table not existing at all.
env.player.trust={};run(4)
assert(#cleared==1 and cleared[1]=='main' and env.player.status=='Event','cutscene at startup clears the main queue without error')
env.player.trust=nil;run(4)
assert(#cleared==1 and cleared[1]=='main','no player.trust at all is also safe')
-- Normal operation: the follower's walk queue is cleared too, in order.
env.player.trust={main_job={role_with_type=function(_,role)assert(role=='follower');return{walk_action_queue=queue('walk')}end}}
run(4)
assert(#cleared==2 and cleared[1]=='main' and cleared[2]=='walk','cutscene during play clears main and walking queues')
-- A job without a follower role no longer errors.
env.player.trust={main_job={role_with_type=function()return nil end}};run(4)
assert(#cleared==1 and cleared[1]=='main','missing follower role is safe')
-- Other statuses are unchanged.
run(0);assert(#cleared==0 and env.player.status=='Idle')
print('PASS cutscene (Event) status during startup and normal play: no error, queues cleared where they exist')
