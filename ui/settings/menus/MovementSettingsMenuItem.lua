-- The sender reads the selected policy from Trust's short-lived movement file.
local MenuItem=require('cylibs/ui/menu/menu_item')
local ButtonItem=require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor=require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem=require('ui/settings/editors/config/PickerConfigItem')
local BooleanConfigItem=require('ui/settings/editors/config/BooleanConfigItem')
local ConfigItem=require('ui/settings/editors/config/ConfigItem')
local M={}
function M.new(owner)
    return MenuItem.new(L{ButtonItem.default('Save'),ButtonItem.default('Status'),ButtonItem.default('Stuck Recovery')},{
        Status=MenuItem.action(function()
            local receiver=windower.trust.movement
            addon_system_message('Movement | '..(receiver and receiver:status() or 'initializing'))
        end,'Movement','Show received, accepted and ignored signals.'),
        ['Stuck Recovery']=MenuItem.new(L{ButtonItem.default('Save'),ButtonItem.default('Status')},{
            Status=MenuItem.action(function()
                addon_system_message('Stuck Recovery | '..require('cylibs/movement/recovery').status())
            end,'Stuck Recovery','Current recovery mode and most recent result.')
        },function(_,infoView)
            return ConfigEditor.new(owner,owner:getSettings().movement.recovery,L{
                PickerConfigItem.new('mode','Off',L{'Off','Detour','Pause'},nil,'Recovery'),
                BooleanConfigItem.new('pulling','Recover pulling'),
                BooleanConfigItem.new('following','Recover following'),
                BooleanConfigItem.new('paths','Recover paths'),
                ConfigItem.new('interval',.5,15,.5,function(v)return v..' seconds'end,'Stuck interval'),
                ConfigItem.new('min_movement',.1,3,.1,function(v)return string.format('%.1f yalms',v)end,'Minimum movement'),
                ConfigItem.new('detour_distance',.5,5,.5,function(v)return v..' yalms'end,'Detour distance'),
                ConfigItem.new('attempts',1,4,1,nil,'Maximum detour attempts'),
                ConfigItem.new('pull_cooldown',5,180,5,function(v)return v..' seconds'end,'Pull target cooldown'),
                BooleanConfigItem.new('diagnostics','Write recovery diagnostics'),
            },infoView)
        end,'Stuck Recovery','Try bounded detours, then skip a blocked pull mob or pause following/path. Stop cancels recovery. No terrain route finding.')
    },function(_,infoView)
        return ConfigEditor.new(owner,owner:getSettings().movement,L{
            PickerConfigItem.new('policy','Send',L{'Send','Ready'},nil,'First movement signal'),
            BooleanConfigItem.new('enabled','Movement follow/assist enabled'),
            BooleanConfigItem.new('quiet','Quiet follow/assist feedback'),
            BooleanConfigItem.new('stop_on_movement','Stop my Trust on movement'),
            BooleanConfigItem.new('start_others','Start others after follow/assist'),
            BooleanConfigItem.new('auto_lockon','Automatic lock-on when engaging'),
        },infoView)
    end,'Movement','Send acts once without waiting; Ready waits for readiness. Follow/assist stays enabled independently of local Stop and others Start. Lock-on controls engaging. Switch clients to rearm.')
end
return M
