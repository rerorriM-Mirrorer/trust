-- Execute real root helpers and dispatcher, including nested quiet/error paths.
local lines={}
windower={add_to_chat=function(c,s)assert(c==0);lines[#lines+1]=s end}
package.loaded.chat={}
string.color=function(s,c)return'<'..c..'>'..s end
local f=assert(io.open('Trust.lua'));local root=f:read('*a');f:close()
assert(load(assert(root:match('(function addon_message.-)\n%-%- Handlers'))))()
local Base=require('cylibs/trust/commands/trust_commands')
unpack=unpack or table.unpack
local c=setmetatable({__class='GeneralTrustCommands',get_command_name=function()return'default'end,commands={
 active={callback=function()return true,'Active'end},
 paused={callback=function()return true,'Paused'end},
 assist={callback=function()return true,'Assisting: Cioara'end},
 follow={callback=function()return true,'Following: Myrr'end},
 burst={callback=function()return true,'Magic Burst: Fire ON'end},
 failure={callback=function()return false,'Cannot assist.'end},
 emptyfailure={callback=function()return false end},
 request={callback=function()return true,'Pause - Requested on all clients.'end},
 none={callback=function()return true end},
}},{__index=Base})
assert(c:handle_command('active'));assert(lines[#lines]=='<200>[Trust] <158>Active')
c:handle_command('paused');assert(lines[#lines]=='<200>[Trust] <167>Paused')
c:handle_command('assist');assert(lines[#lines]=='<200>[Trust] <167>Assisting: <0>Cioara')
c:handle_command('follow');assert(lines[#lines]=='<200>[Trust] <167>Following: <0>Myrr')
c:handle_command('burst');assert(lines[#lines]=='<200>[Trust] <167>Magic Burst: <0>Fire <158>ON')
c:handle_command('request');assert(lines[#lines]=='<200>[Trust] <0>Pause - Requested on all clients.')
c:handle_command('failure');assert(lines[#lines]=='<200>[Trust] <167>Cannot assist.')
c:handle_command('emptyfailure');assert(lines[#lines]=='<200>[Trust] <167>Command failed')
local Feedback=require('cylibs/util/command_feedback');local count=#lines
Feedback.run(true,function()c:handle_command('assist')end);assert(#lines==count)
Feedback.run(true,function()c:handle_command('failure')end);assert(#lines==count+1)
c:handle_command('none');assert(#lines==count+1)
for _,line in ipairs(lines)do assert(not line:find('TrustCommands',1,true) and not line:find('..',1,true))end
-- Root systems/status helpers also use the label, and alternate States loading
-- cannot restore the legacy Trust: prefix.
addon_system_message('Log filter: None');assert(lines[#lines]=='<200>[Trust] <167>Log filter: <0>None')
local s=assert(io.open('cylibs/util/States.lua')):read('*a')
assert(load(assert(s:match('(function addon_message.-)\nend'))..'\nend'))()
addon_message(207,'Active');assert(lines[#lines]=='<200>[Trust] <158>Active')
print('PASS labeled feedback, state/name colors, no class names, unchanged punctuation, quiet successes/errors and alternate helper')
