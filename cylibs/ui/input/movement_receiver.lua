-- A: RC3 movement receiver integrated into Trust. No pending takeover/retries.
local M={}
function M.new(options)
    local self={received=0,accepted=0,ignored=0,down=false,last='waiting for movement'}
    function self:policy()
        return options.settings().policy=='Ready' and 'Ready' or 'Send'
    end
    function self:reason()
        if options.settings().enabled==false then return 'disabled' end
        return options.blocked()
    end
    function self:receive()
        self.received=self.received+1
        local reason=self:reason()
        if not reason then
            local ok,result,message=pcall(options.perform)
            if not ok then reason=tostring(result)
            elseif result==false then reason=message or 'action unavailable' end
        end
        if reason then self.ignored=self.ignored+1;self.last=reason;return false end
        self.accepted=self.accepted+1;self.last='follow/assist requested';return true
    end
    function self:key(dik,pressed)
        if dik~=0x7B then return end
        -- Consume both edges; repeat downs never trigger another action.
        if not options.focused() then self.down=false;return true end
        if pressed then
            if not self.down then self.down=true;self:receive() end
        else self.down=false end
        return true
    end
    function self:tick(force)
        local name=options.name()
        if not name then self:close();return end
        local path=options.path(name)
        if self.path and self.path~=path then options.remove(self.path) end
        self.path=path
        local now=options.clock()
        if not force and self.next and now<self.next then return end
        self.next=now+.25
        local f=options.open(path,'w')
        if f then
            f:write('name='..name..'\ntimestamp='..options.timestamp()..
                '\nready='..(self:reason()==nil and '1' or '0')..'\npolicy='..self:policy()..'\n')
            f:close()
        end
    end
    function self:status()
        return self:policy()..' | received '..self.received..' | accepted '..self.accepted..
            ' | ignored '..self.ignored..' | current: '..(self:reason() or 'ready')..' | last: '..self.last
    end
    function self:close()
        self.down=false
        if self.path then options.remove(self.path);self.path=nil end
    end
    return self
end
return M
