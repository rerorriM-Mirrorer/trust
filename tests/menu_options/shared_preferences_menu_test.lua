L=function(t)return t or {}end
local function node(buttons,children,construct,title,description)
    return {buttons=buttons,childMenuItems=children or {},contentViewConstructor=construct,titleText=title,descriptionText=description,
        setChildMenuItem=function(self,k,v)self.childMenuItems[k]=v end,destroy=function()end}
end
local Menu={new=node,action=function(fn,title,description)local m=node(nil,nil,nil,title,description);m.callback=fn;return m end,destroy=function()end}
package.loaded['cylibs/ui/menu/menu_item']=Menu
package.loaded['cylibs/ui/collection_view/items/button_item']={default=function(k)return k end}
package.loaded['ui/settings/editors/config/ConfigEditor']={new=function(owner,values,items)return {owner=owner,values=values,items=items}end}
package.loaded['ui/settings/editors/config/ConfigItem']={new=function(key)return key end}
package.loaded['ui/settings/editors/config/BooleanConfigItem']={new=function(key)return key end}
package.loaded['cylibs/events/dispose_bag']={new=function()return{destroy=function()end}end}
local pulling={Targets={'shared'},TargetIds={},Blacklist={'excluded'},Distance=30,Delay=0}
local pullOwner={getSettings=function()return{Default={PullSettings=pulling}}end}
local soundValues={disabled=true};local soundOwner={getSettings=function()return soundValues end}
local writes={}
local store={owner=function(_,section)return section=='Pulling' and pullOwner or soundOwner end,
    read=function()return{Pulling=pulling}end,update=function(_,section,value)writes[#writes+1]={section,value};return true end}
package.loaded['settings/shared_preferences']={shared=function()return store end}
local targetOwners={}
for _,path in ipairs({'PullTargetsMenuItem','PullTargetIDsMenuItem'})do
    package.loaded['ui/settings/menus/pulling/'..path]={new=function(owner,mode)targetOwners[#targetOwners+1]=owner;assert(mode.value=='Default');return node()end}
end
package.loaded['ui/settings/menus/pulling/PullSettingsMenuItem']={getBlacklistMenuItem=function(self)assert(self.trust_settings==pullOwner);return node()end}
local addon={getSettings=function()return{use_shared_pulling=true}end}
local job={getSettings=function()return{Solo={PullSettings={Targets={'legacy'},Blacklist={},TargetIds={},Distance=12,Delay=2,Gambits={'action'}}}}end}
local menu=require('ui/settings/menus/pulling/SharedPullSettingsMenuItem').new(addon,{},job,{value='Solo'}, {})
local c=menu.childMenuItems
assert(c.Targets and c['Target IDs'] and c.Exclusions and c.Config and c.Source and c['Import Job'] and c['Clear Targets'] and c.Reload and not c.Actions)
assert(targetOwners[1]==pullOwner and c.Config.contentViewConstructor().owner==pullOwner)
assert(c.Source.contentViewConstructor().owner==addon)
local parent={showMenu=function(_,shown)assert(shown==menu)end}
c['Import Job'].callback(parent)
assert(writes[1][1]=='Pulling' and writes[1][2].Targets[1]=='legacy' and writes[1][2].Distance==12 and not writes[1][2].Gambits)
-- Actual sound menu method must use the shared owner, not addon config.
local f=assert(io.open('ui/settings/menus/ConfigSettingsMenuItem.lua'));local source=f:read('*a');f:close()
local env=setmetatable({ConfigSettingsMenuItem={},MenuItem=Menu,ButtonItem=package.loaded['cylibs/ui/collection_view/items/button_item'],ConfigEditor=package.loaded['ui/settings/editors/config/ConfigEditor'],BooleanConfigItem=package.loaded['ui/settings/editors/config/BooleanConfigItem']},{__index=_G})
local method=assert(source:match('(function ConfigSettingsMenuItem:getSoundSettingsMenuItem.-)\nfunction '))
assert(load(method,'actual sound menu','t',env))()
local soundMenu=env.ConfigSettingsMenuItem:getSoundSettingsMenuItem(addon)
local editor=soundMenu.contentViewConstructor()
assert(editor.owner==soundOwner and editor.values==soundValues and soundMenu.titleText=='Sounds (shared)')
print('PASS actual shared menus: shared target/config/sound owners, per-character source choice, explicit import without actions, scope and reload controls')
