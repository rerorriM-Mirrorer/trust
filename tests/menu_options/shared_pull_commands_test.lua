local list={};function list:append(v)self[#self+1]=v;return self end
L=function(t)return setmetatable(t or {},{__index=list})end
T=L
local data={Pulling={Targets={},TargetIds={},Blacklist={},Distance=30,Delay=0},Sounds={disabled=true}}
local saved,revision,legacy=true,0,false
local store={read=function()return data,tostring(revision)end,update=function(_,section,value,expected)
    if not saved then return false,'save failed'end
    assert(not expected or expected.source==tostring(revision));data[section]=value;revision=revision+1;return true
end}
package.loaded['settings/shared_preferences']={shared=function()return store end,enabled=function()return not legacy end}
local modes={}
package.loaded['cylibs/trust/commands/trust_commands']={new=function()return{
    commands={},add_command=function(self,k,fn)self.commands[k]=fn end,
    handle_set_mode=function(_,name,value)modes[name]=value;return true end,
}end}
package.loaded['cylibs/trust/commands/gambit_commands']={register=function(self)self.commands.add='existing ability command'end}
package.loaded['cylibs/gambits/gambit_target']={TargetType={Enemy='Enemy'}}
package.loaded['ui/settings/editors/config/PickerConfigItem']={new=function()end}
local raw={Targets=L{'legacy'},Blacklist=L{},Distance=12,Delay=2,Gambits={'job action'}}
local writes=0
local owner={getSettings=function()return{Default={PullSettings=raw}}end,saveSettings=function()writes=writes+1;return true end}
state={MainTrustSettingsMode={value='Default'}}
windower={ffxi={get_mob_by_target=function()return{name='Goblin Weaver'}end}}
local Commands=require('commands/PullCommands')
local cmd=Commands.new({},owner,{}, {})
assert(cmd.commands.add=='existing ability command' and cmd.commands.target and cmd.commands.distance)
assert(cmd:handle_target(nil,'add','Mandragora') and modes.AutoPullMode=='Auto')
assert(cmd:handle_target(nil,'add','mandragora') and #data.Pulling.Targets==1)
assert(cmd:handle_target(nil,'add','<t>') and #data.Pulling.Targets==2)
assert(cmd:handle_target(nil,'remove','MANDRAGORA') and data.Pulling.Targets[1]=='Goblin Weaver')
assert(cmd:handle_distance(nil,'31.5') and data.Pulling.Distance==31.5)
assert(not cmd:handle_distance(nil,'51'))
assert(cmd:handle_ignore(nil,'Goblin','Smithy') and data.Pulling.Blacklist[1]=='Goblin Smithy')
assert(cmd:handle_delay(nil,'4') and data.Pulling.Delay==4)
assert(cmd:handle_target(nil,'clear') and #data.Pulling.Targets==0)
modes.AutoPullMode='Off';saved=false;assert(not cmd:handle_target(nil,'add','Bee') and modes.AutoPullMode=='Off');saved=true
assert(writes==0 and raw.Distance==12 and raw.Gambits[1]=='job action')
legacy=true;assert(cmd:handle_distance(nil,'19') and raw.Distance==19 and writes==1)
-- Sound command writes shared state before changing the player.
local player={enabled=false,isEnabled=function(self)return self.enabled end,setEnabled=function(self,v)self.enabled=v end}
local sound=require('commands/SoundCommands').new(player)
assert(sound:handle_set_sound_enabled(true) and player.enabled and not data.Sounds.disabled)
saved=false;assert(not sound:handle_set_sound_enabled(false) and player.enabled)
print('PASS pulling/sound commands: preserved action commands, target add/remove/clear, local activation, ranges, exclusions, delay, shared-vs-legacy writes and sound save failure')
