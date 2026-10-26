-- A: the standard full editor with a factory-file owner instead of a profile.
local Editor=require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local MenuItem=require('cylibs/ui/menu/menu_item')
local Shared=require('settings/shared_job_gambits')
local Style=require('ui/settings/menus/gambits/GambitEditorStyle')
local M={}
function M.new(trust,owner,_,modeSettings)
    local shared,err=Shared.new(owner)
    local scope='Shared '..owner.jobNameShort..' Job rules for all characters/profiles in this installation. Other clients reload Trust to update.'
    if not shared then
        return MenuItem.action(function()addon_system_error(err)end,'Job (shared)',scope..' Unable to read the shared file.')
    end
    local editor=Editor.new(trust,shared,{value='Default'},modeSettings,'GambitSettings',nil,nil,nil,Style.named('Shared Job gambit','Shared Job gambits'))
    editor.titleText='Job (shared)'
    editor.descriptionText=scope
    editor:setChildMenuItem('Reload',MenuItem.action(function(menu)
        local ok,why=pcall(function()shared:reloadSettings()end)
        if not ok then addon_system_error(tostring(why));return end
        menu:showMenu(editor)
    end,'Reload shared Job rules','Discard this draft and read the latest shared rules.'))
    local toggle=editor:getChildMenuItem('Toggle')
    if toggle then toggle.descriptionText='Enable or disable this shared Job rule permanently.'end
    local reset=editor:getChildMenuItem('Reset')
    if reset then reset.descriptionText='Restore original factory Job gambits for everyone in this installation.'end
    return editor
end
return M
