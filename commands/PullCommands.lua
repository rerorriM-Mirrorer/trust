local gambit_commands = require('cylibs/trust/commands/gambit_commands')
local GambitTarget = require('cylibs/gambits/gambit_target')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local PullTrustCommands = setmetatable({}, {__index = TrustCommands })
PullTrustCommands.__index = PullTrustCommands
PullTrustCommands.__class = "PullTrustCommands"

function PullTrustCommands.new(trust, trust_settings, action_queue, puller)
    local self = setmetatable(TrustCommands.new(), PullTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.action_queue = action_queue
    self.puller = puller

    -- AutoPullMode
    self:add_command('default', function(_) return self:handle_toggle_mode('AutoPullMode', 'Auto', 'Off')  end, 'Toggle pulling on and off')
    self:add_command('auto', function(_) return self:handle_set_mode('AutoPullMode', 'Auto')  end, 'Automatically pull monsters for the party from the target list')
    self:add_command('aggroed', function(_) return self:handle_set_mode('AutoPullMode', 'Aggroed')  end, 'Automatically pull any monster aggressive to the party')
    self:add_command('all', function(_) return self:handle_set_mode('AutoPullMode', 'All')  end, 'Automatically pull nearby monsters')
    self:add_command('off', function(_) return self:handle_set_mode('AutoPullMode', 'Off')  end, 'Disable pulling')
    self:add_command('camp', self.handle_camp, 'Automatically return to camp after battle')
    self:add_command('ignore', self.handle_ignore, 'Save exclusion: //trust pull ignore <name|<t>>; //trust pull ignore list shows saved exclusions')
    self:add_command('delay', self.handle_delay, 'Set delay between pulls')

    gambit_commands.register(self, {
        noun = self:get_command_name(),
        trust = trust,
        default_target = GambitTarget.TargetType.Enemy,
        gambits = function(commands)
            local settings = commands:get_settings()
            return settings and settings.PullSettings and settings.PullSettings.Gambits
        end,
        save = function(commands) commands:get_pull_owner():saveSettings(true) end,
    })
    self:add_command('randomize', self.handle_set_randomize, 'Enable or disable randomizing pull targets', L{
        PickerConfigItem.new('value', 'true', L{ 'true', 'false' }, nil, "Randomize Target")
    })

    self:add_command('action', function(_, _, mode_value)
        return self:handle_set_mode('PullActionMode', mode_value or 'Auto')
    end, 'Action to pull monsters with', L{
        PickerConfigItem.new('mode_value', 'auto', L{ 'auto', 'target', 'approach' }, nil, "Pull Action")
    }, true)

    -- Preserve pull add/remove as ability-gambit commands; target is explicit.
    self:add_command('target',self.handle_target,'Edit targets: target add/remove <name>, or target clear')
    self:add_command('clear',function(commands)return commands:handle_target(nil,'clear')end,'Clear target names and IDs')
    self:add_command('distance',self.handle_distance,'Set shared or legacy search distance (0-50 yalms)')
    return self
end

function PullTrustCommands:get_command_name()
    return 'pull'
end

function PullTrustCommands:get_puller()
    return self.puller
end

function PullTrustCommands:get_pull_owner()
    if sub_trust_settings and self.trust.role_with_type and self.puller~=self.trust:role_with_type('puller') then return sub_trust_settings,state.SubTrustSettingsMode end
    return self.trust_settings,state.MainTrustSettingsMode
end
function PullTrustCommands:get_settings()
    local owner,mode=self:get_pull_owner()
    return owner:getSettings()[mode.value]
end
function PullTrustCommands:edit_pull(edit)
    local shared=require('settings/shared_preferences')
    if shared.enabled() then
        local data,source=shared.shared():read();if not data then return false,source end
        local ok,why=edit(data.Pulling);if ok==false then return false,why end
        return shared.shared():update('Pulling',data.Pulling,{source=source})
    end
    local value=self:get_settings().PullSettings
    local ok,why=edit(value);if ok==false then return false,why end
    return self:get_pull_owner():saveSettings(true)
end
function PullTrustCommands:handle_target(_,verb,...)
    verb=tostring(verb or ''):lower()
    if verb~='add' and verb~='remove' and verb~='clear' then return false,'Usage: //trust pull target add/remove <name> | clear' end
    local name=table.concat({...},' '):match('^%s*(.-)%s*$')
    if name=='<t>' then local target=windower.ffxi.get_mob_by_target('t');name=target and target.name or ''end
    if verb~='clear' and name=='' then return false,'Specify a target name or <t>' end
    local ok,err=self:edit_pull(function(p)
        if verb=='clear' then p.Targets=L{};p.TargetIds=L{};return true end
        local targets=L{};local found=false
        for _,item in ipairs(p.Targets or {})do
            if item:lower()==name:lower() then found=true;if verb=='add' then targets:append(item)end
            else targets:append(item)end
        end
        if verb=='add' and not found then targets:append(name)end
        p.Targets=targets;return true
    end)
    if not ok then return false,err end
    if verb=='add' then
        local enabled,why=self:handle_set_mode('AutoPullMode','Auto')
        if enabled==false then return false,'Target saved; pulling mode unchanged: '..tostring(why)end
    end
    return true,'Pull target list updated ('..(require('settings/shared_preferences').enabled() and 'shared' or 'legacy job')..')'
end
function PullTrustCommands:handle_distance(_,value)
    local distance=tonumber(value)
    if not distance or distance<0 or distance>50 then return false,'Distance must be 0-50 yalms' end
    local ok,err=self:edit_pull(function(p)p.Distance=distance end)
    return ok,ok and ('Pull search distance set to '..distance..' yalms') or err
end

-- // trust pull camp
function PullTrustCommands:handle_camp(_)
    local success
    local message

    handle_set('AutoCampMode', 'Auto')

    local position = ffxi_util.get_mob_position(windower.ffxi.get_player().name)
    self:get_puller():set_camp_position(V{ position[1], position[2] })

    success = true
    message = "Pull return: Current position"

    return success, message
end

-- // trust pull ignore
function PullTrustCommands:handle_ignore(_, ...)
    local shared=require('settings/shared_preferences')
    local scope=shared.enabled() and 'shared' or 'legacy job'
    local function readExclusions()
        if shared.enabled() then
            local data,err=shared.shared():read();if not data then return nil,err end
            return data.Pulling.Blacklist or {}
        end
        return self:get_settings().PullSettings.Blacklist or {}
    end
    local name=table.concat({...},' '):match('^%s*(.-)%s*$')
    if name=='' or name:lower()=='list' then
        local names,err=readExclusions();if not names then return false,err end
        local items={};for _,item in ipairs(names)do items[#items+1]=item end
        return true,'Pull exclusions ('..scope..', '..#items..'): '..(#items>0 and table.concat(items,', ') or 'none')
    end
    if name:lower()=='<t>' then local target=windower.ffxi.get_mob_by_target('t');name=target and target.name or ''end
    if name=='' then return false,'Select a target or specify an exclusion name'end
    local already=false
    local ok,err=self:edit_pull(function(p)
        -- Rebuild as a proper Windower list: table.insert alone does not
        -- maintain L{}'s internal length in legacy job settings.
        local names=L{}
        for _,item in ipairs(p.Blacklist or {})do
            names:append(item);if item:lower()==name:lower()then already=true end
        end
        if not already then names:append(name)end
        p.Blacklist=names
    end)
    if not ok then return false,err end
    return true,(already and 'Already excluded ' or 'Saved exclusion ')..name..' ('..scope..')'
end

-- // trust pull delay <seconds>
function PullTrustCommands:handle_delay(_,value)
    local delay=tonumber(value)
    if not delay or delay<0 or delay>50 then return false,'Delay must be 0-50 seconds'end
    local ok,err=self:edit_pull(function(p)p.Delay=delay end)
    return ok,ok and ('Pull delay set to '..delay..' seconds') or err
end

-- // trust pull randomize <true|false>
function PullTrustCommands:handle_set_randomize(_, value)
    if value ~= "true" and value ~= "false" then
        return false, 'Usage: // trust pull randomize <true|false>'
    end

    local enabled = value == "true"
    self:get_settings().PullSettings.RandomizeTarget = enabled
    self:get_pull_owner():saveSettings(true)

    return true, 'Pull randomization: '..(enabled and 'ON' or 'OFF')
end

-- // trust pull [auto, party, all]
function PullTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
    local success = true
    local message

    local mode_var = get_state(mode_var_name)
    if mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end

    return success, message
end

return PullTrustCommands
