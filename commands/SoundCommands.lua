local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SoundCommands = setmetatable({}, {__index = TrustCommands })
SoundCommands.__index = SoundCommands
SoundCommands.__class = "SoundCommands"

function SoundCommands.new(mediaPlayer)
    local self = setmetatable(TrustCommands.new(), SoundCommands)

    self.mediaPlayer = mediaPlayer

    self:add_command('default', self.handle_toggle_sound, 'Toggles sound effects from Trust')

    self:add_command('enable', function(_)
        return self:handle_set_sound_enabled(true)
    end, 'Enables sound effects from Trust')

    self:add_command('disable', function(_)
        return self:handle_set_sound_enabled(false)
    end, 'Disables sound effects from Trust')

    return self
end

function SoundCommands:get_command_name()
    return 'sounds'
end

-- // trust sounds
function SoundCommands:handle_toggle_sound()
    local data,err=require('settings/shared_preferences').shared():read()
    if not data then return false,err end
    return self:handle_set_sound_enabled(data.Sounds.disabled)
end

-- // trust sounds [enable | disable]
function SoundCommands:handle_set_sound_enabled(is_enabled)
    local success = true
    local message

    if is_enabled then
        message = "Sounds: ON"
    else
        message = "Sounds: OFF"
    end
    local ok,err=require('settings/shared_preferences').shared():update('Sounds',{disabled=not is_enabled})
    if not ok then return false,err end
    self.mediaPlayer:setEnabled(is_enabled)

    return success, message
end

return SoundCommands
