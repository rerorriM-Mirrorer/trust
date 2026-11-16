-- Config > Menu now also holds "Disable sound effects for this installation".
-- Runs the real reloadSettings Menu constructor against stubs and checks that each
-- value is written back to its own owner: menu options to this character's settings,
-- the sound switch to the shared installation file.
L=function(t)return t end
addon_system_error=function(m)error('unexpected error: '..tostring(m))end
local f=assert(io.open('ui/settings/menus/ConfigSettingsMenuItem.lua'));local s=f:read('*a');f:close()
local body=assert(s:match('(function ConfigSettingsMenuItem:reloadSettings.-)\nfunction ConfigSettingsMenuItem:'))
local soundValues={disabled=false};local soundSaves=0;local soundFail=false
local soundOwner={getSettings=function()return soundValues end,saveSettings=function()soundSaves=soundSaves+1;if soundFail then return false,'disk' end;return true end}
local sharedOwnerError
local menu={layout='Condensed',save_on_exit=true,adjacent=true,ijkl=false,extra='kept'}
local addonSaves=0
local addon={getSettings=function()return{menu=menu,autocomplete={visible=true}}end,saveSettings=function()addonSaves=addonSaves+1 end}
local env=setmetatable({ConfigSettingsMenuItem={},L=L,
 ButtonItem={default=function(k)return k end},
 BooleanConfigItem={new=function(k,label)return{key=k,label=label}end},
 PickerConfigItem={new=function(k)return{key=k}end},
 MenuItem={new=function(_,_,view,title)return{view=view,title=title}end},
 WidgetSettingsMenuItem={new=function()return{}end},RemoteCommandsSettingsMenuItem={new=function()return{}end},
 ConfigEditor={new=function(owner,values,items)return{owner=owner,values=values,items=items}end},
 addon_system_error=function(m)sharedOwnerError=m end,
 require=function(name)
  if name=='cylibs/ui/menu/menu_preferences' then return{layout=function()return'Condensed'end}end
  if name=='settings/shared_preferences' then return{shared=function()return{owner=function(_,section)assert(section=='Sounds');return soundOwner end}end}end
  return{new=function()return{}end}
 end},{__index=_G})
assert(load(body,'actual Config menu','t',env))()
local children={}
env.ConfigSettingsMenuItem.reloadSettings({buttonItems={},setChildMenuItem=function(_,k,v)children[k]=v end,
 getLoggingMenuItem=function()return{}end},addon)
assert(not children.Sounds,'no separate Sounds entry')
local editor=children.Menu.view(nil,{})
local keys={};for _,item in ipairs(editor.items)do keys[#keys+1]=item.key end
assert(table.concat(keys,',')=='layout,save_on_exit,adjacent,ijkl,sounds_disabled','sound option is last in Config > Menu')
assert(editor.items[5].label=='Disable sound effects for this installation')
assert(editor.values.sounds_disabled==false and editor.values.layout=='Condensed')
assert(editor.values~=menu and menu.sounds_disabled==nil,'the sound flag must never leak into per-character menu settings')
-- Editing then saving routes each value to its own owner.
editor.values.layout='Full';editor.values.sounds_disabled=true
assert(editor.owner:saveSettings()==true)
assert(menu.layout=='Full' and menu.extra=='kept' and menu.sounds_disabled==nil and addonSaves==1)
assert(soundValues.disabled==true and soundSaves==1)
-- An unchanged sound value does not rewrite the shared file.
local again=children.Menu.view(nil,{});again.values.ijkl=true
assert(again.values.sounds_disabled==true and again.owner:saveSettings()==true)
assert(menu.ijkl==true and soundSaves==1 and addonSaves==2)
-- A failed shared write is reported to the editor.
soundFail=true;local third=children.Menu.view(nil,{});third.values.sounds_disabled=false
local ok,err=third.owner:saveSettings();assert(ok==false and err=='disk')
-- No shared owner: the option is omitted, the menu options still work, and the error is shown.
soundOwner=nil
local envOwner=function()return nil,'no shared file' end
env.require=function(name)
  if name=='cylibs/ui/menu/menu_preferences' then return{layout=function()return'Condensed'end}end
  if name=='settings/shared_preferences' then return{shared=function()return{owner=envOwner}end}end
  return{new=function()return{}end}
end
children={}
env.ConfigSettingsMenuItem.reloadSettings({buttonItems={},setChildMenuItem=function(_,k,v)children[k]=v end,
 getLoggingMenuItem=function()return{}end},addon)
local fourth=children.Menu.view(nil,{})
assert(fourth.values.sounds_disabled==nil and sharedOwnerError=='no shared file')
fourth.values.adjacent=false;assert(fourth.owner:saveSettings()==true and menu.adjacent==false)
print('PASS Config > Menu holds the shared sound switch: per-character menu options and the shared file are saved separately')
