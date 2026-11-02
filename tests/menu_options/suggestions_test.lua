-- Production autocomplete callback: Off skips both matching and update events.
local function list(t)return setmetatable(t or {},{__index={it=function(s)local i=0;return function()i=i+1;return s[i]end end}})end
L=list
local matches,updates,subscriptions,removed=0,0,0,0
package.loaded['cylibs/ui/input/autocomplete/command_trie']={new=function()return{
 addCommand=function()end,getCommands=function(_,text)matches=matches+1;assert(text=='pull');return list{'pull'}end}end}
package.loaded['cylibs/events/dispose_bag']={new=function()return{
 add=function()subscriptions=subscriptions+1 end,addAny=function()end,destroy=function()removed=removed+1 end}end}
package.loaded['cylibs/events/Luvent']={newEvent=function()return{
 trigger=function()updates=updates+1 end,removeAllActions=function()end}end}
local event={addAction=function(_,fn)return fn end}
package.loaded['cylibs/ui/input/keyboard']={input=function()return{on_key_pressed=function()return event end}end}
local enabled=false;local text='//trust pull'
windower={ffxi={get_info=function()return{chat_open=true}end},chat={get_input=function()return text end}}
local C=require('cylibs/ui/input/autocomplete/chat_auto_completer')
local c=C.new(list{'//trust pull'},function()return enabled end)
for i=1,20 do c:onKeyboardEvent(1,false)end
assert(matches==0 and updates==0)
enabled=true;c:onKeyboardEvent(1,false);assert(matches==1 and updates==1)
c:onKeyboardEvent(1,false);assert(matches==1,'same input recomputed')
enabled=false;c:onKeyboardEvent(1,false);enabled=true;c:onKeyboardEvent(1,false)
assert(matches==2,'reenabling failed to recompute the current input')
c:destroy();assert(removed==1 and subscriptions==1)
-- Execute root wiring: toggling saved visibility hides an already visible box;
-- disabled callbacks perform no list rebuilding, and reload disposes old listeners.
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
local a=assert(root:find('    if chat_auto_completer then chat_auto_completer:destroy() end',1,true))
local b=assert(root:find('\nend\n\nfunction get_job_commands',a,true))
local block=root:sub(a,b-1)
local change,termsChanged;local visible=true;local cleared=0;local layouts=0;local destroyed=0
local settings={autocomplete={visible=true}}
local bag={add=function()end}
local env=setmetatable({
 chat_auto_completer={destroy=function()destroyed=destroyed+1 end},
 ChatAutoCompleter={new=function(_,isEnabled)return{disposeBag=bag,enabled=isEnabled,
 onAutoCompleteListChange=function()return{addAction=function(_,fn)termsChanged=fn end}end}end},
 all_commands=list{},addon_settings={getSettings=function()return settings end,
 onSettingsChanged=function()return{addAction=function(_,fn)change=fn end}end},
 command_widget={isVisible=function()return visible end,setVisible=function(_,v)visible=v end,
 getDataSource=function()return{removeAllItems=function()cleared=cleared+1 end}end},
 hud={trustMenu={isVisible=function()return false end},infoBar={setVisible=function(_,v)assert(v==false)end,layoutIfNeeded=function()layouts=layouts+1 end}},
},{__index=_G})
assert(load(block,'actual autocomplete root wiring','t',env))()
assert(destroyed==1 and env.chat_auto_completer.enabled())
settings.autocomplete.visible=false;change()
assert(not visible and cleared==1 and layouts==1 and not env.chat_auto_completer.enabled())
termsChanged(nil,list{});assert(cleared==1,'disabled UI callback rebuilt list')
-- Config exposes both separate entries in Full/Condensed reload paths.
local file=assert(io.open('ui/settings/menus/ConfigSettingsMenuItem.lua'));local s=file:read('*a');file:close()
local body=assert(s:match('(function ConfigSettingsMenuItem:reloadSettings.-)\nfunction ConfigSettingsMenuItem:'))
local children={};local opts={autocomplete={visible=false}}
local owner={getSettings=function()return opts end}
local configEnv=setmetatable({ConfigSettingsMenuItem={},L=function(t)return t end,
 ButtonItem={default=function(s)return s end},BooleanConfigItem={new=function(k)return k end},
 MenuItem={new=function(buttons,children,view,title)return{view=view,title=title}end},
 WidgetSettingsMenuItem={new=function()return{}end},RemoteCommandsSettingsMenuItem={new=function()return{}end},
 require=function(name)
  if name=='cylibs/ui/menu/menu_preferences' then return{layout=function()return'Condensed'end}end
  return{new=function()return{module=name}end}
 end,ConfigEditor={new=function(o,v,items)return{owner=o,values=v,items=items}end},
},{__index=_G})
assert(load(body,'actual Config routes','t',configEnv))()
configEnv.ConfigSettingsMenuItem.reloadSettings({buttonItems={filter=function()return{}end},setChildMenuItem=function(_,k,v)children[k]=v end,
 getLoggingMenuItem=function()return{}end,getSoundSettingsMenuItem=function()return{}end},owner)
assert(not children.Recovery and not children.Movement)
local suggestions=children.Autosuggest.view();assert(suggestions.owner==owner and suggestions.values==opts.autocomplete and suggestions.items[1]=='visible')
print('PASS autocomplete Off skips matching/UI, live visibility change hides popup, reload cleans subscription, and Config exposes Recovery/suggestions')
