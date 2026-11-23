-- A: compact Trust widget states (Stop/Pause/Act/Start), cross-fade, pulses,
-- preview path, and the widget left|right|look|fade commands.
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function method(path,first,last,env)
 local s=source(path);local a=assert(s:find(first,1,true),first);local b=assert(s:find(last,a+1,true),last)
 assert(load(s:sub(a,b-1),'production','t',env))()
end
local pass=0
local function ok(c,m) assert(c,m); pass=pass+1 end
local Look=dofile('ui/widgets/CompactTrustLook.lua')
local T=Look.tunables

-- Mapping from Trust's control_state.
ok(Look.name_for('Parked',false)=='stop','Parked=stop')
ok(Look.name_for('Paused',false)=='pause','Paused=pause')
ok(Look.name_for('Retreat',false)=='pause','Retreat looks like pause')
ok(Look.name_for('Act',true)=='act' and Look.name_for('Active',true)=='start','act/start')
ok(Look.name_for(nil,true)=='start' and Look.name_for(nil,false)=='pause','fallback on enabled')

-- Targets per state.
local t,p=Look.targets('stop',false); ok(t.hourglass==1 and t.red==1 and t.crystal==0 and t.green==0 and not p.hourglass,'stop: steady hourglass + red')
t,p=Look.targets('stop',true); ok(t.green==0,'no halo while stopped even if an action string lingers')
t,p=Look.targets('pause',false); ok(t.hourglass==1 and t.red==0 and p.hourglass and not p.crystal,'pause: pulsing hourglass, no tint')
t,p=Look.targets('act',false); ok(t.crystal==1 and t.hourglass==0 and p.crystal and t.green==0,'act idle: pulsing crystal')
t,p=Look.targets('act',true); ok(t.green==1,'act acting: halo')
t,p=Look.targets('start',true); ok(t.crystal==1 and not p.crystal and t.green==1,'start: steady crystal + halo')

-- Cross-fade: 0.25 s total, linear; 0 = instant.
local cur={hourglass=1,crystal=0}
Look.step(cur,{hourglass=0,crystal=1},0.1,0.25); ok(math.abs(cur.hourglass-0.6)<1e-9 and math.abs(cur.crystal-0.4)<1e-9,'partial fade')
Look.step(cur,{hourglass=0,crystal=1},0.5,0.25); ok(cur.hourglass==0 and cur.crystal==1,'fade clamps at target')
cur={red=1}; Look.step(cur,{red=0},0.001,0); ok(cur.red==0,'fade 0 is instant')
cur={}; Look.step(cur,{red=1},0.05,0.25); ok(cur.red==1,'first frame starts at target (no fade-in on load)')

-- Pulse: floor at start, full at half period.
ok(math.abs(Look.pulse(0,2.4,0.11)-0.11)<1e-9 and math.abs(Look.pulse(1.2,2.4,0.11)-1)<1e-9,'pulse floor..full')
local a=Look.alphas({hourglass=1},{hourglass=true},0,T); ok(a.hourglass==math.floor(220*0.11+0.5) and a.book==230,'pause hourglass starts dim')
a=Look.alphas({hourglass=1,red=1},{},0,T); ok(a.hourglass==220 and a.red==70,'stop alphas')

-- Widget wiring, with stand-ins for views and timer.
local Widget={refreshCompactSong=function() end} -- song row tested in compact_song_test
local env=setmetatable({TrustStatusWidget=Widget,CompactTrustLook=Look,windower={addon_path='addon/'},
 Color={clear={clear=true},new=function(...)return{...}end}},{__index=_G})
method('ui/widgets/TrustStatusWidget.lua','function TrustStatusWidget:isCompactActing()','function TrustStatusWidget:setCompactPartyCount',env)
local function view()return{layouts=0,setNeedsLayout=function()end,layoutIfNeeded=function(s)s.layouts=s.layouts+1 end,
 setVisible=function(s,v)s.visible=v end,setBackgroundColor=function(s,c)s.color=c end}end
local timer={running=false,isRunning=function(s)return s.running end,start=function(s)s.running=true end,cancel=function(s)s.running=false end}
local enabled=false
local queue={control_state='Parked'}
local w=setmetatable({compactMode=true,currentAction='Idle',addonEnabled={getValue=function()return enabled end},actionQueue=queue,compactLayers={},
 compactIcon=view(),compactHourglass=view(),compactGlowOuter=view(),compactGlowInner=view(),compactTint=view(),compactCrystal=view(),compactPulseTimer=timer},{__index=Widget})
