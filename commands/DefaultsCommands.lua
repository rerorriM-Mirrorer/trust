local TrustCommands=require('cylibs/trust/commands/trust_commands')
local Starter=require('settings/starter_modes')
local Defaults=setmetatable({}, {__index=TrustCommands})
Defaults.__index=Defaults
Defaults.__class='DefaultsCommands'
function Defaults.new(job,modes)
    local self=setmetatable(TrustCommands.new(),Defaults)
    self.job,self.modes=job,modes
    self:add_command('default',self.handle_status,'Show the starter defaults; does not change settings')
    self:add_command('status',self.handle_status,'Show the starter defaults')
    self:add_command('apply',self.handle_apply,'Apply and save starter modes to the current job/profile')
    return self
end
function Defaults:get_command_name() return 'defaults' end
function Defaults:handle_status()
    return true,'Starter defaults Test 1 | engage Always | heal Emergency | buffs Auto | skillchains/Trusts/shooting Off'..
        (self.job=='SMN' and ' | avatar Carbuncle' or '')..' | apply affects current job/profile only'
end
function Defaults:handle_apply()
    if is_modes_locked() then return false,'Modes are temporarily locked. Stop the current activity before applying defaults.' end
    local changes,err=Starter.apply(self.job,get_state,function(name,value) get_state(name):set(value) end)
    if not changes then return false,err end
    -- This explicit adoption writes even with ordinary command autosave Off.
    -- It changes only named starter keys, retaining all other profile choices.
    local ok,message=self.modes:saveModeChanges(state.TrustMode.value,changes)
    if ok==false then return false,message or 'Unable to save starter defaults.' end
    return true,'Starter modes applied and saved for '..self.job..' / '..state.TrustMode.value..'. Existing pull lists and positioning retained.'
end
return Defaults
