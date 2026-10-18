-- Real dispatcher, command base and settings writers; filesystem/game are mocked.
-- Run: luatex --luaonly tests/menu_options/command_settings_test.lua
unpack=unpack or table.unpack
local checks=0
local function check(ok, message) checks=checks+1; assert(ok,message) end
local function source(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function actual(s,name)
    s=s:gsub('("[^"\n]*"):(%a+)%(',function(q,m) return '('..q..'):'..m..'(' end)
    return assert((loadstring or load)(s,'@'..name))()
end
local methods={}
local function list(t) return setmetatable(t or {},{__index=methods}) end
function methods:copy() local r=list();for k,v in pairs(self) do r[k]=v end;return r end
function methods:it() local i=0;return function() i=i+1;return self[i] end end
function methods:unpack() return unpack(self) end
function methods:tovstring() return require('cylibs/util/serializer_util').serialize(self) end
L,T,S=list,list,list
function table.diff(t,other) local r=list();for k,v in pairs(t) do if v~=other[k] then r[k]=v end end;return r end
function table.merge(t,other) local r=t:copy();for k,v in pairs(other) do r[k]=v end;return r end
package.preload.logger=function() return {} end
package.preload['cylibs/util/extensions/tables']=function() return table end
local disk,writes,fail={},{},{}
local File={new=function(path) return {exists=function() return true end,write=function(_,value)
    writes[path]=(writes[path] or 0)+1
    if fail[path] then error('disk unavailable') end
    disk[path]=value
end} end}
files=File;package.preload.files=function() return File end
config={save=function(settings) writes.addon=(writes.addon or 0)+1;disk.addon=settings.follow.distance end}
local errors,notices={},{}
addon_system_error=function(s) errors[#errors+1]=s end
addon_system_message=function(s) notices[#notices+1]=s end
addon_message=function() end
windower={addon_path='',ffxi={get_player=function() return {name='Test'} end}}
local prefs=require('cylibs/ui/menu/menu_preferences')
local Sync=require('cylibs/trust/commands/command_settings')
local Settings=actual(source('TrustSettings.lua'),'TrustSettings.lua')
local Addon=require('settings/TrustAddonSettings')
local Modes=require('TrustModeSettings')
local Base=require('cylibs/trust/commands/trust_commands')
addon_settings=Addon.new();addon_settings.settings={menu={save_on_exit=true},follow={distance=1}}
prefs.configure(addon_settings)
state={TrustMode={value='Custom'},MainTrustSettingsMode={value='Default'},
    AutoRaiseMode={value='Off',_class='mode',_type='list',options=function() return {'Off','Auto'} end},
    OtherMode={value='SessionOnly'}}
main_trust_settings=Settings.new('WHM','Test')
main_trust_settings.settings={Default={CombatSettings={Distance=4}}}
trust_mode_settings=Modes.new('WHM','Test',state.TrustMode)
trust_mode_settings.settings={Default={autoraisemode='Off',othermode='Stored'},
    Custom={autoraisemode='Off',othermode='Stored'}}
local reloaded=0
trust_mode_settings.reloadSettings=function() reloaded=reloaded+1 end
local path='data/WHM_Test.lua'
local modePath='data/modes/WHM_Test.lua'
local general=Base.new()
general:add_command('set',function(_,_,key,value) state[key].value=value;return true end)
general:add_command('change',function()
    main_trust_settings.settings.Default.CombatSettings.Distance=6;return true
end)
general:add_command('already',function()
    main_trust_settings.settings.Default.CombatSettings.Distance=7
    main_trust_settings:saveSettings(true);return true
end)
general:add_command('afterwrite',function()
    main_trust_settings.settings.Default.CombatSettings.Distance=8
    main_trust_settings:saveSettings(true)
    main_trust_settings.settings.Default.CombatSettings.Distance=9;return true
end)
general:add_command('reject',function()
    main_trust_settings.settings.Default.CombatSettings.Distance=10;return false,'rejected'
end)
general:add_command('noop',function() return true end)
general:add_command('notify',function()
    main_trust_settings.settings.Default.CombatSettings.Distance=11
    main_trust_settings:saveSettings(false);return true
end)
general:add_command('replace',function()
    main_trust_settings.settings={Default={CombatSettings={Distance=20}}};return true
end)
general:add_command('profilechange',function()
    state.TrustMode.value='Default';state.AutoRaiseMode.value='Off';return true
end)
shortcuts={default=general}
local visible,commits,refreshes=false,0,0
hud={trustMenu={isVisible=function() return visible end,
    commitCurrentEditor=function() commits=commits+1;return true end,
    refreshAfterCommand=function() refreshes=refreshes+1 end}}
local dispatch=actual(assert(source('Trust.lua'):match('(local function addon_command%(cmd, %.%.%.%).-)\nfunction load_chunk_event'))..'\nreturn addon_command','root dispatch')
dispatch('autoraise','Auto')
check(writes[modePath]==1,'direct shortened alias persists changed mode')
check(state.TrustMode.value=='Custom' and reloaded==0,'command save does not reload/reset selected set')
check(trust_mode_settings.settings.Custom.othermode=='Stored','unrelated session mode does not leak into profile')
check(disk[modePath]:find('autoraisemode = "Auto"',1,true),'mode write contains commanded value')
dispatch('autoraise','Auto')
check(writes[modePath]==1,'idempotent setting does not write again')
dispatch('autoraise','invalid')
check(writes[modePath]==1 and #errors==1,'invalid alias does not save')
visible=true;dispatch('set','AutoRaiseMode','Off')
check(commits==1 and refreshes==1 and writes[modePath]==2,'root menu preflight, save and refresh connected')
visible=false
dispatch('change');check(writes[path]==1,'nested job setting change saves')
dispatch('already');check(writes[path]==2,'existing explicit writer is not duplicated')
dispatch('afterwrite');check(writes[path]==4 and disk[path]:find('Distance = 9',1,true),'mutation after explicit write is persisted')
dispatch('reject');check(writes[path]==4,'failed command never implicitly saves')
dispatch('noop');check(writes[path]==4,'no-op does not flush previous failed changes')
dispatch('notify');check(writes[path]==5,'notification-only save is not mistaken for disk persistence')
addon_settings.settings.menu.save_on_exit=false
dispatch('change');dispatch('autoraise','Auto')
check(writes[path]==5 and writes[modePath]==2,'autosave Off disables new owner and mode writes')
dispatch('already');check(writes[path]==6,'autosave Off retains existing explicit save behavior')
addon_settings.settings.menu.save_on_exit=true
dispatch('replace');check(writes[path]==6,'replaced settings root is not saved into stale owner scope')
dispatch('profilechange');check(writes[modePath]==2,'profile selector change never implicitly snapshots modes')
fail[path]=true
dispatch('change')
check(writes[path]==7 and errors[#errors]:find('not saved',1,true),'write failure clearly reports runtime/save distinction')
fail[path]=nil
local token=Sync.capture('follow',{addon=addon_settings},state,trust_mode_settings,{'distance','3','--quiet'})
addon_settings.settings.follow.distance=3
local count=#notices;Sync.finish(token,true,state)
check(writes.addon==1 and disk.addon==3 and #notices==count,'quiet change saves without extra success chatter')
for _,command in ipairs({'stop','start','status','reload','save','profile','sendall'}) do
    check(Sync.capture(command,{addon=addon_settings},state,trust_mode_settings)==nil,'no autosave snapshot for '..command)
end
local handled,success=general:handle_command('reject')
check(handled and success==false,'command base exposes actual failure independently of handled status')
package.preload['cylibs/messages/command_message']=function() return {} end
local Follow=actual(source('commands/FollowCommands.lua'),'FollowCommands.lua')
local distance
local follow=setmetatable({get_follower=function() return {set_distance=function(_,v) distance=v end} end},Follow)
check(follow:handle_set_follow_distance(nil,'12') and distance==12 and addon_settings.settings.follow.distance==12,
    'follow distance changes existing persistent option when autosave On')
addon_settings.settings.menu.save_on_exit=false
check(follow:handle_set_follow_distance(nil,'9') and distance==9 and addon_settings.settings.follow.distance==12,
    'autosave Off keeps follow distance runtime-only')
check(not follow:handle_set_follow_distance(nil,nil) and not follow:handle_set_follow_distance(nil,'51'),
    'missing/out-of-range follow distances do not crash or mutate')
state.TrustMode.value='Default'
check(trust_mode_settings:saveModeChanges('Default',{autoraisemode='Auto'}),'Default command save succeeds')
local stored=assert((loadstring or load)(disk[modePath]))()
check(trust_mode_settings.settings.Custom.autoraisemode==stored.Default.autoraisemode,
    'in-memory inherited modes match disk semantics after Default save')
fail[modePath]=true
local old=trust_mode_settings.settings.Default.autoraisemode
local ok=pcall(function() trust_mode_settings:saveModeChanges('Default',{autoraisemode='Off'}) end)
check(not ok and trust_mode_settings.settings.Default.autoraisemode==old,'failed mode write does not update stored model')
print('PASS: '..checks..' command settings assertions (real writers/dispatcher; game and disk mocked)')
