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
    return true, flank_state.status(flank_state.clock()) .. ' [Combat Mode: ' .. mode .. ']' .. FlankCommands.size_report()
end

-- Fork: sizes for tuning "Measure from body edges": the current target's and this
-- character's model size, and the centre and edge distances between them.
function FlankCommands.size_report()
    local ok, text = pcall(function()
        local player = windower.ffxi.get_player()
        local me = player and windower.ffxi.get_mob_by_index(player.index)
        local target = windower.ffxi.get_mob_by_target('t')
        if me == nil or target == nil or target.distance == nil then return '' end
        local centre = math.sqrt(target.distance)
        local sizes = require('cylibs/util/combat_distance').sizes(target, me)
        return string.format(' [%s size %.1f, mine %.1f: centre %.1f, edge %.1f yalms]',
            target.name or 'target', target.model_size or 0, me.model_size or 0, centre, centre - sizes)
    end)
    return ok and text or ''
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
