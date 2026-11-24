-- A: derive direct mode commands from the modes loaded for this job.
-- Registered commands win. Exact mode names win over shortened names; ambiguous
-- shortened names are never guessed. Dispatch still uses the original set/cycle.
-- Name tiers, first match wins: exact (AutoEngageMode), without Mode
-- (autoengage), without Auto and Mode (engage).
local Aliases = {}

local function registered(name, groups)
    return groups and (groups[name] or (groups.default and groups.default.commands and groups.default.commands[name]))
end

local tiers={false,'^(.-)mode$','^auto(.+)mode$'}
Aliases.tiers=tiers
local function short(key, tier)
    local candidate=key:lower()
    if tiers[tier] then candidate=candidate:match(tiers[tier]) end
    return candidate
end
local function findMode(name, states, tier)
    local found={}
    for key,mode in pairs(states or {}) do
        if type(key)=='string' and type(mode)=='table' and mode._class=='mode' then
            local candidate=short(key, tier)
            if candidate==name then found[#found+1]=key end
        end
    end
    table.sort(found)
    if #found==1 then return found[1] end
    if #found>1 then return nil,'Ambiguous mode name: '..table.concat(found,', ')..'. Use //trust set or //trust cycle with the exact name.' end
end

-- Mode key for a typed name through the same three tiers, ignoring command
-- names (callers like //trust set already know the name is a mode).
function Aliases.find(name, states)
    if type(name)~='string' then return nil end
    name=name:lower()
    for tier=1,#tiers do
        local key,err=findMode(name,states,tier)
        if key or err then return key,err end
    end
end

local function options(mode)
    if mode._type=='boolean' then return {'on','off','true','false'} end
    if mode._type=='string' then return nil end
    return mode:options()
end
Aliases.options=options

function Aliases.resolve(command, args, groups, states)
    local name=type(command)=='string' and command:lower() or ''
    if registered(name,groups) then return nil end
    local key,err
    for tier=1,#tiers do
        key,err=findMode(name,states,tier)
        if key or err then break end
    end
    if err or not key then return nil,err end
    local mode=states[key]
    if not args or #args==0 then
        if mode._type=='string' then return nil,key..' requires a value.' end
        return {command='cycle',arguments={key},mode=key}
    end
    -- Windower may split a multi-word option; join only after resolving a mode.
    local value=table.concat(args,' ')
    local choices=options(mode)
    if choices then
        local canonical
        -- Prefer an exact spelling before case-insensitive matching.
        for _,choice in ipairs(choices) do if tostring(choice)==value then canonical=choice;break end end
        if canonical==nil then
            for _,choice in ipairs(choices) do
                if tostring(choice):lower()==value:lower() then
                    if canonical~=nil then return nil,'Ambiguous value for '..key..'. Use the exact option spelling.' end
                    canonical=choice
                end
            end
        end
        local legacy=rawget(mode,'legacy_values')
        if canonical==nil and legacy and legacy[value:lower()] then canonical=legacy[value:lower()] end
        if canonical==nil then
            local names={};for _,choice in ipairs(choices) do names[#names+1]=tostring(choice) end
            return nil,'Invalid value for '..key..'. Options: '..table.concat(names,', ')
        end
        value=canonical
    end
    return {command='set',arguments={key,value},mode=key}
end

function Aliases.commands(states, groups)
    local result,seen={},{}
    for key,mode in pairs(states or {}) do
        if type(key)=='string' and type(mode)=='table' and mode._class=='mode' then
            for _,name in ipairs({key,key:lower():match('^(.+)mode$'),short(key,3)}) do
                local token=name:lower()
                local resolved,err=Aliases.resolve(name,mode._type=='string' and {tostring(mode.value)} or {},groups,states)
                if not registered(token,groups) and not seen[token] and not err
                        and (resolved or mode._type=='string') and (not resolved or resolved.mode==key) then
                    seen[token]=true
                    result[#result+1]='// trust '..name
                    for _,choice in ipairs(options(mode) or {}) do result[#result+1]='// trust '..name..' '..tostring(choice) end
                end
            end
        end
    end
    table.sort(result)
    return result
end

return Aliases
