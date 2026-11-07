local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIFastPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitLibraryMenuItem = {}

function GambitLibraryMenuItem.getGambitCategories()
    return require('ui/settings/menus/gambits/library/GambitLibrary')
end

local function pickerMenu(title, description, categories, showCategory, addGambit)
    return MenuItem.new(L{
        ButtonItem.localized('Filter', i18n.translate('Button_Filter')),
    }, {}, function(_, _, showMenu)
        local entries = L{}
        for category in categories:it() do
            for gambit in category:getGambits():it() do
                entries:append({ gambit = gambit, category = category:getName() })
            end
        end

        local configItem = MultiPickerConfigItem.new("Gambits", L{}, entries, function(entry)
            local label = entry.gambit:tostring()
            return showCategory and "["..entry.category.."] "..label or label
        end, "", nil, nil, function(entry)
            return entry.gambit:tostring()
        end)
        configItem:setNumItemsRequired(1, 1)

        local picker = FFXIFastPickerView.new(configItem, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge, 17)
        picker:setPickOnSelect(true)
        picker:getDisposeBag():add(picker:on_pick_items():addAction(function(_, items)
            if items[1] then
                addGambit(items[1].gambit:copy(), showMenu)
            end
        end), picker:on_pick_items())
        picker:setNeedsLayout()
        picker:layoutIfNeeded()
        return picker
    end, title, description)
end

function GambitLibraryMenuItem.new(categoryFilter, addGambit)
    local categories = GambitLibraryMenuItem.getGambitCategories():filter(categoryFilter or function() return true end)
    if categories:length() == 0 then return nil end
    return pickerMenu("Gambits", "Choose a preset gambit.", categories, true, addGambit)
end

function GambitLibraryMenuItem.getGambitCategoryMenuItem(category, addGambit)
    return pickerMenu(category:getName(), category:getDescription(), L{ category }, false, addGambit)
end

return GambitLibraryMenuItem
