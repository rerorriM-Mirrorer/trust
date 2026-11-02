-- The sender reads the selected policy from Trust's short-lived movement file.
local MenuItem=require('cylibs/ui/menu/menu_item')
local ButtonItem=require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor=require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem=require('ui/settings/editors/config/PickerConfigItem')
local BooleanConfigItem=require('ui/settings/editors/config/BooleanConfigItem')
local M={}
function M.new(owner)
    return MenuItem.new(L{ButtonItem.default('Save'),ButtonItem.default('Status')},{
        Status=MenuItem.action(function()
            local receiver=windower.trust.movement
            addon_system_message('Movement | '..(receiver and receiver:status() or 'initializing'))
        end,'Movement','Show received, accepted and ignored signals.'),

    },function(_,infoView)
        local values=owner:getSettings().movement
        return ConfigEditor.new(owner,owner:getSettings().movement,L{
            PickerConfigItem.new('policy',values.policy or 'Send',L{'Send','Ready'},nil,'First movement signal'),
            BooleanConfigItem.new('enabled','Movement follow/assist enabled'),
            BooleanConfigItem.new('quiet','Quiet follow/assist feedback'),
            BooleanConfigItem.new('stop_on_movement','Stop my Trust on movement'),
            BooleanConfigItem.new('start_others','Start others after follow/assist'),
            BooleanConfigItem.new('auto_lockon','Automatic lock-on when engaging'),
        },infoView)
    end,'Movement','Send acts once without waiting; Ready waits for readiness. Follow/assist stays enabled independently of local Stop and others Start. Lock-on controls engaging. Switch clients to rearm.')
end
return M
