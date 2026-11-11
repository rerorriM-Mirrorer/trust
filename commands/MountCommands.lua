local CommandMessage = require('cylibs/messages/command_message')
local DismountAction = require('cylibs/actions/dismount')
local MountAction = require('cylibs/actions/mount')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MountCommands = setmetatable({}, {__index = TrustCommands })
MountCommands.__index = MountCommands
MountCommands.__class = "MountCommands"

local function is_mounted()
    local character = windower.ffxi.get_player()
    return character and (character.status == 5 or character.status == 85)
end

local function find_mount(name)
    for _, mount in pairs(res.mounts) do
        if mount.en:lower() == name:lower() then return mount end
    end
end

function MountCommands.new(trust)
    local self = setmetatable(TrustCommands.new(), MountCommands)
    self.trust = trust
    self.action_queue = ActionQueue.new(nil, false, 5, false, false)
    self.allowed_mounts = S(player_util.get_mounts():map(function(name) return name:lower() end))
    local mount_names = L{}
    for _, mount in pairs(res.mounts) do
        if self.allowed_mounts:contains(mount.en:lower()) then
            local name = mount.en
            self:add_command(name:lower(), function() return self:handle_mount(name) end,
                'Mount '..name..': //trust mount '..name)
            mount_names:append(name)
        end
    end
    mount_names:sort()
    self:add_command('default', function(_, first, ...)
        local name = table.concat({...}, ' ')
        -- The default handler receives the first word too for unregistered names.
        if first and first ~= '' and first:lower() ~= 'default' then name = first..(name ~= '' and ' '..name or '') end
        return self:handle_mount(name ~= '' and name or 'Raptor')
    end, 'Mount locally: //trust mount [mount name]')
    self:add_command('random', self.handle_random_mount, 'Mount a learned random mount: //trust mount random')
    local all_names = L{''}
    for name in mount_names:it() do all_names:append(name) end
    self:add_command('all', self.handle_mount_all,
        'Toggle all from your mounted state; a named mount forces mounting: //trust mount all [mount name]', L{
            PickerConfigItem.new('mount_name', '', all_names, function(name)
                return name == '' and 'Toggle from my state' or name
            end, 'Mount Name'),
        })
    self:add_command('dismount', self.handle_dismount, 'Dismount locally or everywhere: //trust mount dismount [all]', L{
        PickerConfigItem.new('all', '', L{'', 'all'}, function(value)
            return value == 'all' and 'All clients' or 'Self'
        end, 'Dismount Target'),
    })
    -- Relay an explicit desired state. Recipients never toggle or rebroadcast.
    self:add_command('request', self.handle_request, 'Internal explicit mount request')
    return self
end

function MountCommands:get_command_name()
    return 'mount'
end

function MountCommands:show_feedback(label, scope)
    require('chat')
    windower.add_to_chat(0, ('[Trust] '):color(200)..label:color(167)..(' - '..scope):color(0))
end

function MountCommands:apply_request(mode, name)
    local character = windower.ffxi.get_player()
    if not character then return false, 'Character unavailable.' end
    if mode == 'dismount' then
        if not is_mounted() then return true end
        self.action_queue:push_action(DismountAction.new(), true)
        return true
    end
    if is_mounted() then return true end
    local mount = find_mount(name or '')
    if not mount then return false, 'Unknown mount: '..tostring(name) end
    -- Read current unlocks so learning a mount does not require reloading Trust.
    local learned = player_util.get_mounts():map(function(value) return value:lower() end)
    if not learned:contains(mount.en:lower()) then
        return false, 'Mount not learned: '..mount.en
    end
    if character.status ~= 0 then
        local status = res.statuses[character.status]
        return false, 'Cannot mount while '..(status and status.en or ('status '..tostring(character.status)))
    end
    if windower.ffxi.get_info().mog_house then return false, 'Cannot mount inside a Mog House' end
    local action = MountAction.new(mount.id)
    if not action:can_perform() then
        action:destroy()
        return false, 'Cannot mount: incapacitated or mounting conditions are not satisfied'
    end
    self.action_queue:push_action(action, true)
    return true
end

function MountCommands:request_all(mode, name)
    local sending = state.IpcMode.value == 'All' or state.IpcMode.value == 'Send'
    if sending then
        IpcRelay.shared():send_message(CommandMessage.new('trust mount request '..mode..(name and ' '..name or '')))
    end
    local success, message = self:apply_request(mode, name)
    local label = mode == 'dismount' and 'Dismount' or 'Mount '..name
    self:show_feedback(label, sending and 'Requested on all clients.' or 'Local only. IPC sending unavailable.')
    -- A local failure must not prevent eligible recipients from acting.
    if not success then return false, message end
    return true
end

function MountCommands:handle_mount(name, include_party)
    local mount = find_mount(name or '')
    if not mount then return false, 'Unknown mount: '..tostring(name) end
    if include_party then return self:request_all('mount', mount.en) end
    local success, message = self:apply_request('mount', mount.en)
    if success then self:show_feedback('Mount '..mount.en, 'Requested.') end
    return success, message
end

function MountCommands:handle_random_mount()
    local mounts = player_util.get_mounts()
    if mounts:length() == 0 then return false, 'You have not learned any mounts' end
    return self:handle_mount(mounts[math.random(mounts:length())])
end

-- A bare group command chooses once, from the issuer; explicit names always mount.
function MountCommands:handle_mount_all(_, ...)
    local name = table.concat({...}, ' ')
    if name == '' and is_mounted() then return self:request_all('dismount') end
    return self:handle_mount(name ~= '' and name or 'Raptor', true)
end

function MountCommands:handle_dismount(_, scope, ...)
    if select('#', ...) > 0 or (scope ~= nil and scope ~= '' and scope:lower() ~= 'all') then
        return false, 'Usage: //trust mount dismount [all]'
    end
    if scope and scope:lower() == 'all' then return self:request_all('dismount') end
    local success, message = self:apply_request('dismount')
    if success then self:show_feedback('Dismount', 'Requested.') end
    return success, message
end

function MountCommands:handle_request(_, mode, ...)
    local name = table.concat({...}, ' ')
    if mode == 'dismount' and name == '' then return self:apply_request('dismount') end
    if mode == 'mount' and find_mount(name) then return self:apply_request('mount', name) end
    return false, 'Invalid mount request'
end

return MountCommands
