local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitLibraryMenuItem = require('ui/settings/menus/gambits/GambitLibraryMenuItem')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local ShortcutMenuItem = require('ui/settings/menus/ShortcutMenuItem')

local GambitConditionSettingsMenuItem = require('ui/settings/menus/gambits/GambitConditionSettingsMenuItem')

local GambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
GambitSettingsMenuItem.__index = GambitSettingsMenuItem

function GambitSettingsMenuItem:onGambitChanged()
    return self.gambitChanged
end

function GambitSettingsMenuItem:onGambitCreated()
    return self.gambitCreated
end

function GambitSettingsMenuItem:onSelectGambit()
    return self.gambitSelected
end

function GambitSettingsMenuItem.compact(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKey, abilityTargets, abilitiesForTargets, conditionTargets, modes, abilityCategory, abilityCategoryPlural, libraryCategoryFilter, itemDescription, gambitTagBlacklist)
    local configItemForGambits = function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit, index)
            return gambit:getAbility():get_localized_name(), gambit:isEnabled() and gambit:isValid()
        end, abilityCategoryPlural, nil, function(gambit)
            return AssetManager.imageItemForAbility(gambit:getAbility():get_name())
        end, function(gambit, _)
            if not gambit:isValid() then
                return "Unavailable on current job or settings."
            else
                return gambit:tostring()
            end
        end)
        configItem:setNumItemsRequired(1, 1)
        return L{ configItem }
    end

    local editorStyle = GambitEditorStyle.new(configItemForGambits, nil, abilityCategory, abilityCategoryPlural, itemDescription)

    local self = GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKey, abilityTargets, abilitiesForTargets, conditionTargets, editorStyle, modes, libraryCategoryFilter, gambitTagBlacklist)
    return self
end

function GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKeys, abilityTargets, abilitiesForTargets, conditionTargets, editorStyle, modes, libraryCategoryFilter, gambitTagBlacklist, conditionTypeFilter)
    editorStyle = editorStyle or GambitEditorStyle.new(function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit, _)
            return gambit:tostring(), gambit:isEnabled() and gambit:isValid()
        end, "Gambits", nil, nil, function(gambit, _)
            if not gambit:isValid() then
                return "Unavailable on current job or settings."
            else
                return gambit:tostring()
            end
        end)
        configItem:setNumItemsRequired(1, 1)
        return L{ configItem }
    end, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, "Gambit", "Gambits")
    conditionTypeFilter = conditionTypeFilter or function(_)
        return true
    end

    if class(settingsKeys) ~= 'List' then
        settingsKeys = L{ settingsKeys }
    end

    local self = setmetatable(MenuItem.new(L{}, {}, nil, editorStyle:getDescription(true), "Configure "..editorStyle:getDescription(true)..".", false), GambitSettingsMenuItem)  -- changed keep views to false

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.settingsKeys = settingsKeys
    self.abilityTargets = abilityTargets or L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally, GambitTarget.TargetType.Enemy }-- S(GambitTarget.TargetType:keyset())
    self.abilitiesForTargets = abilitiesForTargets or function(targets)
        return self:getAbilitiesForTargets(targets)
    end
    self.conditionTargets = conditionTargets or L{ Condition.TargetType.Self, Condition.TargetType.Ally, Condition.TargetType.Enemy }
    self.gambitTagBlacklist = gambitTagBlacklist or S{}
    self.editorConfig = editorStyle
    self.modes = modes or L{ 'AutoGambitMode' }
    self.libraryCategoryFilter = libraryCategoryFilter
    self.conditionSettingsMenuItem = GambitConditionSettingsMenuItem.new(self.trustSettings, nil, function()
        return editorStyle:hasEditPermission(self.selectedGambit, GambitEditorStyle.Permissions.Conditions)
    end, conditionTypeFilter)
    self.conditionSettingsMenuItem:setTargetTypes(S(self.conditionTargets))
    self.defaultGambitTags = L{}
    self.gambitChanged = Event.newEvent()
    self.gambitCreated = Event.newEvent()
    self.gambitSelected = Event.newEvent()
    self.disposeBag = DisposeBag.new()

    local updateCurrentGambit = function(cursorIndexPath)
        if cursorIndexPath == nil then
            self.selectedGambit = nil
            return
        end
        local currentGambits = self:getSettings().Gambits

        local selectedGambit = currentGambits[cursorIndexPath.row]
        self.selectedGambit = selectedGambit

        self:onSelectGambit():trigger(self.selectedGambit, cursorIndexPath.row)

        if self.selectedGambit then
            self.conditionSettingsMenuItem:setConditions(function() return selectedGambit.conditions end)
            --self.conditionSettingsMenuItem:setConditions(selectedGambit.conditions:map(function(condition) return condition:getCondition() end)) -- FIXME: condition menu item remove and add doesn't work
            --self.conditionSettingsMenuItem:setTargetTypes(S{ selectedGambit:getConditionsTarget() })
        end
    end

    self.contentViewConstructor = function(_, infoView, _)
        local currentGambits = self:getSettings().Gambits
        
        local configItem = self.editorConfig:getConfigItem(currentGambits)

        local gambitSettingsEditor
        if configItem:length() > 0 then -- FFXIFastPickerView is not ready for use here yet, too many issues
            gambitSettingsEditor = FFXIPickerView.new(configItem, false, self.editorConfig:getViewSize())
        else
            local FFXIFastPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
            gambitSettingsEditor = FFXIFastPickerView.new(configItem[1], self.editorConfig:getViewSize())
        end

        gambitSettingsEditor:setAllowsCursorSelection(true)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(gambitSettingsEditor:didMoveCursorToIndexPath():addAction(function(cursorIndexPath) -- add back _, for FFXIFastPickerView
            updateCurrentGambit(cursorIndexPath)
        end))

        self.gambitSettingsEditor = gambitSettingsEditor

        -- NOTE: needed for self:showMenu(self) in order to call updateCurrentGambit
        if currentGambits:length() > 0 then
            gambitSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
            updateCurrentGambit(IndexPath.new(1, 1))
        end

        return gambitSettingsEditor
    end

    self:reloadSettings()

    return self
