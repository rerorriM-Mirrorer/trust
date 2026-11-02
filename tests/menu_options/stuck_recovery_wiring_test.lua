-- Run production movement callbacks and menu constructors with native I/O mocked.
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local function method(path,first,last,env)
 local s=read(path);local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+1,true))
 setmetatable(env,{__index=_G});assert(load(s:sub(a,b-1),'actual movement hook','t',env))()
end
local held=true;local run_calls,follow_calls,step_calls=0,0,0
local recovery={step=function()step_calls=step_calls+1;return held end}
local renderer={addAction=function(_,fn)_G.motion_callback=fn;return fn end}
local player={x=0,y=0,z=0,id=1,status=0};local target={x=10,y=0,z=0,distance=100,index=2}
local env={RunToAction={},windower={ffxi={get_player=function()return player end,
 get_mob_by_index=function()return target end,get_mob_by_id=function()return player end,
 run=function()run_calls=run_calls+1 end,follow=function()follow_calls=follow_calls+1 end},send_command=function()end},
 Renderer={shared=function()return{onPrerender=function()return renderer end}end},
 require=function(n)assert(n=='cylibs/movement/recovery');return recovery end}
method('cylibs/actions/runto.lua','function RunToAction:perform()','function RunToAction:gettype()',env)
local a={target_index=2,distance=2,is_cancelled=function()return false end,
 dispose_bag={add=function()end}}
env.RunToAction.perform(a);motion_callback()
assert(step_calls==1 and run_calls==0 and follow_calls==0,'detour must replace original run steering')
-- FollowAction must not issue a new /follow while recovery owns movement.
local FollowAction={};env.FollowAction=FollowAction;env.Condition={check_conditions=function()return false end}
env.MaxDistanceCondition={new=function()end};env.windower.ffxi.get_mob_by_target=function()return target end
method('cylibs/actions/follow.lua','function FollowAction:check_follow','function FollowAction:is_following()',env)
a.is_following=function()error('original follow ran during recovery')end
FollowAction.check_follow(a);assert(step_calls==2)
-- Coordinate movement registers its callback even when initially held; normal
-- steering resumes once recovery releases it.
local RunToLocationAction={};env.RunToLocationAction=RunToLocationAction
local position={0,0,0};env.player_util={get_player_position=function()return position end}
method('cylibs/actions/runtolocation.lua','function RunToLocationAction:perform()','function RunToLocationAction:target_distance()',env)
a.x,a.y,a.z,a.distance,a.vector_location=10,0,0,1,{10,0,0}
a.target_distance=function()return 10 end
RunToLocationAction.perform(a);local baseline=run_calls;motion_callback();assert(run_calls==baseline)
held=false;motion_callback();assert(run_calls==baseline+1)
-- Load the actual nested menu and construct both editors.
local real_require=require
local function constructor(...)return{args={...}}end
package.loaded['cylibs/ui/menu/menu_item']={new=function(buttons,children,view,title)return{buttons=buttons,children=children,view=view,title=title}end,action=constructor}
package.loaded['cylibs/ui/collection_view/items/button_item']={default=function(s)return s end}
package.loaded['ui/settings/editors/config/ConfigEditor']={new=function(owner,data,items)return{data=data,items=items}end}
for _,n in ipairs({'PickerConfigItem','BooleanConfigItem','ConfigItem'}) do
 package.loaded['ui/settings/editors/config/'..n]={new=constructor}
end
L=function(t)return t end
local options={movement={policy='Ready',recovery={mode='Detour'}}};local owner={getSettings=function()return options end}
local menu=real_require('ui/settings/menus/MovementSettingsMenuItem').new(owner)
assert(not menu.children['Stuck Recovery'] and not menu.children.Recovery)
local sub=real_require('ui/settings/menus/RecoverySettingsMenuItem').new(owner);assert(sub.title=='Recovery')
local editor=sub.view();assert(editor.data==options.movement.recovery and #editor.items==10)
local expected={'mode','pulling','following','paths','interval','min_movement','detour_distance','attempts','pull_cooldown','diagnostics'}
for i,key in ipairs(expected)do assert(editor.items[i].args[1]==key)end
assert(menu.view().data==options.movement and menu.view().items[1].args[2]=='Ready')
assert(editor.items[1].args[2]=='Detour','saved Recovery selection was reset to Off')
options.movement.recovery.mode='Pause';assert(sub.view().items[1].args[2]=='Pause')
options.movement.recovery.mode='Off';assert(sub.view().items[1].args[2]=='Off')
print('PASS actual run/follow/location hooks replace steering and separate Recovery config preserves saved selections and exposes all controls')
