-- Control-state file for xivcrossbar: format, change/heartbeat writes, path
-- change, unload removal, and party_intent from the actual command methods.
local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local P=require('cylibs/trust/control_publish')
local files,removed,writes={}, {},0
local now,t=0,1000
local queue={control_state='Paused'}
local id=7
local pub=P.new({queue=queue,id=function()return id end,path=function(i)return 'cs-'..i..'.txt'end,
 open=function(p)return{write=function(_,s)files[p]=s;writes=writes+1 end,close=function()end}end,
 remove=function(p)files[p]=nil;removed[#removed+1]=p end,clock=function()return now end,time=function()return t end})
pub:tick()
check(files['cs-7.txt']=='trust-control1\n7\npause\nnone\n1000\nEND\n','first write')
now=.1;queue.control_state='Act';pub:tick()
check(writes==1,'throttled to 4 checks a second')
now=.3;pub:tick()
check(writes==2 and files['cs-7.txt']:find('\nact\nnone\n',1,true),'state change written')
now=.6;pub:tick();check(writes==2,'no change, no write')
queue.party_intent='act';now=.9;pub:tick()
check(writes==3 and files['cs-7.txt']:find('\nact\nact\n',1,true),'intent change written')
now=6;t=1006;pub:tick()
check(writes==4 and files['cs-7.txt']:find('\n1006\n',1,true),'heartbeat refreshes stamp')
for state,name in pairs({Active='start',Paused='pause',Parked='stop',Retreat='retreat',Act='act'}) do
 queue.control_state=state;now=now+1;pub:tick()
 check(files['cs-7.txt']:find('\n'..name..'\n',1,true),state..' published as '..name)
end
id=8;now=now+1;pub:tick()
check(files['cs-7.txt']==nil and files['cs-8.txt'],'character change moves the file')
pub:close();check(files['cs-8.txt']==nil,'unload removes the file')
id=nil;now=now+1;pub:tick();check(next(files)==nil,'no character, no file')

-- Commands record the last party-wide request.
local gc=source('commands/GeneralCommands.lua')
check(gc:find("self.action_queue.party_intent = ({ready='start',act='act',standdown='pause'})[operation]",1,true),'ready/actall/standdown intent')
check(gc:find("self:apply_park()\n    self.action_queue.party_intent='stop'",1,true),'stop/stopall intent')
check(gc:find("local intent = ({pause='pause',start='start'})[command]",1,true),'pauseall/startall intent')
local tl=source('Trust.lua')
check(tl:find("if control_publish then control_publish:tick() end",1,true),'ticked every frame')
check(tl:find("if control_publish then control_publish:close();control_publish=nil end",1,true),'closed on unload')
check(tl:find("'data/control-state-'..tostring(windower.ffxi.get_info().server)..'-'..id..'.txt'",1,true),'path contract')
print('PASS control_publish_test: '..checks..' assertions')