end

function GambitSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.gambitChanged:removeAllActions()
    self.gambitCreated:removeAllActions()

    self.disposeBag:destroy()
end

function GambitSettingsMenuItem:getDefaultSettings()
    local defaultSettings = T(self.trustSettings:getDefaultSettings().Default):clone()
    for settingsKey in self.settingsKeys:it() do
        defaultSettings = defaultSettings[settingsKey]
    end
    return defaultSettings
end

function GambitSettingsMenuItem:getSettings(mode)
    mode = mode or self.trustSettingsMode.value
    local settings = self.trustSettings:getSettings()[mode]
    for settingsKey in self.settingsKeys:it() do
        settings = settings[settingsKey]
    end
    return settings
end

function GambitSettingsMenuItem:setChildMenuItem(text, childMenuItem)
    -- TODO: localize these
    if self.editorConfig:allowsAction(text) then
        MenuItem.setChildMenuItem(self, text, childMenuItem)
    end
end

function GambitSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Edit", self:getEditGambitMenuItem())
    if self.buffTargetEditor then
        self:setChildMenuItem("Copy", self:getCopyGambitMenuItem())
        self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
    else
        self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
        self:setChildMenuItem("Copy", self:getCopyGambitMenuItem())
    end
    self:setChildMenuItem("Move Up", self:getMoveUpGambitMenuItem())
    self:setChildMenuItem("Move Down", self:getMoveDownGambitMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleMenuItem())
    self:setChildMenuItem("Reset", self:getResetGambitsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    if self:getConfigKey() and not self.hideShortcuts then
        self:setChildMenuItem("Shortcuts", ShortcutMenuItem.new(string.format("shortcut_%s", self:getConfigKey()), "Open the gambit editor.", false, string.format("// trust menu %s", self:getConfigKey())))
    end
end

function GambitSettingsMenuItem:getAbilitiesForTargets(targets)
    return self.editorConfig:getAbilitiesForTargets(targets, self.trust)
end

---
-- Gets a list of abilities for a gambit target.
--
-- @tparam GambitTarget.TargetType gambitTarget Gambit target
-- @tparam boolean flatten If true, return as a single list
--
-- @treturn list List of abilities
--
function GambitSettingsMenuItem:getAbilities(gambitTarget, flatten)
    local gambitTargetMap = T{
        [GambitTarget.TargetType.Self] = S{'Self'},
        [GambitTarget.TargetType.Ally] = S{'Party', 'Corpse'},
        [GambitTarget.TargetType.Enemy] = S{'Enemy'}
    }
    local targets = gambitTargetMap[gambitTarget]

    local sections = self.abilitiesForTargets(targets)
    if flatten then
        sections = sections:flatten(false)
    end
    return sections
end

function GambitSettingsMenuItem:getAbilitiesByTargetType()
    local abilitiesByTargetType = T{}
    for abilityTarget in L(GambitTarget.TargetType:keyset()):it() do
        if self.abilityTargets:contains(abilityTarget) then
            abilitiesByTargetType[abilityTarget] = self:getAbilities(abilityTarget, true):compact_map()
        else
            abilitiesByTargetType[abilityTarget] = L{}
        end
    end
    if self.buffTargetEditor then
        abilitiesByTargetType.Both = abilitiesByTargetType.Self:filter(function(ability)
            return abilitiesByTargetType.Ally:contains(ability)
        end)
    end
    return abilitiesByTargetType
end

-- White Mage menus opt in individually. The shared Gambits menus keep their
-- existing multi-step Add flow.
function GambitSettingsMenuItem:enableDirectAdd(targetType, categoryName, buffTargetEditor)
    self.directAddTarget = targetType
    self.directAddCategory = categoryName
    self.buffTargetEditor = buffTargetEditor

    if buffTargetEditor then
        self.hideShortcuts = true
        self.buttonItems:clear()
        self.childMenuItems.Shortcuts = nil
        self:reloadSettings()
    else
        self.hideShortcuts = true
        self.buttonItems = self.buttonItems:filter(function(button)
            return button:getTextItem():getText() ~= "Shortcuts"
        end)
        self.childMenuItems.Shortcuts = nil
        self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    end
end

function GambitSettingsMenuItem:appendGambit(gambit, showMenu)
    self:onGambitCreated():trigger(gambit)
    local gambits = self:getSettings().Gambits
    gambits:append(gambit)
    local saved, err = self.trustSettings:saveSettings(true)
    if saved == false then
        gambits:remove(gambits:length())
        addon_system_error(err or "Unable to save settings.")
        return
    end
    showMenu(self)

    local editor = self.gambitSettingsEditor
    local indexPath = IndexPath.new(1, self:getSettings().Gambits:length())
    local bottom = editor:getContentSize().height + editor:getPadding().bottom - editor:getSize().height
    editor:setContentOffset(editor:getContentOffset().x, math.min(0, -bottom))
    editor:getDelegate():setCursorIndexPath(indexPath)
    editor:getDelegate():selectItemAtIndexPath(indexPath)
end

function GambitSettingsMenuItem:getAddAbilityMenuItem()
    local newAbilityMenuItem = function(targetType)
        return MenuItem.new(L{
            ButtonItem.localized('Filter', i18n.translate('Button_Filter')),
        }, {}, function(_, _, showMenu)
            local abilitiesByTargetType = self:getAbilitiesByTargetType()

            local abilityPickerItem = MultiPickerConfigItem.new('abilities', L{}, abilitiesByTargetType[targetType], function(ability)
                return ability:get_localized_name()
            end, "Choose an ability.", nil, function(ability)
                return AssetManager.imageItemForAbility(ability:get_name())
            end, function(ability)
                return self.editorConfig:getItemDescription(ability) or "Add a new "..targetType.." "..self.editorConfig:getDescription().."."
            end)
            abilityPickerItem:setNumItemsRequired(1, 1)

            local FFXIFastPickerView = require('ui/themes/ffxi/FFXIFastPickerView')

            local abilityPickerView = FFXIFastPickerView.new(abilityPickerItem)
            abilityPickerView:setPickOnSelect(true)
            abilityPickerView:getDisposeBag():add(abilityPickerView:on_pick_items():addAction(function(_, selectedItems)
                if selectedItems:length() > 0 then
                    self:appendGambit(Gambit.new(targetType, L{}, selectedItems[1], targetType, self.defaultGambitTags), showMenu)
                end
            end), abilityPickerView:on_pick_items())

            return abilityPickerView
        end, self:getTitleText(), "Add a new "..targetType.." "..self.editorConfig:getDescription()..".")
    end

    if self.directAddTarget then
        return newAbilityMenuItem(self.directAddTarget)
    end
    if self.directAddCategory then
        local category = GambitLibraryMenuItem.getGambitCategories():firstWhere(function(item)
            return item:getName() == self.directAddCategory
        end)
        return GambitLibraryMenuItem.getGambitCategoryMenuItem(category, function(gambit, showMenu)
            self:appendGambit(gambit, showMenu)
        end)
    end

    local addMenu = MenuItem.new(L{}, {}, nil, self:getTitleText(), "Choose an ability target or browse presets.")
    if self.editorConfig:hasEditPermission(self.selectedGambit, GambitEditorStyle.Permissions.New) then
        for _, targetType in ipairs({GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally, GambitTarget.TargetType.Enemy}) do
            if self.abilityTargets:contains(targetType) then
                addMenu:setChildMenuItem(targetType, newAbilityMenuItem(targetType))
            end
        end
    end
    local browse = GambitLibraryMenuItem.new(self.libraryCategoryFilter, function(gambit, showMenu)
        self:appendGambit(gambit, showMenu)
    end)
    if browse then
        addMenu:setChildMenuItem("Browse", browse)
    end
    return addMenu
end

function GambitSettingsMenuItem:getEditGambitMenuItem()
    local editGambitMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {}, function(_, _, showMenu)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()
        local gambitEditor = GambitSettingsEditor.new(self.selectedGambit, self.trustSettings, self.trustSettingsMode, abilitiesByTargetType, self.conditionTargets, showMenu, Gambit.Tags.AllTags:filter(function(t) return not self.gambitTagBlacklist:contains(t)  end), function(ability, index)
            return self.editorConfig:getItemDescription(ability, index) or ability:get_localized_name()
        end, self.buffTargetEditor)

        gambitEditor:getDisposeBag():add(gambitEditor:onGambitChanged():addAction(function(newGambit, oldGambit)
            self:onGambitChanged():trigger(newGambit, oldGambit)

            self.conditionSettingsMenuItem:setConditions(function() return newGambit:getConditions() end)
            --self.conditionSettingsMenuItem:setConditions(newGambit:getConditions():map(function(condition) return condition:getCondition() end)) -- FIXME
            --self.conditionSettingsMenuItem:setTargetTypes(S{ newGambit:getConditionsTarget() })
        end), gambitEditor:onGambitChanged())

        return gambitEditor
    end, self:getTitleText(), "Edit the selected "..self.editorConfig:getDescription()..".", false, function()
        return self.selectedGambit ~= nil
    end)

    local editAbilityMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {
        Confirm = MenuItem.action(function(parent)
            --parent:showMenu(editGambitMenuItem)
        end, self:getTitleText(), "Edit ability.")
    }, function(_, infoView, showMenu)
        local configItems = L{}
        if self.selectedGambit:getAbility().get_config_items then
            configItems = self.selectedGambit:getAbility():get_config_items(self.trust) or L{}
        end
        if not configItems:empty() then
            local editAbilityEditor = ConfigEditor.new(self.trustSettings, self.selectedGambit:getAbility(), configItems, infoView, nil, showMenu)
            editAbilityEditor:setSaveOnExit(false)

            self.disposeBag:add(editAbilityEditor:onConfigConfirm():addAction(function(newSettings, oldSettings)
                if self.selectedGambit:getAbility().on_config_changed then
                    self.selectedGambit:getAbility():on_config_changed(oldSettings)
                end
            end), editAbilityEditor:onConfigChanged())

            return editAbilityEditor
        end
        return nil
    end, self:getTitleText(), "Edit ability.", false, function()
        return self.selectedGambit ~= nil and self.selectedGambit:getAbility().get_config_items and self.selectedGambit:getAbility():get_config_items():length() > 0
    end)

    editGambitMenuItem:setChildMenuItem("Edit", editAbilityMenuItem)
    editGambitMenuItem:setChildMenuItem("Conditions", self.conditionSettingsMenuItem)

    return editGambitMenuItem
