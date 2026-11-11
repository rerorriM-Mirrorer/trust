-- Host regression: execute production menu callbacks, validator and singer builder.
local methods = {}
local mt = {__index=methods}
function L(t) return setmetatable(t or {}, mt) end
function mt.__add(a,b) local r=L{};for _,v in ipairs(a) do r:append(v) end;for _,v in ipairs(b) do r:append(v) end;return r end
function methods:append(v) self[#self+1]=v end
function methods:length() return #self end
function methods:it() local i=0;return function() i=i+1;return self[i] end end
function methods:map(f) local r=L{};for i,v in ipairs(self) do r:append(f(v,i)) end;return r end
function methods:filter(f) local r=L{};for _,v in ipairs(self) do if f(v) then r:append(v) end end;return r end
function methods:contains(v) for _,x in ipairs(self) do if x==v then return true end end;return false end
function methods:clear() for k in pairs(self) do self[k]=nil end end
function methods:sort() table.sort(self);return self end
function S(t) local r=L{};for _,v in ipairs(t) do if not r:contains(v) then r:append(v) end end;return r end
T=function(t)return t end
local function event()return {callbacks={},addAction=function(self,f)self.callbacks[#self.callbacks+1]=f;return f end,trigger=function(self,...)for _,f in ipairs(self.callbacks)do f(...)end end} end
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function stubs(path)for n in source(path):gmatch("require%('([^']+)'%)")do package.loaded[n]=package.loaded[n] or {} end end
local Slots=require('cylibs/entity/jobs/bard/song_slots')
local song
song = function(n) return {get_name=function()return n end,get_job_abilities=function()return L{} end,get_job_names=function()return L{} end,set_requires_all_job_abilities=function()end,set_job_abilities=function()end,copy=function()return song(n)end} end
local ballad,minuet,paeon=song("Mage's Ballad"),song('Valor Minuet'),song("Army's Paeon II")
local sparse={[2]=ballad,[4]=minuet,[5]=paeon}
assert(Slots.active(sparse):length()==3 and Slots.active(sparse)[1]==ballad)
assert(Slots.active(L{'None',ballad,'None',minuet,paeon})[2]==minuet)
assert(Slots.active(nil):length()==0)
-- Production BRD validator accepts blanks but still rejects duplicate/conflicting songs.
local Bard={}
local buffs={["Mage's Ballad"]=1,['Valor Minuet']=2,["Army's Paeon II"]=3,['Other Minuet']=2}
local env=setmetatable({Bard=Bard,spell_util={spell_id=function(n)return n end},buff_util={buff_for_spell=function(n)return{id=assert(buffs[n],n)}end},set={intersection=function(a,b)return a:filter(function(v)return b:contains(v)end)end}},{__index=_G})
local src=source('cylibs/entity/jobs/BRD.lua')
assert(load(src:match('(function Bard:validate_songs.-)\nfunction Bard:get_extra_song_items'),nil,'t',env))()
assert(Bard:validate_songs(L{'None',"Mage's Ballad",'None','Valor Minuet','None'},L{}))
assert(Bard:validate_songs(L{'None','None'},L{}))
assert(not Bard:validate_songs(L{'Valor Minuet','Valor Minuet'},L{}))
assert(not Bard:validate_songs(L{'Valor Minuet'},L{'Other Minuet'}))
-- Full menu constructor with host UI doubles. Real picker configuration classes.
local path='ui/settings/menus/songs/SongSettingsMenuItem.lua';stubs(path)
package.loaded['ui/settings/editors/config/PickerConfigItem']=dofile('ui/settings/editors/config/PickerConfigItem.lua')
package.loaded['ui/settings/editors/config/MultiPickerConfigItem']=dofile('ui/settings/editors/config/MultiPickerConfigItem.lua')
package.loaded['cylibs/ui/menu/menu_item'].new=function(_,_,_,title)return{titleText=title}end
package.loaded['cylibs/ui/collection_view/items/button_item']={localized=function()end,default=function()end}
package.loaded['cylibs/events/dispose_bag'].new=function()return{add=function()end}end
package.loaded['cylibs/entity/jobs/bard/song_validator'].new=function()return{}end
local Config={}
function Config.new(_,settings,items,_,validator)
 local events={changed=event(),item=event(),invalid=event()};local e={configSettings=settings,items=items,validator=validator,events=events,delegate=event()}
 function e:onConfigChanged()return events.changed end
 function e:onConfigItemChanged()return events.item end
 function e:onConfigValidationError()return events.invalid end
 function e:getDelegate()return{didMoveCursorToItemAtIndexPath=function()return self.delegate end}end
 function e:setShouldRequestFocus()end
 function e:getSize()return{width=400}end
 function e:setTitle(title)self.title=title end
 function e:readDraft()return self.configSettings end
 return e
end
package.loaded['ui/settings/editors/config/ConfigEditor']=Config
local Menu=dofile(path);Menu.reloadSettings=function()end
i18n={translate=function(v)return v end};job_util={all_jobs=function()return L{'BRD'}end}
localization_util={commas=function()return '' end}
Spell={new=function(n)assert(n~='None');return song(n)end}
addon_system_error=function(m)error(m)end
local sets={Default={Songs=L{song('Other Minuet')}},Travel={Songs=L{ballad,'None',minuet,'None',paeon}}}
local root={Default={SongSettings={SongSets=sets,DummySongs=L{song('Other Minuet')}}}}
local saved=0
local owner={getSettings=function()return root end,saveSettings=function()saved=saved+1 end}
local job={get_spells=function()return L{} end,validate_songs=function(_,a,b)return Bard:validate_songs(a,b)end}
local trust={get_job=function()return job end,role_with_type=function()return{}end}
local menu=Menu.new(owner,{value='Default'},{},'Travel',trust)
assert(menu.titleText=='Songs - Travel')
local editor=menu.contentViewConstructor(nil,{setDescription=function()end},function()end)
assert(editor.title=='Songs - Travel')
assert(editor.configSettings.Song2=='None' and editor.configSettings.Song5=="Army's Paeon II")
assert(editor.items[1]:getNumItemsRequired().minNumItems==0)
editor.configSettings.DummySongs:clear();editor.items[1]:getOnConfirm()(L{})
assert(saved==1 and root.Default.SongSettings.DummySongs:length()==0)
editor.configSettings.Song4='Valor Minuet';editor.configSettings.Song3='None'
menu:setSongSetName('Default') -- an older editor must retain its own save target
editor:onConfigItemChanged():trigger()
assert(saved==2 and sets.Travel.Songs[3]=='None' and Slots.name(sets.Travel.Songs[4])=='Valor Minuet')
assert(Slots.name(sets.Default.Songs[1])=='Other Minuet')
menu:setSongSetName('Travel');assert(menu.titleText=='Songs - Travel')
local reopened=menu.contentViewConstructor(nil,{setDescription=function()end},function()end)
assert(reopened.configSettings.Song4=='Valor Minuet' and reopened.configSettings.Song3=='None')
assert(reopened.configSettings.DummySongs:length()==0)
-- Existing nonempty dummy selections survive subsequent song saves.
reopened.configSettings.DummySongs=L{song('Other Minuet')}
reopened.configSettings.Song4='None';reopened:onConfigItemChanged():trigger()
assert(root.Default.SongSettings.DummySongs:length()==1)
-- Clear touches just the selected slot and never restores factory songs.
package.loaded['cylibs/ui/menu/menu_item'].action=function(callback,_,_,_,enabled)return{callback=callback,enabled=enabled}end
menu.selectedSongIndex=2
local clear=menu:getClearSongMenuItem();assert(clear.enabled())
clear.callback({showMenu=function(_,target)assert(target==menu)end})
assert(sets.Travel.Songs[1]=='None' and Slots.name(sets.Travel.Songs[5])=="Army's Paeon II")
assert(Slots.name(sets.Default.Songs[1])=='Other Minuet')
menu.selectedSongIndex=1;assert(not clear.enabled())
-- Song-set list opens at the active set and points Edit at the same set.
local setsPath='ui/settings/menus/songs/SongSetsMenuItem.lua';stubs(setsPath)
T=function(t)return setmetatable({}, {__index=function(_,key)
 if key=='keyset' then return function()local r={};for k in pairs(t)do r[#r+1]=k end;return r end end
 return t[key]
end})end
package.loaded['ui/settings/menus/songs/SongSettingsMenuItem']=Menu
local base=package.loaded['cylibs/ui/menu/menu_item']
base.new=function(_,_,_,title)return{titleText=title,setChildMenuItem=function()end}end
package.loaded['cylibs/events/value_relay'].new=function(v)
 local e=event();return{value=v,getValue=function(self)return self.value end,onValueChanged=function()return e end,setValue=function(self,n)self.value=n;e:trigger(nil,n)end}
end
package.loaded['cylibs/ui/collection_view/index_path'].new=function(section,row)return{section=section,row=row}end
local cursor
package.loaded['ui/themes/ffxi/FFXIPickerView'].withConfig=function(config)
 local moved,selected=event(),event()
 local delegate={didMoveCursorToItemAtIndexPath=function()return moved end,didSelectItemAtIndexPath=function()return selected end,
 setCursorIndexPath=function(_,index)cursor=index;moved:trigger(index)end}
 return {setAllowsCursorSelection=function()end,setNeedsLayout=function()end,layoutIfNeeded=function()end,
 getDelegate=function()return delegate end,getDataSource=function()return{itemAtIndexPath=function(_,index)
  local name=config:getAllValues()[index.row];return{getText=function()return name end}
 end}end}
end
state={SongSet={value='Travel'}}
local SetsMenu=dofile(setsPath);SetsMenu.reloadSettings=function()end
local listMenu=SetsMenu.new(owner,{value='Default'},{},trust)
listMenu.contentViewConstructor()
assert(cursor.row==2 and listMenu.editSetMenuItem.songSetName=='Travel')
listMenu.selectedSetName:setValue('Default')
listMenu.contentViewConstructor()
assert(cursor.row==1 and listMenu.editSetMenuItem.songSetName=='Default')
-- Actual singer builder: compact slots before assigning capacity gates.
local singerPath='cylibs/trust/roles/singer.lua';stubs(singerPath)
local function condition(kind,...)return{kind=kind,args={...},is_editable=function()return true end}end
local function constructor(kind)return{new=function(...)return condition(kind,...)end}end
for _,name in ipairs({'conditional','cooldown','has_max_num_songs','max_num_songs','num_expiring_songs','num_songs','song_duration'})do package.loaded['cylibs/conditions/'..name]=constructor(name)end
for _,name in ipairs({'script','sequence','wait'})do package.loaded['cylibs/battle/'..name]=constructor(name)end
package.loaded['cylibs/gambits/gambit_target'].TargetType={Self='Self',Ally='Ally'}
Condition={Operator={LessThan='<',GreaterThanOrEqualTo='>=',Equals='='},LogicalOperator={Or='or'},TargetType={Self='Self'}}
for _,n in ipairs({'NotCondition','HasSongsCondition','IsAlterEgoCondition','ModeCondition','JobAbility','JobCondition'})do _G[n]=constructor(n)end
GambitCondition={new=function(c)return c end}
Gambit={new=function(_,conditions,ability)return{conditions=conditions,ability=ability,addCondition=function()end}end}
state={SongSet={value='Travel'}}
local Singer=dofile(singerPath)
local singer=setmetatable({job={max_num_songs=2,is_clarion_call_active=function()return false end},get_default_conditions=function()return L{}end,set_gambit_settings=function()end},{__index=Singer})
singer:set_song_settings({DummySongs=L{},SongSets={Travel={Songs=sparse,PianissimoSongs=L{}}},DummySongThreshold=2})
assert(singer.songs:length()==3 and singer.dummy_songs:length()==0)
local g=singer.gambit_settings.Songs
assert(g:length()==6 and g[1].ability==ballad and g[3].ability==minuet and g[5].ability==paeon)
assert(g[5].conditions[2].kind=='max_num_songs' and g[5].conditions[2].args[1]==3)
assert(g[5].conditions[4].args[1][2].args[1]==5) -- no dummy threshold deadlock
singer:set_song_settings({ResingMissingSongs=true,DummySongs=L{},SongSets={Travel={Songs=sparse,PianissimoSongs=L{}}},DummySongThreshold=2})
assert(singer.gambit_settings.PianissimoSongs[3].conditions[2].args[1]==3)
singer:set_song_settings({DummySongs=L{},SongSets={Travel={Songs=L{'None','None'},PianissimoSongs=L{}}},DummySongThreshold=2})
assert(singer.gambit_settings.Gambits:length()==0)
print('PASS BRD empty slots, dummy clearing/preservation, named set save/reopen, ordering and capacity gates')
