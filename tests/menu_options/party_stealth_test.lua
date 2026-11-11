-- Production coordinator/receiver and Control, with a simulated IPC bus, queues,
-- spell/ability/item adapters and delayed server buffs. This is not an FFXI test.
local Planner=require('cylibs/trust/stealth/planner')
local Control=require('cylibs/trust/control_state')
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function list(t)return setmetatable(t,{__index={it=function(self)local i=0;return function()i=i+1;return self[i]end end}})end
local function scenario(config)
 local now,bus,clients,log,pendingbuffs=100,{}, {}, {}, {}
 local recasts={}
 local names={};for name in pairs(config)do names[#names+1]=name end;table.sort(names)
 local spells={Sneak={id=1,mp_cost=12},Invisible={id=2,mp_cost=15},['Monomi: Ichi']={id=3,mp_cost=0},['Tonko: Ni']={id=4,mp_cost=0},['Tonko: Ichi']={id=5,mp_cost=0}}
 for name,spell in pairs(spells)do spell.en=name end
 local resources={with=function(_,_,name)return spells[name]end};for _,v in pairs(spells)do resources[v.id]=v end
 local function buffs(name)
  local r={};for id,on in pairs(config[name].buffs or {})do if on then r[#r+1]=id end end;return r
 end
 local function mob(name)
  local c=config[name];return {name=name,id=c.id,index=c.id,x=c.x or 0,y=0,z=0,distance=(c.x or 0)^2,hpp=100}
 end
 local members={}
 for i,name in ipairs(names)do
  local c=config[name];c.id=i;c.buffs=c.buffs or {};c.items=c.items or {};c.spells=c.spells or {}
  members[#members+1]={get_name=function()return name end,get_mob=function()return mob(name)end,
   get_buff_ids=function()return buffs(name)end,get_zone_id=function()return 1 end}
 end
 local party={get_party_members=function()return list(members)end,get_party_member_named=function(_,name)
  for _,m in ipairs(members)do if m:get_name()==name then return m end end
 end}
 for _,name in ipairs(names)do
  local c=config[name]
  if c.client~=false then
   local state={IpcMode={value='All'}}
   local p={name=name,id=c.id,index=c.id,status=c.status or 0,vitals={mp=200},main_job_id=c.nin and 13 or 1}
   local follower={manual_pause=c.manual or false,start_following=function()end,stop_following=function()end}
   local main={control_state=c.paused and 'Paused' or 'Active'}
   local enabled={value=not c.paused,getValue=function(self)return self.value end,setValue=function(self,value)self.value=value end}
   local trust={get_party=function()return party end,role_with_type=function()return follower end}
   local events={};local queues={}
   local function adapter(kind,method)
    return {to_action=function(_,index)return {kind=kind,method=method,index=index}end}
   end
   local deps={
    ['cylibs/trust/stealth/planner']=Planner,['cylibs/trust/control_state']=Control,
    ['cylibs/util/timers/timer']={scheduledTimer=function()return {onTimeChange=function()return {addAction=function()end}end,start=function()end,destroy=function()end}end},
    ['cylibs/actions/action_queue']={new=function()
     local q={enable=function(self)self.is_enabled=true end,disable=function(self)self.is_enabled=false;self.current_action=nil end,
      destroy=function()end,length=function()return 0 end,push_action=function(self,action)
       check(self.is_enabled,'worker queue enabled before use')
       check(follower.stealth_hold and not enabled.value,'held still and automation paused before use')
       check(not c.buffs[69],'never strip existing Invisible')
       self.current_action=action;self.due=now+2
       if c.cooldowns and spells[action.method] then
        recasts[name]=recasts[name] or {};recasts[name][spells[action.method].id]=now+10
       end
       log[#log+1]={provider=name,method=action.method,index=action.index,kind=action.kind,time=now}
      end}
     queues[#queues+1]=q;return q
    end},
    ['cylibs/battle/spell']={new=function(method)return adapter('spell',method)end},
    ['cylibs/battle/abilities/job_ability']={new=function(method)return adapter('ability',method)end},
    ['cylibs/battle/use_item']={new=function(method)return adapter('item',method)end},
    ['cylibs/util/spell_util']={knows_spell=function(id)return c.spells[resources[id].en] or false end,
     can_cast_spell=function(id)return c.spells[resources[id].en] and (not recasts[name] or (recasts[name][id] or 0)<=now) or false end},
    ['cylibs/util/job_util']={job_ability_id=function(method)return method end,knows_job_ability=function(method)return c[method] or false end,can_use_job_ability=function(method)return c[method] or false end},
    ['cylibs/util/inventory_util']={get_item_count=function(item)return c.items[item] or 0 end},
    ['cylibs/util/party_util']={is_alter_ego=function()return false end},
    ['cylibs/logger/logger']={notice=function()end},
    ['cylibs/actions/strategem']={new=function()return {kind='accession'}end},
    ['cylibs/actions/sequence']={new=function(actions)return {kind='area',method=actions[3].method,index=c.id}end},
    ['cylibs/actions/spell']={new=function(_,_,_,id,index)return {method=resources[id].en,index=index}end},
    ['cylibs/actions/wait']={new=function()return {}end},
   }
   local messages={}
   local env=setmetatable({require=function(path)return assert(deps[path],path)end,L=list,unpack=table.unpack,
    os={time=function()return now end},state=state,res={spells=resources},player={player={}},
    addon_system_message=function(message)messages[#messages+1]=message end,
    windower={register_event=function(event,callback)events[#events+1]={event=event,callback=callback};return #events end,
     unregister_event=function(id)events[id].removed=true end,
     send_ipc_message=function(message)bus[#bus+1]=message end,
     ffxi={get_spell_recasts=function()local r={};for id,t in pairs(recasts[name] or {})do r[id]=math.max(0,t-now)*60 end;return r end,
      get_player=function()p.buffs=buffs(name);return p end,run=function()end,follow=function()end}}}, {__index=_G})
   local module=assert(loadfile('cylibs/trust/stealth/party_stealth.lua','t',env))()
   clients[name]={engine=module.new(trust,main,enabled),main=main,enabled=enabled,follower=follower,queues=queues,
    events=events,state=state,messages=messages,player=p}
  end
 end
 local function flush()
  local count=0
  while #bus>0 do
   count=count+1;assert(count<1000,'IPC loop')
   local message=table.remove(bus,1)
   for _,client in pairs(clients)do client.engine:receive(message)end
  end
 end
 local function step(seconds)
  for _=1,seconds do
   now=now+1
   for name,client in pairs(clients)do
    for _,queue in ipairs(client.queues)do
     if queue.current_action and queue.due<=now then
      local a=queue.current_action;queue.current_action=nil
      local target=names[a.index]
      if not config[name].fail then
       local effects={}
       if a.method=='Sneak' or a.method=='Monomi: Ichi' or a.method=='Silent Oil' then effects={71}
       elseif a.method=='Spectral Jig' then effects={71,69} else effects={69} end
       pendingbuffs[#pendingbuffs+1]={due=now+1,target=target,effects=effects,area=a.kind=='area'}
      end
     end
    end
   end
   for i=#pendingbuffs,1,-1 do
    local b=pendingbuffs[i]
    if b.due<=now then
     for _,name in ipairs(names)do
      if name==b.target or b.area then for _,id in ipairs(b.effects)do config[name].buffs[id]=true end end
     end
     table.remove(pendingbuffs,i)
    end
   end
   flush()
   for _,client in pairs(clients)do client.engine:tick();flush()end
  end
 end
 return {clients=clients,log=log,step=step,flush=flush,config=config,now=function()return now end,
  control=function(name,mode,manual)local c=clients[name];Control.set(c.main,c.enabled,{role_with_type=function()return c.follower end},mode,manual)end}
end
local s=scenario({Alice={spells={Sneak=true,Invisible=true},cooldowns=true},Bob={},Cleo={paused=true}})
check(s.clients.Alice.engine:start('stealth'),'start')
s.flush();s.step(90)
for name,c in pairs(s.config)do check(c.buffs[71] and c.buffs[69],name..' both actually observed')end
check(not s.clients.Alice.engine.session,'one shot completes')
check(s.clients.Alice.enabled.value and not s.clients.Cleo.enabled.value,'restore each original Act/Pause state')
check(not s.clients.Cleo.follower.manual_pause,'paused following restored')
local last=s.log[#s.log];check(last.method=='Invisible' and last.index==1,'caster Invisible last')
local invis=false
for _,a in ipairs(s.log)do if a.method=='Invisible'then invis=true else check(not invis,'Sneak actions all precede Invisible')end end
check(s.clients.Alice.messages[#s.clients.Alice.messages]:match('Covered 3/3'),'actual coverage summary')
local before=#s.log;s.step(20);check(#s.log==before,'no continuous upkeep')
check(s.clients.Alice.engine:start('stealth'),'repeat while already covered');s.flush();s.step(6)
check(#s.log==before,'existing effects skipped on repeat')

s=scenario({Alice={['Spectral Jig']=true},Bob={items={['Silent Oil']=1,['Prism Powder']=1},paused=true}})
check(s.clients.Alice.engine:start('stealth'),'mixed self methods');s.flush();s.step(60)
check(s.config.Alice.buffs[71] and s.config.Alice.buffs[69],'Jig grants both')
check(s.config.Bob.buffs[71] and s.config.Bob.buffs[69],'oil then powder')
check(#s.log==3,'one Jig and two items')
check(s.log[1].method=='Spectral Jig' and s.log[2].method=='Silent Oil' and s.log[3].method=='Prism Powder','self method ordering')

s=scenario({Alice={spells={Sneak=true,Invisible=true},fail=true},Bob={items={['Silent Oil']=1,['Prism Powder']=1}}})
s.clients.Alice.engine:start('stealth');s.flush();s.step(120)
check(s.config.Bob.buffs[71] and s.config.Bob.buffs[69],'failed spells fall back to items')
check(not s.config.Alice.buffs[71],'dispatch alone does not satisfy Sneak')
check(s.clients.Alice.messages[#s.clients.Alice.messages]:match('Missing: Alice'),'partial report names missing member')

s=scenario({Alice={spells={Sneak=true,Invisible=true}},Bob={}})
s.clients.Alice.engine:start('stealth');s.flush()
s.control('Bob','Paused',true);s.step(1)
check(s.clients.Bob.engine.lease==nil,'stick/control takeover releases worker')
s.step(60)
check(s.clients.Bob.follower.manual_pause and not s.clients.Bob.enabled.value,'restoration never overrides manual takeover')
for _,a in ipairs(s.log)do check(a.index~=2,'aborted recipient never assigned')end

s=scenario({Alice={spells={Sneak=true}},Bob={}})
s.clients.Alice.engine:start('sneak');s.flush()
s.control('Bob','Paused',false);s.step(1)
check(not s.clients.Bob.follower.stealth_hold and not s.clients.Bob.follower.manual_pause,'ordinary Pause removes hold and permits following')

s=scenario({Alice={items={['Silent Oil']=1}},Bob={client=false}})
s.clients.Alice.engine:start('sneak');s.flush();s.step(30)
check(s.config.Alice.buffs[71] and not s.config.Bob.buffs[71],'unresponsive client cannot spend items')
check(s.clients.Alice.messages[#s.clients.Alice.messages]:match('Bob %(Sneak%)'),'unresponsive member reported')

s=scenario({Alice={spells={Sneak=true,Invisible=true},['Accession']=true,buffs={[358]=true}},Bob={}})
s.clients.Alice.engine:start('stealth');s.flush();s.step(40)
check(#s.log==2 and s.log[1].kind=='area' and s.log[2].kind=='area','eligible Accession area methods')
check(s.config.Bob.buffs[71] and s.config.Bob.buffs[69],'area effects confirmed')

s=scenario({Alice={spells={Sneak=true}},Bob={}})
s.clients.Alice.engine:start('sneak');s.flush();s.step(4)
local token=s.clients.Alice.engine.session.token
s.clients.Alice.engine:cancel();s.flush()
check(s.clients.Alice.engine.session==nil and s.clients.Bob.engine.lease==nil,'cancel releases everyone')
s.clients.Bob.engine:handle('Alice',token,'hold',{})
check(s.clients.Bob.engine.lease==nil,'late duplicate hold cannot restart completed transaction')
s.clients.Bob.engine:handle('Alice','0_0','action',{'1','s','Bob','sneak'})
check(s.clients.Bob.engine.work==nil,'stale action ignored')
for _,client in pairs(s.clients)do client.engine:destroy();client.engine:destroy();for _,event in ipairs(client.events)do check(event.removed,'event cleanup')end end
s=scenario({Alice={buffs={[69]=true},items={['Silent Oil']=1}}})
s.clients.Alice.engine:start('stealth');s.step(8)
check(#s.log==0 and s.config.Alice.buffs[69],'pre-existing Invisible never cancelled to add Sneak')
check(s.clients.Alice.messages[#s.clients.Alice.messages]:match('Alice %(Sneak%)'),'preserved Invisible with missing Sneak explained')

s=scenario({Alice={spells={['Monomi: Ichi']=true,['Tonko: Ni']=true},items={['Sanjaku-Tenugui']=1,['Shinobi-Tabi']=1}}})
s.clients.Alice.engine:start('stealth');s.step(30)
check(#s.log==2 and s.log[1].method=='Monomi: Ichi' and s.log[2].method=='Tonko: Ni','NIN self spells with tools')
s=scenario({Alice={spells={['Monomi: Ichi']=true},items={['Silent Oil']=1}}})
s.clients.Alice.engine:start('sneak');s.step(20)
check(#s.log==1 and s.log[1].method=='Silent Oil','missing ninja tool skips spell')

s=scenario({Alice={spells={Sneak=true}}})
local actor=s.clients.Alice
for _,event in ipairs(actor.events)do if event.event=='action'then event.callback({actor_id=1,category=8,param=0})end end
actor.engine:start('sneak');s.step(5)
check(#s.log==0 and actor.engine.session,'wait for existing cast rather than conclude no method')
for _,event in ipairs(actor.events)do if event.event=='action'then event.callback({actor_id=1,category=4,param=1})end end
s.step(20)
check(s.config.Alice.buffs[71],'prepare after prior cast completion')

s=scenario({Alice={status=5,items={['Silent Oil']=1}}})
check(s.clients.Alice.engine:start('sneak')==false,'mounted issuer rejected')
check(s.clients.Alice.engine.lease==nil and #s.log==0,'mounted rejection leaves no work')

s=scenario({Alice={spells={Sneak=true}},Bob={}})
s.clients.Alice.engine:start('sneak');s.flush();s.clients.Bob.state.IpcMode.value='Off'
s.clients.Alice.engine:cancel();s.flush();s.step(195)
check(s.clients.Bob.engine.lease==nil and s.clients.Bob.enabled.value,'lease expires if release IPC is lost')

-- Command handler is exercised from production source, not a copied parser.
local f=assert(io.open('commands/GeneralCommands.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function GeneralTrustCommands:handle_stealth',1,true))
local b=assert(source:find('function GeneralTrustCommands:handle_autosuggest',a,true))
local G={};local fake={start=function(_,mode)return true,mode end,status=function()return 'Idle'end,cancel=function(self)self.cancelled=true end}
local env=setmetatable({GeneralTrustCommands=G,require=function()return {current=function()return fake end}end},{__index=_G})
assert(load(source:sub(a,b-1),'stealth command','t',env))()
local ok,mode=G.handle_stealth({},'sneak');check(ok and mode=='sneak','root Sneak handler')
check(G.handle_stealth({},'invisible','status')==false,'single effect commands reject extra arguments')
check(G.handle_stealth({},'stealth','cancel'),'cancel handler');check(fake.cancelled,'cancel dispatched')
check(G.handle_stealth({},'stealth','status'),'status handler')
check(G.handle_stealth({},'stealth','status','extra')==false,'extra arguments rejected')
local Policy=require('cylibs/ui/menu/menu_command_policy')
check(Policy.effect('stealth',{})=='commit' and Policy.effect('sneak',{})=='commit','runtime menu access')
print('party stealth: '..checks..' checks')
