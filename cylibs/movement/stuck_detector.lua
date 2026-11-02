-- A: displacement-based recovery, independent of Windower for deterministic tests.
-- One active goal owns the feet. Time without movement requests never counts as
-- obstruction time. Detours are finite offsets, not collision-aware routes.
local M={}
local function distance(a,b)
    local x,y=a[1]-b[1],a[2]-b[2]
    return math.sqrt(x*x+y*y)
end
local function point(p)return {p[1],p[2],p[3]}end
function M.new(clock)
    local self={clock=clock,attempts=0,last='idle'}
    function self:reset()self.context=nil;self.last='idle'end
    function self:sample(key,pos,goal,radius,settings,blocked)
        local now=self.clock()
        if settings.mode=='Off' then self:reset();return 'normal' end
        local c=self.context
        if not c or c.key~=key then
            c={key=key,anchor=point(pos),since=now,last=now,attempts=0,best=distance(pos,goal)}
            self.context=c
        end
        if blocked then
            c.anchor=point(pos);c.since=now;c.last=now;c.detour=nil
            self.last='suspended';return 'hold'
        end
        if math.sqrt(distance(pos,goal)^2+(pos[3]-goal[3])^2)<=radius then
            self:reset();return 'normal'
        end
        if now-c.last>.75 then
            c.anchor=point(pos);c.since=now;c.detour=nil
        end
        c.last=now
        if c.failed then self.last='paused';return 'failed' end
        if c.detour then
            if distance(pos,c.detour)<=.3 or now>=c.until_time then
                c.detour=nil;c.anchor=point(pos);c.since=now
                self.last='retrying original goal';return 'normal'
            end
            self.last='detour '..c.attempts;return 'detour',c.detour
        end
        -- Useful progress can replenish attempts; the detour itself cannot.
        local remaining=distance(pos,goal)
        if c.best-remaining>=settings.detour_distance then
            c.attempts=0;c.best=remaining
        end
        if distance(pos,c.anchor)>=settings.min_movement then
            c.anchor=point(pos);c.since=now
        elseif now-c.since>=settings.interval then
            if settings.mode=='Pause' or c.attempts>=settings.attempts then
                c.failed=true;self.last='paused';return 'failed'
            end
            local x,y=goal[1]-pos[1],goal[2]-pos[2]
            local length=math.sqrt(x*x+y*y)
            if length<.001 then x,y,length=1,0,1 end
            x,y=x/length,y/length
            c.attempts=c.attempts+1
            local side=c.attempts%2==1 and 1 or -1
            local scale=settings.detour_distance/math.sqrt(1+.35*.35)
            c.detour={pos[1]+(.35*x-side*y)*scale,pos[2]+(.35*y+side*x)*scale,pos[3]}
            c.until_time=now+2
            self.last='detour '..c.attempts;return 'detour',c.detour,true
        end
        self.last='watching';return 'normal'
    end
    return self
end
return M
