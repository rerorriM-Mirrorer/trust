-- Actual command registration and HUD open method; no live renderer required.
local source_path=os.getenv('TRUST_MENU_SOURCE') or 'commands/MenuCommands.lua'
local hud_path=os.getenv('TRUST_HUD_SOURCE') or 'ui/TrustHud.lua'
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local commands={}
local base={new=function()return{add_command=function(_,name,fn)commands[name]=fn end}end}
package.loaded['cylibs/trust/commands/trust_commands']=base
package.loaded['cylibs/ui/menu/menu_preferences']={get=function()return true end}
package.loaded['cylibs/ui/menu/menu_save_trace']={entries={}}
local module=assert(load(read(source_path),'actual MenuCommands'))()
local visible,shown,closed,built,discard,fail=false,0,0,0,nil,false
local hud={trustMenu={isVisible=function()return visible end,
    closeAll=function(_,force)closed=closed+1;discard=force;if fail then return false end;visible=false;return true end,
    showMenu=function(_,item)assert(item.id=='main');shown=shown+1;visible=true end},
    getMainMenuItem=function()built=built+1;return{id='main'}end,
    getViewStack=function()return{getCurrentView=function()return nil end}end}
local method=assert(read(hud_path):match('(function TrustHud:openMenu%(menuItem%).-\nend)'))
assert(load(method,'actual HUD open','t',setmetatable({TrustHud=hud},{__index=_G})))()
local menu=module.new({}, {},hud)
assert(commands.open==module.handle_open and commands.close==module.handle_close)
assert(commands.open(menu));assert(visible and shown==1 and closed==1 and built==1)
assert(commands.open(menu));assert(shown==1 and closed==1 and built==1,'open rebuilt current submenu/draft')
local ok,message=commands.close(menu);assert(ok and message==nil and not visible and discard==nil)
assert(commands.open(menu));assert(visible and shown==2 and built==2)
fail=true;ok,message=commands.close(menu)
assert(not ok and message:find('Correct the editor',1,true) and visible,'close discarded invalid draft')
assert(commands.open(menu));assert(shown==2 and built==2,'open disturbed rejected draft')
fail=false;assert(commands.close(menu));assert(not visible)
assert(commands.close(menu));assert(not visible and shown==2)
local _,status=commands.status(menu);assert(status:find('explicit open: true',1,true))
-- Route through the actual Trust dispatcher too, so 'open' cannot fall through
-- to the older default/toggle callback. Case folding remains the base's policy.
local dispatch_path=os.getenv('TRUST_COMMAND_SOURCE') or 'cylibs/trust/commands/trust_commands.lua'
local mt={__index={unpack=function(self)return table.unpack(self)end}}
T=function(t)return setmetatable(t or {},mt)end;L=T;unpack=table.unpack
package.loaded['cylibs/util/command_feedback']={is_quiet=function()return false end,
    run=function(_,fn)return fn()end}
package.loaded['cylibs/trust/commands/trust_commands']=assert(load(read(dispatch_path),'actual Trust dispatcher'))()
local direct=assert(load(read(source_path),'actual MenuCommands with dispatcher'))().new({}, {},hud)
local errors={};addon_message=function()end;addon_system_error=function(s)errors[#errors+1]=s end
visible=false;local old_shown=shown
assert(direct:handle_command('open') and visible and shown==old_shown+1)
assert(direct:handle_command('OPEN') and shown==old_shown+1)
assert(direct:handle_command('close') and not visible)
assert(direct:handle_command('open') and visible)
fail=true;assert(direct:handle_command('close') and visible and #errors==1)
fail=false
print('Actual Trust menu command/HUD: explicit registration, once-only open, visible submenu/draft preservation, close/save validation and capability status passed.')
