-- Gates are installed before synchronous cancellation callbacks. Targets remain
-- remembered; only an explicit new follow request reopens movement production.
local M={}
function M.is_movement(action)
    if not action then return false end
    local kind=action.gettype and action:gettype() or action.__type or ''
    if kind:match('^run') then return true end
    if action.current_action and M.is_movement(action.current_action) then return true end
    if action.queue and action.queue.it then
        for child in action.queue:it() do if M.is_movement(child) then return true end end
    end
    return false
end
function M.discard(action)
    local run=windower.ffxi.run
    windower.ffxi.run=function(value,...) if value~=false then return run(value,...) end end
    local ok,err=pcall(function() action:destroy() end)
    windower.ffxi.run=run
    if not ok then error(err) end
end
local function owns_movement(action)
    if not action then return false end
    if action.current_action then return owns_movement(action.current_action) end
    return action.gettype and action:gettype():match('^run')~=nil
end
function M.apply(trust,queue,enabled,pause,park)
    local follower=trust:role_with_type('follower')
    local owned=owns_movement(queue.current_action) or (follower and owns_movement(follower.walk_action_queue.current_action))
    if not pause and not park then queue.control_revision=(queue.control_revision or 0)+1 end
    queue.movement_suspended=true
    queue.parked=park or queue.parked
    if follower then follower.manual_pause=true end
    local run=windower.ffxi.run
    -- Legacy action destructors release run repeatedly. Coalesce those calls,
    -- and never stop native stick input when Trust owned no movement.
    windower.ffxi.run=function(value,...) if value~=false then return run(value,...) end end
    local ok,err=pcall(function()
        if pause or park then
            require('cylibs/trust/control_state').set(queue,enabled,trust,park and 'Parked' or 'Paused',true)
        else
            local active=queue.is_enabled
            queue:disable()
            if active then queue:enable() end
        end
        if follower then follower:stop_following() end
        require('cylibs/movement/recovery').reset()
        windower.ffxi.follow()
    end)
    windower.ffxi.run=run
    if owned then run(false) end
    if not ok then error(err) end
end
return M
