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
            PickerConfigItem.new('policy',values.policy or 'Send',L{'Send','Ready'},nil,'Delivery policy (advanced)'),
            BooleanConfigItem.new('enabled','Request follow on movement'),
            BooleanConfigItem.new('quiet','Quiet movement follow feedback'),
            BooleanConfigItem.new('stop_on_movement','Pause my Trust on movement'),
            BooleanConfigItem.new('start_others','Act others on movement'),
            BooleanConfigItem.new('assist_others','Request assist on movement'),
            BooleanConfigItem.new('auto_lockon','Automatic lock-on when engaging'),
        },infoView)
    end,'Movement','Send attempts each fresh signal; Ready checks receiver readiness first. Client/Neutral arming is selected in XIVCrossbar. Follow, Assist and Act are independent.')
end
return M