end

function GambitSettingsMenuItem:getRemoveAbilityMenuItem()
    return MenuItem.action(function()
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local indexPath = selectedIndexPath

                local currentGambits = self:getSettings().Gambits
                currentGambits:remove(indexPath.row)

                self.gambitSettingsEditor:getDataSource():removeItem(indexPath)

                self.selectedGambit = nil
                self.trustSettings:saveSettings(true)

                if self.gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) > 0 then
                    self.selectedGambit = currentGambits[1]
                    self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
                end
            end
        end
    end, self:getTitleText(), "Remove the selected "..self.editorConfig:getDescription()..".")
end

function GambitSettingsMenuItem:getCopyGambitMenuItem()
    local copyGambitMenuItem =  MenuItem.action(function(menu)
        if self.selectedGambit then
            local newGambit = self.selectedGambit:copy()

            local currentGambits = self:getSettings().Gambits
            currentGambits:append(newGambit)

            self.trustSettings:saveSettings(true)
            self.trustSettings:reloadSettings()

            menu:showMenu(self)
        end
    end, self:getTitleText(), "Copy the selected "..self.editorConfig:getDescription()..".")

    copyGambitMenuItem.enabled = function()
        return self.selectedGambit ~= nil
    end

    return copyGambitMenuItem
end

