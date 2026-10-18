-- A: derive direct mode commands from the modes loaded for this job.
-- Registered commands win. Exact mode names win over shortened names; ambiguous
-- shortened names are never guessed. Dispatch still uses the original set/cycle.
local Aliases = {}

local function registered(name, groups)
    return groups and (groups[name] or (groups.default and groups.default.commands and groups.default.commands[name]))
end

local function findMode(name, states, shortened)
    local found={}
    for key,mode in pairs(states or {}) do
        if type(key)=='string' and type(mode)=='table' and mode._class=='mode' then
            local candidate=key:lower()
            if shortened then candidate=candidate:match('^(.-)mode$') end
            if candidate==name then found[#found+1]=key end
        end
    end
    table.sort(found)
    if #found==1 then return found[1] end
    if #found>1 then return nil,'Ambiguous mode name: '..table.concat(found,', ')..'. Use //trust set or //trust cycle with the exact name.' end
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
    local key,err=findMode(name,states,false)
    if not key and not err then key,err=findMode(name,states,true) end
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
            local short=key:lower():match('^(.+)mode$')
            for _,name in ipairs({key,short}) do
                local token=name:lower()
                local resolved,err=Aliases.resolve(name,mode._type=='string' and {tostring(mode.value)} or {},groups,states)
                if not registered(token,groups) and not seen[token] and not err
                        and (resolved or mode._type=='string') then
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
