-- Exercise production mode declaration and gambit construction with condition/action doubles.
local count=0
local function check(v,label) count=count+1;assert(v,label) end
local methods={}
function methods:it() local i=0;return function() i=i+1;return self[i] end end
function methods:filter(fn) local t=L{};for _,v in ipairs(self) do if fn(v) then t[#t+1]=v end end;return t end
function methods:map(fn) local t=L{};for _,v in ipairs(self) do t[#t+1]=fn(v) end;return t end
L=function(t) return setmetatable(t or {},{__index=methods,__add=function(a,b) local t=L{};for _,v in ipairs(a) do t[#t+1]=v end;for _,v in ipairs(b) do t[#t+1]=v end;return t end}) end
state={AutoPullMode={value='Off'}}
M=function(t) return {value=t[1],set_description=function() end} end
Condition={LogicalOperator={Or='or'},Operator={GreaterThanOrEqualTo='ge'}}
local function condition() return {is_editable=function() return true end,set_editable=function() end} end
ModeCondition={new=function(name,value) local c=condition();c.test=function() return state[name].value==value end;return c end}
local conditional={new=function(conditions) local c=condition();c.test=function() for _,v in ipairs(conditions) do if v.test and v.test() then return true end end;return false end;return c end}
for _,name in ipairs({'StatusCondition','MaxDistanceCondition','ValidTargetCondition','NotCondition'}) do _G[name]={new=condition} end
GambitCondition={__type='GambitCondition',new=function(c) c.__type='GambitCondition';return c end}
Gambit={new=function(_,conditions,ability) return {conditions=conditions,ability=ability,addCondition=function(self,c) self.conditions[#self.conditions+1]=c end} end}
alter_ego_util={untargetable_alter_egos=function() return {} end}
local base={new=function() return {} end,set_gambit_settings=function(self,s) self.settings=s end}
package.preload['cylibs/trust/roles/gambiter']=function() return base end
package.preload['cylibs/conditions/conditional']=function() return conditional end
package.preload['cylibs/gambits/gambit_target']=function() return {TargetType={Self='self',Enemy='enemy',Ally='ally',CurrentTarget='current'}} end
setmetatable(package.preload,{__index=function() return function() return {new=condition} end end})
local Attacker=assert(loadfile('cylibs/trust/roles/attacker.lua'))()
check(state.AutoEngageMode.value=='Always','default remains Always')
local a=Attacker.new({},{});local gambits=a.settings.Gambits
check(#gambits==6,'existing gambit count/order preserved')
local engage_mode=gambits[3].conditions[1]
for _,mode in ipairs({'Always','Aggro','Mirror','Off'}) do
 state.AutoEngageMode.value=mode
 check(engage_mode.test()==(mode=='Always' or mode=='Aggro'),'engage condition for '..mode)
end
check(a:get_cooldown()==1 and not a:allows_multiple_actions(),'existing queue throttle preserved')
print('Attacker: '..count..' checks passed')
