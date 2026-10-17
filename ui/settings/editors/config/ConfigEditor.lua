local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXITextFieldItem = require('ui/themes/ffxi/FFXITextFieldItem')
local FFXIToggleButtonItem = require('ui/themes/ffxi/FFXIToggleButtonItem')
local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerCollectionViewCell = require('cylibs/ui/collection_view/cells/picker_collection_view_cell')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local PickerItem = require('cylibs/ui/collection_view/items/picker_item')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local SliderCollectionViewCell = require('cylibs/ui/collection_view/cells/slider_collection_view_cell')
local SliderItem = require('cylibs/ui/collection_view/items/slider_item')
local TextConfigItem = require('ui/settings/editors/config/TextConfigItem')
local TextFieldCollectionViewCell = require('cylibs/ui/collection_view/cells/text_field_collection_view_cell')
local TextFieldItem = require('cylibs/ui/collection_view/items/text_field_item')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local ToggleButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/toggle_button_collection_view_cell')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local MenuPreferences = require('cylibs/ui/menu/menu_preferences')
local EditorValues = require('cylibs/ui/menu/editor_values')

local ModelSettings = {}
ModelSettings.__index = ModelSettings

function ModelSettings.new(model)
    local self = setmetatable({}, ModelSettings)
    self.model = model
    for k, v in pairs(self.model) do
        if k ~= "table" and k ~= "primary_key" then
            self[k] = v
        end
    end
    return self
end

function ModelSettings:saveSettings()
    for k, v in pairs(self) do
        if k ~= "model" then
            self.model[k] = v
        end

    end
    self.model:save()
end

function ModelSettings:copy()
    return ModelSettings.new(self.model)
end

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local ConfigEditor = setmetatable({}, {__index = FFXIWindow })
ConfigEditor.__index = ConfigEditor
ConfigEditor.__type = "ConfigEditor"

function ConfigEditor:onConfigChanged()
    return self.configChanged
end

function ConfigEditor:onConfigItemChanged()
    return self.configItemChanged
end

function ConfigEditor:onConfigConfirm()
    return self.configConfirm
end

function ConfigEditor:onConfigValidationError()
    return self.configValidationError
end

function ConfigEditor.fromModel(model, configItems, infoView, validator, showMenu, viewSize)
    local modelSettings = ModelSettings.new(model)

    local self = ConfigEditor.new(modelSettings, modelSettings, configItems, infoView, validator, showMenu, viewSize)
    return self
end

function ConfigEditor.new(trustSettings, configSettings, configItems, infoView, validator, showMenu, viewSize, title)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == SliderItem.__type then
            local cell = SliderCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == TextItem.__type then
            local cell = MarqueeCollectionViewCell.new(item, 0.9)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == FFXIToggleButtonItem.__type then
            local cell = ToggleButtonCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == PickerItem.__type then
            local textStyle = TextStyle.ConfigEditor.TextSmall
            textStyle.highlightBold = true
            local cell = PickerCollectionViewCell.new(item, textStyle)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == TextFieldItem.__type then
            local cell = TextFieldCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(item:getSize().height)
            return cell
        end
        return nil
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.ConfigEditor, 10), nil, title ~= nil, viewSize or FFXIClassicStyle.WindowSize.Editor.ConfigEditor), ConfigEditor)

    self:setAllowsCursorSelection(false)
    self:setAllowsMultipleSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.configSettings = configSettings
    self.exitOwnerRoot = trustSettings and trustSettings.getSettings and trustSettings:getSettings()
    self.exitModeScope = {}
    if trustSettings and trustSettings.jobNameShort and state then
        for _, name in ipairs({'TrustMode', 'MainTrustSettingsMode', 'SubTrustSettingsMode', 'WeaponSkillSettingsMode'}) do
            self.exitModeScope[name] = state[name] and state[name].value
        end
    end
    self.validator = validator or function() return true end
    self.showMenu = function(menuItem)
        -- A nested picker is still part of this edit, not Save & Back.
        self.openingChildPicker = true
        FFXIWindow.resignFocus(self)
        self.openingChildPicker = false
        showMenu(menuItem)
    end
    self.valueForCellConfigItem = {}
    self.configChanged = Event.newEvent()
    self.configItemChanged = Event.newEvent()
    self.configValidationError = Event.newEvent()
    self.configConfirm = Event.newEvent()

    self:setConfigItems(configItems)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
        if cell then
            if cell.__type == PickerCollectionViewCell.__type then
                if infoView then
                    infoView:setDescription("Hold shift and press the left and right arrow keys to cycle faster.")
                end
            end
        end

        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            if item.__type == PickerItem.__type then
                if item:getAllowsMultipleSelection() then
                    self:getDelegate():deselectItemAtIndexPath(indexPath)
                end
            end
            if item.__type == TextItem.__type then
                -- NOTE: this breaks skillchain finder
                --self:getDelegate():deselectItemAtIndexPath(indexPath)
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)
        if infoView then
            infoView:setDescription("Edit the selected item.")
        end
        local configItem = self.configItems[indexPath.section]
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if (item.getCurrentValue and configItem.getInitialValue) then
            self:onConfigItemChanged():trigger(configItem:getKey(), item:getCurrentValue(), configItem:getInitialValue())
            --if item:getCurrentValue() ~= configItem:getInitialValue() then
            if configItem.getDependencies then
                for dependency in configItem:getDependencies():it() do
                    if dependency.onReload then
                        local allValues = dependency.onReload(configItem:getKey(), item:getCurrentValue(), configItem)
                        dependency:setAllValues(allValues)

                        self:reloadConfigItem(dependency)
                    end
                end
            end
            --end
        end
    end), self:getDelegate():didDeselectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self.exitBaseline = self:readDraft()
    self.exitSourceValues = EditorValues.copy(self.configSettings)
    return self
