-- Keep-autorun takeover policy, autorun detection, notices, command, defaults and status.
-- Production modules run against Windower doubles; the real native call is NOT exercised here.
local function src(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local function load_with(path,env)return assert(loadfile(path,'t',env))()end

-- Windower double: player table is replaced per case; follow/run calls are counted.
local player,follows,runs={},0,0
local W={ffxi={get_player=function()return player end,
    follow=function()follows=follows+1 end,
    run=function(v)if v==false then runs=runs+1 end end}}
local env=setmetatable({windower=W},{__index=_G})
local Autorun=load_with('cylibs/movement/autorun.lua',env)

-- read(): nil unless Windower provides a boolean; /follow is not kept autorun.
player=nil;assert(Autorun.read()==nil,'no player is unknown')
player={};assert(Autorun.read()==nil,'missing field is unknown, never guessed')
player={autorun='yes'};assert(Autorun.read()==nil)
player={autorun=true};assert(Autorun.read()==true)
player={autorun=false};assert(Autorun.read()==false)
player={autorun=true,follow_index=0};assert(Autorun.read()==true)
player={autorun=true,follow_index=17};assert(Autorun.read()==false,'native /follow is not autorun to keep')
-- should_preserve(): setting, ownership and detection must all agree.
player={autorun=true}
assert(Autorun.should_preserve(true,false)==true)
assert(Autorun.should_preserve(false,false)==false and Autorun.should_preserve(nil,false)==false,'default off')
assert(Autorun.should_preserve(true,true)==false,'Trust-owned run is still released')
player={};assert(Autorun.should_preserve(true,false)==false,'unknown state keeps the old behavior')
player={autorun=false};assert(Autorun.should_preserve(true,false)==false)

-- takeover.apply(): real production engine, real autorun module.
local Control=require('cylibs/trust/control_state')
local queue={is_enabled=true,control_state='Active'}
local follower={manual_pause=false,walk_action_queue={}}
function follower.stop_following()W.ffxi.run(false)end
local trust={role_with_type=function()return follower end}
local enabled={value=true,getValue=function(s)return s.value end,setValue=function(s,v)s.value=v end}
function queue.disable(s)s.is_enabled=false;W.ffxi.run(false)end
function queue.enable(s)s.is_enabled=true end
local tenv=setmetatable({windower=W,require=function(p)
    if p=='cylibs/trust/control_state'then return Control end
    if p=='cylibs/movement/autorun'then return Autorun end
    return{reset=function()end}end},{__index=_G})
local Takeover=load_with('cylibs/movement/takeover.lua',tenv)
local function reset()follows,runs=0,0;queue.current_action=nil;queue.movement_suspended=nil;follower.walk_action_queue.current_action=nil;follower.manual_pause=false;enabled.value=true;queue.is_enabled=true end

reset();player={autorun=true}
Takeover.apply(trust,queue,enabled,true,false)
assert(follows==1,'default (argument omitted) still cancels native follow/autorun')
reset();Takeover.apply(trust,queue,enabled,true,false,false)
assert(follows==1,'setting off cancels as before')
reset();Takeover.apply(trust,queue,enabled,true,false,true)
assert(follows==0 and runs==0,'kept autorun: no native follow() and no native run(false)')
assert(queue.movement_suspended and follower.manual_pause and not enabled.value,'Trust still takes the gates and pauses itself')
reset();player={autorun=false};Takeover.apply(trust,queue,enabled,true,false,true)
assert(follows==1,'setting on but not autorunning: ordinary takeover')
reset();player={};Takeover.apply(trust,queue,enabled,true,false,true)
assert(follows==1,'setting on but state unavailable: ordinary takeover')
reset();player={autorun=true,follow_index=5};Takeover.apply(trust,queue,enabled,true,false,true)
assert(follows==1,'native /follow of another character is still cancelled')
reset();player={autorun=true};queue.current_action={gettype=function()return'runtolocationaction'end}
Takeover.apply(trust,queue,enabled,true,false,true)
assert(follows==1 and runs>=1,'Trust-owned run is released and follow cancelled even with the setting on')
reset();assert(Takeover.owned(trust,queue)==false)
queue.current_action={gettype=function()return'runtoaction'end};assert(Takeover.owned(trust,queue)==true)
queue.current_action=nil;follower.walk_action_queue.current_action={gettype=function()return'runtolocationaction'end}
assert(Takeover.owned(trust,queue)==true,'follower walk queue counts as Trust-owned movement')

-- monitor(): baseline silence, two-sample debounce, Trust-owned and unreadable cases.
local now,state,owned,wanted,notes,unavailable=0,false,false,true,{},0
local M=Autorun.monitor({clock=function()return now end,enabled=function()return wanted end,
    read=function()return state end,owned=function()return owned end,
    notify=function(on)notes[#notes+1]=on end,unavailable=function()unavailable=unavailable+1 end})
local function tick(dt)now=now+(dt or .3);M:update()end
tick();assert(#notes==0,'first sample is only a baseline')
state=true;tick();assert(#notes==0,'one sample is not a transition')
tick();assert(#notes==1 and notes[1]==true,'autorun on reported after two samples')
tick();tick();assert(#notes==1,'no repeats while unchanged')
state=false;tick();state=true;tick();assert(#notes==1,'a flicker is not reported')
state=false;tick();tick();assert(#notes==2 and notes[2]==false,'autorun off reported')
owned=true;state=true;tick();tick();tick();assert(#notes==2,'Trust running the character is not news')
owned=false;state=false;tick();tick();assert(#notes==2,'state after Trust stops matches baseline: silent')
now=now+.05;local before=#notes;M:update();assert(#notes==before,'update is throttled to 0.25s')
wanted=false;tick();wanted=true;state=true;tick();assert(#notes==2,'disabling resets; re-enabling baselines the current state silently')
state=nil;M:reset();tick();tick();tick();assert(unavailable==1,'unavailable is reported once per enabling')

-- //trust keepautorun, with the production handler and dispatch policy.
local settings={movement={keep_autorun=false}};local saved,chat=0,{}
string.color=function(s,c)return '['..c..']'..s end
package.loaded.chat={}
local methods={}
local cenv=setmetatable({GeneralTrustCommands=methods,
    windower={add_to_chat=function(_,line)chat[#chat+1]=line end},
    addon_settings={getSettings=function()return settings end,saveSettings=function()saved=saved+1;return true end}},{__index=_G})
local text=src('commands/GeneralCommands.lua')
local a=assert(text:find('function GeneralTrustCommands:handle_keep_autorun(',1,true))
local b=assert(text:find('function GeneralTrustCommands:handle_fan(',a,true))
assert(load(text:sub(a,b-1),'keepautorun','t',cenv))()
local c=setmetatable({},{__index=methods})
assert(c:handle_keep_autorun() and settings.movement.keep_autorun==true and saved==1,'bare toggles on')
assert(c:handle_keep_autorun(nil,'ON') and saved==1,'explicit set is idempotent and does not resave')
assert(c:handle_keep_autorun(nil,'off') and settings.movement.keep_autorun==false and saved==2)
local ok,msg=c:handle_keep_autorun(nil,'maybe');assert(not ok and msg:find('Usage: //trust keepautorun',1,true) and saved==2)
assert(not c:handle_keep_autorun(nil,'on','extra'))
assert(chat[1]:find('Keep autorun on stick movement',1,true) and chat[1]:find('ON',1,true))
assert(text:find("add_command('keepautorun'",1,true),'command is registered with help text')
assert(dofile('cylibs/ui/menu/menu_command_policy.lua').effect('keepautorun',{'on'})=='commit')

-- Defaults: the real settings module. Off for both options on fresh and existing characters.
L=function(t)return t or {}end;S=L
package.loaded['cylibs/events/Luvent']={newEvent=function()return{trigger=function()end}end}
package.loaded['settings/shared_preferences']={configure=function()end}
package.loaded['cylibs/trust/commands/command_settings']={recordSaved=function()end}
local function copy(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
local function merge(x,y)for k,v in pairs(y)do if type(v)=='table' and type(x[k])=='table'then merge(x[k],v)else x[k]=copy(v)end end;return x end
local factory,store
config={load=function(d)factory=d;return merge(copy(d),store)end,save=function(v)store=copy(v)end}
store={movement={defaults_version=2,keep_autorun=true,autorun_messages=true}}
local owner=require('settings/TrustAddonSettings').new();owner:loadSettings()
assert(factory.movement.keep_autorun==false and factory.movement.autorun_messages==false,'factory defaults are Off')
assert(owner:getSettings().movement.keep_autorun==true,'a saved opt-in survives reload')
store={movement={defaults_version=2}};owner:loadSettings()
local m=owner:getSettings().movement
assert(m.keep_autorun==false and m.autorun_messages==false,'existing characters gain the options Off')

-- Movement status reports the options and what Windower says about autorun.
local live={keep_autorun=true,autorun_messages=false,policy='Send'}
local autorunNow
local R=require('cylibs/ui/input/movement_receiver').new({settings=function()return live end,blocked=function()end,
    autorun_state=function()return autorunNow end})
autorunNow=nil;assert(R:status():find('keep autorun true | autorun msgs false | autorun now unavailable',1,true))
autorunNow=true;assert(R:status():find('autorun now on',1,true))
autorunNow=false;assert(R:status():find('autorun now off',1,true))
local bare=require('cylibs/ui/input/movement_receiver').new({settings=function()return live end,blocked=function()end})
assert(bare:status():find('autorun now unavailable',1,true),'receivers without the hook still report')
print('PASS keep-autorun takeover (off by default, Trust-owned run still released, unknown state unchanged), debounced notices, command, defaults and status')
