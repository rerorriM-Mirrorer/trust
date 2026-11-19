-- Combat recovery batch (2026-11-19): hardcoded 1 s check and 3 + 3 yalm detours,
-- 45-degree back-and-side detours for following only, combat positioning that never
-- gives up while engaged, and RunAway taking part in recovery.
local now=0;local clock=function()return now end
package.preload['socket']=function()return{gettime=clock}end
package.preload['cylibs/movement/stuck_detector']=function()return dofile('cylibs/movement/stuck_detector.lua')end
local function dist(a,b)return math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2)end

-- 1) Detector: detours grow 3, 6, 9 ... and the shapes differ.
local D=dofile('cylibs/movement/stuck_detector.lua')
local s={mode='Detour',interval=1,min_movement=.5,detour_distance=3,detour_step=3,attempts=6,shape='side'}
local d=D.new(clock)
local pos,goal={0,0,0},{20,0,0}
local reaches,offsets={},{}
for i=1,400 do
    now=now+.1
    local decision,offset,started=d:sample('k',pos,goal,1,s,false)
    if started then reaches[#reaches+1]=d.context.reach;offsets[#offsets+1]=offset end
    if decision=='failed' then break end
end
assert(table.concat(reaches,',')=='3,6,9,12,15,18','detour lengths: '..table.concat(reaches,','))
assert(math.abs(dist(offsets[1],pos)-3)<.01 and offsets[1][1]>0,'side detour goes slightly forward')
assert(offsets[1][2]>0 and offsets[2][2]<0,'side detours alternate')
d:reset();s.shape='back';now=now+5
local first
for i=1,30 do now=now+.1;local _,o,st=d:sample('k',pos,goal,1,s,false);if st then first=o;break end end
assert(first and math.abs(dist(first,pos)-3)<.01,'back detour is 3 yalms')
assert(first[1]<0 and math.abs(math.abs(first[2])-math.abs(first[1]))<.01,'back detour is 45 degrees back and to the side: '..first[1]..','..first[2])
-- The first check comes after 1 s without movement.
d:reset();now=now+5;local t0=now;local when
for i=1,30 do now=now+.1;local _,_,st=d:sample('k',pos,goal,1,s,false);if st then when=now-t0;break end end
assert(when and when>=1 and when<1.25,'stuck check after about 1 s: '..tostring(when))
print('PASS detector: 1 s check, detours 3/6/9/12/15/18 yalms, side shape alternates slightly forward, back shape at 45 degrees')

-- 2) Adapter: hardcoded values ignore saved ones; shape per kind; combat cycles.
local config={mode='Detour',interval=5,detour_distance=1,min_movement=.5,attempts=2,pull_cooldown=5,diagnostics=false,verbose=false}
addon_settings={getSettings=function()return{movement={recovery=config},follow={auto_pause=false}}end}
local character={id=1,status=1,buffs={}}
local info={zone=100,logged_in=true}
windower={ffxi={get_info=function()return info end,get_player=function()return character end,
    follow=function()end,run=function()end},send_command=function()end}
addon_system_message=function()end
local R=dofile('cylibs/movement/recovery.lua')
local function act(kind)
    local a={is_cancelled=function(x)return x.cancelled end,cancel=function(x)x.cancelled=true end,
        set_start_time=function(x)x.renewed=(x.renewed or 0)+1 end,gettype=function()return'sequenceaction'end}
    R.tag(a,kind,42,kind..':42');return a
end
local c=act('combat')
assert(c.recovery_timeout and math.abs(c.recovery_timeout-21.75)<.01,'queue budget covers 3 detours up to 9 yalms: '..tostring(c.recovery_timeout))
config.attempts=nil;local c6=act('combat');config.attempts=2
assert(c6.recovery_timeout>=50,'default 6 attempts get a longer budget: '..tostring(c6.recovery_timeout))
local starts={}
local old_sample=nil
for i=1,600 do
    now=now+.1
    R.step(c,{0,0,0},{20,0,0},3)
    if c.renewed and c.renewed>=2 then break end
end
assert(not c.cancelled,'engaged combat positioning never gives up')
assert((c.renewed or 0)>=2,'combat starts new detour cycles with a fresh queue budget')
-- Disengaged: a used-up cycle cancels instead of looping.
character.status=0;R.reset(true)
local c2=act('combat')
for i=1,600 do now=now+.1;R.step(c2,{0,0,0},{20,0,0},3);if c2.cancelled then break end end
assert(c2.cancelled,'combat recovery stops once no longer engaged')
-- Cast pending holds combat recovery (no detour while casting).
character.status=1;R.reset(true);R.casting_until=now+30
local c3=act('combat')
for i=1,40 do now=now+.1;assert(R.step(c3,{0,0,0},{20,0,0},3)==true) end
assert(R.last~='detour 1' and not c3.cancelled,'cast pending holds combat recovery')
R.casting_until=0
-- Combat can be switched off on its own.
config.combat=false;R.reset(true)
assert(R.step(act('combat'),{0,0,0},{20,0,0},3)==false,'Recover combat positioning off bypasses recovery');config.combat=nil
print('PASS adapter: saved interval/detour ignored, budget covers growing detours, combat cycles while engaged, cancels when not, cast hold, combat toggle')

-- 3) RunAway asks recovery before backing off, toward a point beyond its distance.
local seen
package.loaded['cylibs/movement/recovery']={step=function(_,p,g,r)seen={p=p,g=g,r=r};return true end}
local function load_windower(path)
    local f=assert(io.open(path));local src=f:read('*a');f:close()
    src=src:gsub("('[^'\n]*'):(%a+)%(",function(q,m)return '('..q..'):'..m..'(' end)
    return assert((loadstring or load)(src,'@'..path))()
end
local frame
local Action={};Action.__index=Action;Action.new=function()return setmetatable({},Action)end
for _,n in ipairs({'vectors','math','logger'}) do package.loaded[n]=true end
package.loaded['cylibs/events/dispose_bag']={new=function()return{add=function()end}end}
package.loaded['cylibs/ui/views/render']={shared=function()return{onPrerender=function()return{addAction=function(_,fn)frame=fn end}end}end}
package.loaded['cylibs/actions/action']=Action
local RunAway=load_windower('cylibs/actions/runaway.lua')
local ra=RunAway.new(7,5);ra.dispose_bag={add=function()end};ra.is_cancelled=function()return false end
windower.ffxi.get_player=function()return{id=1,target_locked=false}end
windower.ffxi.get_mob_by_index=function()return{x=0,y=0,z=0,distance=4}end
windower.ffxi.get_mob_by_id=function()return{x=2,y=0,z=0}end
ra:perform();frame()
assert(seen and math.abs(seen.g[1]-5.3)<.01 and math.abs(seen.g[2])<.01,'RunAway goal is just past its distance, away from the target')
print('PASS RunAway takes part in recovery with a goal beyond its distance')
