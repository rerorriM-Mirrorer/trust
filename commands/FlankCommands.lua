-- Fork addition: //trust flank status - what CombatMode Flank last did and why (Flank2),
-- and the quiet tank announcement other clients send (Flank3).
local flank_state = require('cylibs/movement/flank_state')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local FlankCommands = setmetatable({}, {__index = TrustCommands })
FlankCommands.__index = FlankCommands
FlankCommands.__class = "FlankCommands"

function FlankCommands.new()
    local self = setmetatable(TrustCommands.new(), FlankCommands)
    self:add_command('status', self.handle_status, 'Show what Flank combat mode last did and why: //trust flank status')
    self:add_command('default', self.handle_status, 'Show Flank status: //trust flank')
    self:add_command('tank', self.handle_tank, 'Sent by other clients: //trust flank tank <name> <on|off>')
    return self
end

function FlankCommands:get_command_name()
    return 'flank'
end

function FlankCommands:handle_status()
    local mode = state.CombatMode and state.CombatMode.value or '?'
    return true, flank_state.status(flank_state.clock()) .. ' [Combat Mode: ' .. mode .. ']'
end

-- Another client announces its Auto Tank Mode (sent with --quiet, so nothing prints).
function FlankCommands:handle_tank(_, name, value)
    if type(name) ~= 'string' or (value ~= 'on' and value ~= 'off') then
        return false, 'Usage: //trust flank tank <name> <on|off>'
    end
    flank_state.set_tank(name, value == 'on')
    return true, 'Flank: '..name..' tank '..value
end

return FlankCommands
