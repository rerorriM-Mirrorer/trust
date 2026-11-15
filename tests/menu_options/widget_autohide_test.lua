-- A: widget autohide state machine. Static/simulated only; no FFXI client.
package.path='./?.lua;'..package.path
local Autohide=require('ui/WidgetAutohide')

local now,focused,automated,suspended,position=100,true,false,nil,{x=0,y=0}
local settings={autohide=false,autohide_seconds=5}
local saves,visible,applied=0,true,0
local fail_save=false
local a=Autohide.new({
    settings=function()return settings end,
    save=function()saves=saves+1;if fail_save then return false,'disk full' end return true end,
    clock=function()return now end,
    focused=function()return focused end,
    apply=function(v)visible=v;applied=applied+1 end,
    position=function()return position end,
    automated=function()return automated end,
    suspended=function()return suspended end,
})
local function advance(seconds)now=now+seconds;a:tick()end

-- Disabled by default: never hides, ignores activity.
a:tick();advance(60)
assert(visible and a.state=='off' and applied==0,'disabled autohide changed visibility')
assert(a:touch('keyboard')==false and a.touches==0)

-- Command surface: bare toggle, explicit idempotent on/off, durations.
local ok,msg=a:command('on')
assert(ok and msg=='Widget autohide ON, hide after 5s' and settings.autohide==true and saves==1,msg)
ok=a:command('on');assert(ok and saves==1,'repeated on must not save again')
ok,msg=a:command('off');assert(ok and msg=='Widget autohide OFF' and settings.autohide==false and saves==2)
ok=a:command('off');assert(ok and saves==2,'repeated off must not save again')
ok,msg=a:command();assert(ok and settings.autohide==true,'bare command toggles on')
ok=a:command();assert(ok and settings.autohide==false,'bare command toggles off')
ok,msg=a:command('10');assert(ok and settings.autohide==true and settings.autohide_seconds==10 and msg:find('10s'),msg)
ok,msg=a:command('0');assert(not ok and msg:find('Seconds must be'),'zero rejected')
ok,msg=a:command('601');assert(not ok,'above maximum rejected')
ok,msg=a:command('-3');assert(not ok,'negative rejected')
ok,msg=a:command('banana');assert(not ok and msg:find('Usage'),'junk rejected')
assert(settings.autohide_seconds==10,'rejected input changed the duration')
ok=a:command('ON');assert(ok,'case-insensitive')

-- Hide after the idle time, wake on activity, restart the countdown.
settings.autohide=true;settings.autohide_seconds=5
a:command('off');a:command('5')
visible=true
advance(4.9);assert(visible and a.state=='awake','hid early')
advance(0.2);assert(not visible and a.state=='hidden','did not hide at timeout')
local hides=a.hides
advance(30);assert(not visible and a.hides==hides,'hidden state must not re-hide')
assert(a:touch('keyboard',true) and visible and a.state=='awake','keyboard did not wake')
advance(4);assert(visible)
a:touch('mouse',true);advance(4);assert(visible,'activity did not reset the timer')
advance(1.1);assert(not visible)

-- Focus-gated sources never wake an unfocused client.
focused=false
assert(a:touch('mouse',true)==false and not visible,'unfocused mouse woke widgets')
assert(a:touch('controller')==true and visible,'controller command must wake')
focused=true
advance(6);assert(not visible)
assert(a:touch('focus') and visible,'regaining focus must wake')

-- Menus / widget editing pause the countdown, then restart it.
advance(2)
suspended='Trust menu'
advance(100);assert(visible,'hid while a menu was open')
assert(a:status():find('paused: Trust menu',1,true))
suspended=nil
advance(4.9);assert(visible,'timer did not restart after the menu closed')
advance(0.2);assert(not visible)
suspended='widget in use'
advance(1);assert(visible,'a widget in use must be shown even if already hidden')
suspended=nil;advance(6);assert(not visible)

-- Player movement wakes; Trust automation does not.
a:touch('keyboard');advance(0.3)
a.next_sample=0;position={x=0,y=0};advance(0.3)         -- baseline sample
advance(6);assert(not visible)
automated=true
for i=1,20 do position={x=i,y=0};advance(0.3) end
assert(not visible,'automated movement kept the widgets awake')
automated=false
position={x=position.x+1,y=0};advance(0.3)
assert(visible and a.source=='movement','manual movement did not wake')
advance(6);assert(not visible)
position={x=position.x+500,y=0};advance(0.3)
assert(not visible,'a zone-sized jump counted as input')
position={x=position.x+0.01,y=0};advance(0.3)
assert(not visible,'jitter counted as input')
position=nil;advance(0.3);position={x=1,y=1};advance(0.3)
assert(not visible,'losing then regaining position counted as input')

-- Turning autohide off restores widgets immediately; close() never leaves them hidden.
a:command('off');assert(visible and a.state=='off')
a:command('on');visible=true;advance(6);assert(not visible)
a:close();assert(visible and a.state=='off','close left widgets hidden')

-- A failed save is reported and not applied silently.
fail_save=true;settings.autohide=false
ok,msg=a:command('on');assert(not ok and msg=='disk full')
fail_save=false

-- Out-of-range stored duration falls back to the default rather than hiding instantly.
settings.autohide=true;settings.autohide_seconds=0
assert(a:seconds()==5)
settings.autohide_seconds='abc';assert(a:seconds()==5)

print('PASS widget autohide: defaults, commands, timer, wake sources, suspension, movement filter, cleanup')
