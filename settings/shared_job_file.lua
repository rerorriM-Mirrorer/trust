-- A: one writer per factory file; native handles close even after a crash.
local M={}
function M.new()
    local self={}
    function self:read(path)
        local f,err=io.open(path,'rb');if not f then return nil,err end
        local text=f:read('*a');f:close();return text
    end
    function self:write(path,text)
        local f,err=io.open(path,'wb');if not f then return nil,err end
        local ok,why=f:write(text);local closed,closeErr=f:close()
        if not ok or not closed then return nil,why or closeErr end
        if self:read(path)~=text then return nil,'File verification failed' end
        return true
    end
    function self:remove(path)os.remove(path)end
    function self:native()
        if self.kernel then return self.kernel,self.ffi end
        local ok,ffi=pcall(require,'ffi')
        if not ok or ffi.os~='Windows' then return nil,'Shared saving requires Windows LuaJIT file support' end
        pcall(ffi.cdef,[[
            void* __stdcall CreateFileA(const char*, unsigned long, unsigned long, void*, unsigned long, unsigned long, void*);
            int __stdcall CloseHandle(void*);
            int __stdcall MoveFileExA(const char*, const char*, unsigned long);
            unsigned long __stdcall GetLastError(void);
        ]])
        self.kernel=ffi.load('kernel32');self.ffi=ffi
        return self.kernel,ffi
    end
    function self:lock(path)
        local kernel,ffi=self:native();if not kernel then return nil,ffi end
        local h=kernel.CreateFileA(path,0xC0000000,0,nil,4,128,nil)
        if h==ffi.cast('void*',-1) then
            return nil,'Shared file is busy or inaccessible (Windows '..tonumber(kernel.GetLastError())..')'
        end
        return function()kernel.CloseHandle(h)end
    end
    function self:replace(source,target)
        local kernel,err=self:native();if not kernel then return nil,err end
        if kernel.MoveFileExA(source,target,9)==0 then
            return nil,'Shared replacement failed (Windows '..tonumber(kernel.GetLastError())..')'
        end
        return true
    end
    return self
end
return M
