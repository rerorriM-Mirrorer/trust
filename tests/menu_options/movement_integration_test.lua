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
        ffxi={get_info=function()return{logged_in=true}end,get_player=function()return{name='Myrr',status=0}end}},
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
assert(load(block,'actual receiver replacement','t',env))()
assert(env.windower.trust.movement.received==0)
print('PASS actual Trust movement wiring: direct action order, quiet scope, menu/IPC guards and replacement')
