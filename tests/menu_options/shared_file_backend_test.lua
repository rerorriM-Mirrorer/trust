-- Run with sqlite3 available (Windower or the real-SQLite host test bridge).
local sqlite=require('sqlite3')
local Disk=require('settings/shared_job_file')
local Shared=require('settings/shared_preferences')
local disk,other=Disk.new(),Disk.new()
local path=os.tmpname();os.remove(path)
local suffix='.shared-previous'
local original_rename=os.rename
local function exists(p)local f=io.open(p,'rb');if f then f:close();return true end end
-- Reproduce Windows destination-exists behavior on a Linux test host.
os.rename=function(a,b)
 if exists(b) then return nil,'destination exists' end
 return original_rename(a,b)
end
-- Force the compatibility route even if a host happens to provide LuaJIT.
disk.native=function()return nil,'FFI deliberately absent' end
other.native=disk.native
local release=assert(disk:lock(path..'.lock'))
assert(not other:lock(path..'.lock'),'two connections acquired the writer lock')
release();release();local nextRelease=assert(other:lock(path..'.lock'));nextRelease()
assert(disk:write(path..'.tmp','first'))
release=assert(disk:lock(path..'.lock'));assert(disk:replace(path..'.tmp',path));release()
assert(disk:read(path)=='first')
assert(disk:write(path..'.tmp','second'))
-- Reads during the rename gap must return complete previous data, never nil.
local gap_reads=0
os.rename=function(a,b)
 if a==path..'.tmp' and b==path then
  assert(not exists(path) and exists(path..suffix))
  assert(other:read(path)=='first');gap_reads=gap_reads+1
 end
 if exists(b)then return nil,'destination exists'end
 return original_rename(a,b)
end
release=assert(disk:lock(path..'.lock'));assert(disk:replace(path..'.tmp',path));release()
assert(disk:read(path)=='second' and gap_reads==1 and not exists(path..suffix))
-- Failed replacement restores original bytes and does not report success.
assert(disk:write(path..'.tmp','bad replacement'))
os.rename=function(a,b)
 if a==path..'.tmp' then return nil,'simulated denied stage' end
 if exists(b)then return nil,'destination exists'end
 return original_rename(a,b)
end
release=assert(disk:lock(path..'.lock'));assert(not disk:replace(path..'.tmp',path));release()
assert(disk:read(path)=='second')
os.rename=original_rename
-- Interrupted replacement: a complete previous file is readable and the next
-- exclusive writer restores it before checking editor source/replacing anything.
assert(os.rename(path,path..suffix));assert(other:read(path)=='second')
release=assert(other:lock(path..'.lock'));assert(exists(path) and not exists(path..suffix));release()
-- Even a failed restore leaves previous complete bytes readable.
assert(os.rename(path,path..suffix));os.rename=function()return nil,'restore denied'end
assert(not disk:lock(path..'.lock'));assert(disk:read(path)=='second')
os.rename=original_rename;release=assert(disk:lock(path..'.lock'));release()
-- End-to-end: real shared writer + SQLite mutex + compatible file replacement.
L=function(t)t=t or {};t.n=#t;return t end
assert(disk:write(path,'return {Pulling={Targets={},TargetIds={},Blacklist={},Distance=30,Delay=0},Sounds={disabled=true}}'))
local serialize=require('cylibs/util/serializer_util').serialize
local a=Shared.new({disk=disk,path=path,serialize=serialize})
local b=Shared.new({disk=other,path=path,serialize=serialize})
local editor=assert(a:owner('Pulling'));editor:getSettings().Default.PullSettings.Distance=50
assert(editor:saveSettings(true));assert(b:read().Pulling.Distance==50)
local stale=assert(a:owner('Pulling'));assert(b:update('Sounds',{disabled=false}))
assert(not stale:saveSettings(true),'stale editor bypassed shared revision guard')
assert(a:read().Pulling.Distance==50 and not a:read().Sounds.disabled)
assert(exists(path..'.bak'))
-- Closing a connection without an explicit release simulates losing a writer.
if sqlite.test_abandon then
 release=assert(disk:lock(path..'.lock'));sqlite.test_abandon()
 nextRelease=assert(other:lock(path..'.lock'));nextRelease()
end
for _,s in ipairs({'','.tmp','.bak',suffix,'.lock.sqlite3','.lock.sqlite3-journal'})do os.remove(path..s)end
print('PASS real SQLite writer exclusion, release/connection-loss, Windows rename compatibility, read gap, crash/restore recovery, failed replacement, distance 50 persistence and stale-editor rejection')
