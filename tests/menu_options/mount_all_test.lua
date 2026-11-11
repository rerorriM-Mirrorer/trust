-- Exercise the real command constructor/dispatcher on mixed-state clients.
local methods={};local mt={__index=methods}
function L(t)return setmetatable(t or {},mt)end
function methods:append(v)self[#self+1]=v end
function methods:length()return #self end
function methods:it()local i=0;return function()i=i+1;return self[i]end end
function methods:contains(v)for _,x in ipairs(self)do if x==v then return true end end;return false end
function methods:map(f)local r=L{};for _,v in ipairs(self)do r:append(f(v))end;return r end
function methods:sort()table.sort(self);return self end
function methods:unpack()return table.unpack(self)end
S=L;T=L;unpack=unpack or table.unpack
local who={status=0,name='Issuer',id=1};local learned=L{'Raptor','Red Crab'}
local queued,sent,feedback,errors={},{},{},{}
local valid=true
local function action(kind,id)return{kind=kind,id=id,can_perform=function()return valid end,destroy=function()end}end
package.loaded['cylibs/actions/mount']={new=function(id)return action('mount',id)end}
package.loaded['cylibs/actions/dismount']={new=function()return action('dismount')end}
package.loaded['cylibs/messages/command_message']={new=function(text)return text end}
package.loaded['ui/settings/editors/config/PickerConfigItem']={new=function()return{}end}
package.loaded.chat={}
string.color=function(s,c)return '['..c..']'..s end
ActionQueue={new=function()return{push_action=function(_,a)queued[#queued+1]={name=who.name,action=a}end}end}
player_util={get_mounts=function()return learned end}
res={mounts={{en='Raptor',id=1},{en='Red Crab',id=2},{en='Tiger',id=3}},statuses={[1]={en='Engaged'},[2]={en='Dead'}}}
local info={mog_house=false}
windower={ffxi={get_player=function()return who end,get_info=function()return info end},add_to_chat=function(_,s)feedback[#feedback+1]=s end}
IpcRelay={shared=function()return{send_message=function(_,s)sent[#sent+1]=s end}end}
state={IpcMode={value='All'}}
addon_system_error=function(s)errors[#errors+1]=s end
addon_message=function()error('unexpected legacy success message')end
local Commands=require('commands/MountCommands');local c=Commands.new({})
local function command(...)local handled,success=c:handle_command(...);assert(handled);return success end
local function relay(text)local tokens={};for word in text:gmatch('%S+')do tokens[#tokens+1]=word end;table.remove(tokens,1);table.remove(tokens,1);return command(table.unpack(tokens))end
assert(command('all') and sent[1]=='trust mount request mount Raptor' and #queued==1)
local request=sent[1]
who={status=85,name='Mounted'};assert(relay(request) and #queued==1)
who={status=0,name='Foot'};assert(relay(request) and #queued==2)
who={status=1,name='Fighting'};assert(not relay(request) and #queued==2 and errors[#errors]:find('Engaged',1,true))
assert(#sent==1,'recipient rebroadcasted')
-- Issuer mounted chooses dismount; clients already on foot do nothing.
who={status=85,name='Issuer'};assert(command('all') and sent[2]=='trust mount request dismount')
assert(queued[#queued].action.kind=='dismount')
request=sent[2];local before=#queued
who={status=0,name='Foot'};assert(relay(request) and #queued==before)
who={status=5,name='Chocobo'};assert(relay(request) and #queued==before+1)
assert(#sent==2)
-- Explicit mount wins even while issuer is mounted; explicit dismount works on foot.
who={status=85,name='Issuer'};before=#queued
assert(command('all','red','crab') and sent[3]=='trust mount request mount Red Crab' and #queued==before)
who={status=0,name='Issuer'};assert(command('dismount','all') and sent[4]=='trust mount request dismount' and #queued==before)
assert(command('dismount') and #queued==before)
-- No local unlock does not prevent another client receiving the explicit request.
learned=L{};local sends=#sent
assert(not command('all','Tiger') and #sent==sends+1 and sent[#sent]=='trust mount request mount Tiger')
assert(errors[#errors]:find('not learned',1,true))
assert(not command('all','Imaginary') and #sent==sends+1)
learned=L{'Raptor','Red Crab'}
state.IpcMode.value='Receive';sends=#sent;assert(command('all') and #sent==sends)
assert(feedback[#feedback]:find('Local only',1,true))
-- Existing local forms and case-insensitive multiword names remain usable.
assert(command('rApToR'));assert(command('Red','Crab'));assert(command())
valid=false;assert(not command('Raptor'));valid=true
info.mog_house=true;assert(not command('Raptor'));info.mog_house=false
assert(not command('request','dismount','extra'))
assert(not command('dismount','maybe'))
assert(require('cylibs/ui/menu/menu_command_policy').effect('mount',{'all'})=='commit')
print('PASS mixed-state mount/dismount convergence, explicit override, no-op, failure isolation, IPC scope and real command dispatch')
