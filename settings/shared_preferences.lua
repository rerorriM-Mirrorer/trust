-- A: one installation-wide pulling setup and sound switch. Job actions and
-- each client's AutoPullMode remain independent. No automatic legacy import.
local M={}
local keys={'Targets','TargetIds','Blacklist','Distance','Delay'}
local function copy(v)
    if type(v)~='table' then return v end
    local r={};for k,x in pairs(v)do r[k]=copy(x)end
    return r
end
local function defaults()return {Pulling={Targets={},TargetIds={},Blacklist={},Distance=30,Delay=0},Sounds={disabled=true}}end
local function validate(v)
    assert(type(v)=='table' and type(v.Pulling)=='table' and type(v.Sounds)=='table','Invalid shared preferences')
    local p=v.Pulling
    assert(type(p.Distance)=='number' and p.Distance>=0 and p.Distance<=50,'Distance must be 0-50')
    assert(type(p.Delay)=='number' and p.Delay>=0 and p.Delay<=50,'Delay must be 0-50')
    assert(type(v.Sounds.disabled)=='boolean','Invalid sound preference')
    for _,k in ipairs({'Targets','TargetIds','Blacklist'})do
        assert(type(p[k])=='table','Invalid '..k)
        -- A: Windower L{} tables carry a physical `n` length field.
        -- Persist only real entries; keep internal list metadata out of the
        -- shared schema while still rejecting unknown keys or sparse arrays.
        local clean,count,maxIndex={},0,0
        for i,x in pairs(p[k])do
            if i=='n' then
                assert(type(x)=='number' and x>=0 and x%1==0,'Invalid '..k..' list length metadata')
            else
                assert(type(i)=='number' and i>=1 and i%1==0,'Invalid '..k..' list index: '..tostring(i))
                if k=='TargetIds' then
                    assert(type(x)=='table' and type(x.Id)=='number' and x.Id>0 and x.Id%1==0 and (x.Name==nil or type(x.Name)=='string'),'Invalid target ID/name entry')
                    clean[i]={Id=x.Id,Name=x.Name}
                else
                    assert(type(x)=='string' and #x>0,'Invalid '..k..' entry')
                    clean[i]=x
                end
                count=count+1;maxIndex=math.max(maxIndex,i)
            end
        end
        assert(count==maxIndex,'Invalid '..k..' list: missing entries')
        p[k]=clean
    end
    return v
end
function M.new(options)
    local disk=options.disk
    local serialize=options.serialize
    local path=options.path
    local self={revision=0}
    local snapshot,values
    local function readFile()
        local source,err=disk:read(path)
        if not source and err and not tostring(err):lower():find('no such file',1,true) then return nil,err end
        return source
    end
    local function decode(source)
        if not source then return defaults()end
        local f,err=(loadstring or load)(source,'shared preferences');assert(f,err)
        if setfenv then setfenv(f,{L=function(t)return t end})end
        return validate(f())
    end
    function self:read()
        local source,readErr=readFile();if readErr then return nil,readErr end
        if values==nil or source~=snapshot then
            local ok,result=pcall(decode,source)
            if not ok then return nil,tostring(result)end
            snapshot=source;values=result;self.revision=self.revision+1
        end
        return copy(values),snapshot
    end
    function self:update(section,value,expected)
        local locked,release,err=pcall(disk.lock,disk,path..'.lock')
        if not locked then err=release;release=nil end
        if not release then return false,err end
        local ok,result=pcall(function()
            local source,readErr=readFile();assert(not readErr,readErr)
            if expected and source~=expected.source then error('Shared preferences changed. Close/reopen this editor before editing again.')end
            local nextValues=decode(source)
            nextValues[section]=copy(value);validate(nextValues)
            local candidate='-- Shared Trust preferences, edited from Trust menus/commands.\nreturn '..serialize(nextValues)..'\n'
            decode(candidate)
            if source then local saved,why=disk:write(path..'.bak',source);assert(saved,why)end
            local saved,why=disk:write(path..'.tmp',candidate);assert(saved,why)
            assert(disk:read(path)==source,'Shared preferences changed during save')
            saved,why=disk:replace(path..'.tmp',path);assert(saved,why)
            snapshot=candidate;values=nextValues;self.revision=self.revision+1
            return true
        end)
        disk:remove(path..'.tmp');release()
        return ok and result or false,not ok and tostring(result) or nil
    end
    function self:owner(section)
        local current,source=self:read();if not current then return nil,source end
        local root=section=='Pulling' and {Default={PullSettings=current.Pulling}} or current.Sounds
        if section=='Pulling' then for _,k in ipairs({'Targets','TargetIds','Blacklist'})do root.Default.PullSettings[k]=L(root.Default.PullSettings[k])end end
        local parent=self
        return {
            getSettings=function()return root end,
            -- A: refresh only when opening a new editor/view. Active drafts
            -- keep their snapshot so stale-save checks still protect edits.
            reloadSettings=function()
                local data,latest=parent:read();if not data then return false,latest end
                root=section=='Pulling' and {Default={PullSettings=data.Pulling}} or data.Sounds
                if section=='Pulling' then
                    for _,k in ipairs({'Targets','TargetIds','Blacklist'})do root.Default.PullSettings[k]=L(root.Default.PullSettings[k])end
                end
                source=latest;return true
            end,
            saveSettings=function(_,persist)
                if not persist then return true end
                local value=section=='Pulling' and root.Default.PullSettings or root
                local nextValue={}
                if section=='Pulling' then for _,k in ipairs(keys)do nextValue[k]=value[k]end else nextValue.disabled=value.disabled end
                local ok,why=parent:update(section,nextValue,{source=source})
                if ok then local _,newSource=parent:read();source=newSource
                elseif addon_system_error then addon_system_error(why)end
                return ok,why
            end,
        }
    end
    return self
end
local instance,addonOwner,nextPoll,lastError= nil,nil,0,nil
function M.shared()
    if not instance then instance=M.new({disk=require('settings/shared_job_file').new(),serialize=require('cylibs/util/serializer_util').serialize,path=windower.addon_path..'data/shared-preferences.lua'})end
    return instance
end
function M.configure(owner)addonOwner=owner end
function M.enabled()return not addonOwner or addonOwner:getSettings().use_shared_pulling~=false end
function M.poll()
    if os.time()<nextPoll then return end
    nextPoll=os.time()+1
    local data,err=M.shared():read()
    if not data and err~=lastError and addon_system_error then addon_system_error(err)end
    lastError=err
    return data
end
function M.effective(jobSettings)
    local result={};for k,v in pairs(jobSettings)do result[k]=v end
    if M.enabled() then
        local data=M.shared():read()
        -- Refuse to pull using a malformed shared file's accidental fallback.
        local p=data and data.Pulling or defaults().Pulling
        for _,k in ipairs(keys)do result[k]=copy(p[k])end
        for _,k in ipairs({'Targets','TargetIds','Blacklist'})do result[k]=L(result[k])end
        if not data then result.Targets=L{};result.TargetIds=L{};result.Distance=0 end
    end
    return result
end
return M
