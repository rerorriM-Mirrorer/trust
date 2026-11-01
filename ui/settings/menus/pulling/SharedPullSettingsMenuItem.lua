local MenuItem=require('cylibs/ui/menu/menu_item')
local ButtonItem=require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor=require('ui/settings/editors/config/ConfigEditor')
local ConfigItem=require('ui/settings/editors/config/ConfigItem')
local BooleanConfigItem=require('ui/settings/editors/config/BooleanConfigItem')
local Shared=require('settings/shared_preferences')
local DisposeBag=require('cylibs/events/dispose_bag')
local M={}
function M.new(addonSettings,trust,jobOwner,jobMode,modes)
    local menu=MenuItem.new(L{}, {},nil,'Pulling (shared)','Targets, exclusions and distance shared by this installation. Pulling modes remain individual.')
    menu.disposeBag=DisposeBag.new()
    menu.destroy=function(self)self.disposeBag:destroy();MenuItem.destroy(self)end
    local function rebuild()
        local owner,err=Shared.shared():owner('Pulling')
        if not owner then addon_system_error(err);return end
        menu.disposeBag:destroy();menu.disposeBag=DisposeBag.new()
        for name,child in pairs(menu.childMenuItems)do
            if name~='Reload' then if child.destroy then child:destroy()end;menu.childMenuItems[name]=nil end
        end
        local mode={value='Default'}
        local old=require('ui/settings/menus/pulling/PullSettingsMenuItem')
        local helper=setmetatable({trust_settings=owner,trust_settings_mode=mode,dispose_bag=menu.disposeBag}, {__index=old})
        menu:setChildMenuItem('Targets',require('ui/settings/menus/pulling/PullTargetsMenuItem').new(owner,mode))
        menu:setChildMenuItem('Target IDs',require('ui/settings/menus/pulling/PullTargetIDsMenuItem').new(owner,mode))
        menu:setChildMenuItem('Exclusions',helper:getBlacklistMenuItem())
        menu:setChildMenuItem('Config',MenuItem.new(L{ButtonItem.default('Save')},{},function(_,info)
            return ConfigEditor.new(owner,owner:getSettings().Default.PullSettings,L{
                ConfigItem.new('Distance',0,50,1,function(v)return v..' yalms'end,'Detection distance'),
                ConfigItem.new('Delay',0,50,1,function(v)return v..' seconds'end,'Delay between pulls'),
            },info)
        end,'Shared Pulling config','Applies across jobs and characters using this installation.'))
        menu:setChildMenuItem('Source',MenuItem.new(L{ButtonItem.default('Save')},{},function(_,info)
            return ConfigEditor.new(addonSettings,addonSettings:getSettings(),L{BooleanConfigItem.new('use_shared_pulling','Use shared pulling setup on this character')},info)
        end,'Pulling source','Off uses this character\'s existing job/profile lists and configuration. Job actions always remain job-owned.'))
        menu:setChildMenuItem('Import Job',MenuItem.action(function(parent)
            local legacy=jobOwner:getSettings()[jobMode.value].PullSettings
            local value={};for _,k in ipairs({'Targets','TargetIds','Blacklist','Distance','Delay'})do value[k]=legacy[k] or ((k=='Distance' and 30) or (k=='Delay' and 0) or {})end
            local ok,why=Shared.shared():update('Pulling',value)
            if not ok then addon_system_error(why);return end
            rebuild();parent:showMenu(menu)
        end,'Import Job list','Replace shared targets/exclusions/config with this job profile. Does not change its pulling actions or enable pulling.'))
        menu:setChildMenuItem('Clear Targets',MenuItem.action(function(parent)
            local data,source=Shared.shared():read();if not data then addon_system_error(source);return end
            data.Pulling.Targets={};data.Pulling.TargetIds={}
            local ok,err=Shared.shared():update('Pulling',data.Pulling,{source=source})
            if not ok then addon_system_error(err);return end
            rebuild();parent:showMenu(menu)
        end,'Clear shared targets','Empty shared target names and IDs. Exclusions and job actions remain.'))
    end
    menu:setChildMenuItem('Reload',MenuItem.action(function(parent)rebuild();parent:showMenu(menu)end,'Reload Pulling','Discard old editor drafts and read the latest shared setup.'))
    rebuild()
    return menu
end
return M
