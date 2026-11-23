-- A: //trust menu rendertrace (input + menu drawing in one file).
local pass=0
local function ok(c,m) assert(c,m); pass=pass+1 end
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
package.loaded['cylibs/ui/diagnostics/menu_trace']=nil
local T=require('cylibs/ui/diagnostics/menu_trace')
local now=1000; T.set_clock(function() return now end)

-- Fake Windower images library (methods resolved through the module table).
local images={}
local meta={__index=images}
function images.new() return setmetatable({p='',v=false},meta) end
function images.visible(i,v) if v==nil then return i.v end i.v=v end
function images.show(i) i.v=true end
function images.hide(i) i.v=false end
function images.path(i,p) if p==nil then return i.p end i.p=p end
function images.pos(i,x,y) end
function images.size(i,w,h) end
function images.alpha(i,a) end
function images.color(i,r,g,b) end
function images.destroy(i) end
local orig_new, orig_visible = images.new, images.visible

-- Off: nothing installed, nothing recorded.
T.event('key','x'); ok(T.status().count==0 and images.new==orig_new,'off records nothing and hooks nothing')

local registered, unregistered = {}, nil
local okc,msg=T.command('on','trace.txt',{images=images,register=function(n,f) registered[n]=f return 77 end,
  unregister=function(id) unregistered=id end,key_name=function(k) return k==0xD0 and 'Down' or '' end})
ok(okc and msg:find('ON (images)',1,true) and images.new~=orig_new and registered.keyboard,'on installs image + keyboard hooks')
ok(not msg:find('[\128-\255]'),'ASCII chat')

-- Keyboard input line.
registered.keyboard(0xD0,true,0,false); registered.keyboard(0xD0,false,0,false)
-- Frames and gaps.
T.frame(1000); T.frame(1000.016); T.frame(1000.2)
ok(T.status().frames==3 and math.abs(T.status().max_gap-0.184)<1e-9,'frames and max gap')

-- Images: untextured show is flagged; textured or coloured is not; repeats coalesce.
local box=images.new(); box:show()
local tex=images.new(); tex:path('assets/x.png'); tex:visible(true)
local col=images.new(); col:color(0,0,0); col:visible(true)
for _=1,50 do tex:pos(5,5); tex:visible(true) end
tex:pos(6,5); tex:hide(); tex:destroy()
ok(box.v==true and tex.p=='assets/x.png','calls still reach Windower')

-- Controller trace via controller_menu's trace option.
local C=require('cylibs/ui/input/controller_menu')
local ctl={}
local fakeMenu,fakeFocus={closeAll=function() end},{onKeyboardEvent=function() end}
local menu=C.new({clock=function() return now end,open=function() return {write=function() return true end,close=function() return true end} end,remove=function() end,
  path=function() return 'p' end,keyName=function() return 'Down' end,
  context=function() return fakeMenu,fakeFocus,'navigation',1 end,
  trace=function(...) T.event('ctl',...) end})
menu:refresh()
menu:accept(menu.token,1,now-0.02,'down'); menu:accept(menu.token,1,now-0.02,'down'); menu:accept(menu.token,2,now-1,'down'); menu:accept('bad',3,now,'down')
ok(menu.accepted==1 and menu.rejected==3,'accept/reject counts unchanged by tracing')

-- Cursor + scroll via production methods.
local csrc=source('cylibs/ui/collection_view/collection_view.lua')
local body=assert(csrc:match('(function CollectionView:moveCursorToIndexPath.-\nend)\n'))
local CV={cursorFront=true}; assert(load(body,'moveCursor','t',setmetatable({CollectionView=CV},{__index=_G})))()
local pos={x=10,y=40}
local cv=setmetatable({cursorImageItem={getSize=function()return{width=37,height=24}end,offsetX=0,offsetY=0},
  selectionBackground={getPosition=function() return pos end,setPosition=function(_,x,y) pos={x=x,y=y} end,setSize=function()end,setVisible=function()end,
    setNeedsLayout=function()end,layoutIfNeeded=function()end,bringToFront=function()end},
  getDelegate=function()return{getCursorIndexPath=function()return{section=1,row=3}end}end,
  getDataSource=function()return{itemAtIndexPath=function()return{}end,cellForItemAtIndexPath=function()return{getPosition=function()return{x=60,y=70}end,getSize=function()return{width=50,height=16}end}end}end,
  hasFocus=function()return true end,isCursorEnabled=function()return true end},{__index=CV})
