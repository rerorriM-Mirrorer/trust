-- Real trace module, command policy, root dispatcher and combat alias.
-- Rendering, command effects and file I/O are mocked; no game client required.
unpack=unpack or table.unpack
local checks=0
local function check(ok,m) checks=checks+1; assert(ok,'FAIL: '..m) end
local function source(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function actual(s,path)
    s=s:gsub('("[^"\n]*"):(%a+)%(',function(q,m) return '('..q..'):'..m..'(' end)
    return assert((loadstring or load)(s,'@'..path))()
end
local messages={}
addon_system_message=function(s) messages[#messages+1]=s end
local Trace=require('cylibs/ui/menu/menu_save_trace')
Trace.record('disabled',{x=1});check(#messages==0 and #Trace.entries==0,'trace is quiet by default')
Trace.setEnabled(true)
state={TrustMode={value='Default'},MainTrustSettingsMode={value='Caster'}}
Trace.editor({__type='ConfigEditor',exitBaseline={autoraisemode='Off'},
    exitTraceContext={kind='modes',set='Default',path='data/modes/WHM_Test.lua'}},
    'exit-request','menu-back',{autoraisemode='Auto'})
local line=Trace.entries[#Trace.entries]
check(line:find('autoraisemode:Off->Auto',1,true) and line:find('set=Default',1,true)
    and line:find('path=data/modes/WHM_Test.lua',1,true),'trace identifies mode diff and destination')
Trace.record('save-failed',{error='disk\nunavailable'})
check(not Trace.entries[#Trace.entries]:find('\n',1,true),'trace values cannot inject log lines')
for i=1,Trace.limit+5 do Trace.record('bounded',{i=i}) end
check(#Trace.entries==Trace.limit and Trace.entries[1]:find('bounded',1,true),'trace memory is bounded')
Trace.setEnabled(false);local count=#messages;Trace.record('off')
check(#messages==count,'off stops collection and chat output')
windower={addon_path='addon/',ffxi={get_player=function() return {name='Test'} end},create_dir=function() end}
local originalOpen=io.open
local written,opened
io.open=function(path,mode) opened=path;return {write=function(_,s) written=s;return true end,close=function() return true end} end
local ok=Trace.dump()
check(ok and opened=='addon/data/logs/menu-save-Test.log' and written:find('bounded',1,true),'dump writes retained session')
io.open=function() return nil,'read-only storage' end
local message;ok,message=Trace.dump()
check(not ok and message:find('read-only storage',1,true),'dump reports open failures')
io.open=function() return {write=function() return nil,'disk full' end,close=function() return true end} end
ok,message=Trace.dump();check(not ok and message:find('disk full',1,true),'dump reports write failures')
io.open=originalOpen
Trace.clear();check(#Trace.entries==0 and Trace.sequence==0,'clear resets bounded session')

local Policy=require('cylibs/ui/menu/menu_command_policy')
for _,cmd in ipairs({'help','status','version','start','stop','startall','stopall','toggle','menu','widget'}) do
    check(Policy.effect(cmd)=='immediate',cmd..' available without draft commit')
end
for _,cmd in ipairs({'reload','load','save','profile','scenario','path'}) do
    check(Policy.effect(cmd)=='blocked',cmd..' cannot replace editor settings')
end
check(Policy.effect('set',{'CombatMode','Mirror'})=='commit','ordinary mode mutation checks editor')
check(Policy.effect('set',{'TRUSTMODE','Other'})=='blocked','profile mode selection stays guarded')
check(Policy.effect('cycle',{'MainTrustSettingsMode'})=='blocked','settings selector cycling stays guarded')
check(Policy.effect('heal',{'add'})=='blocked' and Policy.effect('heal',{'auto'})=='commit','runtime verbs do not authorize structural edits')
check(Policy.effect('nuke',{'delete'})=='blocked' and Policy.effect('mb',{'fire'})=='commit','spell runtime whitelist is narrow')
check(Policy.effect('follow',{'Clairvaux'})=='commit','player name is treated as follow argument')

-- Execute the actual root-dispatch function, including menu preflight calls.
local text=source('Trust.lua')
local dispatchText=text:match('(local function addon_command%(cmd, %.%.%.%).-)\nfunction load_chunk_event')
assert(dispatchText,'root dispatcher extract failed')
local dispatch=actual(dispatchText..'\nreturn addon_command','Trust.lua:addon_command')
local visible,valid,commits,refreshes=true,false,0,0
hud={trustMenu={isVisible=function() return visible end,commitCurrentEditor=function(_,reason)
    commits=commits+1;check(reason:find('command:',1,true)==1,'command reason reaches editor');return valid end,
    refreshAfterCommand=function() refreshes=refreshes+1 end}}
local executed={}
local handler={handle_command=function(_,...) executed[#executed+1]={...} end,is_valid_command=function() return true end}
shortcuts={default=handler,assist=handler,combat=handler}
local errors={};addon_system_error=function(m) errors[#errors+1]=m end
dispatch('STOP');check(#executed==1 and executed[1][1]=='stop' and commits==0,'emergency stop survives invalid draft')
dispatch('assist','Clairvaux');check(#executed==1 and commits==1,'invalid draft prevents tactical command')
valid=true;dispatch('assist','Clairvaux')
check(#executed==2 and executed[2][1]=='Clairvaux','assist argument retains exact casing')
local before=#executed;dispatch('set','TrustMode','Other');dispatch('reload')
check(#executed==before and #errors==2,'profile/reload blocked at actual root entry point')
dispatch('status');check(#executed==before+1 and commits==2,'status does not commit pending draft')
check(refreshes==1,'read-only and emergency commands do not rebuild the editor')
visible=false;dispatch('reload');check(#executed==before+2,'closed-menu command behavior is unchanged')

package.preload['cylibs/messages/command_message']=function() return {} end
package.preload['cylibs/util/party_util']=function() return {} end
local General=actual(source('commands/GeneralCommands.lua'),'commands/GeneralCommands.lua')
state.CombatMode={value='Off'};handle_set=function(name,v) state[name].value=v end
local commands=setmetatable({},General)
ok,message=commands:handle_combat(nil,nil)
check(ok and message=='CombatMode: Off','bare combat command reports mode')
ok=commands:handle_combat(nil,'mIRroR');check(ok and state.CombatMode.value=='Mirror','combat alias accepts case-insensitive modes')
ok=commands:handle_combat(nil,'wrong');check(not ok and state.CombatMode.value=='Mirror','invalid combat value never mutates mode')
print('PASS: '..checks..' save trace / menu command assertions (OS and I/O mocked)')