end

function ConfigEditor:destroy()
    FFXIWindow.destroy(self)

    self.configChanged:removeAllActions()
    self.configItemChanged:removeAllActions()
    self.configValidationError:removeAllActions()
    self.configConfirm:removeAllActions()
end

function ConfigEditor:setConfigItems(configItems)
    self.configItems = configItems:filter(function(configItem)
        return self.configSettings[configItem:getKey()] ~= nil
    end)
    self.numSections = self.configItems:length()
    self:reloadSettings()
end

function ConfigEditor:reloadConfigItem(configItem)
    local sectionIndex = self.configItems:indexOf(configItem)

    self:getDataSource():removeItemsInSection(sectionIndex)

    local items = L{}

    local defaultItems = L{}
    if configItem.__type == GroupConfigItem.__type then
        for childConfigItem in configItem:getConfigItems():it() do
            defaultItems:append(self:getCellItemForConfigItem(childConfigItem))
        end
    else
        defaultItems:append(self:getCellItemForConfigItem(configItem))
    end

    if defaultItems:length() > 0 then
        local rowIndex = 1
        for defaultItem in defaultItems:it() do
            items:append(IndexedItem.new(defaultItem, IndexPath.new(sectionIndex, rowIndex)))
            rowIndex = rowIndex + 1
        end
        sectionIndex = sectionIndex + 1
    end

    self:getDataSource():addItems(items)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function ConfigEditor:reloadSettings()
    local previousCursorIndexPath = self:getDelegate():getCursorIndexPath()

    self:getDataSource():removeAllItems()

    local items = L{}

    local sectionIndex = 1

    for configItem in self.configItems:it() do
        if configItem:getDescription() then
            local sectionHeaderItem = SectionHeaderItem.new(
                    TextItem.new(configItem:getDescription(), TextStyle.Default.SectionHeader),
                    ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
                    16
            )
            self:getDataSource():setItemForSectionHeader(sectionIndex, sectionHeaderItem)
        end

        local defaultItems = L{}
        if configItem.__type == GroupConfigItem.__type then
            for childConfigItem in configItem:getConfigItems():it() do
                defaultItems:append(self:getCellItemForConfigItem(childConfigItem))
            end
        else
            defaultItems:append(self:getCellItemForConfigItem(configItem))
        end

        if defaultItems:length() > 0 then
            local rowIndex = 1
            for defaultItem in defaultItems:it() do
                items:append(IndexedItem.new(defaultItem, IndexPath.new(sectionIndex, rowIndex)))
                rowIndex = rowIndex + 1
            end
            sectionIndex = sectionIndex + 1
        end
    end

    self.numSections = sectionIndex - 1

    self:getDataSource():addItems(items)

    if previousCursorIndexPath and self:getDataSource():itemAtIndexPath(previousCursorIndexPath) then
        self:getDelegate():setCursorIndexPath(previousCursorIndexPath)
    elseif self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function ConfigEditor:getCellItemForConfigItem(configItem)
    if configItem.__type == ConfigItem.__type then
        return SliderItem.new(
                configItem:getMinValue(),
                configItem:getMaxValue(),
                self.configSettings[configItem:getKey()] or configItem:getDefaultValue(),
                configItem:getInterval(),
                ImageItem.new(windower.addon_path..'assets/backgrounds/slider_track.png', 166, 16),
                ImageItem.new(windower.addon_path..'assets/backgrounds/slider_fill.png', 166, 16),
                configItem:getTextFormat()
        )
    elseif configItem.__type == BooleanConfigItem.__type then
        local defaultItem = FFXIToggleButtonItem.new()
        defaultItem:setEnabled(self.configSettings[configItem:getKey()])
        return defaultItem
    elseif configItem.__type == PickerConfigItem.__type then
        local pickerItem = PickerItem.new(configItem:getInitialValue(), configItem:getAllValues(), configItem:getTextFormat())
        pickerItem:setShouldTruncateText(configItem:getShouldTruncateText())
        return pickerItem
    elseif configItem.__type == TextConfigItem.__type then
        local textItem = TextItem.new(configItem:getText(), TextStyle.Default.TextSmall)
        --textItem:setShouldTruncateText(true)
        return textItem
    elseif configItem.__type == MultiPickerConfigItem.__type then
        local pickerItem = PickerItem.new(configItem:getInitialValues(), configItem:getAllValues(), configItem:getTextFormat(), configItem:isEnabled(), configItem:getImageItem())
        pickerItem:setShouldTruncateText(true)
        pickerItem:setNumItemsRequired(configItem:getNumItemsRequired().minNumItems, configItem:getNumItemsRequired().maxNumItems)
        pickerItem:setAllowsMultipleSelection(configItem:getAllowsMultipleSelection())
        pickerItem:setPickerTitle(configItem:getPickerTitle())
        pickerItem:setPickerDescription(configItem:getPickerDescription())
        pickerItem:setPickerTextFormat(configItem:getPickerTextFormat())
        pickerItem:setPickerItemDescription(function(value)
            return configItem:getItemDescription(value)
        end)
        pickerItem:setShowMenu(self.showMenu)
        pickerItem:setOnPickItems(function(newValue)
            local is_valid, error = configItem:getPickerValidator()(newValue)
            if not is_valid then
                addon_system_error(error)
                return
            end
            if class(newValue) == 'List' then
                self.configSettings[configItem:getKey()]:clear()
                for value in newValue:it() do
                    self.configSettings[configItem:getKey()]:append(value)
                end
            else
                self.configSettings[configItem:getKey()] = newValue
            end
            addon_system_message("Your choices have been updated.")

            configItem:getOnConfirm()(newValue)
        end)
        return pickerItem
    elseif configItem.__type == TextInputConfigItem.__type then
        return FFXITextFieldItem.new(configItem:getPlaceholderText(), configItem:getValidator(), configItem:getWidth(), configItem:getHeight())
    end
    return nil
