-- Manual1: describe/decide from cylibs/trust/manual_input.lua, and the real ActionQueue
-- hold/front_is_manual/push_manual methods (loaded from source) on a minimal queue.
local checks=0
local function check(v,label) checks=checks+1;assert(v,label) end
local function source(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end

package.loaded['resources']={
 spells={[376]={en='Horde Lullaby',prefix='/song'},[112]={en='Flash',prefix='/magic'}},
 job_abilities={[35]={en='Provoke',prefix='/jobability'},[595]={en='Flaming Crush',prefix='/pet'}},
 weapon_skills={[42]={en='Savage Blade'}},
 items={[27556]={en='Echad Ring'}},
}
windower={ffxi={}}
local mi=require('cylibs/trust/manual_input')

-- describe
local s=mi.describe(0x01A,{Category=0x03,Param=376,Target=1001,['Target Index']=55})
check(s.kind=='spell' and s.name=='Horde Lullaby' and s.command=='/song "Horde Lullaby" 1001' and s.target_index==55,'spell')
s=mi.describe(0x01A,{Category=0x09,Param=595,Target=1001})
check(s.command=='/pet "Flaming Crush" 1001','pet command keeps /pet')
s=mi.describe(0x01A,{Category=0x07,Param=42,Target=1001})
check(s.command=='/ws "Savage Blade" 1001','weapon skill')
s=mi.describe(0x01A,{Category=0x10,Param=0,Target=1001})
check(s.command=='/ra 1001','ranged')
check(mi.describe(0x01A,{Category=0x02,Param=0,Target=1001})==nil,'engage is not an action')
check(mi.describe(0x01A,{Category=0x0F,Param=0,Target=1001})==nil,'switch target is not an action')
s=mi.describe(0x037,{Bag=8,Slot=3,Player=7,['Player Index']=9},{items=function(b,sl)return b==8 and sl==3 and 27556 end})
check(s.kind=='item' and s.command=='/item "Echad Ring" 7','item')

-- decide
local function list(t)return{it=function()local i=0;return function()i=i+1;return t[i]end end}end
local spell={name='Horde Lullaby'}
local q={is_enabled=true}
check(mi.decide(q,spell)=='pass','idle Trust: straight through')
q.current_action={spell_id=376}
check(mi.decide(q,spell)=='own',"Trust's own cast is untouched")
q.current_action={queue=list({{__type='WaitAction'},{spell_id=112}})}
check(mi.decide(q,spell)=='queue','busy with another spell (inside a wait sequence): queue')
q.current_action={job_ability_name='Provoke'}
check(mi.decide(q,spell)=='queue','busy with an ability: queue')
q.current_action={__type='RunTo'}
check(mi.decide(q,spell,function(a)return a.__type=='RunTo' end)=='pass_cancel','walking: cancel walk, pass')
q.current_action={__type='Mystery'}
check(mi.decide(q,spell,function()return false end)=='ignore','unreadable action: leave alone')
q.is_enabled=false
check(mi.decide(q,spell)=='ignore','Trust off: ignore')
q.is_enabled=true;mi.Enabled=false
check(mi.decide(q,spell)=='ignore','manual off: ignore');mi.Enabled=true
check(select(2,mi.command('hold','2.5')):find('hold 2.5 s',1,true),'hold command')
check(mi.command('bogus')==false,'bad option')

-- ActionQueue methods from source.
local src=source('cylibs/actions/action_queue.lua')
local function method(name)
 local a=assert(src:find('function ActionQueue:'..name..'(',1,true))
 local b=assert(src:find('\nend\n',a,true))
 return src:sub(a,b+4)
end
local function Qnew()
 local items={}
 return{items=items,push=function(_,x)items[#items+1]=x end,clear=function()for i=#items,1,-1 do items[i]=nil end end,
  it=function()local i=0;return function()i=i+1;return items[i]end end}
end
ActionQueue={}
assert((loadstring or load)(method('hold')..method('front_is_manual')..method('push_manual')))()
local performed=0
local queue=setmetatable({is_enabled=true,queue=Qnew(),current_action={},
 perform_next_action=function()performed=performed+1 end,
 on_action_queued=function()return{trigger=function()end}end},{__index=ActionQueue})
local destroyed={}
local function act(n,manual)return{n=n,manual=manual,spec=manual and {name=n},destroy=function()destroyed[n]=true end}end
for i=1,5 do queue.queue:push(act('t'..i)) end
check(queue:push_manual(act('Horde Lullaby',true))==nil,'first manual press')
check(queue.queue.items[1].n=='Horde Lullaby' and #queue.queue.items==6,'manual first, the 5 Trust actions kept')
check(queue:front_is_manual(),'front is manual')
check(queue:push_manual(act('Foe Lullaby',true))=='Horde Lullaby','newer press replaces older')
check(destroyed['Horde Lullaby'] and queue.queue.items[1].n=='Foe Lullaby' and #queue.queue.items==6,'one manual slot only')
check(queue.queue.items[2].n=='t1' and queue.queue.items[6].n=='t5','Trust order unchanged')
check(performed==0,'busy queue waits for the running action')
queue.current_action=nil;queue:push_manual(act('Echad Ring',true))
check(performed==1,'idle queue fires it now')
queue.is_enabled=false
check(queue:push_manual(act('x',true))==nil and destroyed['x'],'disabled queue drops it')
queue.hold_until=nil;queue:hold(1);local h=queue.hold_until;queue:hold(0.1)
check(queue.hold_until==h,'a shorter hold never shortens a longer one')

print('manual_input_test: '..checks..' checks passed')
