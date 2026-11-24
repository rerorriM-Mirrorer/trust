-- EngageWith1: decide() and target lookup from cylibs/trust/engage_with_action.lua.
local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local E=require('cylibs/trust/engage_with_action')
local function list(t)return{it=function()local i=0;return function()i=i+1;return t[i]end end}end
local mobs={[50]={id=500,index=50,valid_target=true,spawn_type=16,hpp=80,claim_id=1},
 [51]={id=510,index=51,valid_target=true,spawn_type=16,hpp=80,claim_id=999},
 [52]={id=520,index=52,valid_target=true,spawn_type=16,hpp=80,claim_id=0}}
local now=100
local function env(mode,status)return{player={id=1,index=7,status=status or 0},mob=function(i)return mobs[i]end,
 party_ids={[1]=true,[2]=true},mode=mode or 'Always',now=now}end
local spell={target_index=50,gettype=function()return'spellaction'end}
check(E.decide(spell,env()).id==500,'idle + claimed by party + Always: engage')
E.reset()
check(E.decide(spell,env('Off'))==nil,'Off: no')
check(E.decide(spell,env('Mirror'))==nil,'Mirror: left to the Attacker')
check(E.decide(spell,env('Aggressive')).id==500,'Aggressive: engage')
E.reset()
check(E.decide(spell,env(nil,1))==nil,'already engaged: no')
check(E.decide({target_index=51},env())==nil,'claimed by someone else: no')
check(E.decide({target_index=52},env())==nil,'unclaimed: no (pulls not included yet)')
check(E.decide({target_index=7},env())==nil,'self target: no')
local seq={queue=list({{__type='WaitAction'},spell})}
check(E.target_index_of(seq)==50,'finds the target inside a wait sequence')
check(E.decide({target_index=50,gettype=function()return'engageaction'end},env())==nil,'never doubles an Engage action')
-- interval: decide does not record; before_perform does. Simulate by recording via a second module load.
E.Enabled=false;check(E.decide(spell,env())==nil,'toggle off');E.Enabled=true
check(select(2,E.command('off')):find('OFF'),'command off');E.command('on')
print('engage_with_action_test: '..checks..' checks passed')
