-- Production PartyTarget integration, simulated Windower APIs/events.
local count=0
local function check(v,label) count=count+1; assert(v,label) end
local function list(t) return setmetatable(t or {},{__index={it=function(self) local i=0;return function() i=i+1;return self[i] end end}}) end
local function event()
    return {actions={},addAction=function(self,f) self.actions[#self.actions+1]=f;return f end,
        removeAllActions=function(self) self.actions={} end,
        trigger=function(self,...) for _,f in ipairs(self.actions) do f(...) end end}
end
package.preload['socket']=function() return {gettime=os.clock} end
package.preload['cylibs/events/Luvent']=function() return {newEvent=event} end
package.preload['cylibs/events/dispose_bag']=function() return {new=function() return {add=function() end,dispose=function() end,destroy=function() end} end} end
package.preload['cylibs/messages/ipc/ipc_relay']=function() return {} end
package.preload['cylibs/messages/target_change_message']=function() return {} end
package.preload['cylibs/util/party_util']=function() return {get_mobs_targeting_party=function() return list({10,20}) end} end
local handlers,removed={},{}
local mobs={ [1]={id=1,index=1,hpp=100},[2]={id=2,index=2,hpp=100} }
for _,i in ipairs({10,20}) do mobs[i]={id=i,index=i,hpp=100,valid_target=true,spawn_type=16,distance=100,status=1,claim_id=0,target_index=2} end
windower={register_event=function(name,f) handlers[name]=f;return name end,unregister_event=function(id) removed[id]=true end,
    ffxi={get_player=function() return {id=1} end,get_mob_by_index=function(i) return mobs[i] end,get_mob_by_id=function(i) return mobs[i] end,get_mob_by_target=function() return nil end}}
logger={notice=function() end}
WindowerEvents={Action=event(),MobKO=event()}
state={AutoEngageMode={value='Always'},AutoPullMode={value='Off'}}
addon_enabled={getValue=function() return true end}
local members=list({{get_mob=function() return mobs[1] end},{get_mob=function() return mobs[2] end}})
local party={get_party_members=function() return members end}
local tracker={add_mob=function() end,add_mob_by_index=function() end,get_targets=function() return list({{get_mob=function() return mobs[10] end},{get_mob=function() return mobs[20] end}}) end}
local PartyTarget=require('cylibs/entity/party/party_target')
local p=PartyTarget.new(tracker,nil,party)
p.log_target_changed=function() end
local changed,leader_event,leader_index=0,event(),nil
local leader_id=2
local leader={get_id=function() return leader_id end,on_target_change=function() return leader_event end,get_target_index=function() return leader_index end,is_valid=function() return true end,get_name=function() return 'Leader' end}
p:on_target_change():addAction(function() changed=changed+1 end)
p:monitor();p:set_assist_target(leader)
check(not p:update_aggro_target() and p:get_target_index()==nil,'Always retains original target')
state.AutoEngageMode.value='Aggro';p:update_aggro_target()
check(p:get_target_index()==10 and changed==1,'Aggro publishes fallback once')
p:update_aggro_target();check(changed==1,'repeated observations do not reset roles/queues')
leader_index=20;leader_event:trigger(leader,20,nil)
check(p:get_target_index()==20 and changed==2,'leader event immediately preempts fallback')
leader_index=1;leader_event:trigger(leader,1,20)
check(p:get_target_index()==10,'friendly leader target permits defense')
state.AutoEngageMode.value='Off';p:update_aggro_target()
check(p:get_target_index()==1 and not p.aggro_active,'Off restores original assist selection')
state.AutoEngageMode.value='Mirror';check(not p:update_aggro_target(),'Mirror not overridden')
state.AutoEngageMode.value='Aggro';state.AutoPullMode.value='Auto';p:set_target_index(20)
check(not p:update_aggro_target() and p:get_target_index()==20,'puller owns its target')
state.AutoPullMode.value='Off';p:set_should_ignore_assist_target(true)
check(not p:update_aggro_target() and p:get_target_index()==20,'explicit ignore-assist ownership respected')
p:set_should_ignore_assist_target(false);p:update_aggro_target()
addon_enabled.getValue=function() return false end;p:update_aggro_target()
check(not p.aggro_active and p:get_target_index()==1,'Stop releases defensive fallback')
addon_enabled.getValue=function() return true end;p:update_aggro_target()
-- Self-assist cursor feedback cannot turn an expired threat into a primary target.
leader_id=1;leader_index=10;p.aggro.selected_id=10;p.auto_defense_id=10
mobs[10].target_index=nil;mobs[20].target_index=nil
p:update_aggro_target();check(p:get_target_index()==nil,'self-assist fallback does not sustain itself')
p:update_aggro_target();check(p:get_target_index()==nil,'expired own cursor remains suppressed on subsequent ticks')
handlers['zone change']();check(p:get_target_index()==nil and p.aggro.selected_id==nil,'zone clears selection and memory')
p:destroy();check(removed.prerender and removed['zone change'],'lifecycle unregisters polling and zone handlers')
print('PartyTarget integration: '..count..' checks passed')
