-- Movement options. Order and wording follow the user's requested layout.
local MenuItem=require('cylibs/ui/menu/menu_item')
local ButtonItem=require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor=require('ui/settings/editors/config/ConfigEditor')
local BooleanConfigItem=require('ui/settings/editors/config/BooleanConfigItem')
local M={}
function M.new(owner)
    return MenuItem.new(L{ButtonItem.default('Save'),ButtonItem.default('Status')},{
        Status=MenuItem.action(function()
            local receiver=windower.trust.movement
            addon_system_message('Movement | '..(receiver and receiver:status() or 'initializing'))
        end,'Movement','Show received, accepted and ignored signals.'),

    },function(_,infoView)
        return ConfigEditor.new(owner,owner:getSettings().movement,L{
            BooleanConfigItem.new('stop_on_movement','Pause on movement'),
            BooleanConfigItem.new('enabled','Request follow'),
            BooleanConfigItem.new('assist_others','Request assist'),
            BooleanConfigItem.new('start_others','Request others act'),
            BooleanConfigItem.new('feedback','Request feedback'),
            BooleanConfigItem.new('auto_lockon','Automatic lock-on when engaging'),
            BooleanConfigItem.new('keep_autorun','Keep autorun on stick movement'),
            BooleanConfigItem.new('autorun_messages','Autorun on/off messages'),
        },infoView)
    end,'Movement','What happens when you take over with the stick. Client/Neutral arming is selected in XIVCrossbar. Follow, Assist and Act are independent requests to your other characters.')
end
return M
