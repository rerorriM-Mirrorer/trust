local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function stubs(path)for n in source(path):gmatch("require%('([^']+)'%)")do package.loaded[n]={} end end
local path='cylibs/ui/collection_view/cells/text_field_collection_view_cell.lua';stubs(path)
package.loaded['cylibs/ui/collection_view/cells/button_collection_view_cell'].onKeyboardEvent=function()return false end
local keyName
package.loaded['cylibs/ui/input/keyboard'].input=function()return{getKey=function()return keyName end}end
local Cell=dofile(path)
local text='';local submitted,cancelled=0,0
local textItem={getText=function()return text end,setText=function(_,s)text=s end}
local item={getTextItem=function()return textItem end,isValid=function(_,s)return #s<=24 end,
 onTextSubmit=function()submitted=submitted+1 end,onTextCancel=function()cancelled=cancelled+1 end}
local cell=setmetatable({getItem=function()return item end,setNeedsLayout=function()end,layoutIfNeeded=function()end},{__index=Cell})
local function press(name,flags,key)keyName=name;cell:onKeyboardEvent(key or 99,true,flags or 0,false)end
for _,name in ipairs({'Up','Down','Left','Right','LShift','RShift','LControl','RControl','Enter','Escape','Tab'})do press(name)end
assert(text=='')
press('B',1);press('A');press('L');press('L');press('A');press('D');assert(text=='Ballad')
press('A',2);press('A',4);assert(text=='Ballad')
press('Backspace');assert(text=='Balla')
press(' ');press('Minus');assert(text=='Balla -')
press('Enter',0,28);press('Escape',0,1);assert(submitted==1 and cancelled==1)
for i=1,100 do press('A')end;assert(#text==24)
-- The actual page rebuild must preserve logical selections across scrolling/filtering.
local Fast={}
local src=source('ui/themes/ffxi/FFXIFastPickerView.lua')
local env=setmetatable({FFXIFastPickerView=Fast},{__index=_G})
local methods={}
function L(t)return setmetatable(t or {},{__index=methods})end
function methods:length()return #self end
function methods:append(v)self[#self+1]=v end
function methods:it()local i=0;return function()i=i+1;return self[i]end end
function methods:contains(v)for _,s in ipairs(self)do if s==v then return true end end;return false end
function methods:indexOf(v)for i,s in ipairs(self)do if s==v then return i end end end
function methods:remove(i)table.remove(self,i)end
local function event()return{callbacks={},addAction=function(self,f)self.callbacks[#self.callbacks+1]=f end,trigger=function(self,...)for _,f in ipairs(self.callbacks)do f(...)end end}end
local select,deselect=event(),event()
local values=L{'Ballad','March','Scop','Paeon'}
local chosen=L{'Ballad','March'}
local relay={getValue=function()return chosen end}
local delegate={}
function delegate:didSelectItemAtIndexPath()return select end
function delegate:didDeselectItemAtIndexPath()return deselect end
function delegate:deselectAllItems()deselect:trigger({row=1})end
function delegate:selectItemAtIndexPath(i)select:trigger(i)end
function delegate:setCursorIndexPath()end
local q={selectedItems=relay,visibleItems=L{'Ballad','March'},maxNumItems=1,
 getDelegate=function()return delegate end,getAllowsMultipleSelection=function()return true end,
 configItem={getAllValues=function()return values end},getItemForValue=function(_,v)return v end,layoutIfNeeded=function()end}
local ds={removeAllItems=function()end,updateItems=function()end,numberOfItemsInSection=function()return 2 end}
q.getDataSource=function()return ds end
local begin=assert(src:find('    self:getDelegate():didSelectItemAtIndexPath():addAction',1,true))
local finish=assert(src:find('    self:setRange(1, self.maxNumItems + 1)',begin,true))
env.self=q
assert(load(src:sub(begin,finish-1),nil,'t',env))()
env.IndexPath={new=function(section,row)return{section=section,row=row}end}
env.IndexedItem={new=function(item,index)return{item=item,index=index}end,fromItems=function(items)
 return items:map(function(v,i)return{getItem=function()return v end,getIndexPath=function()return{section=1,row=i}end}end)
end}
function methods:map(f)local r=L{};for i,v in ipairs(self)do r:append(f(v,i))end;return r end
begin=assert(src:find('function FFXIFastPickerView:setRange',1,true));finish=assert(src:find('function FFXIFastPickerView:reload()',begin,true))
assert(load(src:sub(begin,finish-1),nil,'t',env))()
Fast.setRange(q,3,4,true)
assert(#chosen==2 and chosen[1]=='Ballad' and chosen[2]=='March')
Fast.setRange(q,1,2,true)
assert(#chosen==2)
deselect:trigger({row=2});assert(#chosen==1 and chosen[1]=='Ballad')
-- Deselecting a row absent from the selected list must not remove its last song.
deselect:trigger({row=2});assert(#chosen==1)
print('PASS printable text/control keys, Enter/Escape callbacks, length bounds and picker selection rebuilds')
-- Rejected multi-picker confirmation restores the previous visible value.
path='cylibs/ui/collection_view/cells/picker_collection_view_cell.lua';stubs(path)
local Menu=package.loaded['cylibs/ui/menu/menu_item'];Menu.new=function(_,_,content)return{content=content}end
package.loaded['cylibs/ui/collection_view/items/button_item'].localized=function()end
package.loaded['ui/settings/editors/config/MultiPickerConfigItem']=dofile('ui/settings/editors/config/MultiPickerConfigItem.lua')
local picked=event()
package.loaded['ui/themes/ffxi/FFXIFastPickerView'].new=function()return{on_pick_items=function()return picked end}end
local Picker=dofile(path)
local old=L{'Scop'};local current=old;local shown;local accept=false
class=function()return 'List'end
i18n={translate=function(x)return x end}
local control={getAllowsMultipleSelection=function()return true end,getCurrentValue=function()return current end,
 setCurrentValue=function(_,v)current=v end,getAllValues=function()return values end,
 getPickerTextFormat=function()return tostring end,getImageItemForText=function()return function()end end,
 getPickerItemDescription=function()end,getNumItemsRequired=function()return{minNumItems=0,maxNumItems=3}end,
 getPickerTitle=function()end,getPickerDescription=function()end,getShowMenu=function()return function(m)shown=m end end,
 getOnPickItems=function()return function()return accept end end}
local pickerCell=setmetatable({getItem=function()return control end,setItem=function()end},{__index=Picker})
pickerCell:showPickerView();shown.content()
picked:trigger(nil,L{'Ballad','March'});assert(current==old)
accept=true;picked:trigger(nil,L{'Ballad','March'});assert(current[1]=='Ballad' and current[2]=='March')
print('PASS rejected multi-picker selection rollback and accepted selection')
-- Search owns submit/cancel and leaves a cancelled draft unapplied.
path='ui/settings/pickers/SearchBarView.lua';stubs(path)
package.loaded['cylibs/events/Luvent'].newEvent=event
package.loaded['cylibs/ui/views/frame'].new=function(x,y,w,h)return{width=w,height=h}end
package.loaded['ui/settings/editors/config/TextInputConfigItem']=dofile('ui/settings/editors/config/TextInputConfigItem.lua')
local searchItem={};local query='ballad';local itemChanged=event()
package.loaded['ui/settings/editors/config/ConfigEditor'].new=function(_,_,config,_,_,_,size)
 assert(size.width==300 and config[1].width==260)
 assert(config[1]:getValidator()(string.rep('x',24)) and not config[1]:getValidator()(string.rep('x',25)))
 return{setTitle=function()end,setNeedsLayout=function()end,layoutIfNeeded=function()end,
 getDataSource=function()return{itemAtIndexPath=function()return searchItem end}end,
 onConfigItemChanged=function()return itemChanged end,readDraft=function()return{query=query}end,
 resignFirstResponder=function()itemChanged:trigger('query',query,'')end,resignFocus=function()end}
end
local Search=dofile(path);local search=Search.new();local applied
search:onSearchQueryChanged():addAction(function(_,q)applied=q end)
searchItem.onTextSubmit();assert(applied=='ballad')
query='march';searchItem.onTextCancel();assert(applied=='ballad')
print('PASS Filter submit/cancel ownership and bounded field configuration')
