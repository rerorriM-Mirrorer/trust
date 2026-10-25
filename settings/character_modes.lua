-- Character preferences override job-profile values only for these three modes.
-- Other tactical/job modes retain their existing ownership and save behavior.
local M = {}
local names = {autofollowmode='AutoFollowMode', autozonemode='AutoZoneMode', autotrustsmode='AutoTrustsMode'}
local owner
function M.owns(name) return names[tostring(name):lower()] ~= nil end
function M.configure(settingsOwner) owner=settingsOwner end
function M.ready() return owner ~= nil end
function M.without(values)
    local result={}
    for name,value in pairs(values) do if not M.owns(name) then result[name]=value end end
    return result
end
function M.overlay(jobModes, lookup)
    if not owner then return jobModes end
    local settings=owner:getSettings()
    local saved=settings.character_modes or {}
    settings.character_modes=saved
    local result=M.without(jobModes)
    local adopted=false
    for key,name in pairs(names) do
        local mode=lookup(name)
        if mode then
            -- Adopt the currently selected legacy job once, then retain the
            -- character choice across job/profile changes and future reloads.
            if saved[key]==nil then saved[key]=jobModes[key] or mode.value;adopted=true end
            result[key]=saved[key]
        end
    end
    if adopted then owner:saveSettings(true) end
    return result
end
function M.save(values)
    if not owner then return false end
    local saved=owner:getSettings().character_modes or {}
    owner:getSettings().character_modes=saved
    local changed=false
    for name,value in pairs(values) do
        local key=name:lower()
        if M.owns(key) and saved[key]~=value then saved[key]=value;changed=true end
    end
    if changed then owner:saveSettings(true) end
    return changed
end
return M