function GambitSettingsMenuItem:getToggleMenuItem()
    local toggleMenuItem = MenuItem.action(function(_)
        local selectedIndexPath = self.gambitSettingsEditor:getCursorIndexPath()
        if selectedIndexPath then
            local currentGambits = self:getSettings().Gambits
            currentGambits[selectedIndexPath.row]:setEnabled(not currentGambits[selectedIndexPath.row]:isEnabled())

            self.trustSettings:saveSettings(true)

            self.gambitSettingsEditor:reload()
        end
    end, self:getTitleText(), "Temporarily enable or disable the selected "..self.editorConfig:getDescription().." until the addon reloads.", false, function()
        if self.selectedGambit then
            return self.selectedGambit:isValid()
        end
        return false
    end)

    return toggleMenuItem
end

function GambitSettingsMenuItem:getMoveUpGambitMenuItem()
    return MenuItem.action(function(menu)
        local currentGambits = self:getSettings().Gambits

        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.row > 1 then
            local newIndexPath = self.gambitSettingsEditor:getDataSource():getPreviousIndexPath(selectedIndexPath)
            local item1 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            local item2 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self.gambitSettingsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                local temp = currentGambits[selectedIndexPath.row - 1]
                currentGambits[selectedIndexPath.row - 1] = currentGambits[selectedIndexPath.row]
                currentGambits[selectedIndexPath.row] = temp

                self.trustSettings:saveSettings(true)

                if self.directAddTarget or self.directAddCategory then
                    self.gambitSettingsEditor:getDelegate():setCursorIndexPath(newIndexPath)
                end
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)
            end
        end
    end, self:getTitleText(), "Move the selected "..self.editorConfig:getDescription().." up. "..self.editorConfig:getDescription(true).." get evaluated in order.",  false, function()
        return self.selectedGambit ~= nil
    end)
