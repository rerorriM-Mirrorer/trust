-- Empty slots stay explicit in saved lists so settings merges cannot refill them.
local Slots = {}
function Slots.name(song)
    if type(song) == 'table' and song.get_name then return song:get_name() end
    return 'None'
end
function Slots.active(songs)
    local result = L{}
    local indices = {}
    for index in pairs(songs or {}) do
        if type(index) == 'number' then indices[#indices + 1] = index end
    end
    table.sort(indices)
    for _, index in ipairs(indices) do
        local song = songs[index]
        if Slots.name(song) ~= 'None' then result:append(song) end
    end
    return result
end
function Slots.names(songs)
    return Slots.active(songs):map(function(song) return song:get_name() end)
end
return Slots
