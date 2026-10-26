-- A: adapt the normal editor to factory Job rules, preserving other source.
local M={}
local first='-- A: factory source BEGIN\n'
local last='\n-- A: factory source END'
local header='-- A: shared Job gambits; backed up before each save.\n'
local function baseSource(source)
    if source:sub(1,#header)~=header then return source end
    local a=source:find(first,1,true);local b=a and source:find(last,a+#first,true)
    if not a or not b then error('Shared factory source markers are damaged') end
    return source:sub(a+#first,b-1)
end
local function evaluate(source)
    local f,err=(loadstring or load)(source,'shared job settings')
    if not f then error(err) end
    local settings=f()
    assert(settings and settings.Default and settings.Default.GambitSettings,'Missing factory GambitSettings')
    return settings
end
function M.new(owner,options)
    options=options or {}
    local disk=options.disk or require('settings/shared_job_file').new()
    local serialize=options.serialize or require('cylibs/util/serializer_util').serialize
    local eval=options.evaluate or evaluate
    local path=options.path or owner:getSettingsFilePath(true)
    local report=options.report or addon_system_error
    local self={jobNameShort=owner.jobNameShort,playerName=owner.playerName}
    local expected,root
    function self:reloadSettings()
        local source,err=disk:read(path);if not source then error(err) end
        local factory=eval(source)
        root={Default={GambitSettings={Gambits=factory.Default.GambitSettings.Default or L{}}}}
        expected=source
        return true
    end
    function self:getSettings()return root end
    function self:getDefaultSettings()
        -- Reset copies abilities shallowly; reload the original source so an
        -- earlier reset/edit cannot mutate the next reset's baseline objects.
        local baseline=eval(baseSource(expected))
        return {Default={GambitSettings={Gambits=baseline.Default.GambitSettings.Default or L{}}}}
    end
    function self:saveSettings(persist)
        if not persist then return true end
        local locked,release,err=pcall(disk.lock,disk,path..'.job-gambits.lock')
        if not locked then err=release;release=nil end
        if not release then if report then report(err)end;return false,err end
        local ok,result=pcall(function()
            assert(disk:read(path)==expected,'Job rules changed on disk. Use Reload in the Job editor before editing again.')
            local serialized=serialize(root.Default.GambitSettings.Gambits)
            local candidate=header..'local function factory_settings()\n'..first..baseSource(expected)..last..
                '\nend\nlocal settings=factory_settings()\nsettings.Default.GambitSettings.Default = '..serialized..'\nreturn settings\n'
            local factory=eval(candidate)
            if candidate==expected then return true end
            local saved,why=disk:write(path..'.job-gambits.bak',expected);assert(saved,why)
            saved,why=disk:write(path..'.job-gambits.tmp',candidate);assert(saved,why)
            assert(disk:read(path)==expected,'Job rules changed during save. Use Reload before editing again.')
            saved,why=disk:replace(path..'.job-gambits.tmp',path);assert(saved,why)
            expected=candidate
            -- Role-added conditions must not leak into the factory draft.
            owner.defaultSettings=factory
            for name,profile in pairs(owner:getSettings()) do
                if name~='Version' and name~='Migrations' and type(profile)=='table' and profile.GambitSettings then
                    profile.GambitSettings.Default=assert((loadstring or load)('return '..serialized))()
                end
            end
            local refreshed,refreshErr=pcall(function()owner:saveSettings(false)end)
            if not refreshed and report then report('Job rules saved; reload Trust to refresh this client: '..tostring(refreshErr))end
            return true
        end)
        disk:remove(path..'.job-gambits.tmp');release()
        if not ok then if report then report(tostring(result))end;return false,tostring(result)end
        return result
    end
    local ok,err=pcall(function()self:reloadSettings()end)
    if not ok then return nil,tostring(err)end
    return self
end
return M
