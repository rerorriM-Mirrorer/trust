-- Real file bytes, generation, evaluation and owner routing; Windows atomic
-- replacement/lock primitives injected because this test also runs on Linux.
local Shared=require('settings/shared_job_gambits')
local Disk=require('settings/shared_job_file')
local disk=Disk.new()
local path=os.tmpname()
local base='-- preserve this comment\nreturn {Version=17, Default={CombatSettings={Distance=7}, GambitSettings={Default=L{"factory"},Gambits=L{"factory custom"}}}, Other={Value=42}}\n'
L=function(t)return t or {}end
local function serialize(list)
    local items={};for _,v in ipairs(list)do items[#items+1]=string.format('%q',v)end
    return 'L{'..table.concat(items,',')..'}'
end
local locked=false
function disk:lock()
    if locked then return nil,'busy' end
    locked=true;return function()locked=false end
end
function disk:replace(a,b)return os.rename(a,b)end
assert(disk:write(path,base))
local writes={}
local owner={jobNameShort='WAR',playerName='Killala',settings={Version=1,
    Default={GambitSettings={Gambits={'personal'},Default={'old'}}},
    Solo={GambitSettings={Gambits={'solo'},Default={'old'}}}}}
function owner:getSettings()return self.settings end
function owner:saveSettings(persist)writes[#writes+1]=persist and 'disk' or 'runtime'end
local reports={}
local options={path=path,disk=disk,serialize=serialize,report=function(s)reports[#reports+1]=s end}
local a=assert(Shared.new(owner,options));local stale=assert(Shared.new(owner,options))
local draft=a:getSettings().Default.GambitSettings.Gambits
draft[1]='edited';draft[2]='new'
assert(owner.settings.Default.GambitSettings.Default[1]=='old','draft changed live state')
assert(a:saveSettings(true) and not locked)
assert(disk:read(path..'.job-gambits.bak')==base)
local saved=assert(disk:read(path));assert(saved:find(base,1,true),'factory source changed')
local result=assert(load(saved))()
assert(result.Version==17 and result.Default.CombatSettings.Distance==7 and result.Other.Value==42)
assert(result.Default.GambitSettings.Default[1]=='edited' and result.Default.GambitSettings.Gambits[1]=='factory custom')
assert(owner.settings.Default.GambitSettings.Gambits[1]=='personal' and owner.settings.Solo.GambitSettings.Gambits[1]=='solo')
assert(owner.settings.Default.GambitSettings.Default[2]=='new' and writes[1]=='runtime')
owner.settings.Default.GambitSettings.Default[1]='runtime condition mutation'
assert(draft[1]=='edited' and owner.settings.Solo.GambitSettings.Default[1]=='edited')
assert(not stale:saveSettings(true) and disk:read(path)==saved and not locked,'stale editor overwrote shared file')
locked=true;assert(not a:saveSettings(true));locked=false
-- Repeated edits retain one original source block and a previous-save backup.
draft[2]='second';assert(a:saveSettings(true))
assert(disk:read(path..'.job-gambits.bak')==saved)
local second=assert(disk:read(path));local _,markers=second:gsub('factory source BEGIN','')
assert(markers==1 and second:find(base,1,true),'nested generated source')
assert(a:getDefaultSettings().Default.GambitSettings.Gambits[1]=='factory')
local replacements=disk.replace
disk.replace=function()return nil,'injected replacement failure'end
draft[2]='failed';assert(not a:saveSettings(true) and disk:read(path)==second and not locked)
assert(disk:read(path..'.job-gambits.tmp')==nil)
disk.replace=replacements
local bad=assert(Shared.new(owner,{path=path,disk=disk,serialize=function()return 'broken lua ??'end,report=options.report}))
assert(not bad:saveSettings(true) and disk:read(path)==second and not locked)
assert(stale:reloadSettings() and stale:getSettings().Default.GambitSettings.Gambits[2]=='second')
stale:getSettings().Default.GambitSettings.Gambits[1]='fresh after reload'
assert(stale:saveSettings(true))
-- New adapter/client reads the shared list, never the character's old Job copy.
local fresh=assert(Shared.new(owner,options))
assert(fresh:getSettings().Default.GambitSettings.Gambits[1]=='fresh after reload')
assert(#reports>=4)
for _,suffix in ipairs({'','.job-gambits.bak','.job-gambits.tmp'})do os.remove(path..suffix)end
-- Actual Windows backend call wiring with Win32 observations mocked.
local calls,failLock,failReplace={},false,false
local kernel={
    CreateFileA=function(p,access,share,security,creation,flags)
        assert(access==0xC0000000 and share==0 and creation==4 and flags==128)
        calls[#calls+1]='lock';return failLock and -1 or 123
    end,
    CloseHandle=function(h)assert(h==123);calls[#calls+1]='close'end,
    MoveFileExA=function(a,b,flags)assert(flags==9);calls[#calls+1]='replace';return failReplace and 0 or 1 end,
    GetLastError=function()return 32 end,
}
package.loaded.ffi={os='Windows',cdef=function()end,load=function()return kernel end,cast=function(_,value)return value end}
local native=Disk.new();local release=assert(native:lock('test.lock'));release()
assert(native:replace('stage','target'))
failLock=true;assert(not native:lock('test.lock'))
failReplace=true;assert(not native:replace('stage','target'))
assert(calls[1]=='lock' and calls[2]=='close' and calls[3]=='replace')
package.loaded.ffi=nil
print('PASS shared Job editor: real file roundtrip, exact base preservation, runtime/profile isolation, backup, stale/busy rejection, failed replace, malformed Lua and reload')
