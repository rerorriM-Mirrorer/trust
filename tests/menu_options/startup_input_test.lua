-- Real mouse router with minimal queue/event mocks; no game or UI required.
package.loaded['cylibs/events/Luvent']={}
local Mouse=require('cylibs/ui/input/mouse')
local mouse=setmetatable({},Mouse)
hud=nil;command_widget=nil
assert(mouse:handleMouseEvent(0,1,1,0)==false)
hud={};assert(mouse:handleMouseEvent(0,1,1,0)==false)
local hits=0
local function view()
    return {hitTest=function()hits=hits+1;return false end}
end
hud=view();hud.trustMenu={};hud.viewStack={}
function Q(items)
    return setmetatable(items,{__index={
        push=function(self,v)assert(v~=nil);self[#self+1]=v end,
        pop=function(self)local v=self[#self];self[#self]=nil;return v end,
        empty=function(self)return #self==0 end}})
end
assert(mouse:handleMouseEvent(0,1,1,0)==false and hits==1)
hud.trustMenu.menuView=view();hud.viewStack.currentView=view();command_widget=view()
assert(mouse:handleMouseEvent(0,1,1,0)==false and hits==5)
-- Defaults registration must work without the include's global assignment.
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
assert(root:find("require('commands/DefaultsCommands').new",1,true))
print('PASS startup input and explicit defaults registration')
