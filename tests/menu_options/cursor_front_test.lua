-- The menu cursor is re-created whenever it appears so it draws above menus rebuilt later.
L=function(t)local l=t or {};l.length=function(self)return #self end;l.it=function(self)local i=0;return function()i=i+1;return self[i]end end;l.append=function(self,v)self[#self+1]=v end;return l end
local created,destroyed={},{}
local Image={new=function()local img={n=#created+1,path_='',visible_=false};created[#created+1]=img
  function img:fit()end;function img:hide()self.visible_=false end;function img:draggable()end
  function img:destroy()destroyed[self.n]=true end;return img end}
package.loaded['images']=Image
package.loaded['cylibs/util/images/image_loader']={}
package.loaded['cylibs/ui/views/render']={shared=function()return{onPrerender=function()return{addAction=function()end}end}end}
local f=assert(io.open('cylibs/ui/image_view.lua'));local src=f:read('*a');f:close()
local bag={destroyables=L{}}
function bag:add()end
function bag:addAny(list)for _,d in ipairs(list)do self.destroyables:append(d)end end
local View={new=function()local v={};function v:getDisposeBag()return bag end;function v:setNeedsLayout()self.dirty=true end;return v end}
package.loaded['cylibs/ui/views/view']=View
local env=setmetatable({require=function(n)return package.loaded[n] or require(n)end,L=L},{__index=_G})
local ImageView=assert(load(src,'image_view','t',env))()
local v=ImageView.new(1,1,255)
local first=v.image;v.imagePath='cursor.png'
v:bringToFront()
assert(v.image~=first and v.image.n>first.n,'new image is newer, so it draws on top')
assert(destroyed[first.n]==true,'old image destroyed')
assert(bag.destroyables[1]==v.image,'disposal list now owns the new image, not the old one')
assert(v.imagePath==nil and v.dirty,'path reloads onto the new image at next layout')
-- A second image view replaces its own entry and leaves the first view's alone.
local v2=ImageView.new(1,1,255);local keep=v.image;v2:bringToFront();assert(bag.destroyables[1]==keep)

-- CollectionView re-creates the cursor only on the transition from hidden to shown.
local cf=assert(io.open('cylibs/ui/collection_view/collection_view.lua'));local csrc=cf:read('*a');cf:close()
local body=assert(csrc:match('(function CollectionView:moveCursorToIndexPath.-\nend)\n'))
local fronts=0
local CV={};local cenv=setmetatable({CollectionView=CV},{__index=_G})
assert(load(body,'moveCursor','t',cenv))()
local focused=true
local cv=setmetatable({cursorImageItem={getSize=function()return{width=37,height=24}end,offsetX=0,offsetY=0},
  selectionBackground={setPosition=function()end,setSize=function()end,setVisible=function(_,v)end,setNeedsLayout=function()end,layoutIfNeeded=function()end,bringToFront=function()fronts=fronts+1 end},
  getDelegate=function()return{getCursorIndexPath=function()return{1,1}end}end,
  getDataSource=function()return{itemAtIndexPath=function()return{}end,cellForItemAtIndexPath=function()return{getPosition=function()return{x=10,y=10}end,getSize=function()return{width=50,height=16}end}end}end,
  hasFocus=function()return focused end,isCursorEnabled=function()return true end},{__index=CV})
cv:moveCursorToIndexPath();assert(fronts==1,'appearing brings the cursor to the front')
cv:moveCursorToIndexPath();cv:moveCursorToIndexPath();assert(fronts==1,'staying visible does not recreate it every frame')
focused=false;cv:moveCursorToIndexPath();focused=true;cv:moveCursorToIndexPath();assert(fronts==2,'each reappearance brings it to the front again')
print('PASS cursor image is re-created on top each time it appears, once per appearance')
