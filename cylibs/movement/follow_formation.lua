-- A: cosmetic follow slots. Party IDs provide the same order on every client;
-- client-relative p0/p1 indices do not. No peer avoidance or terrain probing.
local Formation={}
Formation.__index=Formation
local slots={{.7,.7},{-.7,.7},{0,1},{.7,1.1},{-.7,1.1}}
function Formation.new()return setmetatable({dx=1,dy=0},Formation)end
function Formation:goal(leader_id,zone,position,ids,self_id,distance)
    local key=tostring(leader_id)..':'..tostring(zone)
    if self.key~=key then
        self.key=key;self.anchor=nil;self.dx=1;self.dy=0
    end
    if self.anchor then
        local dx,dy=position[1]-self.anchor[1],position[2]-self.anchor[2]
        local length=math.sqrt(dx*dx+dy*dy)
        -- Accumulate small steps, ignore standing jitter and teleport headings.
        if length>=.3 then
            if length<=16 then self.dx=dx/length;self.dy=dy/length end
            self.anchor={position[1],position[2]}
        end
    else self.anchor={position[1],position[2]} end
    local members,seen={},{}
    for _,id in ipairs(ids) do
        if type(id)=='number' and not seen[id] then members[#members+1]=id;seen[id]=true end
    end
    if not seen[leader_id] or not seen[self_id] or leader_id==self_id then return end
    table.sort(members)
    local rank=0
    for _,id in ipairs(members) do
        if id~=leader_id then
            rank=rank+1
            if id==self_id then break end
        end
    end
    local slot=slots[rank]
    if not slot then return end
    local radius=math.max(.1,tonumber(distance) or 1)*(rank>3 and 1.2 or 1)
    local scale=radius/math.sqrt(slot[1]^2+slot[2]^2)
    local lateral,behind=slot[1]*scale,slot[2]*scale
    local x=position[1]-self.dy*lateral-self.dx*behind
    local y=position[2]+self.dx*lateral-self.dy*behind
    -- Arrival radius and a larger restart radius prevent constant shuffling.
    local tolerance=math.max(.15,math.min(.35,radius*.2))
    return {x,y,position[3]},tolerance,rank
end
return Formation
