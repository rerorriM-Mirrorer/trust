local f=assert(io.open('commands/GeneralCommands.lua'))
local source=f:read('*a');f:close()
local a=assert(source:find('function GeneralTrustCommands:handle_fan(',1,true))
local b=assert(source:find('function GeneralTrustCommands:handle_combat',a,true))
local settings={follow={}}
local saved,sent=0,{}
local feedback={}
string.color=function(s,c)return '['..c..']'..s end
package.loaded.chat={}
unpack=unpack or table.unpack
local methods={}
local env=setmetatable({
 GeneralTrustCommands=methods,
 windower={add_to_chat=function(_,line)feedback[#feedback+1]=line end},
 addon_settings={getSettings=function()return settings end,saveSettings=function()saved=saved+1 end},
 state={IpcMode={value='All'}},
 IpcRelay={shared=function()return{send_message=function(_,message)sent[#sent+1]=message end}end},
 CommandMessage={new=function(command)return command end},
},{__index=_G})
assert(load(source:sub(a,b-1),'fan commands','t',env))()
local c=setmetatable({},{__index=methods})
assert(c:handle_fan() and settings.follow.fan_out==false and saved==1)
assert(c:handle_fan(nil,'off') and saved==1)
assert(c:handle_fan(nil,'ON') and settings.follow.fan_out and saved==2)
assert(not c:handle_fan(nil,'maybe') and saved==2)
assert(not c:handle_fan_all(nil,'on','extra') and #sent==0)
assert(c:handle_fan_all() and not settings.follow.fan_out and sent[1]=='trust fan off --quiet')
assert(c:handle_fan_all(nil,'on') and settings.follow.fan_out and sent[2]=='trust fan on --quiet')
env.state.IpcMode.value='Receive'
assert(c:handle_fan_all(nil,'off') and not settings.follow.fan_out and #sent==2)
local policy=dofile('cylibs/ui/menu/menu_command_policy.lua')
assert(policy.effect('fan',{})=='commit' and policy.effect('fanall',{'off'})=='commit')
print('PASS Fan Out toggle/default, explicit idempotence, validation, consistent all-client state and IPC/menu guards')

-- Replay the exact serialized relay through the production command dispatcher.
local Base=require('cylibs/trust/commands/trust_commands')
local receiver=setmetatable({
 get_command_name=function()return 'default' end,
 commands={fan={callback=function(...)return c:handle_fan(...)end}},
},{__index=Base})
addon_message=function()error('unexpected unformatted success feedback')end
addon_system_error=function(message)error(message)end
local count=#feedback
assert(receiver:handle_command('fan','on','--quiet'))
assert(settings.follow.fan_out==true and #feedback==count)
assert(c:handle_fan(nil,'off'))
assert(feedback[#feedback]=='[200][Trust] [167]Fan Out [167]OFF[0]')
env.state.IpcMode.value='All'
assert(c:handle_fan_all(nil,'on'))
assert(feedback[#feedback]=='[200][Trust] [167]Fan Out [158]ON[0] - Requested on all clients.')
print('PASS recipient dispatch accepts quiet state and issuer feedback uses labeled colored fragments')
