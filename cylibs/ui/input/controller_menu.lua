-- A: direct menu actions from the shared xivcrossbar controller receiver.
-- A short-lived, character-specific lease exposes ownership, never game keys.
local M = {}
local keys = {up=200, right=205, down=208, left=203, confirm=28, back=1}
function M.new(options)
    local self = {epoch=0, sequence=0, accepted=0, rejected=0}
    local session = string.format('%.0f', options.clock()*1000000)..tostring({}):gsub('[^%w]', '')
    function self:refresh()
        local menu, focus, mode, id = options.context()
        local key = tostring(menu)..tostring(focus)..tostring(mode)..tostring(id)
        if self.key ~= key then
            self.key=key; self.epoch=self.epoch+1; self.sequence=0
            self.token=session..'-'..self.epoch
        end
        self.menu,self.focus,self.mode,self.id=menu,focus,mode,id
        return mode
    end
    function self:close()
        if self.path then options.remove(self.path); self.path=nil end
        self.key=nil; self.mode='closed'
    end
    function self:tick(force)
        self:refresh()
        if not self.id then self:close();return end
        local path=options.path(self.id)
        if self.path and self.path~=path then options.remove(self.path) end
        self.path=path
        local now=options.clock()
        if self.mode=='closed' and self.published==self.token then return end
        if not force and self.next_write and now<self.next_write and self.published==self.token then return end
        self.next_write=now+.10
        local f=options.open(path,'w')
        if f then
            local ok=f:write(string.format('trust-menu1\n%d\n%s\n%s\n%.6f\nEND\n', self.id,self.token,self.mode,now))
            local closed=f:close()
            if ok and closed then self.published=self.token end
        end
    end
    function self:accept(token, sequence, stamp, action)
        self:refresh()
        sequence,stamp=tonumber(sequence),tonumber(stamp)
        local age=stamp and options.clock()-stamp
        if token~=self.token or not sequence or sequence%1~=0 or sequence<=self.sequence
                or not age or age<-.1 or age>.35 or not keys[action] and action~='close'
                or self.mode=='closed' or self.mode=='paused'
                or self.mode=='text' and action~='confirm' and action~='back' and action~='close' then
            self.rejected=self.rejected+1;return false
        end
        self.sequence=sequence;self.accepted=self.accepted+1
        if action=='close' then self.menu:closeAll()
        elseif self.focus and not self.focus.destroyed then
            -- Keep both edges with the original control if Enter/Back changes focus.
            local focus=self.focus
            focus:onKeyboardEvent(keys[action],true,0,false,options.keyName(keys[action]))
            if not focus.destroyed then focus:onKeyboardEvent(keys[action],false,0,false,options.keyName(keys[action])) end
        end
        self:tick(true)
        return true
    end
    return self
end
return M
