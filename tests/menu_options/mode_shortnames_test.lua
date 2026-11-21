-- Third alias tier (without Auto and Mode) on the real mode library and resolver.
-- Windower command effects and UI are not used.
unpack=unpack or table.unpack
local checks=0
local function check(ok,m) checks=checks+1;assert(ok,'FAIL: '..m) end
local methods={}
local function list(t) return setmetatable(t or {},{__index=methods}) end
function methods:flatten() local r=list();for _,v in ipairs(self) do r[#r+1]=v end;return r end
function methods:append(v) self[#self+1]=v end
function methods:map(f) local r=list();for _,v in ipairs(self) do r:append(f(v)) end;return r end
function methods:contains(v) for _,x in ipairs(self) do if x==v then return true end end;return false end
L,T,S=list,list,list
package.preload.sets=function() return {} end
require('cylibs/util/Modes')
require('cylibs/util/States')
local errors={}
addon_system_error=function(m) errors[#errors+1]=m end
addon_system_message=function() end
state.AutoRaiseMode=M{description='Raise','Off','Auto'}
state.CombatMode=M{description='Position','Off','Auto','Mirror'}
state.TrustMode=M{description='Profile','Default','My Set'}
state.SwitchMode=M(false,'Boolean')
state.TextMode=M{description='Text',string='Original Text'}
local Aliases=require('cylibs/trust/commands/mode_aliases')
local groups={default={commands={combat={},stop={},status={},set={},cycle={}}},assist={}}
-- Third tier: without Auto and Mode.
state.AutoEngageMode=M{description='Engage','Always','Off','Mirror','Defensive','Aggressive'}
state.AutoEngageMode.legacy_values={aggro='Defensive'}
local a,err=Aliases.resolve('engage',{'mirror'},groups,state)
check(a and a.command=='set' and a.arguments[1]=='AutoEngageMode' and a.arguments[2]=='Mirror','engage mirror')
a=Aliases.resolve('ENGAGE',{},groups,state)
check(a and a.command=='cycle' and a.arguments[1]=='AutoEngageMode','bare short name cycles')
check(Aliases.resolve('autoengage',{'off'},groups,state).arguments[2]=='Off','Mode-only short name still works')
check(Aliases.resolve('AutoEngageMode',{'aggro'},groups,state).arguments[2]=='Defensive','full name and legacy value still work')
check(Aliases.resolve('raise',{'auto'},groups,state).arguments[1]=='AutoRaiseMode','raise auto')
a,err=Aliases.resolve('engage',{'sideways'},groups,state)
check(not a and err:find('Always, Off, Mirror, Defensive, Aggressive',1,true),'bad value lists options')
-- Registered commands still win.
state.AutoFollowMode=M{description='Follow','Always','Off'}
groups.follow={}
check(not Aliases.resolve('follow',{'off'},groups,state),'existing follow command wins')
check(Aliases.resolve('autofollow',{'off'},groups,state).arguments[1]=='AutoFollowMode','longer name reaches the shadowed mode')
-- A closer tier wins over Auto/Mode stripping (PUP: ManeuverMode vs AutoManeuverMode).
state.AutoManeuverMode=M{description='Use','Off','Auto'}
state.ManeuverMode=M{description='Set','Default','Light'}
check(Aliases.resolve('maneuver',{},groups,state).arguments[1]=='ManeuverMode','Mode-only tier wins')
check(Aliases.resolve('automaneuver',{},groups,state).arguments[1]=='AutoManeuverMode','other mode still reachable')
-- Two Auto...Mode modes differing only in case are never guessed.
state.AUTOWIDGETMODE=M{description='A','X','Y'}
state.AutoWidgetMode=M{description='B','X','Y'}
a,err=Aliases.resolve('widget',{},groups,state)
check(not a and err:find('Ambiguous',1,true),'ambiguous third tier refused')
state.AUTOWIDGETMODE=nil;state.AutoWidgetMode=nil
-- Autocomplete lists the third tier only where it resolves to that mode.
local found={}
for _,entry in ipairs(Aliases.commands(state,groups)) do found[entry]=true end
check(found['// trust engage'] and found['// trust engage Mirror'],'autocomplete: engage')
check(not found['// trust follow'] and found['// trust autofollow'],'autocomplete: shadowed name hidden')
check(not found['// trust maneuver Auto'] and found['// trust automaneuver Auto'],'autocomplete: no misleading options')
print('PASS mode_shortnames_test: '..checks..' assertions')
