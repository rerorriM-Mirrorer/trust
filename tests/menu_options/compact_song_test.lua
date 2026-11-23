-- A: BRD song note + re-sing timer in the compact Trust widget.
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function method(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true),first);local b=assert(s:find(last,a+1,true),last)
 assert(load(s:sub(a,b-1),'production','t',env))()
end
local pass=0
local function ok(c,m) assert(c,m); pass=pass+1 end
local Song=dofile('ui/widgets/CompactSongTimer.lua')
-- Format like the game's status icons.
ok(Song.format(nil)=='','no songs: no text')
ok(Song.format(59)=='59s' and Song.format(59.9)=='59s' and Song.format(0.4)=='0s','seconds under a minute')
ok(Song.format(-5)=='0s','past the re-sing point shows 0s')
ok(Song.format(60)=='1m' and Song.format(119)=='1m' and Song.format(120)=='2m' and Song.format(899)=='14m','whole minutes, rounded down')
ok(Song.remaining({},20,100)==nil,'no songs')
ok(Song.remaining({500,300,400},20,100)==180,'soonest expiry minus expiring_duration')

-- Widget row.
local Widget={}
local clock=0
local function item(text) return {text=text,setShouldWordWrap=function()end} end
local env=setmetatable({TrustStatusWidget=Widget,CompactSongTimer=Song,os={clock=function() return clock end},
 TextItem={new=function(t) return item(t) end}},{__index=_G})
method('ui/widgets/TrustStatusWidget.lua','function TrustStatusWidget:placeCompactSong()','function TrustStatusWidget:setExpanded',env)
local function view()return{setNeedsLayout=function()end,layoutIfNeeded=function()end,setVisible=function(s,v)s.visible=v end,
 setPosition=function(s,x,y)s.x,s.y=x,y end,setSize=function(s,w,h)s.w,s.h=w,h end,setItem=function(s,i)s.item=i end}end
local w=setmetatable({compactMode=true,compactSongIcon=view(),compactSongCell=view()},{__index=Widget})
w:placeCompactSong(); ok(w.compactSongIcon.x==4 and w.compactSongIcon.y==13 and w.compactSongCell.x==15,'row placed under the count')
w:refreshCompactSong(true); ok(not w.compactSongIcon.visible and not w.compactSongCell.visible,'no source (not BRD): hidden')
local singing,rem=false,nil
w:setCompactSongSource(function() return singing,rem end)
ok(w.compactSongIcon.visible and w.compactSongIcon.alpha==110 and not w.compactSongCell.visible,'BRD, no songs: dim note only')
singing,rem=true,185; clock=1; w:refreshCompactSong()
ok(w.compactSongIcon.alpha==255 and w.compactSongCell.visible and w.compactSongCell.item.text=='3m','singing, 3m')
rem=45; clock=1.2; w:refreshCompactSong(); ok(w.compactSongCell.item.text=='3m','polled at most every 0.5 s')
clock=1.6; w:refreshCompactSong(); ok(w.compactSongCell.item.text=='45s','under a minute counts seconds')
w:setCompactSongSource(function() return nil end); ok(not w.compactSongIcon.visible,'source returning nil (job changed) hides')
w:setCompactSongSource(function() error('boom') end); ok(not w.compactSongIcon.visible,'source error hides, no crash')
w.compactMode=false; w:setCompactSongSource(function() return true,30 end); ok(not w.compactSongIcon.visible,'full mode: hidden')

-- BRD factory: default hides the Bard widget and feeds the host.
local host={}; function host.setCompactSongSource(_,fn) host.fn=fn end
local class={}
local benv=setmetatable({BardTrust=class,addon_settings={getSettings=function()return{widgets={hide_pet=true}}end},
 require=function(n) if n=='ui/widgets/CompactSongTimer' then return Song end error('must not build BardWidget: '..n) end,
 windower={trust={ui={get_widget=function(n) return n=='trust' and host or nil end}},ffxi={get_player=function() return {main_job='BRD'} end}},
 player={party={get_player=function() return {get_songs=function() return {it=function() local i=0 local t={{get_expire_time=function() return os.time()+200 end}}
   return function() i=i+1 return t[i] end end} end} end}},
 os=os},{__index=_G})
do local src=source('cylibs/trust/data/BRD.lua');local a=assert(src:find('function BardTrust'..string.char(58)..'get_widget()',1,true))
 local b=assert(src:find('    local BardWidget',a,true));assert(load(src:sub(a,b-1)..'end','brd','t',benv))() end
local singer={song_tracker={expiring_duration=20},get_is_singing=function() return true end}
local trust=setmetatable({role_with_type=function() return singer end},{__index=class})
ok(class.get_widget(trust)==nil and host.fn,'hide_bard default: no Bard widget, host gets source')
local s1,r1=host.fn(); ok(s1==true and r1>=179 and r1<=180,'source: singing, ~180 s to re-sing')
benv.windower.ffxi.get_player=function() return {main_job='WHM'} end; ok(host.fn()==nil,'not BRD main: nil')
ok(source('settings/TrustAddonSettings.lua'):find('hide_bard=true',1,true),'default hide_bard=true')
print('PASS compact_song_test '..pass)
