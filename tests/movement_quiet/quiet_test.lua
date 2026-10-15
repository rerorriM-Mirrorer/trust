-- Actual Trust command/role methods with Windower and movement hardware mocked.
-- Run from repository root: luatex --luaonly tests/movement_quiet/quiet_test.lua
unpack = unpack or table.unpack
local count, notices, chatter, errors, relayed, mode_notices = 0, {}, {}, {}, {}, 0
local function check(value, description)
    count=count+1; assert(value, 'FAIL: '..description)
end
local function list(t)
    return setmetatable(t or {}, {__index={
        unpack=function(self) return unpack(self) end,
        map=function(self, fn) local out={}; for _,v in ipairs(self) do out[#out+1]=fn(v) end; return list(out) end,
        contains=function(self, value) for _,v in ipairs(self) do if v==value then return true end end; return false end,
        it=function(self) local i=0; return function() i=i+1; return self[i] end end,
    }})
end
T, L = list, list
ConfigItem={new=function() return {} end}
Role={}
M=function(values)
    return {value=values[1], set_description=function() end, set=function(self,v) self.value=v end}
end
local function member(name,id)
    return {get_name=function() return name end, get_id=function() return id end}
end
local myrr, cioara = member('Myrr',1), member('Cioara',2)
local current_name='Myrr'
windower={ffxi={get_player=function() return {name=current_name, id=current_name=='Myrr' and 1 or 2} end}}
addon_message=function(_,message) notices[#notices+1]=message end
addon_system_message=function(message) notices[#notices+1]=message end
addon_system_error=function(message) errors[#errors+1]=message end
local feedback=require('cylibs/util/command_feedback')
local Base=require('cylibs/trust/commands/trust_commands')
local function load_windower(path)
    local file=assert(io.open(path,'r')); local source=file:read('*a'); file:close()
    -- Trust's existing Windower Lua dialect permits "literal":format(...).
    -- Parenthesize those literals only for this standard Lua test runtime.
    source=source:gsub('("[^"\n]*"):(%a+)%(',function(literal,method)
        return '('..literal..'):'..method..'('
    end)
    return assert((loadstring or load)(source,'@'..path))()
end
-- Unused class dependencies are isolated. Real command/role modules below
-- are loaded explicitly; this test does not replace their edited methods.
setmetatable(package.preload,{__index=function(_,name) return function() return {} end end})
package.preload['cylibs/messages/command_message']=function() return {new=function(command) return {command=command} end} end
package.preload['ui/settings/editors/config/PickerConfigItem']=function() return {new=function() return {} end} end
package.preload['cylibs/logger/logger']=function() return {error=function() end} end
IpcRelay={shared=function() return {send_message=function(_,msg) relayed[#relayed+1]=msg.command end} end}
state={IpcMode={value='All'}}
local Follower=load_windower('cylibs/trust/roles/follower.lua')
local Party=load_windower('cylibs/entity/party.lua')
local Pather=load_windower('cylibs/trust/roles/pather.lua')
local Follow=load_windower('commands/FollowCommands.lua')
local Assist=load_windower('commands/AssistCommands.lua')
local party=setmetatable({party_target={set_assist_target=function() end}}, {__index=Party})
party.add_to_chat=function(_,_,message) chatter[#chatter+1]=message end
party.get_player=function() return myrr end
party.get_party_members=function() return list({myrr,cioara}) end
party.on_party_members_changed=function() return {addAction=function() end} end
party.on_party_assist_target_change=function() return {trigger=function() end} end
local alliance={get_alliance_member_named=function(_,name) if name=='Myrr' then return myrr elseif name=='Cioara' then return cioara end end}
local follow_target
local follower=setmetatable({}, {__index=Follower})
follower.get_alliance=function() return alliance end
follower.get_party=function() return party end
follower.is_valid_target=function(_,name) return name=='Myrr' or name=='Cioara' end
follower.set_follow_target=function(_,value) follow_target=value end
follower.start_following=function() end
local trust={get_party=function() return party end, get_alliance=function() return alliance end,
    role_with_type=function(_,name) if name=='follower' then return follower end end}
get_state=function(name) return state[name] end
handle_set=function(name,value) mode_notices=mode_notices+1; state[name]:set(value) end

local follow=Follow.new(trust,{})
local assist=Assist.new(trust,{})
follow:handle_command('me','--quiet')
check(follow_target==nil,'quiet follow me clears local follow target')
check(relayed[#relayed]=='trust follow Myrr --quiet','follow quiet flag reaches remote command')
check(#notices==0,'quiet leader acknowledgment suppressed')
follow:handle_command('me')
check(relayed[#relayed]=='trust follow Myrr','ordinary follow broadcast unchanged')
check(#notices==1,'ordinary leader acknowledgment retained')
assist:handle_command('me','--QUIET')
check(relayed[#relayed]=='trust assist Myrr --quiet','assist quiet flag propagated case-insensitively')
local n,c,m=#notices,#chatter,mode_notices
follow:handle_command('Cioara','--quiet')
check(follow_target==cioara,'quiet recipient actually follows target')
check(state.AutoFollowMode.value=='Always','quiet follow still enables follow mode')
check(#notices==n and #chatter==c and mode_notices==m,'quiet recipient hides acknowledgment/chatter/mode help')
follow:handle_command('Cioara')
check(#notices==n+1 and #chatter==c+1 and mode_notices==m+1,'manual follow keeps all normal feedback')
n,c=#notices,#chatter
assist:handle_command('Cioara','--quiet')
check(party.assist_target==cioara,'quiet recipient actually changes assist target')
check(#notices==n and #chatter==c,'quiet assist confirmation/chatter suppressed')
assist:handle_command('Cioara','--quiet')
check(#chatter==c,'already-assisting chatter also quiet')
assist:handle_command('Cioara')
check(#chatter==c+1,'manual already-assisting chatter retained')
local e=#errors
follow:handle_command('Missing','--quiet')
check(#errors==e+1,'invalid quiet follow remains visible as an error')
state.IpcMode.value='Off'; e=#errors
assist:handle_command('me','--quiet')
check(#errors==e+1,'quiet IPC configuration failure remains visible')
state.IpcMode.value='All'
local pather=setmetatable({follower=follower}, {__index=Pather})
n=#notices
feedback.run(true,function() pather:stop(true); return true end)
check(#notices==n,'takeover-induced path-cleared notice quiet')
pather:stop(true)
check(#notices==n+1,'ordinary path-cleared notice retained')
local normal=Base.new(); normal.get_command_name=function() return 'send' end
local received_arg
normal:add_command('default',function(_,name,argument) received_arg=argument; return true,'sent' end)
normal:handle_command('Cioara','--quiet')
check(received_arg=='--quiet','other command groups preserve literal quiet argument')
check(not feedback.is_quiet(),'scope restored after ordinary/quiet operations')
local ok=pcall(function() feedback.run(true,function() error('controlled failure') end) end)
check(not ok and not feedback.is_quiet(),'scope restored after thrown error')
feedback.run(true,function()
    feedback.run(true,function() check(feedback.is_quiet(),'nested scope is quiet'); return true end)
    check(feedback.is_quiet(),'outer scope survives nested return')
    return true
end)
check(not feedback.is_quiet(),'nested scope fully restored')
print('PASS: '..count..' Trust quiet integration assertions')
