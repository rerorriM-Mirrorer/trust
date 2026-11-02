local f=assert(io.open('cylibs/battle/spell.lua'));local s=f:read('*a');f:close()
local body=assert(s:match('(function Spell:to_action.-)\n%-%-%-%-%-%-%-'))
local list={};function list:append(v)self[#self+1]=v;return self end
function list:length()return #self end
function list:it()local i=0;return function()i=i+1;return self[i]end end
function list:map(fn)local out=L{};for _,v in ipairs(self)do out:append(fn(v))end;return out end
function list:filter(fn)local out=L{};for _,v in ipairs(self)do if fn(v)then out:append(v)end end;return out end
L=function(t)return setmetatable(t or {},{__index=list})end
local env=setmetatable({Spell={},L=L,SpellAction={new=function()return{kind='spell'}end},
 WaitAction={new=function(_,_,_,duration)return{kind='wait',duration=duration}end},
 SequenceAction={new=function(q)return q end},windower={ffxi={get_mob_by_target=function()return nil end}}},{__index=_G})
assert(load(body,'actual spell sequence','t',env))()
local ability={get_job_abilities=function()return L{}end,requires_all_job_abilities=function()return true end,
 get_spell=function()return{id=1,en='Dia'}end,get_target=function()return nil end}
local actor={is_moving=function()return false end}
local normal=env.Spell.to_action(ability,2,actor)
local pull=env.Spell.to_action(ability,2,actor,nil,true)
assert(#normal==2 and normal[2].duration==2 and #pull==1 and pull[1].kind=='spell')
print('PASS production spell pull omits trailing wait while normal spell sequences retain it')