cv:moveCursorToIndexPath(); cv:moveCursorToIndexPath()
local ssrc=source('cylibs/ui/scroll_view/scroll_view.lua')
local sbody=assert(ssrc:match('(function ScrollView:setContentOffset.-\nend)\n'))
local SV={}; assert(load(sbody,'scroll','t',setmetatable({ScrollView=SV},{__index=_G})))()
local sv=setmetatable({contentOffset={x=0,y=0},setNeedsLayout=function()end,layoutIfNeeded=function()end},{__index=SV})
sv:setContentOffset(0,-16); sv:setContentOffset(0,-16); sv:setContentOffset(0,-32)

T.command('mark')
local dump=T.dump()
local function has(p) return dump:find(p,1,true)~=nil end
local function n(p) local c=0 for _ in dump:gmatch(p) do c=c+1 end return c end
ok(has('\tkey\t-\t0xD0|Down|down|0|') and has('\tkey\t-\t0xD0|Down|up|0|'),'key down/up lines')
ok(has('\tframe-gap\t-\t0.1840'),'frame gap logged')
ok(n('\timg%.new\t')==3,'three images created')
ok(n('\timg%.show\t[^\n]*UNTEXTURED')==1,'only the untextured image is flagged')
ok(n('\timg%.pos\t')==2,'unchanged pos repeats coalesced (5,5 once, 6,5 once)')
ok(n('\timg%.show\t')==3 and n('\timg%.hide\t')==1 and has('img.destroy'),'show/hide/destroy')
ok(has('|down|0.020|navigation|accepted') and has('rejected sequence') and has('rejected age') and has('rejected token'),'controller lines with reasons')
ok(n('\tcursor\t')==2 and has('|1:3|') and has('|shown|recreated'),'cursor: first move shown+recreated, then real position change only')
ok(n('\tscroll\t')==2,'scroll changes only')
ok(has('\tMARK\t') and has('# Trust menu trace v1') and has('# calls.img.pos=51'),'mark, header, call totals')

-- Save, then off restores everything.
local written
okc,msg=T.command('save','trace.txt',{open=function(p,m) return {write=function(_,b) written=b return true end,close=function() end} end})
ok(okc and written and written:find('MARK',1,true),'save writes the dump')
-- save uses io.open by default; off with a fake open via options
okc=T.command('off','trace.txt',{open=function() return {write=function() return true end,close=function() end} end})
ok(okc and not T.enabled and images.new==orig_new and images.visible==orig_visible and unregistered==77,'off restores images and unregisters keyboard')
local before=T.status().count; T.event('key','x'); ok(T.status().count==before,'off again records nothing')

-- Ring keeps the newest lines.
T.capacity=5; T.start({}); for i=1,12 do T.event('e',i) end
local s=T.status(); ok(s.count==5 and s.dropped==8,'ring capacity')
ok(T.dump():find('\te\t-\t12',1,true) and not T.dump():find('\te\t-\t7\n',1,true),'newest kept')
T.stop(); T.capacity=30000

-- Wiring.
ok(source('Trust.lua'):find("menu_trace.frame()",1,true) and source('Trust.lua'):find("menu_trace.event('ctl',...)",1,true),'Trust.lua frame + controller wiring')
ok(source('commands/MenuCommands.lua'):find("add_command('rendertrace'",1,true),'command registered')
ok(source('cylibs/ui/focus/focus_manager.lua'):find("'resign-all'",1,true),'focus wiring')
print('PASS menu_trace_test '..pass)
