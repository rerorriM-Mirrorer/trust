-- A: the small, explicit baseline requested for early party play. It does not
-- replace saved profiles or change positioning, pulling, follow or burst policy.
local M={}
function M.values(job)
    local values={AutoEngageMode='Always',AutoHealMode='Emergency',AutoBuffMode='Auto',
        AutoSkillchainMode='Off',AutoTrustsMode='Off',AutoShootMode='Off'}
    if job=='SMN' then values.AutoAvatarMode='Carbuncle' end
    return values
end
function M.apply(job,lookup,setter)
    local changes={}
    -- Validate everything before changing a live mode. Unsupported roles can
    -- be absent, but a loaded mode with an incompatible value must be reported.
    for name,value in pairs(M.values(job)) do
        local mode=lookup(name)
        if mode then
            local valid=false
            for _,option in ipairs(mode:options()) do if option==value then valid=true end end
            if not valid then return nil,name..' does not support '..value end
            changes[name:lower()]=value
        end
    end
    for name,value in pairs(changes) do if lookup(name).value~=value then setter(name,value) end end
    return changes
end
return M
