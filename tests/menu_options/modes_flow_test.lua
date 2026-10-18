-- Real mode/editor constructors, item models, data source, events and menu exit.
-- Rendering, OS input, mode state and persistence are simulated.
-- Run: luatex --luaonly tests/menu_options/modes_flow_test.lua
unpack = unpack or table.unpack
local checks = 0
local function check(ok, message) checks=checks+1; assert(ok, message) end
local methods = {}
local function list(t) return setmetatable(t or {}, {__index=methods}) end
function methods:it() local i=0; return function() i=i+1; return self[i] end end
function methods:length() return #self end
function methods:empty() return #self==0 end
function methods:last() return self[#self] end
function methods:append(v) self[#self+1]=v end
function methods:remove(i) return table.remove(self,i) end
function methods:filter(f) local r=list(); for _,v in ipairs(self) do if f(v) then r:append(v) end end; return r end
function methods:map(f) local r=list(); for _,v in ipairs(self) do r:append(f(v)) end; return r end
function methods:compact_map() return self end
function methods:contains(v) for _,x in ipairs(self) do if x==v then return true end end; return false end
function methods:add(v) self:append(v) end
L,T,S=list,list,list
local function actual(path)
    local f=assert(io.open(path..'.lua')); local s=f:read('*a'); f:close()
    s=s:gsub('("[^"\n]*"):(%a+)%(', function(q,m) return '('..q..'):'..m..'(' end)
    s=s:gsub("('[^'\n]*'):(%a+)%(", function(q,m) return '('..q..'):'..m..'(' end)
    return assert((loadstring or load)(s,'@'..path..'.lua'))()
end
local Event=require('cylibs/events/Luvent')
-- Stub graphics classes only; keep the option/item types used by the editor.
local f=assert(io.open('ui/settings/editors/config/ConfigEditor.lua')); local s=f:read('*a'); f:close()
for name in s:gmatch("require%('([^']+)'%)") do
    local kind=name:match('([^/]+)$')
    package.preload[name]=function() return {__type=kind,new=function() return {} end} end
end
package.preload['cylibs/events/Luvent']=function() return Event end
for _,name in ipairs({'cylibs/ui/menu/menu_preferences','cylibs/ui/menu/editor_values','cylibs/ui/menu/menu_save_trace',
    'ui/settings/editors/config/PickerConfigItem','cylibs/ui/collection_view/items/picker_item',
    'cylibs/ui/collection_view/index_path','cylibs/ui/collection_view/indexed_item',
    'cylibs/ui/collection_view/collection_view_data_source'}) do
    package.preload[name]=nil
end
for _,name in ipairs({'container_collection_view_cell','image_collection_view_cell',
    'section_header_collection_view_cell','text_collection_view_cell'}) do
    package.preload['cylibs/ui/collection_view/cells/'..name]=function() return {} end
end
-- ContainerCollectionViewCell lives beside the data source in this UI library.
package.preload['cylibs/ui/collection_view/cells/container_collection_view_cell']=function() return {} end
package.preload['cylibs/ui/collection_view/items/view_item']=function() return {__type='ViewItem'} end
package.preload['ui/themes/FFXI/FFXIClassicStyle']=function()
    return {Padding={ConfigEditor={}},WindowSize={Editor={ConfigEditor={}}}}
end
package.preload['cylibs/ui/style/text_style']=function() return {Default={}} end
local focus=require('cylibs/ui/focus/focus_manager').shared()
local Window={}
function Window.new(dataSource)
    local cursor
    local delegate={getCursorIndexPath=function() return cursor end,
        setCursorIndexPath=function(_,v) cursor=v end,deselectItemsInSections=function() end}
    for _,n in ipairs({'didSelectItemAtIndexPath','didDeselectItemAtIndexPath','didMoveCursorToItemAtIndexPath'}) do
        local e=Event.newEvent(); delegate[n]=function() return e end
    end
    return {dataSource=dataSource,delegate=delegate}
end
function Window:getDataSource() return self.dataSource end
function Window:getDelegate() return self.delegate end
function Window:getDisposeBag() return {add=function() end} end
function Window:hasFocus() return self.focused end
function Window:setHasFocus(v) self.focused=v end
function Window:shouldResignFocus() return true end
function Window:requestFocus() return focus:requestFocus(self) end
function Window:resignFocus() focus:resignFocus(self) end
for _,n in ipairs({'setAllowsCursorSelection','setAllowsMultipleSelection','setScrollDelta',
    'setScrollEnabled','setNeedsLayout','layoutIfNeeded','setShouldRequestFocus'}) do Window[n]=function() end end
package.preload['ui/themes/ffxi/FFXIWindow']=function() return Window end
local Editor=actual('ui/settings/editors/config/ConfigEditor')
package.loaded['ui/settings/editors/config/ConfigEditor']=Editor
local ModesView=actual('ui/settings/editors/config/ModeConfigEditor')
package.loaded['ui/settings/editors/config/ModeConfigEditor']=ModesView
package.preload['cylibs/ui/collection_view/items/button_item']=function()
    return {localized=function() return {setEnabled=function() end} end,default=function() return {} end}
end
package.preload['cylibs/ui/menu/menu_item']=function() return {
    new=function(buttons,children,constructor) return {children=children,contentViewConstructor=constructor} end,
    setChildMenuItem=function(self,k,v) self.children[k]=v end,action=function(f) return {callback=f} end}
end
package.preload['ui/settings/menus/ShortcutMenuItem']=function() return {} end
package.preload['cylibs/events/dispose_bag']=function() return {new=function() return {} end} end
package.preload['cylibs/ui/input/keyboard']=function() return {} end
package.preload['cylibs/sounds/sound_theme']=function() return {} end
package.preload['cylibs/ui/menu/menu_view']=function() return {} end
local Menu=actual('cylibs/ui/menu/menu')
local Modes=actual('ui/settings/menus/ModesMenuItem')
local prefs=require('cylibs/ui/menu/menu_preferences')
local notices, writes, errors = 0,0,{}
prefs.configure({getSettings=function() return {menu={save_on_exit=true}} end},function() notices=notices+1 end)
addon_system_error=function(m) errors[#errors+1]=m end
addon_message=function() end
i18n={translate=function(t) return t end}
windower={addon_path='',ffxi={get_player=function() return {name='Test'} end,get_info=function() return {chat_open=false} end}}
local locked=false
is_modes_locked=function() return locked end
state={TrustMode={value='Default'},AutoRaiseMode={value='Off',description='Auto raise',
    options=function() return {'Off','Auto'} end,get_description=function() return '' end}}
handle_set=function(name,value) state[name].value=value end
local disk
local owner={jobNameShort='WHM',playerName='Test',saveSettings=function(_,setName)
    writes=writes+1; disk={setName=setName,autoraisemode=state.AutoRaiseMode.value}
end}
local trace=require('cylibs/ui/menu/menu_save_trace')
addon_system_message=function() end
trace.setEnabled(true)
local item=Modes.new(owner,'',L{'AutoRaiseMode','TrustMode'},true)
-- The profile selector is a picker too, matching the long Modes page.
state.TrustMode.options=function() return {'Default','Other'} end
state.TrustMode.get_description=function() return '' end
local view=item.contentViewConstructor(nil,{setDescription=function() end})
view:getDataSource().cellForItem=function() return {setVisible=function() end,setClipsToBounds=function() end,destroy=function() end,hasFocus=function() return false end} end
local row=view:getDataSource():itemAtIndexPath({section=1,row=1})
check(view:exitSaveStatus()=='unchanged','new mode editor is clean')
row:setCurrentValue('Auto')
check(view:exitSaveStatus()=='pending changes','actual picker exposes pending mode change')
-- Use the menu departure hook, rather than calling the writer directly.
local menu=setmetatable({contentViewStack={getCurrentView=function() return view end}},Menu)
check(menu:commitCurrentEditor(),'mode departure succeeds: '..tostring(errors[#errors]))
check(state.AutoRaiseMode.value=='Auto','actual ModeConfigEditor applies selected mode')
check(writes==1 and disk.setName=='Default' and disk.autoraisemode=='Auto','named mode set persists')
check(notices==1 and view:exitSaveStatus()=='unchanged','mode save notice and clean snapshot')
check(menu:commitCurrentEditor() and writes==1,'repeat exit does not save again')
local reopened=item.contentViewConstructor(nil,{setDescription=function() end})
check(reopened:getDataSource():itemAtIndexPath({section=1,row=1}):getCurrentValue()=='Auto','reopened editor retains change')
view=reopened
view:getDataSource().cellForItem=function() return {setVisible=function() end,setClipsToBounds=function() end,destroy=function() end,hasFocus=function() return false end} end
row=view:getDataSource():itemAtIndexPath({section=1,row=1}); row:setCurrentValue('Off')
locked=true
check(not menu:commitCurrentEditor() and writes==1 and state.AutoRaiseMode.value=='Auto','locked modes cannot falsely save')
locked=false
check(menu:commitCurrentEditor() and writes==2 and disk.autoraisemode=='Off','unlock allows retry')
state.AutoRaiseMode.value='Auto'
menu:refreshAfterCommand()
check(row~=view:getDataSource():itemAtIndexPath({section=1,row=1}) and
    view:getDataSource():itemAtIndexPath({section=1,row=1}):getCurrentValue()=='Auto','clean Modes view follows runtime commands')
row=view:getDataSource():itemAtIndexPath({section=1,row=1});row:setCurrentValue('Off')
state.AutoRaiseMode.value='Off'
menu:refreshAfterCommand()
check(view:getDataSource():itemAtIndexPath({section=1,row=1})==row and view:exitSaveStatus()=='pending changes',
    'emergency command refresh never overwrites a pending draft')
check(menu:commitCurrentEditor() and writes==3,'refreshed mode conflict snapshot permits later valid edit')
local joined=table.concat(trace.entries,'\n')
check(joined:find('path=data/modes/WHM_Test.lua',1,true) and joined:find('autoraisemode:Off->Auto',1,true),
    'real Modes trace includes changed value and selected destination')
check(joined:find('save-returned',1,true) and joined:find('validation-failed',1,true),
    'real commit and rejected commit both leave diagnostic events')
trace.setEnabled(false)
print('PASS: '..checks..' Modes flow checks (rendering, state and persistence mocked)')
