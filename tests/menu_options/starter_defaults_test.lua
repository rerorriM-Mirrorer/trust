-- Actual starter policy/command; runtime mode callbacks and disk writes mocked.
local Starter=require('settings/starter_modes')
local modes,sets,writes={},0,{}
for name,value in pairs(Starter.values('SMN')) do
    local old=value=='Off' and 'Auto' or 'Off'
    modes[name:lower()]={value=old,options=function()return {'Off','Auto','Always','Emergency','Carbuncle'} end,
        set=function(self,v)self.value=v;sets=sets+1 end}
end
function get_state(name)return modes[name:lower()]end
local locked=false
function is_modes_locked()return locked end
state={TrustMode={value='MyProfile'}}
package.loaded['cylibs/trust/commands/trust_commands']={new=function()return {add_command=function()end}end}
local Defaults=require('commands/DefaultsCommands')
local owner={saveModeChanges=function(_,name,changes)writes[#writes+1]={name,changes};return true end}
local command=Defaults.new('SMN',owner)
locked=true;assert(not command:handle_apply() and sets==0 and #writes==0)
locked=false
local original=modes.autoavatarmode.options
modes.autoavatarmode.options=function()return {'Off'}end
assert(not command:handle_apply() and sets==0 and #writes==0,'partial application before validation')
modes.autoavatarmode.options=original
assert(command:handle_apply() and sets==7 and #writes==1)
assert(writes[1][1]=='MyProfile' and writes[1][2].autoavatarmode=='Carbuncle')
assert(writes[1][2].autoengagemode=='Always' and writes[1][2].autohealmode=='Emergency')
assert(not writes[1][2].combatmode and not writes[1][2].autopullmode and not writes[1][2].autofollowmode)
assert(command:handle_apply() and sets==7 and #writes==2,'idempotent apply retriggered modes')
assert(writes[2][2].autoengagemode=='Always','unchanged live value not persisted on explicit adoption')
assert(not Starter.values('WHM').AutoAvatarMode)
local policy=require('cylibs/ui/menu/menu_command_policy')
assert(policy.effect('defaults',{})=='immediate')
assert(policy.effect('defaults',{'status'})=='immediate')
assert(policy.effect('defaults',{'apply'})=='commit')
assert(policy.effect('defaults',{'bad'})=='blocked')
-- Factory sets execute without invoking game APIs. Test all 22 job defaults
-- against the same public starter policy rather than assuming one tested job.
local jobs={'WAR','MNK','WHM','BLM','RDM','THF','PLD','DRK','BST','BRD','RNG','SAM','NIN','DRG','SMN','BLU','COR','PUP','DNC','SCH','GEO','RUN'}
for _,job in ipairs(jobs)do
    local factory=assert(loadfile('settings/default/modes/'..job..'.lua'))().Default
    for name,value in pairs(Starter.values(job))do assert(factory[name:lower()]==value,job..' '..name)end
end
print('Starter defaults: all 22 factory mode sets, validation-before-mutation, lock refusal, exact profile delta, explicit save, idempotence, SMN isolation and menu policy passed.')