end

function GambitSettingsMenuItem:getMoveDownGambitMenuItem()
    return MenuItem.action(function(_)
        local currentGambits = self:getSettings().Gambits

        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.row < currentGambits:length() then
            local newIndexPath = self.gambitSettingsEditor:getDataSource():getNextIndexPath(selectedIndexPath)-- IndexPath.new(indexPath.section, indexPath.row + 1)
            local item1 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            local item2 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self.gambitSettingsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                local temp = currentGambits[selectedIndexPath.row + 1]
                currentGambits[selectedIndexPath.row + 1] = currentGambits[selectedIndexPath.row]
                currentGambits[selectedIndexPath.row] = temp

                self.trustSettings:saveSettings(true)

                if self.directAddTarget or self.directAddCategory then
                    self.gambitSettingsEditor:getDelegate():setCursorIndexPath(newIndexPath)
                end
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)
            end
        end
    end, self:getTitleText(), "Move the selected "..self.editorConfig:getDescription().." down. "..self.editorConfig:getDescription(true).." get evaluated in order.", false, function()
        return self.selectedGambit ~= nil
    end)
end

function GambitSettingsMenuItem:getResetGambitsMenuItem()
    return MenuItem.action(function(menu)
        local defaultGambitSettings = self:getDefaultSettings()
        if defaultGambitSettings and defaultGambitSettings.Gambits then
            local currentGambitSettings = self:getSettings()
            currentGambitSettings.Gambits:clear()

            for gambit in defaultGambitSettings.Gambits:it() do
                currentGambitSettings.Gambits:append(gambit:copy())
            end

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've reset my "..self.editorConfig:getDescription(true).." to their factory settings!")

            menu:showMenu(self)
        end
    end, self:getTitleText(), "Reset to default "..self.editorConfig:getDescription(true)..".")
end

function GambitSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for "..self.editorConfig:getDescription(true)..".", self.modes)
end

function GambitSettingsMenuItem:setDefaultGambitTags(tags)
    self.defaultGambitTags = tags
end

function GambitSettingsMenuItem:getDisposeBag()
    return self.disposeBag
end

function GambitSettingsMenuItem:setConfigKey(configKey)
    MenuItem.setConfigKey(self, configKey)

    if self:getConfigKey() and not self.hideShortcuts then
        self:setChildMenuItem("Shortcuts", ShortcutMenuItem.new(string.format("shortcut_%s", self:getConfigKey()), "Open the gambit editor.", false, string.format("// trust menu %s", self:getConfigKey())))
    end
end

return GambitSettingsMenuItem
