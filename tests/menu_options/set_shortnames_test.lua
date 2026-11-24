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
local messages={}
addon_system_message=function(m) messages[#messages+1]=m end
state.SkillchainAssistantMode=M{['description']='Show Skillchain Assistant','Auto','Off'}
state.AutoEngageMode=M{description='Engage','Always','Off','Mirror','Defensive','Aggressive'}
state.AutoRaiseMode=M{description='Raise','Off','Auto'}
state.RaiseMode=M{description='Raise kind','Off','Auto'}
local changed
on_state_changed():addAction(function(name) changed=name end)
-- A's 2026-11-23 report: //trust set skillchainassistant off was "Unknown field".
handle_set('skillchainassistant','Off')
check(state.SkillchainAssistantMode.value=='Off','set accepts the name without Mode')
check(messages[#messages]=='SkillchainAssistantMode is now Off.','reply uses the real mode name: '..tostring(messages[#messages]))
check(changed=='SkillchainAssistantMode','state change event gets the real mode name')
handle_set('skillchainassistantmode','Auto')
check(messages[#messages]=='SkillchainAssistantMode is now Auto.','lowercase full name echoes real name')
handle_set('engage','Mirror')
check(state.AutoEngageMode.value=='Mirror','set accepts the name without Auto and Mode')
handle_cycle('engage')
check(messages[#messages]=='AutoEngageMode is now Defensive.','cycle accepts short names: '..tostring(messages[#messages]))
handle_set('raise','Auto')
check(state.RaiseMode.value=='Auto' and state.AutoRaiseMode.value=='Off','exact-without-Mode tier wins over Auto tier')
handle_set('AutoRaiseMode','Auto')
check(state.AutoRaiseMode.value=='Auto','full names unchanged')
local before=#errors
handle_set('nosuchthing','On')
check(#errors==before+1 and errors[#errors]:find('Unknown field %[nosuchthing%]'),'unknown names still reported as typed')
print('set_shortnames_test: '..checks..' passed')
