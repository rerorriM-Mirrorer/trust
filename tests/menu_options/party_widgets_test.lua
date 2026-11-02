local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function method(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true),first);local b=assert(s:find(last,a+1,true),last)
 assert(load(s:sub(a,b-1),'production widget method','t',env))()
end
local Widget={}
local env=setmetatable({TrustStatusWidget=Widget,windower={addon_path='addon/'},
 Color={clear={},new=function(...)return{...}end}},{__index=_G})
method('ui/widgets/TrustStatusWidget.lua','function TrustStatusWidget:getCompactState()','function TrustStatusWidget:setCompactPartyCount',env)
local function view()return{setNeedsLayout=function()end,layoutIfNeeded=function()end,
 loadImage=function(s,p)s.path=p end,setVisible=function(s,v)s.visible=v end,setBackgroundColor=function()end}end
local enabled=false
local timer={running=false,isRunning=function(s)return s.running end,start=function(s)s.running=true end,cancel=function(s)s.running=false end}
local w=setmetatable({compactMode=true,currentAction='Idle',addonEnabled={getValue=function()return enabled end},
 compactIcon=view(),compactGlowOuter=view(),compactGlowInner=view(),compactTint=view(),compactCrystal=view(),compactPulseTimer=timer},{__index=Widget})
w:refreshCompactIcon();assert(w.compactIcon.alpha==155 and w.compactIcon.path:find('icon_timer.png',1,true))
assert(not timer.running and not w.compactCrystal.visible)
enabled=true;w:refreshCompactIcon();assert(w.compactIcon.alpha==230 and w.compactIcon.path:find('menu_mapsg_book.png',1,true))
w.currentAction='Casting';w:refreshCompactIcon();assert(w.compactIcon.alpha==230 and timer.running and w.compactCrystal.visible)
enabled=false;w:refreshCompactIcon();assert(w.compactIcon.alpha==155 and not timer.running and w.compactCrystal.alpha==0,'Off must win over active action')
-- The production pet-widget factories return before importing any UI or gauges.
for _,job in ipairs({{'SMN','SummonerTrust'},{'PUP','PuppetmasterTrust'}})do
 local class={};local petenv=setmetatable({addon_settings={getSettings=function()return{}end},
 require=function()error('hidden pet widget must not construct a visual layer')end},{__index=_G});petenv[job[2]]=class
 method('cylibs/trust/data/'..job[1]..'.lua','function '..job[2]..string.char(58)..'get_widget()','return '..job[2],petenv)
 assert(class.get_widget({})==nil)
 petenv.addon_settings.getSettings=function()return{widgets={hide_pet=true}}end;assert(class.get_widget({})==nil)
end
assert(source('settings/TrustAddonSettings.lua'):find('default.widgets = {hide_pet=true}',1,true))
print('PASS actual compact opacity/Off/Idle/animated Active transitions and SMN/PUP hidden visual factories; pet automation untouched')
