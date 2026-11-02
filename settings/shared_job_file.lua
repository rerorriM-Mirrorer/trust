-- A: serialize shared edits with Windower's existing SQLite module. LuaJIT is
-- optional: use Win32 atomic replacement when available, otherwise rename the
-- previous complete file aside and retain it until the new file is verified.
local M={}
local previous_suffix='.shared-previous'
local function rawread(path)
    local f,err,code=io.open(path,'rb');if not f then return nil,err,code end
    local text=f:read('*a');f:close();return text
end
function M.new()
    local self={}
    function self:read(path)
        local text,err,code=rawread(path)
        if text~=nil then return text end
        -- Standard Windows rename cannot overwrite an existing destination.
        -- During that short gap (or after a crash), expose the previous full
        -- file instead of treating an existing installation as fresh defaults.
        if code==2 or tostring(err):lower():find('no such file',1,true) then
            local old=rawread(path..previous_suffix)
            if old~=nil then return old end
            -- A concurrent writer may have completed between our two opens.
            local retry=rawread(path);if retry~=nil then return retry end
        end
        return nil,err
    end
    function self:write(path,text)
        local f,err=io.open(path,'wb');if not f then return nil,err end
        local ok,why=f:write(text);local closed,closeErr=f:close()
        if not ok or not closed then return nil,why or closeErr end
        if rawread(path)~=text then return nil,'File verification failed' end
        return true
    end
    function self:remove(path)os.remove(path)end
    function self:native()
        if self.kernel then return self.kernel,self.ffi end
        local ok,ffi=pcall(require,'ffi')
        if not ok or ffi.os~='Windows' then return nil,'Win32 FFI unavailable' end
        local loaded,kernel=pcall(function()
            pcall(ffi.cdef,[[
                void* __stdcall CreateFileA(const char*, unsigned long, unsigned long, void*, unsigned long, unsigned long, void*);
                int __stdcall CloseHandle(void*);
                int __stdcall MoveFileExA(const char*, const char*, unsigned long);
                unsigned long __stdcall GetLastError(void);
            ]])
            return ffi.load('kernel32')
        end)
        if not loaded then return nil,tostring(kernel) end
        self.kernel=kernel;self.ffi=ffi
        return kernel,ffi
    end
    function self:recover(target)
        local old=rawread(target..previous_suffix)
        if old==nil then return true end
        if rawread(target)==nil then
            local ok,err=os.rename(target..previous_suffix,target)
            if not ok then return nil,'Restore previous shared file failed: '..tostring(err) end
        else
            local ok,err=os.remove(target..previous_suffix)
            if not ok then return nil,'Clean previous shared file failed: '..tostring(err) end
        end
        return true
    end
    function self:lock(path)
        local loaded,sqlite=pcall(require,'sqlite3')
        if not loaded or type(sqlite.open)~='function' then
            return nil,'Shared saving requires Trust\'s sqlite3 module: '..tostring(sqlite)
        end
        local db=sqlite.open(path..'.sqlite3')
        if not db then return nil,'Could not open shared-settings lock database' end
        if db.busy_timeout then db:busy_timeout(0) end
        -- One reserved writer lock per shared file; SQLite releases it when
        -- the process closes or crashes. Never block the game's render thread.
        local ok,result=pcall(db.exec,db,'BEGIN IMMEDIATE')
        if not ok or result~=(sqlite.OK or 0) then
            local err=db.errmsg and db:errmsg() or tostring(result)
            db:close();return nil,'Shared file is busy or inaccessible: '..tostring(err)
        end
        local released=false
        local function release()
            if released then return end
            released=true;pcall(db.exec,db,'ROLLBACK');db:close()
        end
        local target=path:gsub('%.job%-gambits%.lock$',''):gsub('%.lock$','')
        local protected,recovered,err=pcall(self.recover,self,target)
        if not protected then err=recovered;recovered=nil end
        if not recovered then release();return nil,err end
        return release
    end
    function self:replace(source,target)
        local candidate,readErr=rawread(source)
        if candidate==nil then return nil,readErr end
        local kernel=self:native()
        if kernel then
            if kernel.MoveFileExA(source,target,9)==0 then
                return nil,'Shared replacement failed (Windows '..tonumber(kernel.GetLastError())..')'
            end
            return true
        end
        local recovered,err=self:recover(target);if not recovered then return nil,err end
        local original=rawread(target)
        local old=target..previous_suffix
        if original~=nil then
            local moved,why=os.rename(target,old)
            if not moved then return nil,'Preserve previous shared file failed: '..tostring(why) end
        end
        local moved,why=os.rename(source,target)
        if not moved then
            if original~=nil then
                local restored,restoreErr=os.rename(old,target)
                if not restored then return nil,'Replacement failed: '..tostring(why)..'; previous file retained at '..old..': '..tostring(restoreErr) end
            end
            return nil,'Shared replacement failed: '..tostring(why)
        end
        if rawread(target)~=candidate then
            -- The staged payload did not survive replacement. Restore the last
            -- complete file, retaining it under the fallback name if restore fails.
            if original~=nil then
                local removed=os.remove(target)
                if removed then os.rename(old,target) end
            end
            return nil,'Shared replacement verification failed; previous file preserved'
        end
        if original~=nil then os.remove(old) end
        return true
    end
    return self
end
return M
