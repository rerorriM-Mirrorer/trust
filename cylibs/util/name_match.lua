-- A: literal entity-name matching, independent of capitalization. No patterns
-- or substring expansion: an exclusion still names the whole mob type.
local M={}
function M.index_of(names,name)
    if type(name)~='string' then return -1 end
    local wanted=name:lower()
    for index,candidate in ipairs(names or {}) do
        if type(candidate)=='string' and candidate:lower()==wanted then return index end
    end
    return -1
end
function M.contains(names,name)return M.index_of(names,name)>0 end
return M
