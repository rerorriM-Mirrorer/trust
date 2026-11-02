-- A: Recovery has its own Config entry; storage remains character-wide.
local MenuItem=require('cylibs/ui/menu/menu_item')
local ButtonItem=require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor=require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem=require('ui/settings/editors/config/PickerConfigItem')
local BooleanConfigItem=require('ui/settings/editors/config/BooleanConfigItem')
local ConfigItem=require('ui/settings/editors/config/ConfigItem')
local M={}
function M.new(owner)
    return MenuItem.new(L{ButtonItem.default('Save'),ButtonItem.default('Status')},{
            Status=MenuItem.action(function()
                addon_system_message('Recovery | '..require('cylibs/movement/recovery').status())
            end,'Recovery','Current recovery mode and most recent result.')
        },function(_,infoView)
            local values=owner:getSettings().movement.recovery
            return ConfigEditor.new(owner,owner:getSettings().movement.recovery,L{
                PickerConfigItem.new('mode',values.mode or 'Off',L{'Off','Detour','Pause'},nil,'Recovery'),
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
        end,'Recovery','Try bounded detours, then skip a blocked pull mob or pause following/path. Stop cancels recovery. No terrain route finding.')
end
return M
