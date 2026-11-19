-- Follow requests skip clients the party list shows in another zone.
local function check(ok, label) if not ok then error('FAIL: '..label, 2) end end
local function load_windower(path)
    local f = assert(io.open(path, 'r')); local s = f:read('*a'); f:close()
    s = s:gsub('("[^"\n]*"):(%a+)%(', function(q, m) return '('..q..'):'..m..'(' end)
    s = s:gsub("('[^'\n]*'):(%a+)%(", function(q, m) return '('..q..'):'..m..'(' end)
    return assert((loadstring or load)(s, '@'..path))()
end
string.color = function(s) return s end

local sent, chat = {}, {}
local function list(t)
    return { map = function(_, fn) local r = {} for i, v in ipairs(t) do r[i] = fn(v) end
        return setmetatable(r, { __index = { [1] = r[1] } }) end }
end
L = function(t) return { contains = function(_, v) for _, x in ipairs(t) do if x == v then return true end end return false end } end
setmetatable(package.preload, { __index = function() return function() return {} end end })
package.preload['cylibs/messages/command_message'] = function()
    return { new = function(command, target) return { command = command, target = target or 'all' } end }
end
package.preload['ui/settings/editors/config/PickerConfigItem'] = function() return { new = function() return {} end } end
package.preload['cylibs/trust/commands/trust_commands'] = function()
    return { new = function() return { add_command = function() end } end }
end
package.preload['chat'] = function() return {} end
package.preload['cylibs/util/command_feedback'] = function() return dofile('cylibs/util/command_feedback.lua') end
ConfigItem = { new = function() return {} end }
IpcRelay = { shared = function() return { send_message = function(_, m) sent[#sent + 1] = m end } end }
state = { IpcMode = { value = 'All' } }

local party_table = {
    p0 = { name = 'Clairvaux', zone = 230 },
    p1 = { name = 'Cioara', zone = 230 },
    p2 = { name = 'Myrr', zone = 243 },          -- parked elsewhere
    p3 = { name = 'Unknownzone' },               -- zone not reported: still asked
    a10 = { name = 'Allyfriend', zone = 230 },   -- alliance, same zone
    a11 = { name = 'Allyaway', zone = 100 },     -- alliance, other zone
}
windower = {
    register_event = function() return 1 end,
    add_to_chat = function(_, text) chat[#chat + 1] = text end,
    ffxi = {
        get_player = function() return { name = 'Clairvaux' } end,
        get_party = function() return party_table end,
        get_info = function() return { zone = 230 } end,
    },
}

local Follow = load_windower('commands/FollowCommands.lua')
local party = { get_party_members = function() return list({}) end,
    on_party_members_changed = function() return { addAction = function() end } end }
local trust = { get_party = function() return party end,
    role_with_type = function() return { set_follow_target = function() end } end }
local f = Follow.new(trust, {})

local r, away = f:get_receipt_recipients()
check(table.concat(r, ',') == 'Cioara,Unknownzone', 'receipt/handoff list skips other-zone party members: '..table.concat(r, ','))
check(table.concat(away, ',') == 'Myrr', 'other-zone party members reported')

local ok, message = f:handle_follow_me()
check(ok, 'follow me succeeds')
local follow_targets, receipt_targets = {}, {}
for _, m in ipairs(sent) do
    check(m.target ~= 'all', 'no broadcast is sent')
    check(m.target ~= 'Myrr' and m.target ~= 'Allyaway', 'nothing sent to other-zone client '..m.target)
    if m.command == 'trust follow Clairvaux' then follow_targets[#follow_targets + 1] = m.target
    elseif m.command:match('^trust follow receipt ') then receipt_targets[#receipt_targets + 1] = m.target end
end
check(table.concat(follow_targets, ',') == 'Allyfriend,Cioara,Unknownzone', 'follow sent to same-zone party and alliance: '..table.concat(follow_targets, ','))
check(table.concat(receipt_targets, ',') == 'Cioara,Unknownzone', 'receipts only to same-zone party')
check(f.pending_follow.total == 2, 'confirmation count excludes other-zone clients')

-- Typed summary names who was skipped.
f.pending_follow.targets = { Cioara = 'accepted', Unknownzone = 'accepted' }
f:finish_follow_receipts()
check(chat[#chat]:find('2/2', 1, true) and chat[#chat]:find('other zone: Allyaway, Myrr', 1, true), 'summary mentions other zone: '..tostring(chat[#chat]))

-- Everyone elsewhere: nothing is sent at all.
sent = {}
party_table = { p0 = { name = 'Clairvaux', zone = 230 }, p1 = { name = 'Myrr', zone = 243 }, p2 = { name = 'Cioara', zone = 243 } }
f:handle_follow_me()
check(#sent == 0, 'no IPC traffic when every other client is in another zone')

print('PASS follow zone filter: other-zone clients are never sent follow, receipt or handoff requests')
