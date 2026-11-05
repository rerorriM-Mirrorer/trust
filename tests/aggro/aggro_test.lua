-- Run from repository root: luatex --luaonly tests/aggro/aggro_test.lua
local count = 0
local function check(v, label) count=count+1; assert(v, label) end
local function list(t) return setmetatable(t, {__index={it=function(self) local i=0; return function() i=i+1; return self[i] end end}}) end
local mobs, tracked = {}, {}
windower={ffxi={get_mob_by_id=function(id) return mobs[id] end, get_mob_by_index=function(index)
    for _,m in pairs(mobs) do if m.index==index then return m end end
end}}
local party_members=list({{get_mob=function() return mobs[1] end},{get_mob=function() return mobs[2] end}})
local party={get_party_members=function() return party_members end}
local tracker={add_mob=function(_,id) tracked[id]=true end,get_targets=function()
    local result={}; for id in pairs(tracked) do result[#result+1]={get_mob=function() return mobs[id] end} end; return list(result)
end}
local function enemy(id,index)
    local m={id=id,index=index,spawn_type=16,valid_target=true,hpp=100,status=1,distance=100,claim_id=0}
    mobs[id]=m; tracked[id]=true; return m
end
mobs[1]={id=1,index=1,hpp=100}; mobs[2]={id=2,index=2,hpp=100,is_npc=true} -- alter ego
local Selector=require('cylibs/entity/party/aggro_target')
local s=Selector.new(party,tracker)
local a,b=enemy(10,10),enemy(20,20)
check(s:select(nil,0)==nil,'nearby engaged enemies alone are unrelated')
a.target_index=2
check(s:select(nil,0)==10,'defend alter ego')
b.target_index=1
check(s:select(nil,1)==10,'retain stable threat')
check(s:select(20,1)==20,'assist takes priority')
check(s:select(nil,1)==10,'deterministic initial selection')
a.claim_id=99
check(s:select(nil,1)==20,'foreign unresolved claim rejected')
b.claim_id=2
check(s:select(nil,1)==20,'party alter ego claim accepted')
b.hpp=0
check(s:select(nil,1)==nil,'dead threat rejected')
b.hpp=100; b.distance=901
check(s:select(nil,1)==nil,'range enforced')
b.distance=100; b.target_index=nil
s:observe({actor_id=20,category=1,targets={{id=2}}},2)
check(s:select(nil,3)==20,'combat event bridges missing target_index')
tracked[20]=nil
check(s:select(nil,3)==20,'fresh event memory survives tracker pruning')
b.claim_id=1;mobs[1].hpp=0
check(s:select(nil,3)==20,'dead party claim owner still belongs to party; victim remains alive')
b.claim_id=2;mobs[1].hpp=100
check(s:select(nil,11)==nil,'event evidence expires')
s:observe({actor_id=20,category=6,targets={{id=1}}},12)
check(s:select(nil,12)==nil,'nonhostile category excluded')
s:observe({actor_id=20,category=1,targets={{id=99}}},12)
check(s:select(nil,12)==nil,'unrelated victim excluded')
s:observe({actor_id=20,category=4,targets={{id=1}}},12)
b.index=21
check(s:select(nil,13)==nil,'index identity mismatch invalidates memory')
b.index=20; mobs[1].hpp=0
check(s:select(nil,13)==nil,'dead party victim invalidates memory')
mobs[1].hpp=100
s:observe({actor_id=20,category=8,targets={{id=1}}},14)
b.claim_id=99
check(s:select(nil,15)==nil,'claim loss invalidates event evidence')
b.claim_id=0; b.status=3
check(s:select(nil,15)==nil,'despawn status rejected')
b.status=1; b.valid_target=false
check(s:select(nil,15)==nil,'untargetable rejected')
b.valid_target=true; b.spawn_type=1
check(s:select(nil,15)==nil,'friendly entity rejected')
b.spawn_type=16; s:reset()
check(s:select(nil,15)==nil,'reset clears zone/assist evidence')
print('Aggro selector: '..count..' checks passed')
