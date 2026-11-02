local Shared=require('settings/shared_preferences')
local Disk=require('settings/shared_job_file')
local disk=Disk.new();local path=os.tmpname();os.remove(path)
local held=false
function disk:lock()if held then return nil,'busy'end;held=true;return function()held=false end end
local fail=false
function disk:replace(a,b)if fail then return nil,'injected'end;return os.rename(a,b)end
L=function(v)return v end
local serialize=require('cylibs/util/serializer_util').serialize
local options={disk=disk,path=path,serialize=serialize}
local a=Shared.new(options);local b=Shared.new(options)
local initial=a:read();assert(initial.Pulling.Distance==30 and initial.Sounds.disabled and #initial.Pulling.Targets==0)
local old=assert(a:owner('Pulling'))
local data=b:read();data.Pulling.Targets={'Mandragora'};data.Pulling.Blacklist={'Goblin'}
data.Pulling.TargetIds={{Id=123456,Name='Mandragora'}}
assert(b:update('Pulling',data.Pulling))
assert(not old:saveSettings(true),'stale editor overwrote file')
assert(a:read().Pulling.Targets[1]=='Mandragora')
assert(a:read().Pulling.TargetIds[1].Id==123456 and a:read().Pulling.TargetIds[1].Name=='Mandragora')
local sound=assert(a:owner('Sounds'));sound:getSettings().disabled=false;assert(sound:saveSettings(true))
local both=b:read();assert(not both.Sounds.disabled and both.Pulling.Targets[1]=='Mandragora')
local backup=assert(disk:read(path..'.bak'));assert(backup:find('Mandragora',1,true))
local exact=disk:read(path)
held=true;assert(not a:update('Sounds',{disabled=true}));held=false
fail=true;assert(not a:update('Sounds',{disabled=true}) and disk:read(path)==exact and not held);fail=false
data=a:read();data.Pulling.Distance=-1;assert(not a:update('Pulling',data.Pulling) and disk:read(path)==exact)
assert(not a:update('Sounds',{disabled='yes'}) and disk:read(path)==exact)
data=a:read();data.Pulling.TargetIds={123456};assert(not a:update('Pulling',data.Pulling) and disk:read(path)==exact)
-- Reopening editors adopts fresh state; unrelated sections survive a save.
local fresh=assert(b:owner('Pulling'));fresh:getSettings().Default.PullSettings.Distance=42
assert(fresh:saveSettings(true));assert(a:read().Pulling.Distance==42 and not a:read().Sounds.disabled)
local realShared=Shared.shared;Shared.shared=function()return a end
local settings={use_shared_pulling=true}
Shared.configure({getSettings=function()return settings end})
local actions={'job action'}
local job={Targets={'old'},TargetIds={},Blacklist={},Distance=12,Delay=1,Gambits=actions,RandomizeTarget=true}
local effective=Shared.effective(job)
assert(effective.Distance==42 and effective.Gambits==actions and effective.RandomizeTarget)
effective.Targets[1]='local mutation';assert(a:read().Pulling.Targets[1]=='Mandragora')
assert(job.Targets[1]=='old' and job.Distance==12)
settings.use_shared_pulling=false;assert(Shared.effective(job).Distance==12)
settings.use_shared_pulling=true;assert(Shared.effective(job).Distance==42)
Shared.shared=realShared
-- Windower List metadata is physically stored on each L{} table. Model its
-- constructor, append and map behavior rather than identity/plain-table mocks.
local plainL=L
L=function(t)t=t or {};t.n=#t;return t end
local windowerEditor=assert(a:owner('Pulling'))
local pull=windowerEditor:getSettings().Default.PullSettings
assert(pull.Targets.n==#pull.Targets and pull.TargetIds.n==#pull.TargetIds and pull.Blacklist.n==#pull.Blacklist)
pull.Distance=50
assert(windowerEditor:saveSettings(true))
local adopted=b:read();assert(adopted.Pulling.Distance==50 and adopted.Pulling.Targets[1]=='Mandragora')
assert(adopted.Pulling.TargetIds[1].Id==123456 and adopted.Pulling.TargetIds[1].Name=='Mandragora')
assert(adopted.Pulling.Targets.n==nil and adopted.Pulling.Blacklist.n==nil)
local empty=adopted.Pulling;empty.Targets=L{};empty.TargetIds=L{};empty.Blacklist=L{}
assert(a:update('Pulling',empty));assert(#b:read().Pulling.Targets==0)
local invalid=a:read().Pulling;invalid.Targets={n=0,unexpected='Goblin'}
assert(not a:update('Pulling',invalid))
invalid.Targets={[2]='Goblin',n=2};assert(not a:update('Pulling',invalid))
invalid.Targets={n='bad'};assert(not a:update('Pulling',invalid))
L=plainL
assert(disk:write(path,'not valid lua'))
assert(not a:read() and not a:update('Sounds',{disabled=true}))
assert(disk:read(path)=='not valid lua','corrupt shared file overwritten')
for _,suffix in ipairs({'','.bak','.tmp'})do os.remove(path..suffix)end
print('PASS shared preferences: defaults, real-file roundtrip, cross-client refresh, scope isolation, stale/busy/failure rejection, backup, validation and corrupt-file preservation')
