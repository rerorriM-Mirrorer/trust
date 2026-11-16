-- Fork addition (Flank2): //trust flank status - what CombatMode Flank last did and why.
local flank_state = require('cylibs/movement/flank_state')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local FlankCommands = setmetatable({}, {__index = TrustCommands })
FlankCommands.__index = FlankCommands
FlankCommands.__class = "FlankCommands"

function FlankCommands.new()
    local self = setmetatable(TrustCommands.new(), FlankCommands)
    self:add_command('status', self.handle_status, 'Show what Flank combat mode last did and why: //trust flank status')
    self:add_command('default', self.handle_status, 'Show Flank status: //trust flank')
    return self
end

function FlankCommands:get_command_name()
    return 'flank'
end

function FlankCommands:handle_status()
    local mode = state.CombatMode and state.CombatMode.value or '?'
    return true, flank_state.status(flank_state.clock()) .. ' [Combat Mode: ' .. mode .. ']'
end

return FlankCommands
