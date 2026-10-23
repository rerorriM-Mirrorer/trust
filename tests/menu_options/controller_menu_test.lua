-- Real Trust adapter with focused-control and file-boundary mocks.
local Controller=require('cylibs/ui/input/controller_menu')
local now,mode,id=100,'navigation',42
local events,files={},{}
local focus={onKeyboardEvent=function(_,key,down) events[#events+1]={key,down} end}
local closed=0
local menu={closeAll=function() closed=closed+1;mode='closed' end}
local adapter=Controller.new({clock=function()return now end,
    context=function()return menu,focus,mode,id end,path=function(n)return tostring(n) end,
    open=function(path)return {write=function(_,s)files[path]=s;return true end,close=function()return true end} end,
    remove=function(path)files[path]=nil end,keyName=function(k)return tostring(k) end})
adapter:tick();local token=adapter.token
assert(files['42']:find('trust%-menu1\n42\n'))
assert(adapter:accept(token,'1',now,'up') and #events==2 and events[1][1]==200 and events[1][2] and not events[2][2])
assert(not adapter:accept(token,'1',now,'up'),'duplicate command accepted')
assert(not adapter:accept(token,'2',now-1,'confirm'),'stale command accepted')
assert(not adapter:accept(token,'2',now+1,'confirm'),'future command accepted')
assert(not adapter:accept(token,'2.5',now,'confirm'),'fractional sequence accepted')
assert(not adapter:accept(token,'2',now,'unknown'),'unknown action accepted')
focus={onKeyboardEvent=function(_,key,down)events[#events+1]={key,down} end}
assert(not adapter:accept(token,'2',now,'confirm'),'old focused control token accepted')
adapter:tick();token=adapter.token
mode='text';adapter:tick();token=adapter.token
assert(not adapter:accept(token,1,now,'up'),'text field received controller direction')
assert(adapter:accept(token,2,now,'confirm'))
mode='paused';adapter:tick();token=adapter.token
assert(not adapter:accept(token,1,now,'back'),'chat/background received action')
mode='navigation';adapter:tick();token=adapter.token
local original=focus
focus.onKeyboardEvent=function(_,key,down)
    events[#events+1]={key,down,original}
    if down then focus={onKeyboardEvent=function()error('release went to new focus')end} end
end
assert(adapter:accept(token,1,now,'back'))
adapter:tick();token=adapter.token
assert(adapter:accept(token,1,now,'close') and closed==1)
assert(not adapter:accept(token,2,now,'confirm'),'closed menu accepted action')
assert(files['42']:find('\nclosed\n',1,true),'closed lease not published')
adapter:close();assert(not files['42'])
print('Trust controller adapter: focused press/release, context invalidation, duplicate/stale/future rejection, text/chat guards and validated close passed.')