end

function ConfigEditor:setCellConfigItemOverride(cellConfigItemType, valueForCellConfigItem)
    self.valueForCellConfigItem[cellConfigItemType] = valueForCellConfigItem
end

function ConfigEditor:sectionForConfigKey(key)
    local section = 1
    for configItem in self.configItems:it() do
        if configItem:getKey() == key then
            return section
        end
        section = section + 1
    end
    return nil
end

function ConfigEditor:readDraft()
    local draft = EditorValues.copy(self.configSettings)
    for sectionIndex = 1, self:getDataSource():numberOfSections(), 1 do
        local configItem = self.configItems[sectionIndex]
        if configItem then
            local configKey = configItem:getKey()
            if configItem.__type == GroupConfigItem.__type then
                local configValues = L{}
                for rowIndex = 1, configItem:getConfigItems():length() do
                    local cellConfigItem = self:getDataSource():itemAtIndexPath(IndexPath.new(sectionIndex, rowIndex))
                    if cellConfigItem.__type == SliderItem.__type then
                        configValues:append(cellConfigItem:getCurrentValue())
                    elseif cellConfigItem.__type == FFXIToggleButtonItem.__type then
                        configValues:append(cellConfigItem:getEnabled())
                    elseif cellConfigItem.__type == PickerItem.__type then
                        configValues:append(cellConfigItem:getCurrentValue())
                    end
                end
                configValues = configValues:filter(function(value) return value ~= 'None' end)
                draft[configKey] = configValues
            else
                local cellConfigItem = self:getDataSource():itemAtIndexPath(IndexPath.new(sectionIndex, 1))

                local valueForCellConfigItem = self.valueForCellConfigItem[cellConfigItem.__type]
                if valueForCellConfigItem then
                    draft[configKey] = valueForCellConfigItem(cellConfigItem)
                else
                    if cellConfigItem.__type == SliderItem.__type then
                        draft[configKey] = cellConfigItem:getCurrentValue()
                    elseif cellConfigItem.__type == FFXIToggleButtonItem.__type then
                        draft[configKey] = cellConfigItem:getEnabled()
                    elseif cellConfigItem.__type == PickerItem.__type then
                        draft[configKey] = cellConfigItem:getCurrentValue()
                    elseif cellConfigItem.__type == TextFieldItem.__type then
                        draft[configKey] = cellConfigItem:getTextItem():getText()
                    elseif cellConfigItem.__type == TextItem.__type then
                        draft[configKey] = configItem:getInitialValues()
                    end
                end
            end
        end
    end

    return draft
