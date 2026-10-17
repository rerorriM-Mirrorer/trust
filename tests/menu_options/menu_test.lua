-- Real edited Lua methods; rendering, Windower I/O and hardware are mocked.
-- Run from repository root: luatex --luaonly tests/menu_options/menu_test.lua
unpack = unpack or table.unpack
local checks=0
local function check(ok, message) checks=checks+1; assert(ok, 'FAIL: '..message) end
local function list(t)
    return setmetatable(t or {}, {__index={
        length=function(s) return #s end, empty=function(s) return #s==0 end,
        last=function(s) return s[#s] end, append=function(s,v) s[#s+1]=v end,
        remove=function(s,i) return table.remove(s,i) end,
        contains=function(s,v) for _,x in ipairs(s) do if x==v then return true end end return false end,
        it=function(s) local i=0; return function() i=i+1; return s[i] end end,
        filter=function(s,f) local r={}; for _,v in ipairs(s) do if f(v) then r[#r+1]=v end end return list(r) end,
        map=function(s,f) local r={}; for _,v in ipairs(s) do r[#r+1]=f(v) end return list(r) end,
    }})
end
L,T,S=list,list,list
local function event()
    return {handlers={}, addAction=function(s,f) s.handlers[#s.handlers+1]=f; return f end,
        trigger=function(s,...) for _,f in ipairs(s.handlers) do f(...) end end,
        removeAllActions=function(s) s.handlers={} end}
end
local function source(path) local f=assert(io.open(path)); local s=f:read('*a'); f:close(); return s end
local function loadActual(path)
    local s=source(path):gsub('("[^"\n]*"):(%a+)%(',function(q,m) return '('..q..'):'..m..'(' end)
    s=s:gsub("('[^'\n]*'):(%a+)%(",function(q,m) return '('..q..'):'..m..'(' end)
    return assert((loadstring or load)(s,'@'..path))()
end
local path='ui/settings/editors/config/ConfigEditor.lua'
for name in source(path):gmatch("require%('([^']+)'%)") do
    if not name:match('^cylibs/ui/menu/') then
        local kind=name:match('([^/]+)$')
        package.preload[name]=function() return {__type=kind,new=function(...) return {...} end} end
    end
end
package.preload['cylibs/events/Luvent']=function() return {newEvent=event} end
package.preload['cylibs/ui/collection_view/index_path']=function() return {new=function(s,r) return {section=s,row=r} end} end
local resigns=0
package.preload['ui/themes/ffxi/FFXIWindow']=function()
    return {resignFocus=function(s) s.focused=false; resigns=resigns+1 end,hasFocus=function(s) return s.focused end}
end
local ConfigEditor=loadActual(path)
local prefs=require('cylibs/ui/menu/menu_preferences')
local values=require('cylibs/ui/menu/editor_values')
local settings={menu={save_on_exit=true,adjacent=true,ijkl=true}}
local saves, errors, savedNotice, changed, confirmed=0,{},0,0,0
prefs.configure({getSettings=function() return settings end},function() savedNotice=savedNotice+1 end)
addon_system_error=function(m) errors[#errors+1]=m end
addon_message=function() end
state={}
local function editor()
    local current={distance=4,enabled=false,choice='Blue'}
    local root={Default=current}
    local owner={getSettings=function() return root end,saveSettings=function() saves=saves+1; return true end}
    local items={
        {__type='slider_item',value=4,getCurrentValue=function(s) return s.value end},
        {__type='FFXIToggleButtonItem',value=false,getEnabled=function(s) return s.value end},
        {__type='picker_item',value='Blue',getCurrentValue=function(s) return s.value end},
    }
    local ci=L{}
    for i,key in ipairs({'distance','enabled','choice'}) do
        ci:append({__type=({'ConfigItem','BooleanConfigItem','PickerConfigItem'})[i],getKey=function() return key end})
    end
    local e=setmetatable({trustSettings=owner,configSettings=current,configItems=ci,valueForCellConfigItem={},
        validator=function() return true end,configChanged=event(),configConfirm=event(),configValidationError=event(),
        exitOwnerRoot=root,exitModeScope={},focused=true},ConfigEditor)
    e.getDataSource=function() return {numberOfSections=function() return 3 end,
        itemAtIndexPath=function(_,ip) return items[ip.section] end} end
    e.getDelegate=function() return {getCursorIndexPath=function() return nil end} end
    e.requestFocus=function(s) s.focused=true end
    e:onConfigChanged():addAction(function() changed=changed+1 end)
    e:onConfigConfirm():addAction(function() confirmed=confirmed+1 end)
    e.exitBaseline=e:readDraft()
    return e,items,current,owner,function(v) root=v end
end
local e,items,current,owner=editor()
check(e:commitOnExit() and saves==0 and confirmed==0,'unchanged exit neither saves nor confirms')
items[1].value=9; items[2].value=true; items[3].value='Green'
e:onConfigChanged():addAction(function() owner:saveSettings(true) end)
check(e:commitOnExit(),'changed scalar editor exits successfully')
check(current.distance==9 and current.enabled and current.choice=='Green','all options applied together')
check(saves==1 and changed==1 and confirmed==1 and savedNotice==1,'callback saves coalesced into one owner write')
check(e:commitOnExit() and saves==1,'repeated navigation does not write again')
items[1].value=10; e:resignFocus()
check(resigns==1 and saves==2 and not e.focused,'editor exit saves before resigning')
e,items,current=editor(); items[1].value=12; e.validator=function() return false,'bad draft' end
local before=saves
check(not e:commitOnExit() and current.distance==4 and saves==before,'invalid draft never mutates or writes')
e:resignFocus(); check(e.focused,'invalid draft retains editor focus')
check(e:onSelectMenuItemAtIndexPath({getText=function() return 'Save' end})==false,'manual validation failure propagates')
e,items,current,owner=editor(); items[1].value=15
local inherited=owner.saveSettings
owner.saveSettings=function() return false,'disk failure' end
local failure=owner.saveSettings
before=savedNotice
check(not e:commitOnExit(),'save failure blocks departure')
check(owner.saveSettings==failure and savedNotice==before,'save method restored, no saved notice after failure')
owner.saveSettings=inherited
check(e:commitOnExit() and savedNotice==before+1,'failed write remains dirty and can be retried')
items[1].value=16; e:onConfigChanged():addAction(function() error('callback failure') end)
check(not e:commitOnExit() and owner.saveSettings==inherited,'callback exception restores save method')
e,items=editor(); items[1].value=22; before=saves
settings.menu.save_on_exit=false
check(e:commitOnExit() and saves==before,'preference off preserves manual saving')
settings.menu.save_on_exit=true; e.openingChildPicker=true
check(e:commitOnExit() and saves==before,'opening nested picker does not save')
e.openingChildPicker=false; e:setSaveOnExit(false)
check(e:commitOnExit() and saves==before,'structural editor exclusion')
e:setSaveOnExit(true); e.trustSettings=nil
check(e:commitOnExit() and saves==before,'ownerless command form never runs on exit')
local modeWrites=0
e.exitOwnerRoot=nil
e:setSaveOnExit(true,function() modeWrites=modeWrites+1 end,function() return false end)
check(not e:commitOnExit() and modeWrites==0,'profile guard checked before mode writer')
e:setSaveOnExit(true,function() modeWrites=modeWrites+1 end,function() return true end)
check(e:commitOnExit() and modeWrites==1,'explicit ownerless mode/layout writer')
local replaceRoot
e,items,current,owner,replaceRoot=editor(); items[1].value=8; replaceRoot({Default={}})
check(not e:commitOnExit() and current.distance==4,'external settings reload cannot receive stale draft')
e,items=editor(); items[1].value=7; state.TrustMode={value='New'}; e.exitModeScope={TrustMode='Old'}
check(not e:commitOnExit(),'external profile switch cannot receive stale draft')
check(values.equal({x=false,y=0},{x=false,y=0}),'false and zero preserved')
check(not values.equal({x=false},{x=true}),'toggle changes detected')
local layout=require('cylibs/ui/menu/menu_layout')
for _,screen in ipairs({{960,540},{1280,720},{1600,900},{3840,2160}}) do
    for _,width in ipairs({220,350,600}) do
        local x,y,mx=layout.positions(screen[1],screen[2],width,300,true)
        check(x+width+8==mx and y==52,'adjacent gap at '..screen[1]..'/'..width)
        check(x>=8 and x+width<=screen[1]-8 and y+300<=screen[2]-8,'panel bounds at '..screen[1]..'/'..width)
    end
end
local x,y=layout.positions(3840,2160,350,300,false)
check(x==16 and y==48,'original placement restored')
-- Actual keyboard event callback, actual focus manager; mocked OS/hardware.
local callbacks={}
windower={ffxi={get_info=function() return {chat_open=false} end},
    register_event=function(n,f) callbacks[n]=f; return n end,unregister_event=function() end,send_command=function() end}
package.preload['settings/settings']=function() return {Shortcut={all=function() return L{} end}} end
package.preload['cylibs/events/value_relay']=function() return {new=function()
    local ev=event(); return {setValue=function() end,onValueChanged=function() return ev end} end} end
local Keyboard=loadActual('cylibs/ui/input/keyboard.lua')
local focus=require('cylibs/ui/focus/focus_manager').shared()
local received={}
local target={onKeyboardEvent=function(_,k,p,f,b) received[#received+1]={key=k,pressed=p,flags=f,blocked=b}; return false end}
focus.focusStack=L{target}
local keyboard=Keyboard.new()
Keyboard.input=function() return keyboard end
package.loaded['cylibs/ui/input/keyboard']=Keyboard
for _,pair in ipairs({{0x17,200},{0x24,203},{0x25,208},{0x26,205}}) do
    check(callbacks.keyboard(pair[1],true,0,false)==true and received[#received].key==pair[2],'IJKL down maps to arrow')
    check(callbacks.keyboard(pair[1],false,0,false)==true and not received[#received].pressed,'IJKL release consumed/routed')
end
callbacks.keyboard(0x24,true,1,false)
check(received[#received].key==203 and received[#received].flags==1,'Shift+J keeps fast picker modifier')
callbacks.keyboard(0x24,false,1,false)
target.acceptsTextInput=function() return true end; callbacks.keyboard(0x17,true,0,false)
check(received[#received].key==0x17,'I stays a letter in text input')
target.acceptsTextInput=nil; windower.ffxi.get_info=function() return {chat_open=true} end
callbacks.keyboard(0x26,true,0,false)
check(received[#received].key==0x26,'chat does not map L')
windower.ffxi.get_info=function() return {chat_open=false} end; callbacks.keyboard(0x17,true,4,false)
check(received[#received].key==0x17,'Ctrl+I not remapped')
settings.menu.ijkl=false; callbacks.keyboard(0x17,true,0,false)
check(received[#received].key==0x17,'IJKL off restores letters')
settings.menu.ijkl=true; focus.focusStack=L{}
check(not keyboard:directionKey(0x17,0,false),'no focus means no mapping')
focus.focusStack=L{target}
check(not keyboard:directionKey(0x17,0,true),'blocked input not mapped')
callbacks.keyboard(0x17,true,0,false); focus.focusStack=L{}
check(callbacks.keyboard(0x17,false,0,false)==true,'release consumed after close')
-- Actual complete-close guard, mocked view rendering.
package.preload['cylibs/events/dispose_bag']=function() return {new=function() return {add=function() end,addAny=function() end} end} end
package.preload['cylibs/sounds/sound_theme']=function() return {UI={Menu={Escape='escape',Cursor='cursor',Enter='enter'}}} end
package.preload['cylibs/ui/menu/menu_view']=function() return {} end
local Menu=loadActual('cylibs/ui/menu/menu.lua')
local closed=0
local currentView={commitOnExit=function() return false end,requestFocus=function() end}
local menu=setmetatable({contentViewStack={getCurrentView=function() return currentView end},
    menuItemStack=L{1},viewStack={dismissAll=function() closed=closed+1 end},
    menuView={destroy=function() end}},Menu)
check(not menu:closeAll() and closed==0 and menu.menuView~=nil,'invalid close stops before destruction')
check(menu:closeAll(true) and closed==1 and menu.menuView==nil,'discard can close blocked editor')
currentView=nil
check(menu:closeAll() and closed==2,'empty close remains idempotent')

-- Real menu selection callback: invalid drafts stop before action dispatch.
local menuViewClass=package.loaded['cylibs/ui/menu/menu_view']
local selected='Other'
local activation=event()
local root
local delegate={deselectAllItems=function() end,deselectItemAtIndexPath=function() end,
    didSelectItemAtIndexPath=function() return activation end,
    didMoveCursorToItemAtIndexPath=function() return event() end,
    getCursorIndexPath=function() return {row=1} end}
menuViewClass.new=function()
    return {getDelegate=function() return delegate end,getItem=function() return root end,
        setItem=function(_,v) root=v end,
        getDataSource=function() return {itemAtIndexPath=function() return {getTextItem=function()
            return {getText=function() return selected end} end} end} end,
        requestFocus=function() end,setHasFocus=function() end}
end
local actionCount, autoCount=0,0
local child={isEnabled=function() return true end,getTitleText=function() return 'Action' end,
    getDescriptionText=function() return '' end,getAction=function() return function() actionCount=actionCount+1 end end}
root={getChildMenuItem=function() return child end,getTitleText=function() return 'Root' end,getDescriptionText=function() return '' end}
local activeEditor={commitOnExit=function() autoCount=autoCount+1; return false end,requestFocus=function() end,
    onSelectMenuItemAtIndexPath=function() return false end}
local stack={view=nil,onStackSizeChanged=function() return event() end,onEmpty=function() return event() end,
    getCurrentView=function(s) return s.view end,isEmpty=function(s) return s.view==nil end,
    present=function(s,v) s.view=v end}
local info={setVisible=function() end,layoutIfNeeded=function() end,setTitle=function() end,setDescription=function() end}
local media={playSound=function() end}
local theme={getSoundForAction=function() return '' end}
focus.focusStack=L{}
local dispatchMenu=Menu.new({getCurrentView=function() return activeEditor end},stack,info,media,theme)
dispatchMenu:showMenu(root)
activation:trigger({})
check(actionCount==0 and autoCount==1,'mouse menu action blocked by invalid pending draft')
selected='Save'; activation:trigger({})
check(actionCount==0 and autoCount==1,'invalid manual Save prevents its child action')
selected='Reset'; activeEditor.onSelectMenuItemAtIndexPath=function() end
activation:trigger({})
check(autoCount==1 and actionCount==1,'Reset is explicit and does not save draft first')
selected='Other'; activeEditor.commitOnExit=function() autoCount=autoCount+1; return true end
activation:trigger({})
check(actionCount==2 and autoCount==2,'valid mouse departure saves before action')
activeEditor.commitOnExit=function() error('must not save while entering retained child') end
local retained={keepViews=true}
dispatchMenu.menuView.getDelegate=function() return delegate end
-- Avoid invoking rendering-only metadata in this focused branch test.
dispatchMenu.onMoveCursorToIndexPath=function() end
dispatchMenu:showMenu(retained)
check(root==retained,'retained nested child opens without editor commit')
check(values.equal(setmetatable({x=1},{__class='Table'}),setmetatable({x=1},{__class='Table'})),'Windower Table values compare without duplicate saves')

-- Exercise the actual Modes menu adapter: selected set and live-mode conflicts.
package.loaded['ui/settings/editors/config/ConfigEditor']=ConfigEditor
package.preload['cylibs/ui/collection_view/items/button_item']=function()
    return {localized=function() return {setEnabled=function() end} end,default=function() return {} end}
end
package.preload['cylibs/ui/menu/menu_item']=function()
    return {new=function(buttons,children,constructor)
        return {children=children,contentViewConstructor=constructor}
    end,setChildMenuItem=function(s,k,v) s.children[k]=v end,
    action=function(f) return {callback=f} end}
end
local modeView={changed=event(),setShouldRequestFocus=function() end,
    setSaveOnExit=ConfigEditor.setSaveOnExit,onConfigChanged=function(s) return s.changed end,
    getDelegate=function() return {didMoveCursorToItemAtIndexPath=function() return event() end} end}
package.preload['ui/settings/editors/config/ModeConfigEditor']=function() return {new=function() return modeView end} end
package.preload['ui/settings/menus/ShortcutMenuItem']=function() return {} end
i18n={translate=function(x) return x end}
state.TrustMode={value='Original'}; state.AutoFollowMode={value='Always'}
local writtenSet
local Modes=loadActual('ui/settings/menus/ModesMenuItem.lua')
local modes=Modes.new({saveSettings=function(_,setName) writtenSet=setName end},'',L{'AutoFollowMode'})
modes.contentViewConstructor()
check(modeView.exitGuard({autofollowmode='Off'}),'ordinary mode edit allowed')
state.AutoFollowMode.value='Off'; modeView.changed:trigger()
check(modeView.exitGuard({autofollowmode='Always'}),'second edit recognizes prior own commit')
state.AutoFollowMode.value='External'
check(not modeView.exitGuard({autofollowmode='Always'}),'external live mode update cannot be overwritten')
state.AutoFollowMode.value='Off'; modeView.exitWriter()
check(writtenSet=='Original','mode adapter saves original selected set')
state.TrustMode.value='Other'
check(not modeView.exitGuard({autofollowmode='Off'}),'profile switch blocks mode persistence')
state.TrustMode.value='Original'
check(not modeView.exitGuard({autofollowmode='Off',trustmode='Other'}),'profile selector itself stays an explicit action')

-- Actual TrustSettings coroutine error propagation, no real disk access.
e,items,current=editor(); e.exitSourceValues=values.copy(current)
items[1].value=8; current.distance=99
check(not e:commitOnExit() and current.distance==99,'same-table external change is preserved')
e,items,current=editor()
e.configItems[3].__type='TextInputConfigItem'
items[3].__type='text_field_item'
items[3].getTextItem=function(s) return {getText=function() return s.value end} end
items[3].isValid=function(_,text) return text~='' end
e.exitBaseline=e:readDraft(); items[2].value=true; items[3].value='ijkl typed'
check(e:commitOnExit() and current.choice=='ijkl typed' and current.enabled,'mixed options and text save final valid values')
items[3].value=''
check(not e:commitOnExit() and current.choice=='ijkl typed','invalid text blocks mixed-editor commit')
package.preload.files=function() return {} end
package.preload.logger=function() return {} end
package.preload['cylibs/util/serializer_util']=function() return {} end
local TrustSettings=loadActual('TrustSettings.lua')
local notifications=0
local persisted=setmetatable({settingsFolder='data/',jobNameShort='WHM',playerName='Test',settings={},
    settingsChanged={trigger=function() notifications=notifications+1 end}},TrustSettings)
persisted.saveToFile=function() return coroutine.create(function() error('disk unavailable') end) end
local ok,err=persisted:saveSettings(true)
check(ok==false and err:find('disk unavailable') and notifications==0,'coroutine file failure returned without false success notification')
persisted.saveToFile=function() return coroutine.create(function() coroutine.yield() end) end
check(persisted:saveSettings(true) and notifications==1,'successful owner save notifies once')
print('PASS: '..checks..' menu/save/layout/input assertions (mocked UI and I/O)')



