local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitLibraryMenuItem = setmetatable({}, {__index = MenuItem })
GambitLibraryMenuItem.__index = GambitLibraryMenuItem

function GambitLibraryMenuItem.new(trustSettings, trustSettingsMode, categoryFilter, settingsKeys)
    categoryFilter = categoryFilter or function(_) return true end

    local gambitCategories = GambitLibraryMenuItem.getGambitCategories()

    local categories = gambitCategories:filter(function(category)
        return categoryFilter(category)
    end)

    local buttonItems = L(categories:map(function(category)
        return ButtonItem.default(category:getName(), 18)
    end))

    local self = setmetatable(MenuItem.new(buttonItems, {}, nil, "Gambits", "Browse pre-made gambits."), GambitLibraryMenuItem)

    for category in categories:it() do
        self:setChildMenuItem(category:getName(), GambitLibraryMenuItem.getGambitCategoryMenuItem(category, function(gambit)
            local settings = self.trustSettings:getSettings()[self.trustSettingsMode.value]
            for settingsKey in self.settingsKeys:it() do
                settings = settings[settingsKey]
            end
            settings.Gambits:append(gambit)
        end, function()
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll add this gambit to my list!")
        end))
    end

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKeys = settingsKeys or L{ 'GambitSettings' }
    self.disposeBag = DisposeBag.new()

    self.enabled = function()
        return categories:length() > 0
    end

    return self
end

function GambitLibraryMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function GambitLibraryMenuItem.getGambitCategories()
    return require('ui/settings/menus/gambits/library/GambitLibrary')
end

function GambitLibraryMenuItem.getGambitCategoryMenuItem(category, addGambit, finishAdding)
    local direct = finishAdding == nil
    local buttons = L{ ButtonItem.localized('Filter', i18n.translate('Button_Filter')) }
    if not direct then
        buttons = L{
            ButtonItem.default('Confirm', 18),
            ButtonItem.localized('Clear All', i18n.translate('Button_Clear_All')),
        } + buttons
    end
    return MenuItem.new(buttons, {}, function(_, _, showMenu)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, category:getGambits(), function(gambit)
            return gambit:tostring()
        end, "", nil, nil, function(gambit)
            return gambit:tostring()
        end)
        configItem:setNumItemsRequired(1, direct and 1 or 999)

        local gambitList = FFXIPickerView.new(configItem, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge, 17)
        if direct then
            gambitList:setPickOnSelect(true)
        end

        gambitList:getDisposeBag():add(gambitList:on_pick_items():addAction(function(_, gambits)
            for gambit in gambits:it() do
                addGambit(gambit:copy(), showMenu)
            end
            if finishAdding then
                finishAdding()
            end
        end), gambitList:on_pick_items())

        gambitList:setNeedsLayout()
        gambitList:layoutIfNeeded()

        return gambitList
    end, category:getName(), category:getDescription())
end

return GambitLibraryMenuItem
