-- A: Recovery has its own Config entry; storage remains character-wide.
local MenuItem=require('cylibs/ui/menu/menu_item')
local ButtonItem=require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor=require('ui/settings/editors/config/ConfigEditor')
local BooleanConfigItem=require('ui/settings/editors/config/BooleanConfigItem')
local ConfigItem=require('ui/settings/editors/config/ConfigItem')
local M={}
function M.new(owner)
    return MenuItem.new(L{ButtonItem.default('Save'),ButtonItem.default('Status')},{
            Status=MenuItem.action(function()
                addon_system_message('Recovery | '..require('cylibs/movement/recovery').status())
            end,'Recovery','Most recent recovery result.')
        },function(_,infoView)
            return ConfigEditor.new(owner,owner:getSettings().movement.recovery,L{
                BooleanConfigItem.new('pulling','Recover pulling'),
                BooleanConfigItem.new('following','Recover following'),
                BooleanConfigItem.new('paths','Recover paths'),
                BooleanConfigItem.new('combat','Recover combat positioning'),
                ConfigItem.new('min_movement',.1,3,.1,function(v)return string.format('%.1f yalms',v)end,'Minimum movement'),
                ConfigItem.new('attempts',1,8,1,nil,'Maximum detour attempts'),
                ConfigItem.new('pull_cooldown',5,180,5,function(v)return v..' seconds'end,'Pull target cooldown'),
                -- A: Fan Out stops short of a slot it can't reach after this long without progress.
                ConfigItem.new('settle_time',.3,5,.1,function(v)return string.format('%.1f seconds',v)end,'Fan Out settle time'),
                BooleanConfigItem.new('diagnostics','Write recovery diagnostics'),
                BooleanConfigItem.new('verbose','Show recovery messages'),
            },infoView)
        end,'Recovery','Turn recovery on or off for each situation below. Detours of 3, 6, 9... yalms, checked every second. Then skip a blocked pull mob or pause following/path; combat keeps trying while engaged. Stop cancels recovery. No terrain route finding.')
end
return M
