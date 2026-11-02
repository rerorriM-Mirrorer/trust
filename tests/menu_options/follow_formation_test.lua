local Formation=require('cylibs/movement/follow_formation')
local function near(a,b)assert(math.abs(a-b)<.00001,tostring(a)..' ~= '..tostring(b))end
local ids={50,10,30,20,40,60}
local leader=10;local f=Formation.new()
local a,r,rank=f:goal(leader,1,{0,0,0},ids,20,1)
assert(rank==1 and a[1]<0 and a[2]>0 and r==.2)
local b=Formation.new():goal(leader,1,{0,0,0},{10,20,30,40,50,60},30,1)
near(a[1],b[1]);near(a[2],-b[2])
local c=Formation.new():goal(leader,1,{0,0,0},ids,40,1);near(c[1],-1);near(c[2],0)
-- Moving north rotates both behind/left; stationary facing is not an input.
local moved=f:goal(leader,1,{0,1,0},ids,20,1)
assert(moved[1]<0 and moved[2]<1)
local held=f:goal(leader,1,{0,1,0},ids,20,1)
near(held[1],moved[1]);near(held[2],moved[2])
local jitter=f:goal(leader,1,{.01,1.01,0},ids,20,1)
near(jitter[1]-held[1],.01);near(jitter[2]-held[2],.01)
local scaled=Formation.new():goal(leader,1,{0,0,0},ids,20,2)
near(scaled[1],a[1]*2);near(scaled[2],a[2]*2)
local tiny,tr=Formation.new():goal(leader,1,{0,0,0},ids,20,.1)
assert(tr==.15 and math.abs(tiny[1])<.1)
assert(not f:goal(leader,1,{0,0,0},ids,leader,1))
assert(not f:goal(99,1,{0,0,0},ids,20,1))
local switched=f:goal(30,2,{0,0,0},ids,20,1);assert(switched[1]<0)
-- Execute actual follower wiring, including bypasses and coalescing.
local file=assert(io.open('cylibs/trust/roles/follower.lua'));local src=file:read('*a');file:close()
local methods={};local dest,created,pushed,tags={},0,0,0
local point={id=20,status=0,x=0,y=0,z=0}
local target={get_id=function()return 10 end,get_name=function()return'Leader'end,get_position=function()return{10,0,0}end}
local queue={push_action=function(self,a)pushed=pushed+1;self.current_action=a end}
local env=setmetatable({Follower=methods,state={AutoFollowMode={value='Always'}},V=function(v)return v end,
 windower={ffxi={get_player=function()return{id=20}end,get_mob_by_id=function()return point end,get_info=function()return{zone=1}end}},
 player_util={get_player_position=function()return{point.x,point.y,point.z}end,
 distance=function(a,b)return math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)end},
 RunToLocation={new=function(x,y,z,r)created=created+1;local a={x=x,y=y,z=z,distance=r,is_cancelled=function()return false end,cancel=function()queue.current_action=nil end};dest=a;return a end},
 require=function(name)assert(name=='cylibs/movement/recovery');return{tag=function()tags=tags+1 end}end},{__index=_G})
for _,name in ipairs({'check_distance','follow_formation_goal'})do
 local body=assert(src:match('(function Follower:'..name..'%(.-)\nfunction Follower:'))
 assert(load(body,'actual '..name,'t',env))()
end
local self=setmetatable({action_queue={is_enabled=true},state_var={value='Always'},fan_out=true,formation=Formation.new(),
 maxfollowdistance=35,walk_action_queue=queue,get_follow_target=function()return target end,
 get_distance=function()return 1 end,is_valid_target=function()return true end,
 get_party=function()return{get_party_member_ids=function()return ids end}end},{__index=methods})
self:check_distance();assert(dest.formation and created==1 and tags==1)
target.get_position=function()return{11,0,0}end
self:check_distance();assert(created==1 and pushed==1 and dest.vector_location,'moving slot was queued instead of updated')
self.action_queue.pull_action={};self:check_distance();assert(created==1);self.action_queue.pull_action=nil
self.action_queue.is_enabled=false;self:check_distance();assert(created==2 and not dest.formation,'Stop must switch to ordinary follow');self.action_queue.is_enabled=true
self.manual_pause=true;local paused=created;self:check_distance();assert(created==paused);self.manual_pause=false
queue.current_action=nil;self.fan_out=false;self:check_distance();assert(not dest.formation and dest.distance==1)
queue.current_action=nil;self.fan_out=true;self.state_var.value='Path';self:check_distance();assert(not dest.formation)
queue.current_action=nil;self.state_var.value='Always';point.status=1;self:check_distance();assert(not dest.formation)
-- A height change retires the active slot before returning to plain following.
point.status=0;queue.current_action=nil;self:check_distance();assert(dest.formation)
point.z=-2;self:check_distance();assert(not dest.formation);point.z=0
-- Near enough to the slot: no new walk, even though outside its arrival radius.
point.status=0;point.x=10.4;point.y=.7;queue.current_action=nil
local goal,radius=self.formation:goal(10,1,{11,0,0},ids,20,1)
point.x=goal[1]+radius+.1;point.y=goal[2]
local before=created;self:check_distance();assert(created==before,'hysteresis restarted idle follower')
local settings=assert(io.open('settings/TrustAddonSettings.lua'));local st=settings:read('*a');settings:close();assert(st:find('default.follow.fan_out = true',1,true))
local menu=assert(io.open('ui/settings/menus/FollowSettingsMenuItem.lua'));local mt=menu:read('*a');menu:close()
local _,count=mt:gsub("BooleanConfigItem.new%('fan_out', 'Fan Out'%)",'');assert(count==2)
print('PASS formation geometry/heading/slots/tolerance, actual follower coalescing and Off/path/combat/pull/Stop bypasses; default and both menu paths')
