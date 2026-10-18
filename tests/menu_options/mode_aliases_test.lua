-- Real mode library, state lock handlers, alias resolver and root dispatcher.
-- Windower command effects and UI are mocked; no file/settings writes.
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
local a,err=Aliases.resolve('autoraise',{},groups,state)
check(a and a.command=='cycle' and a.arguments[1]=='AutoRaiseMode','short name cycles full mode')
a=Aliases.resolve('AUTORAISEMODE',{'aUtO'},groups,state)
check(a.command=='set' and a.arguments[2]=='Auto','full mode and value resolve case-insensitively')
a,err=Aliases.resolve('autoraise',{'wrong'},groups,state)
check(not a and err:find('Off, Auto',1,true) and state.AutoRaiseMode.value=='Off','invalid option gives choices without mutation')
check(not Aliases.resolve('combat',{},groups,state),'existing combat command wins')
check(Aliases.resolve('CombatMode',{},groups,state).command=='cycle','explicit mode name remains available')
check(not Aliases.resolve('assist',{},groups,state),'existing command group wins')
state.StopMode=M{description='Stop mode','Off','On'}
check(not Aliases.resolve('stop',{},groups,state),'existing default command wins over shortened mode')
state.Collision=M{description='Exact','A','B'}
state.CollisionMode=M{description='Short','C','D'}
check(Aliases.resolve('collision',{},groups,state).mode=='Collision','exact mode name wins over shortened mode')
state.COLLISIONMODE=M{description='Ambiguous','E','F'}
a,err=Aliases.resolve('collisionmode',{},groups,state)
check(not a and err:find('Ambiguous',1,true),'ambiguous identifiers are never guessed')
state.COLLISIONMODE=nil
a=Aliases.resolve('trust',{'my','set'},groups,state)
check(a.arguments[1]=='TrustMode' and a.arguments[2]=='My Set','multi-word option preserves canonical case')
a=Aliases.resolve('switch',{'TRUE'},groups,state)
check(a.arguments[2]=='true','boolean option uses existing accepted spelling')
a,err=Aliases.resolve('text',{},groups,state)
check(not a and err:find('requires a value',1,true),'string modes cannot silently cycle')
a=Aliases.resolve('text',{'Keep','My','Case'},groups,state)
check(a.arguments[2]=='Keep My Case','free-form mode text retains case')
state.CaseMode=M{description='Case','AUTO','Auto'}
a,err=Aliases.resolve('case',{'auto'},groups,state)
check(not a and err:find('Ambiguous',1,true),'ambiguous value casing requests exact spelling')
check(Aliases.resolve('case',{'Auto'},groups,state).arguments[2]=='Auto','exact value disambiguates case')
local entries=Aliases.commands(state,groups);local found={}
for _,entry in ipairs(entries) do check(not found[entry],'autocomplete entries are unique');found[entry]=true end
check(found['// trust autoraise'] and found['// trust AutoRaiseMode Auto'],'autocomplete contains short/full forms and values')
check(not found['// trust combat'] and found['// trust CombatMode'],'autocomplete does not advertise a colliding alias')
check(found['// trust text'] and found['// trust switch on'],'string and boolean modes are discoverable')
state.AutoRaiseMode=nil
check(not Aliases.resolve('autoraise',{},groups,state),'unloaded job modes are unavailable dynamically')
state.AutoRaiseMode=M{description='Raise','Off','Auto'}

local f=assert(io.open('Trust.lua'));local s=f:read('*a');f:close()
s=s:match('(local function addon_command%(cmd, %.%.%.%).-)\nfunction load_chunk_event')
s=s:gsub('("[^"\n]*"):(%a+)%(',function(q,m) return '('..q..'):'..m..'(' end)
local dispatch=assert((loadstring or load)(s..'\nreturn addon_command'))()
local visible,valid,commits,refreshes=false,true,0,0
hud={trustMenu={isVisible=function() return visible end,commitCurrentEditor=function()
    commits=commits+1;return valid end,refreshAfterCommand=function() refreshes=refreshes+1 end}}
local legacy={}
groups.default.handle_command=function(_,cmd,name,value)
    if cmd=='cycle' then handle_cycle(name)
    elseif cmd=='set' then handle_set(name,value)
    else legacy[#legacy+1]={cmd,name,value} end
end
groups.default.is_valid_command=function() return true end
shortcuts=groups
dispatch('autoraise');check(state.AutoRaiseMode.value=='Auto','root alias executes actual cycle handler')
dispatch('autoraise','OFF');check(state.AutoRaiseMode.value=='Off','root alias executes actual set handler')
set_modes_locked(true,'locked')
dispatch('autoraise');check(state.AutoRaiseMode.value=='Off' and errors[#errors]=='locked','real mode locks still apply')
set_modes_locked(false)
visible=true;valid=false;dispatch('autoraise')
check(state.AutoRaiseMode.value=='Off' and commits==1,'invalid menu draft blocks mode alias')
valid=true;dispatch('autoraise')
check(state.AutoRaiseMode.value=='Auto' and refreshes==1,'valid menu preflight and refresh apply to aliases')
local count=commits;dispatch('trust','My Set')
check(state.TrustMode.value=='Default' and commits==count,'short profile alias retains menu profile protection')
count=commits;dispatch('autoraise','wrong')
check(commits==count and state.AutoRaiseMode.value=='Auto','invalid alias value does not commit a menu draft')
dispatch('combat');check(legacy[#legacy][1]=='combat','registered combat shorthand keeps its behavior')
dispatch('stop');check(legacy[#legacy][1]=='stop','existing emergency command is untouched')
print('PASS: '..checks..' mode alias assertions (real modes/locks; UI and OS mocked)')
