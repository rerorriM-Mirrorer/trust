-- Production pull state machine with game/event doubles; no native delivery claim.
local function event()
 local e={callbacks={}}
 function e:addAction(fn)self.callbacks[#self.callbacks+1]=fn end
 function e:trigger(...)local c={table.unpack(self.callbacks)};for _,fn in ipairs(c)do fn(...)end end
 function e:removeAllActions()self.callbacks={}end
 return e
end
local list={};function list:it()local i=0;return function()i=i+1;return self[i]end end
L=function(t)return setmetatable(t or {},{__index=list})end
ActionPriority={high=3,default=1}
local A={}
function A.new(_,_,_,index)return{target_index=index,event=event()}end
function A:on_action_complete()return self.event end
function A:complete(ok)if self.completed then return end;self.completed=true;self.success=ok;self.event:trigger(self,ok)end
function A:destroy()self.is_destroyed=true;self.event:removeAllActions()end
function A:getpriority()return self.priority end
package.loaded['cylibs/actions/action']=A
local now,blocked,skipped,claimed,active,eligible,ready=100,false,false,false,true,true,true
local char={id=1,index=1,status=1,target_index=2}
local mob={id=20,index=2,hpp=100,claim_id=0,distance=40^2,x=40,y=0,z=0}
local p={x=0,y=0,z=0}
local runs,engages,created,finished,notes={},0,0,{},{}
windower={ffxi={get_player=function()return char end,get_mob_by_index=function()return mob end,
 get_mob_by_id=function()return p end,follow=function()end,run=function(v)runs[#runs+1]=v end}}
package.loaded['cylibs/util/player_util']={face=function()end}
package.loaded.socket={gettime=function()return now end}
package.loaded['cylibs/util/timers/timer']={scheduledTimer=function()return{onTimeChange=function()return event()end,start=function()end,cancel=function()end,destroy=function()end}end}
package.loaded['cylibs/movement/recovery']={suspended=function()return blocked end,is_skipped=function()return skipped end,
 step=function()return false end,tag=function()end}
package.loaded['cylibs/actions/engage']={new=function()
 return{can_perform=function()return true end,on_action_complete=function()return event()end,
 perform=function()engages=engages+1 end,destroy=function()end}
end}
local children={}
local ability={get_name=function()return 'Dia'end,to_action=function(_,index,player,jobs,pulling)
 assert(index==2 and pulling==true);created=created+1
 local c=setmetatable(A.new(0,0,0,index),{__index=A})
 c.can_perform=function()return true end;c.perform=function()end;c.set_start_time=function()end
 c.cancel=function(self)self.cancelled=true;self:complete(false)end
 children[#children+1]=c;return c
end}
local Pull=require('cylibs/actions/pull_attempt')
local function new(melee)
 local queue={queue=L{},forced_delay_time=0}
 local o={queue=queue,index=2,id=20,name='Crab',ability=ability,range=melee and 2 or 19.5,melee=melee,
 active=function()return active end,eligible=function()return eligible end,ready=function()return ready end,
 claimed=function()return claimed end,start=function()end,report=function(s)notes[#notes+1]=s end,
 finished=function(ok)finished[#finished+1]=ok end}
 return Pull.new(o),queue
end

math.atan2=math.atan2 or math.atan
-- Melee pull: approach to 1.7 (inside the 2-yalm range), then stay settled
-- until the mob is beyond 2.5, so the pull no longer flaps at the range edge.
local a=new(true);a:perform()
local function at(d)mob.distance=d*d;mob.x=d;runs={};a:step();return runs[#runs] end
assert(type(at(1.9))=='number','approach continues inside 2.0 down to 1.7')
assert(at(1.6)==false,'stops once inside the approach limit')
assert(at(2.3)==nil,'settled: small drift outside 2.0 does not restart the approach')
assert(at(2.4)==nil and a.settled)
assert(type(at(2.7))=='number' and not a.settled,'clear drift (>2.5) re-approaches')
a:cancel()
-- Spell pull keeps its range as the approach limit (already range-0.5 upstream).
local s=new(false);s:perform();mob.distance=19^2;runs={};s:step()
assert(runs[#runs]==false or #runs==0,'spell pull inside range does not run')
s:cancel()
print('PASS pull approach hysteresis: melee approaches to 1.7, holds until 2.5; spell range unchanged')

-- Battle-menu recognition shared by pulls and the stick takeover.
local rsrc=assert(io.open('cylibs/movement/recovery.lua')):read('*a')
local fn=assert(rsrc:match('(function M%.battle_menu%(character%).-\nend)\n'))
local st=nil
local env=setmetatable({M={},windower={ffxi={get_player=function()return char end,
  get_mob_by_target=function(k)assert(k=='st');return st end}}},{__index=_G})
assert(load(fn,'battle_menu','t',env))()
local bm=env.M.battle_menu
assert(bm({status=1})==true,'engaged: menu_open is the battle menu')
assert(bm({status=0})==false,'idle: a real menu')
st={id=5};assert(bm({status=1})==false,'sub-target cursor open: still blocks');st=nil
-- The receiver consults it after looking up the character, and recovery uses it.
local trust=assert(io.open('Trust.lua')):read('*a')
local blk=assert(trust:match('blocked=function%(local_only%)(.-)\n        end,'))
local c=blk:find("local character=windower.ffxi.get_player()",1,true)
local g=blk:find("battle_menu(character)",1,true)
assert(c and g and c<g,'stick takeover ignores menu_open while engaged')
assert(rsrc:find("info.menu_open and not travel_follow and not M.battle_menu(character)",1,true))
print('PASS menu_open while engaged no longer blocks pulls or the stick takeover; sub-target still does')