end

function ConfigEditor:onConfirmClick(skipSave, quiet)
    self:resignFirstResponder()
    local originalSettings = EditorValues.copy(self.configSettings)
    local draft = self:readDraft()
    -- Validation must precede mutation: an invalid exit leaves live settings
    -- untouched and the editor available for correction.
    local isValid, errorMessage = self.validator(draft)
    if isValid then
        for i, configItem in ipairs(self.configItems) do
            local item = self:getDataSource():itemAtIndexPath(IndexPath.new(i, 1))
            if item and item.__type == TextFieldItem.__type and item.isValid
                    and not item:isValid(draft[configItem:getKey()]) then
                isValid, errorMessage = false, 'Invalid '..configItem:getKey()..'.'
                break
            end
        end
    end
    if not isValid then
        self:onConfigValidationError():trigger(errorMessage)
        if quiet then addon_system_error(errorMessage or 'Correct the highlighted options before leaving.') end
        return false
    end

    for key, value in pairs(draft) do self.configSettings[key] = value end

    self:onConfigConfirm():trigger(self.configSettings, originalSettings)

    if not quiet or not EditorValues.equal(draft, originalSettings) then
        self:onConfigChanged():trigger(self.configSettings, originalSettings)
    end

    if self.trustSettings and not skipSave then
        local result, err = self.trustSettings:saveSettings(true)
        if result == false then error(err or 'Unable to save settings.') end
        if not quiet then
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my settings!")
        end
    end
    self.exitBaseline = self:readDraft()
    self.exitSourceValues = EditorValues.copy(self.configSettings)
    return true
end

-- Ordinary option editors are eligible by default. Command forms, renamed
-- profiles, nested multi-pickers and structural gambit editors stay explicit.
-- A menu can opt in a known safe ownerless editor with an explicit writer.
function ConfigEditor:canSaveOnExit()
    if self.saveOnExit == false then return false end
    if self.exitWriter then return true end
    if getmetatable(self) ~= ConfigEditor or not self.trustSettings then return false end
    local hasOptions = false
    for configItem in self.configItems:it() do
        if L{ ConfigItem.__type, BooleanConfigItem.__type, PickerConfigItem.__type }:contains(configItem.__type) then
            hasOptions = true
        elseif configItem.__type == GroupConfigItem.__type then
            for child in configItem:getConfigItems():it() do
                if not L{ ConfigItem.__type, BooleanConfigItem.__type, PickerConfigItem.__type }:contains(child.__type) then return false end
            end
            hasOptions = true
        elseif configItem.__type ~= TextInputConfigItem.__type then
            return false
        end
    end
    -- Name/creation forms containing only text fields remain explicit.
    return hasOptions
