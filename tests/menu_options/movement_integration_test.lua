-- Execute the actual root wiring and its internal follow/assist calls.
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
local block=assert(root:match('(    if movement_receiver then movement_receiver:close%(%) end.-movement_receiver:tick%(true%))'))
local Feedback=require('cylibs/util/command_feedback')
local Receiver=require('cylibs/ui/input/movement_receiver')
local events,requests,quiet={},{},{}
local options={movement={policy='Send',enabled=true,quiet=true}}
local focus,menu=true,false
local env=setmetatable({
    addon_settings={getSettings=function()return options end},
    hud={trustMenu={isVisible=function()return menu end}},state={IpcMode={value='All'}},
    windower={addon_path='addon/',trust={},has_focus=function()return focus end,
        create_dir=function()end,unregister_event=function()end,
        register_event=function(name,fn)events[name]=fn;return name end,
        ffxi={follow=function()requests[#requests+1]='native follow cancel'end,run=function(v)assert(v==false);requests[#requests+1]='native run cancel'end,get_info=function()return{logged_in=true}end,get_player=function()return{name='Myrr',status=0}end}},
    shortcuts={follow={handle_follow_me=function()requests[#requests+1]='follow';quiet[#quiet+1]=Feedback.is_quiet();return true end},
        assist={handle_assist_me=function()requests[#requests+1]='assist';quiet[#quiet+1]=Feedback.is_quiet();return true end}},
    io={open=function()return{write=function()end,close=function()end}end},
    require=function(name)
        if name=='socket' then return{gettime=function()return 100 end} end
        if name=='cylibs/ui/input/movement_receiver' then return Receiver end
        if name=='cylibs/util/command_feedback' then return Feedback end
        error(name)
    end,
},{__index=_G})
assert(load(block,'actual movement integration','t',env))()
assert(events.keyboard)
events.keyboard(0x7B,true);events.keyboard(0x7B,false)
assert(table.concat(requests,',')=='follow,assist' and quiet[1] and quiet[2])
assert(not Feedback.is_quiet(),'quiet scope leaked')
menu=true;events.keyboard(0x7B,true);events.keyboard(0x7B,false)
assert(#requests==2 and env.windower.trust.movement.last=='Trust menu')
menu=false;env.state.IpcMode.value='Receive'
events.keyboard(0x7B,true);events.keyboard(0x7B,false)
assert(#requests==2 and env.windower.trust.movement.ignored==2)
-- Optional handoff: local Stop precedes one ordered remote operation.
menu=false;env.state.IpcMode.value='All'
local order={}
options.movement.stop_on_movement=true;options.movement.start_others=true
env.handle_stop=function()order[#order+1]='stop'end
env.shortcuts.follow.get_follower=function()return{set_follow_target=function(_,target)
    assert(target==nil);order[#order+1]='clear local follow'end}end
env.IpcRelay={shared=function()return{send_message=function(_,m)
    order[#order+1]=m.command end}end}
local original_require=env.require
env.require=function(name)
    if name=='cylibs/messages/command_message' then return{new=function(c)return{command=c}end} end
    return original_require(name)
end
events.keyboard(0x7B,true);events.keyboard(0x7B,false)
assert(table.concat(order,',')=='stop,clear local follow,trust handoff Myrr --quiet')
assert(not Feedback.is_quiet())
menu=true;events.keyboard(0x7B,true);events.keyboard(0x7B,false)
assert(#order==3,'blocked movement must not stop or start anyone')
menu=false
-- Same-client takeover stops/clears locally, even with IPC send disabled.
order={};env.state.IpcMode.value='Receive'
events.keyboard(0x79,true);events.keyboard(0x79,true);events.keyboard(0x79,false)
assert(table.concat(order,',')=='stop,clear local follow','local takeover broadcast or repeated')
assert(env.windower.trust.movement.last=='local movement takeover')
assert(requests[#requests-1]=='native follow cancel' and requests[#requests]=='native run cancel')
options.movement.stop_on_movement=false
order={};events.keyboard(0x79,true);events.keyboard(0x79,false)
assert(#order==0 and env.windower.trust.movement.last=='local Stop disabled')
options.movement.stop_on_movement=true
menu=true;events.keyboard(0x79,true);events.keyboard(0x79,false)
assert(#order==0,'menu stick navigation must not take over')
menu=false
assert(load(block,'actual receiver replacement','t',env))()
assert(env.windower.trust.movement.received==0)
print('PASS actual Trust movement wiring: direct action order, quiet scope, menu/IPC guards and replacement')
