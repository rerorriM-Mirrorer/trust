local f=assert(io.open('commands/GeneralCommands.lua'));local src=f:read('*a');f:close()
local first=assert(src:find('function GeneralTrustCommands:handle_autosuggest(',1,true))
local last=assert(src:find('function GeneralTrustCommands:handle_fan(',first,true))
local G={};local settings={autocomplete={visible=false}};local saved=0;local feedback={}
string.color=function(s,color)return '['..color..']'..s end
package.loaded.chat={}
local env=setmetatable({GeneralTrustCommands=G,addon_settings={getSettings=function()return settings end,saveSettings=function()saved=saved+1;return true end},windower={add_to_chat=function(_,s)feedback[#feedback+1]=s end}},{__index=_G})
assert(load(src:sub(first,last-1),nil,'t',env))()
local c=setmetatable({},{__index=G})
assert(c:handle_autosuggest(nil,'off') and saved==0)
assert(c:handle_autosuggest() and settings.autocomplete.visible and saved==1)
assert(c:handle_autosuggest(nil,'ON') and saved==1)
assert(c:handle_autosuggest(nil,'off') and not settings.autocomplete.visible and saved==2)
assert(not c:handle_autosuggest(nil,'maybe') and saved==2)
assert(not c:handle_autosuggest(nil,'on','extra') and saved==2)
assert(feedback[#feedback]=='[200][Trust] [167]Autosuggest [167]OFF')
local Base=require('cylibs/trust/commands/trust_commands')
local receiver=setmetatable({get_command_name=function()return'default'end,commands={autosuggest={callback=function(...)return c:handle_autosuggest(...)end}}},{__index=Base})
unpack=unpack or table.unpack
addon_message=function()error('unexpected duplicate feedback')end
addon_system_error=function(m)error(m)end
assert(receiver:handle_command('autosuggest','on') and settings.autocomplete.visible)
assert(require('cylibs/ui/menu/menu_command_policy').effect('autosuggest',{'off'})=='commit')
local defaults=assert(io.open('settings/TrustAddonSettings.lua'));local text=defaults:read('*a');defaults:close()
assert(text:find('default.autocomplete.visible = false',1,true))
print('PASS Autosuggest command toggle, explicit idempotence, parsing, feedback, dispatch, menu policy and Off default')
