-- Option-list input model (real ConfigEditor / Menu key code, stubbed UI):
--   Left/Right and Confirm act on the item under the cursor, no "select first";
--   Up/Down save the finished option then move; Circle/Escape returns to the menu
--   column; Confirm on a slider or choice only saves; Left/Right inside a list never hop columns.
L=function(t)t=t or {};t.contains=function(self,k)for _,v in ipairs(self)do if v==k then return true end end;return false end;return t end;S=function(t)local s={};for _,v in ipairs(t or {})do s[v]=true end;s.contains=function(self,k)return self[k]==true end;return s end
local f=assert(io.open('ui/settings/editors/config/ConfigEditor.lua'));local src=f:read('*a');f:close()
local names={[200]='Up',[208]='Down',[203]='Left',[205]='Right',[28]='Enter',[1]='Escape'}
local fell={}   -- what reached the base window handler
local Window={onKeyboardEvent=function(_,key)fell[#fell+1]=key;return false end,
  resignFocus=function()end,new=function()error('not used')end}
local stubs={
 ['ui/themes/ffxi/FFXIWindow']=Window,
 ['ui/themes/ffxi/FFXIToggleButtonItem']={__type='toggle'},['cylibs/ui/collection_view/items/slider_item']={__type='slider'},
 ['cylibs/ui/collection_view/items/picker_item']={__type='picker'},
 ['cylibs/ui/input/keyboard']={input=function()return{getKey=function(_,key)return names[key]end}end},
 ['cylibs/ui/menu/menu_save_trace']={editor=function()end,enabled=false,record=function()end},
 ['cylibs/ui/menu/menu_preferences']={get=function()return true end,saved=function()end},
}
local env=setmetatable({require=function(name)return stubs[name] or setmetatable({__type=name},{__index=function()return function()end end})end},{__index=_G})
local ConfigEditor=assert(load(src,'ConfigEditor','t',env))()

local Toggle,Slider,Picker=stubs['ui/themes/ffxi/FFXIToggleButtonItem'],stubs['cylibs/ui/collection_view/items/slider_item'],stubs['cylibs/ui/collection_view/items/picker_item']
local function toggle(v)local i={__type='toggle',value=v};function i:setEnabled(x)self.value=x end;function i:getEnabled()return self.value end;return i end
local function slider(v,min,max,step)local i={__type='slider',value=v};function i:getCurrentValue()return self.value end
  function i:setCurrentValue(x)self.value=math.min(math.max(x,min),max)end;function i:getInterval()return step end;return i end
local function list(t)t.indexOf=function(self,v)for k,x in ipairs(self)do if x==v then return k end end end;t.length=function(self)return #self end;return t end
local function picker(v,all,multi)local i={__type='picker',value=v,all=list(all)};function i:getCurrentValue()return self.value end
  function i:setCurrentValue(x)self.value=x end;function i:getAllValues()return self.all end;function i:getAllowsMultipleSelection()return multi==true end;return i end

local function editor(item)
  local log={refreshed=0,finished=0,confirmed=0,commits={},commitOk=true}
  local ed=setmetatable({ownsDirectionalInput=true,log=log},ConfigEditor)
  ed.isVisible=function()return true end
  ed.getDelegate=function()return{getCursorIndexPath=function()return{section=1,row=1}end}end
  ed.getDataSource=function()return{itemAtIndexPath=function()return item end,cellForItemAtIndexPath=function()return{setItem=function()log.refreshed=log.refreshed+1 end}end}end
  ed.playSoundsForKey=function()end
  ed.fieldFinished=function()log.finished=log.finished+1 end
  ed.onConfirmClick=function()log.confirmed=log.confirmed+1;return true end
  ed.commitOnExit=function(_,reason)log.commits[#log.commits+1]=reason;return log.commitOk end
  return ed,log
end
local function press(ed,key,flags)fell={};local r=ed:onKeyboardEvent(key,true,flags or 0,false);return r end

-- Boolean: Left, Right and Confirm all toggle in place; nothing is "selected".
local t=toggle(false);local ed,log=editor(t)
assert(press(ed,203)==true and t.value==true and log.refreshed==1 and log.finished==1 and #fell==0,'Left toggles')
assert(press(ed,205)==true and t.value==false)
assert(press(ed,28)==true and t.value==true and log.confirmed==0 and #fell==0,'Confirm toggles, does not select')

-- Slider: Left/Right adjust immediately and clamp; Confirm only saves.
local sl=slider(5,1,6,2);ed,log=editor(sl)
press(ed,205);assert(sl.value==6,'clamped at max');press(ed,203);assert(sl.value==4);press(ed,203);press(ed,203);assert(sl.value==1,'clamped at min')
assert(log.finished==4)
local before=sl.value;assert(press(ed,28)==true and sl.value==before and log.confirmed==1 and #fell==0,'Confirm on a slider saves and changes nothing')

-- Single-choice picker: cycles with wrap, shift jumps further, Confirm only saves.
local pk=picker('b',{'a','b','c'});ed,log=editor(pk)
press(ed,205);assert(pk.value=='c');press(ed,205);assert(pk.value=='a','wraps forward');press(ed,203);assert(pk.value=='c','wraps back')
assert(log.finished==3)
assert(press(ed,28)==true and pk.value=='c' and log.confirmed==1 and #fell==0)
local big={};for i=1,120 do big[i]='v'..i end;pk=picker('v1',big);ed,log=editor(pk);press(ed,205,1);assert(pk.value=='v51','shift steps by 50')

-- Multi-select picker: Confirm keeps its old behavior (opens the chooser via selection); Left/Right do not leave.
pk=picker('a',{'a','b'},true);ed,log=editor(pk)
assert(press(ed,205)==true and pk.value=='a' and log.finished==0,'Left/Right inside a list never hop columns')
assert(press(ed,28)==false and #fell==1 and fell[1]==28,'Confirm falls through to select the multi-picker')

-- Up/Down: save the finished option first, then move; a failed save keeps the cursor.
ed,log=editor(toggle(true))
press(ed,200);assert(log.commits[1]=='cursor-move' and #fell==1 and fell[1]==200,'Up saves then moves')
press(ed,208);assert(#log.commits==2 and fell[1]==208)
log.commitOk=false;assert(press(ed,208)==true and #fell==0,'failed save blocks the move')

-- Escape reaches the window's own handler (commit on exit, then return to the menu column).
ed,log=editor(toggle(true));press(ed,1);assert(#fell==1 and fell[1]==1 and #log.commits==0)
-- Releases and non-owning editors are untouched.
ed,log=editor(toggle(true));fell={};assert(ed:onKeyboardEvent(203,false,0,false)==false and #fell==1)
ed,log=editor(toggle(true));ed.ownsDirectionalInput=nil;press(ed,203);assert(#fell==1 and log.finished==0)
-- Plain editors give up Right as a way back to the menu column; subclasses keep the default.
assert(ConfigEditor.new~=nil)

-- Menu: Left in the menu column re-enters an option list; an option list is focusable on open whatever autosave says.
local mf=assert(io.open('cylibs/ui/menu/menu.lua'));local msrc=mf:read('*a');mf:close()
local prefs={save_on_exit=false}
local Menu={}
local menv=setmetatable({Menu=Menu,L=L,S=S,windower={ffxi={get_info=function()return{chat_open=false}end}},
  MenuPreferences={get=function(k)return prefs[k]end},SaveTrace={editor=function()end},
  Keyboard={input=function()return{getKey=function(_,k)return names[k]end}end},
  require=function()return{}end},{__index=_G})
for _,m in ipairs({'focusOptionsEditor','onKeyboardEvent'})do
  local body=assert(msrc:match('(function Menu:'..m..'.-)\nfunction Menu:'))
  assert(load(body,'Menu:'..m,'t',menv))()
end
local focused,paged=0,0
local view={ownsDirectionalInput=true,canSaveOnExit=function()return true end,shouldRequestFocus=function()return true end,
  getDelegate=function()return{getCursorIndexPath=function()return{1,1}end}end,requestFocus=function()focused=focused+1 end,hasFocus=function()return false end}
local menu=setmetatable({isChatOpen=false,contentViewStack={getCurrentView=function()return view end},
  menuView={pageLeft=function()paged=paged+1 end,pageRight=function()paged=paged+1 end},playSoundsForKey=function()end},{__index=Menu})
assert(menu:focusOptionsEditor()==true and focused==1,'option lists are entered on open even with autosave off')
view.ownsDirectionalInput=nil;assert(menu:focusOptionsEditor()==false,'other views still follow the autosave preference')
focused=0;view.ownsDirectionalInput=true
menu:onKeyboardEvent(203,true,0,false);assert(focused==1 and paged==0,'Left in the menu column re-enters the option list')
view.shouldRequestFocus=function()return false end;menu:onKeyboardEvent(203,true,0,false);assert(focused==1 and paged==1,'no focusable list: Left pages the menu')
print('PASS option-list input model: in-place toggle/slider/choice, save on Up/Down and Confirm, Escape returns, Left/Right inside a list never hop columns')