local clock=100; env.os={clock=function() return clock end}
w:refreshCompactIcon()
ok(timer.running and w.compactHourglass.alpha==220 and w.compactTint.color[1]==70 and w.compactTint.color[2]==170,'stop drawn')
ok(not w.compactCrystal.visible and w.compactGlowOuter.color.clear,'stop: no crystal, no halo')
local before=w.compactTint.layouts; clock=clock+0.05; w:tickCompactLook(); ok(w.compactTint.layouts==before,'unchanged frame does not relayout')
queue.control_state='Paused'; clock=clock+0.1; w:tickCompactLook()
ok(w.compactTint.color[1]>0 and w.compactTint.color[1]<70,'red tint fades out, not instant')
clock=clock+0.3; w:tickCompactLook(); ok(w.compactTint.color.clear,'red gone after the fade')
local h1=w.compactHourglass.alpha; clock=clock+1.2; w:tickCompactLook(); ok(w.compactHourglass.alpha~=h1,'pause hourglass pulses')
enabled=true; queue.control_state='Act'; clock=clock+1; w:tickCompactLook()
ok(not w.compactHourglass.visible and w.compactCrystal.visible and w.compactGlowOuter.color.clear,'act idle: crystal, no hourglass, no halo')
w.currentAction='Cure'; clock=clock+1; w:tickCompactLook(); ok(w.compactGlowOuter.color[1]==18 and w.compactGlowInner.color[1]==24,'act acting: halo')
local c1=w.compactCrystal.alpha; clock=clock+0.6; w:tickCompactLook(); ok(w.compactCrystal.alpha~=c1,'act crystal pulses')
queue.control_state='Active'; clock=clock+1; w:tickCompactLook(); local c2=w.compactCrystal.alpha
clock=clock+0.6; w:tickCompactLook(); ok(c2==220 and w.compactCrystal.alpha==220,'start crystal steady')
-- Preview path (E4b): wins over live state; off returns to live.
w:setCompactLookPreview('stop',false); clock=clock+1; w:tickCompactLook()
ok(w:getCompactState()=='stop' and w.compactHourglass.alpha==220 and w.compactGlowOuter.color.clear,'preview stop overrides live acting')
w:setCompactLookPreview('start',true); clock=clock+1; w:tickCompactLook(); ok(w.compactGlowOuter.color[1]==18,'preview start acting')
w:setCompactLookPreview(nil); ok(w:getCompactState()=='start','preview off = live')

-- Commands.
local cmds={}
local ui={widgets={trust=w}}
local arranged
local cenv=setmetatable({GeneralTrustCommands=cmds,S=function(t) local s={} for _,v in ipairs(t) do s[v]=true end
  return {contains=function(_,v) return s[v] or false end} end,
 require=function(name)
  if name=='ui/widgets/CompactTrustLook' then return Look end
  if name=='ui/WidgetLayout' then return {arrange=function(a) arranged=a; return true end} end
  return require(name) end,
 windower={trust={ui={get_widget=function(n) return ui.widgets[n] end}}}},{__index=_G})
method('commands/GeneralCommands.lua','function GeneralTrustCommands:handle_widget(','-- // trust autohide [on|off|engaged|<seconds>]',cenv)
local r,msg=cmds.handle_widget(cmds,'widget','left'); ok(r and arranged=='Left' and msg=='Widgets aligned left','widget left')
r=cmds.handle_widget(cmds,'widget','RIGHT'); ok(r and arranged=='Right','widget right (case)')
r=cmds.handle_widget(cmds,'widget','align','left'); ok(r and arranged=='Left','widget align left')
r=cmds.handle_widget(cmds,'widget','align','up'); ok(r==false,'bad align refused')
r=cmds.handle_widget(cmds,'widget','fade','0'); ok(r and T.fade==0,'fade 0')
r=cmds.handle_widget(cmds,'widget','fade','400'); ok(r and math.abs(T.fade-0.4)<1e-9,'fade 400 ms')
r=cmds.handle_widget(cmds,'widget','fade','x'); ok(r==false,'bad fade refused')
r=cmds.handle_widget(cmds,'widget','look','pause'); ok(r and w.compactLookPreview.name=='pause','look pause')
r=cmds.handle_widget(cmds,'widget','look','act','acting'); ok(r and w.compactLookPreview.acting,'look act acting')
r=cmds.handle_widget(cmds,'widget','look','nope'); ok(r==false,'bad look refused')
r,msg=cmds.handle_widget(cmds,'widget','look','off'); ok(r and w.compactLookPreview==nil and msg:find('live',1,true),'look off')
for _,m in ipairs({msg}) do ok(not m:find('[\128-\255]'),'ASCII chat') end
-- Menu uses the shared layout helper; helper keeps the old 16 px margin and 5 px gap.
ok(source('ui/settings/menus/widgets/WidgetSettingsMenuItem.lua'):find("require('ui/WidgetLayout').arrange(newSettings.Alignment)",1,true),'menu uses WidgetLayout')
local L_=source('ui/WidgetLayout.lua'); ok(L_:find('margin = 16',1,true) and L_:find('gap = 5',1,true),'layout constants unchanged')
print('PASS widget_states_test '..pass)
