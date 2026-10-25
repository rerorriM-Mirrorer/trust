local Receiver=require('cylibs/ui/input/movement_receiver')
local settings={policy='Send',enabled=true}
local now,focused,reason,performed=100,true,nil,0
local files,removed={},{}
local succeed=true
local receiver=Receiver.new({settings=function()return settings end,
    focused=function()return focused end,blocked=function()return reason end,
    perform=function()performed=performed+1;return succeed,'IPC unavailable' end,
    clock=function()return now end,timestamp=function()return 1234 end,
    name=function()return 'Myrr'end,path=function(n)return n..'.lease'end,
    open=function(path)return{write=function(_,s)files[path]=s end,close=function()end}end,
    remove=function(path)removed[path]=true end})
receiver:tick(true)
assert(files['Myrr.lease']:find('policy=Send',1,true))
assert(receiver:key(99,true)==nil and receiver.received==0)
receiver:key(0x7B,true);receiver:key(0x7B,true)
assert(performed==1 and receiver.accepted==1 and receiver.received==1)
receiver:key(0x7B,false)
reason='Trust menu';receiver:key(0x7B,true);receiver:key(0x7B,false)
assert(performed==1 and receiver.ignored==1 and receiver.last=='Trust menu')
reason=nil;now=101;receiver:tick()
assert(performed==1,'blocked signal retried itself')
settings.policy='Ready';receiver:tick(true)
assert(files['Myrr.lease']:find('policy=Ready',1,true))
focused=false;receiver:key(0x7B,true)
assert(receiver.received==2 and not receiver.down)
focused=true;succeed=false;receiver:key(0x7B,true);receiver:key(0x7B,false)
assert(receiver.ignored==2 and receiver.last=='IPC unavailable')
settings.enabled=false
receiver:key(0x7B,true);receiver:key(0x7B,false)
assert(receiver.last=='disabled' and receiver.ignored==3)
receiver:close();receiver:close();assert(removed['Myrr.lease'])
print('PASS movement receiver: policies, debounce, immediate ignore, no retry, action failure and cleanup')
