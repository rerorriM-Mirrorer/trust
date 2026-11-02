-- Real command, shared store and long-lived menu; disk/UI are small doubles.
local methods={append=function(s,v)s.n=s.n+1;rawset(s,s.n,v);return s end}
L=function(t)t=t or {};t.n=#t;return setmetatable(t,{__index=methods})end;T=L
local Shared=require('settings/shared_preferences')
local bytes={};local held=false
local disk={read=function(_,p)return bytes[p]end,write=function(_,p,v)bytes[p]=v;return true end,
 remove=function(_,p)bytes[p]=nil end,replace=function(_,a,b)bytes[b]=bytes[a];bytes[a]=nil;return true end,
 lock=function()assert(not held);held=true;return function()held=false end end}
local store=Shared.new({disk=disk,path='shared',serialize=require('cylibs/util/serializer_util').serialize})
local legacy=false
package.loaded['settings/shared_preferences']={shared=function()return store end,enabled=function()return not legacy end}
package.loaded['cylibs/trust/commands/trust_commands']={new=function()return{add_command=function()end}end}
package.loaded['cylibs/trust/commands/gambit_commands']={register=function()end}
package.loaded['cylibs/gambits/gambit_target']={TargetType={Enemy='Enemy'}}
package.loaded['ui/settings/editors/config/PickerConfigItem']={new=function()end}
local legacyValue={Blacklist=L{}}
local owner={getSettings=function()return{Default={PullSettings=legacyValue}}end,saveSettings=function()return true end}
state={MainTrustSettingsMode={value='Default'}}
windower={ffxi={get_mob_by_target=function()return{name='Goblin Weaver'}end}}
local Commands=require('commands/PullCommands');local command=Commands.new({},owner,{},{})
local function node(buttons,children,construct)return{buttonItems=buttons,childMenuItems=children or {},contentViewConstructor=construct,
 setChildMenuItem=function(s,k,v)s.childMenuItems[k]=v end,destroy=function()end}end
package.loaded['cylibs/ui/menu/menu_item']={new=node,action=function(fn)return{callback=fn}end,destroy=function()end}
package.loaded['cylibs/ui/collection_view/items/button_item']={default=function(s)return s end}
package.loaded['ui/settings/editors/config/ConfigEditor']={new=function(o,v)return{owner=o,values=v}end}
package.loaded['ui/settings/editors/config/ConfigItem']={new=function()end}
package.loaded['ui/settings/editors/config/BooleanConfigItem']={new=function()end}
package.loaded['cylibs/events/dispose_bag']={new=function()return{destroy=function()end}end}
local exclusionOwner
package.loaded['ui/settings/menus/pulling/PullSettingsMenuItem']={getBlacklistMenuItem=function(s)
 exclusionOwner=s.trust_settings
 return node({}, {Add=node({}, {},function()return s.trust_settings:getSettings().Default.PullSettings.Blacklist end)},
 function()return s.trust_settings:getSettings().Default.PullSettings.Blacklist end)
end}
for _,name in ipairs({'PullTargetsMenuItem','PullTargetIDsMenuItem'})do
 package.loaded['ui/settings/menus/pulling/'..name]={new=function(o)return node({}, {},function()return o:getSettings().Default.PullSettings end)end}
end
local menu=require('ui/settings/menus/pulling/SharedPullSettingsMenuItem').new({getSettings=function()return{}end},{},owner,state.MainTrustSettingsMode,{})
assert(exclusionOwner:getSettings().Default.PullSettings.Blacklist.n==0)
assert(command:handle_ignore(nil,'<t>'))
assert(store:read().Pulling.Blacklist[1]=='Goblin Weaver')
-- Menu was constructed before the command: its owner is an old snapshot.
assert(exclusionOwner:getSettings().Default.PullSettings.Blacklist.n==0)
local shown=menu.childMenuItems.Exclusions.contentViewConstructor()
assert(shown.n==1 and shown[1]=='Goblin Weaver','opening Exclusions retained stale data')
local ok,message=command:handle_ignore(nil,'list');assert(ok and message:find('shared, 1',1,true) and message:find('Goblin Weaver',1,true))
assert(command:handle_ignore(nil,'goblin','weaver'));assert(#store:read().Pulling.Blacklist==1)
-- Another client/store adds something; reopening Add and Config gets fresh source.
local other=Shared.new({disk=disk,path='shared',serialize=require('cylibs/util/serializer_util').serialize})
local data=other:read();data.Pulling.Blacklist[2]='Orcish Fodder';assert(other:update('Pulling',data.Pulling))
assert(menu.childMenuItems.Exclusions.childMenuItems.Add.contentViewConstructor().n==2)
local editor=menu.childMenuItems.Config.contentViewConstructor();assert(editor.values.Blacklist[2]=='Orcish Fodder')
-- An active draft stays protected until explicitly reopened.
local draft=assert(store:owner('Pulling'));assert(command:handle_ignore(nil,'Yagudo','Initiate'))
assert(not draft:saveSettings(true));assert(draft:reloadSettings());assert(draft:saveSettings(true))
legacy=true;assert(command:handle_ignore(nil,'Bat'));assert(legacyValue.Blacklist.n==1)
ok,message=command:handle_ignore(nil,'list');assert(ok and message:find('legacy job, 1',1,true))
assert(#store:read().Pulling.Blacklist==3,'legacy edit changed shared list')
print('PASS ignore saves, scoped readback, proper list length, fresh Exclusions/Add/Config after commands/other-client edits and stale-draft protection')
