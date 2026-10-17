-- Compare draft values without copying ability objects or their metatables.
-- Only plain tables/lists are recursively compared; domain objects retain
-- their identity. Used for validation-before-apply and no-op exit detection.
local Values = {}

function Values.copy(source)
    local result = {}
    for key, value in pairs(source) do result[key] = value end
    return setmetatable(result, getmetatable(source))
end

function Values.equal(a, b)
    if rawequal(a, b) then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end
    if (a.__class and a.__class ~= 'List' and a.__class ~= 'Table')
            or (b.__class and b.__class ~= 'List' and b.__class ~= 'Table')
            or (a.__type and a.__type ~= 'List')
            or (b.__type and b.__type ~= 'List') then return false end
    for key, value in pairs(a) do
        if not Values.equal(value, b[key]) then return false end
    end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

return Values