end

function ConfigEditor:setSaveOnExit(enabled, writer, guard)
    self.saveOnExit = enabled
    self.exitWriter = writer
    self.exitGuard = guard
end

function ConfigEditor:commitOnExit()
    if self.committingExit or self.openingChildPicker or not MenuPreferences.get('save_on_exit')
            or not self:canSaveOnExit() then return true end
    local draft = self:readDraft()
    if EditorValues.equal(draft, self.exitBaseline) then return true end
    if self.exitSourceValues then
        for configItem in self.configItems:it() do
            local key = configItem:getKey()
            if not EditorValues.equal(self.configSettings[key], self.exitSourceValues[key])
                    and not EditorValues.equal(self.configSettings[key], draft[key]) then
                addon_system_error('An option changed outside this editor. Discard and reopen it before saving.')
                return false
            end
        end
    end
    if self.exitOwnerRoot and self.trustSettings:getSettings() ~= self.exitOwnerRoot then
        addon_system_error('This settings set was reloaded. Reopen the editor before saving.')
        return false
    end
    for name, value in pairs(self.exitModeScope or {}) do
        if state[name] and state[name].value ~= value then
            addon_system_error('The profile changed. Reopen this editor before saving.')
            return false
        end
    end
    if self.exitGuard then
        local valid, message = self.exitGuard(draft)
        if not valid then
            addon_system_error(message or 'Settings changed outside this editor. Reopen it before saving.')
            return false
        end
    end
    self.committingExit = true
    local baseline = self.exitBaseline
    local sourceValues = self.exitSourceValues
    local owner = self.trustSettings
    local save = owner and owner.saveSettings
    local ownSave = owner and rawget(owner, 'saveSettings')
    -- Several existing onConfigChanged callbacks save the same owner too.
    -- Coalesce those synchronous requests into one final save/notification.
    if owner and save then owner.saveSettings = function() return true end end
    local ok, result = pcall(function()
        if not self:onConfirmClick(true, true) then return false end
        if owner then owner.saveSettings = ownSave end
        if self.exitWriter then self.exitWriter(self.configSettings) end
        if save then
            local success, err = save(owner, true)
            if success == false then error(err or 'Unable to save settings.') end
        end
        return true
    end)
    if owner then owner.saveSettings = ownSave end
    self.committingExit = false
    if not ok or not result then
        -- A failed write may have applied runtime values. Keep the draft dirty
        -- so a deliberate retry can persist it rather than claiming success.
        self.exitBaseline = baseline
        self.exitSourceValues = sourceValues
        if not ok then addon_system_error('Settings were not saved: '..tostring(result)) end
        return false
    end
    self.exitBaseline = self:readDraft()
    if self.exitOwnerRoot then self.exitOwnerRoot = self.trustSettings:getSettings() end
    MenuPreferences.saved()
    return true
end

function ConfigEditor:resignFocus()
    if self:hasFocus() and not self:commitOnExit() then return end
    FFXIWindow.resignFocus(self)
end

function ConfigEditor:onResetClick()
    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function ConfigEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if L{ 'Confirm', 'Save', 'Search' }:contains(textItem:getText()) then
        return self:onConfirmClick()
    elseif textItem:getText() == 'Reset' then
        self:onResetClick()
    end
end

function ConfigEditor:shouldDeselectOnLoseFocus(section)
    return true
end

function ConfigEditor:setHasFocus(focus)
    FFXIWindow.setHasFocus(self, focus)

    if focus then
        local sections = S{}
        for i = 1, self.numSections do
            if self:shouldDeselectOnLoseFocus(i) then
                sections:add(i)
            end
        end
        self:getDelegate():deselectItemsInSections(sections)
    end
end

function ConfigEditor:resignFirstResponder()
    local cursorIndexPath = self:getDelegate():getCursorIndexPath()
    if cursorIndexPath then
        local cell = self:getDataSource():cellForItemAtIndexPath(cursorIndexPath)
        if cell and cell:hasFocus() then
            cell:setShouldResignFocus(true)
            cell:resignFocus()
        end
    end
end

return ConfigEditor
