-- A: publish this character's control state and last party-wide request for
-- xivcrossbar's Trust toggle slots. One small file per character:
--   trust-control1\n<character id>\n<state>\n<intent>\n<os.time()>\nEND\n
-- state  = act | start | pause | stop | retreat   (this client, named after commands)
-- intent = act | start | pause | stop | none      (last party-wide request sent from here)
-- Written on change and every few seconds as a heartbeat; removed on unload.
local M = {}

M.state_names = { Act='act', Active='start', Paused='pause', Parked='stop', Retreat='retreat' }

function M.format(id, state, intent, stamp)
    return string.format('trust-control1\n%d\n%s\n%s\n%d\nEND\n', id, state, intent, stamp)
end

-- options: queue, id(), path(id), open, remove, clock (seconds), time (whole seconds)
function M.new(options)
    local self = { next_check = 0, heartbeat = options.heartbeat or 5 }
    function self:snapshot()
        local queue = options.queue
        return M.state_names[queue.control_state] or 'pause', queue.party_intent or 'none'
    end
    function self:tick(force)
        local now = options.clock()
        if not force and now < self.next_check then return end
        self.next_check = now + .25
        local id = options.id()
        if not id then return end
        local path = options.path(id)
        if self.path and self.path ~= path then options.remove(self.path) end
        local state, intent = self:snapshot()
        if not force and path == self.path and state == self.state and intent == self.intent
                and now < (self.next_write or 0) then return end
        local f = options.open(path, 'wb')
        if not f then return end
        f:write(M.format(id, state, intent, options.time()))
        f:close()
        self.path, self.state, self.intent, self.next_write = path, state, intent, now + self.heartbeat
    end
    function self:close()
        if self.path then options.remove(self.path); self.path = nil end
    end
    return self
end

return M
