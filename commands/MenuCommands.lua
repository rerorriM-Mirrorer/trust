local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MenuPreferences = require('cylibs/ui/menu/menu_preferences')
local SaveTrace = require('cylibs/ui/menu/menu_save_trace')
local MenuTrustCommands = setmetatable({}, {__index = TrustCommands })
MenuTrustCommands.__index = MenuTrustCommands
MenuTrustCommands.__class = "MenuTrustCommands"

function MenuTrustCommands.new(trust, action_queue, hud)
    local self = setmetatable(TrustCommands.new(), MenuTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.hud = hud

    self:add_command('default', self.handle_toggle_menu, 'Show and hide the Trust menu')
    self:add_command('close', self.handle_close, 'Save eligible options and close all Trust menus')
    self:add_command('discard', self.handle_discard, 'Close menus without applying the pending editor draft')
    self:add_command('status', self.handle_status, 'Show menu test build and saved preferences')
    self:add_command('trace', self.handle_trace, 'Trace menu saves: //trust menu trace [on|off|status|dump|clear]')

    return self
end

function MenuTrustCommands:handle_close()
    local success = self.hud.trustMenu:closeAll()
    return success ~= false, success == false and 'Correct the editor or use //trust menu discard.' or nil
end

function MenuTrustCommands:handle_discard()
    self.hud.trustMenu:closeAll(true)
    return true
end

function MenuTrustCommands:handle_status()
    local view = self.hud:getViewStack():getCurrentView()
    local editorStatus = view and view.exitSaveStatus and view:exitSaveStatus() or 'no eligible editor'
    return true, string.format('Menu options Test 4 (20261018) | save on exit: %s | adjacent: %s | IJKL: %s | editor: %s',
        tostring(MenuPreferences.get('save_on_exit')), tostring(MenuPreferences.get('adjacent')),
        tostring(MenuPreferences.get('ijkl')), editorStatus)
end

function MenuTrustCommands:handle_trace(_, action)
    action=type(action)=='string' and action:lower() or 'status'
    if action=='on' or action=='off' then
        SaveTrace.setEnabled(action=='on')
        local view=self.hud:getViewStack():getCurrentView()
        if SaveTrace.enabled and view and view.exitSaveStatus then
            SaveTrace.editor(view,'current-editor',view:exitSaveStatus(),view:readDraft())
        end
    elseif action=='clear' then SaveTrace.clear()
    elseif action=='dump' then return SaveTrace.dump()
    elseif action~='status' then return false,'Usage: //trust menu trace [on|off|status|dump|clear]' end
    return true,'Menu save trace '..(SaveTrace.enabled and 'ON' or 'OFF')..' | retained events: '..#SaveTrace.entries
end

function MenuTrustCommands:get_command_name()
    return 'menu'
end

-- // trust menu
function MenuTrustCommands:handle_toggle_menu(configKey)
    local success = true
    local message

    coroutine.schedule(function()
        local menuItem = self.hud:getMenuItem(configKey)
        if menuItem then
            self.hud:openMenu(menuItem)
        else
            self.hud:toggleMenu()
        end
    end, 0.2)

    return success, message
end

return MenuTrustCommands
