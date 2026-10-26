-- Actual Job menu adapter; renderer and standard editor are replaced by probes.
local owner={jobNameShort='WHM'}
local shared={reloadSettings=function(self)self.reloaded=true end}
local captured
package.loaded['settings/shared_job_gambits']={new=function(o)assert(o==owner);return shared end}
package.loaded['ui/settings/menus/gambits/GambitEditorStyle']={named=function(a,b)return {a,b}end}
package.loaded['cylibs/ui/menu/menu_item']={action=function(callback,title,description)return{callback=callback,titleText=title,descriptionText=description}end}
package.loaded['ui/settings/menus/gambits/GambitSettingsMenuItem']={new=function(trust,settings,mode,modes,key,a,b,c,style)
    assert(settings==shared and mode.value=='Default' and key=='GambitSettings' and style[1]=='Shared Job gambit')
    captured={children={Toggle={},Reset={}},getChildMenuItem=function(self,k)return self.children[k]end,
        setChildMenuItem=function(self,k,v)self.children[k]=v end}
    return captured
end}
addon_system_error=function(message)error(message)end
local menu=require('ui/settings/menus/gambits/JobGambitSettingsMenuItem').new({},owner,{}, {})
assert(menu==captured and menu.titleText=='Job (shared)')
assert(menu.descriptionText:find('all characters/profiles',1,true))
assert(menu.children.Toggle.descriptionText:find('permanently',1,true))
local shown
menu.children.Reload.callback({showMenu=function(_,value)shown=value end});assert(shared.reloaded and shown==menu)
print('PASS actual Job menu: full editor uses shared owner, fixed shared profile, visible scope, persistent toggle and Reload')
