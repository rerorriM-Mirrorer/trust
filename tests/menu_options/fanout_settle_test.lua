-- Fan Out settle: a follower near an unreachable slot stops after settle_time
-- without progress, stays put until the slot moves 1 yalm, and a leader that keeps
-- walking never triggers a settle.
local now=0;local clock=function()return now end
package.preload['socket']=function()return{gettime=clock}end
package.preload['cylibs/movement/stuck_detector']=function()return dofile('cylibs/movement/stuck_detector.lua')end
local config={mode='Detour',interval=2,min_movement=.5,detour_distance=2,attempts=2,pull_cooldown=5,settle_time=1,diagnostics=false}
addon_settings={getSettings=function()return{movement={recovery=config},follow={auto_pause=false}}end}
local character={id=1,status=0,buffs={}}
local info={zone=100,logged_in=true}
local stops=0
windower={ffxi={get_info=function()return info end,get_player=function()return character end,
    follow=function()end,run=function(x)if x==false then stops=stops+1 end end},send_command=function()end}
addon_system_message=function()end
local R=dofile('cylibs/movement/recovery.lua')

local function slot_action()
    local a={formation=true,follow_while_stopped=true,
        is_cancelled=function()return false end,cancel=function()end,
        complete=function(s,ok)s.completed=true;s.ok=ok end}
    R.tag(a,'following',nil,'following:Cioara')
    return a
end

-- 1) Blocked 0.8 yalm short of a slot (inside a wall): settles after ~1s.
local a=slot_action();local pos={0,0,0};local goal={.8,0,0}
local held
for i=1,9 do now=now+.1;held=R.step(a,pos,goal,.3) end
assert(not a.completed and held==false,'keeps steering directly before settle_time')
for i=1,3 do now=now+.1;held=R.step(a,pos,goal,.3) end
assert(a.completed and a.ok and held==true and stops>0,'settles and stops running after 1s without progress')
assert(R.is_settled('following:Cioara',{.8,0,0}),'settled spot remembered')
assert(R.step(a,pos,goal,.3)==true,'a completed action never steers again')

-- 2) Small leader shuffles (slot moves < 1 yalm) keep it settled; 1 yalm re-arms.
assert(R.is_settled('following:Cioara',{1.4,.3,0}),'small slot move stays settled')
assert(not R.is_settled('following:Cioara',{1.9,0,0}),'slot moving 1+ yalm re-arms')
assert(R.formation_settled==nil)

-- 3) Steady progress toward the slot never settles.
local b=slot_action();now=now+1
for i=1,30 do now=now+.1;R.step(b,{i*.02,0,0},{1.8,0,0},.3) end
assert(not b.completed,'progress keeps it moving')

-- 4) Leader walking: the slot moves every step, so pacing behind it never settles.
local c=slot_action();now=now+1
for i=1,50 do now=now+.1;R.step(c,{i*.1,0,0},{1+i*.1,0,0},.3) end
assert(not c.completed,'moving slot never settles')

-- 5) Stick handoff / new leader clears the settle; another leader key does not match.
local d=slot_action();now=now+1
for i=1,15 do now=now+.1;R.step(d,{0,0,0},{.8,0,0},.3) end
assert(d.completed and R.formation_settled)
assert(not R.is_settled('following:Myrr',{.8,0,0}),'a different leader is never treated as settled')
for i=1,15 do now=now+.1;R.step(slot_action(),{0,0,0},{.8,0,0},.3) end
R.clear_settle();assert(not R.is_settled('following:Cioara',{.8,0,0}),'handoff clears it')

-- 6) Ordinary (non-formation) following is unaffected.
local e={is_cancelled=function()return false end,cancel=function()end,complete=function(s)s.completed=true end}
R.tag(e,'following',nil,'following:Cioara');now=now+1
for i=1,20 do now=now+.1;R.step(e,{0,0,0},{.8,0,0},.3) end
assert(not e.completed,'plain following never settles')

-- 7) Formation heading starts from the leader's facing before it moves.
local F=dofile('cylibs/movement/follow_formation.lua')
local f=F.new()
local g=f:goal(10,100,{0,0,0},{10,20},20,1,math.pi/2) -- facing pi/2 -> forward (0,-1)
assert(g and math.abs(g[1])<1 and g[2]>0,'slot is behind the way the leader faces: '..g[1]..','..g[2])
print('PASS fan out settle: stops short of unreachable slot, holds until slot moves 1 yalm or handoff, moving/progress/plain follow unaffected, facing seeds heading')
