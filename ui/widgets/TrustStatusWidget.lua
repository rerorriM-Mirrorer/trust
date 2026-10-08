local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local TrustStatusWidget = setmetatable({}, {__index = Widget })
TrustStatusWidget.__index = TrustStatusWidget

TrustStatusWidget.Buttons = {}
TrustStatusWidget.Buttons.On = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        17,
        14
)
TrustStatusWidget.Buttons.Off = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_off.png',
        23,
        14
)

TrustStatusWidget.TextSmall = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        true
)
TrustStatusWidget.TextSmall2 = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.new(255, 77, 186, 255),
        Color.new(255, 65, 155, 200),
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        true
)
TrustStatusWidget.TextSmall3 = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        false
)
TrustStatusWidget.Subheadline = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.lightGrey,
        0,
        0.5,
        Color.black,
        true,
        Color.red
)

function TrustStatusWidget.new(frame, addonEnabled, actionQueue, mainJobName, subJobName, player)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.section == 1 then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(true)
            return cell
        elseif indexPath.section == 2 then
            local cell = MarqueeCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(true)
            return cell
        else
            local cell = MarqueeCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(false)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Trust", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 20), TrustStatusWidget)

    self.mainJobName = mainJobName
    self.subJobName = subJobName

    -- The title border uses four 20px end pieces; 104px leaves room for "Trust".
    -- Keep the full widget size so tapping the title can restore the normal view.
    self.fullWidth = frame.width
    self.fullHeight = frame.height
    self.compactWidth = 104
    self.compactHeight = 14

    self:getDisposeBag():addAny(L{ self.action_queue })

    self:setJobs(mainJobName, subJobName)

    self:getDataSource():addItem(TextItem.new(state.TrustMode.value, TrustStatusWidget.TextSmall3), IndexPath.new(1, 3))
    self:getDataSource():addItem(TextItem.new('', TrustStatusWidget.Subheadline), IndexPath.new(2, 1))

    self:setUserInteractionEnabled(true)
    self:setVisible(true)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    for mode in L{ state.TrustMode }:it() do
        self:getDisposeBag():add(mode:on_state_change():addAction(function(_, new_value, old_value)
            local item = self:getDataSource():itemAtIndexPath(IndexPath.new(1, 3))
            if item and item:getText() and item:getText() ~= new_value then
                self:getDataSource():updateItem(TextItem.new(state.TrustMode.value, TrustStatusWidget.TextSmall3), IndexPath.new(1, 3))
            end
        end), mode:on_state_change())
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)
        if indexPath.section == 1 then
            if L{ 1, 2 }:contains(indexPath.row) then
                coroutine.schedule(function()
                    self:resignFocus()
                    windower.send_command('trust menu')
                end, 0.2)
            elseif indexPath.row == 3 then
                coroutine.schedule(function()
                    self:resignFocus()
                    local profilesMenuItem = hud:getMainMenuItem():getChildMenuItem("Profiles")
                    if profilesMenuItem then
                        hud:openMenu(profilesMenuItem)
                    end
                end, 0.2)
            end
        elseif indexPath.section == 2 then
            windower.send_command('trust toggle')
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(actionQueue:on_action_start():addAction(function(_, s)
        self:setAction(s:tostring() or '')
    end), actionQueue:on_action_start())

    self:getDisposeBag():add(actionQueue:on_action_end():addAction(function(s, _)
        self:setAction('')
    end), actionQueue:on_action_end())

    self:getDisposeBag():add(addonEnabled:onValueChanged():addAction(function(_, isEnabled)
        if isEnabled then
            self:setAction('')
        else
            self:setAction('OFF')
        end
    end), addonEnabled:onValueChanged())

    self:getDisposeBag():add(player:on_level_change():addAction(function(_, _)
        self:setJobs(mainJobName, subJobName)
    end), player:on_level_change())

    self:getDisposeBag():add(i18n.onLocaleChanged():addAction(function(_)
        self:setJobs(mainJobName, subJobName)
    end), i18n.onLocaleChanged())

    if not addonEnabled:getValue() then
        self:setAction('OFF')
    end

    self.events.zone_change = windower.register_event('zone change', function(new_zone_id, old_zone_id)
        if new_zone_id ~= old_zone_id then
            self:setJobs(mainJobName, subJobName)
        end
    end)

    -- This experimental view starts title-only. Clicking the title restores Full.
    self:setExpanded(false)

    return self
end

-- Only this widget uses the title-only layout; Party and Target remain unchanged.
function TrustStatusWidget:setExpanded(expanded)
    if not Widget.setExpanded(self, expanded) then
        return false
    end

    if expanded then
        self:setSize(self.fullWidth, self.fullHeight)
    else
        self:setSize(self.compactWidth, self.compactHeight)
    end
    self:setNeedsLayout()
    self:layoutIfNeeded()
    return true
end

function TrustStatusWidget:layoutIfNeeded()
    if self.compactWidth and not self:isExpanded() then
        -- Widget.layoutIfNeeded would grow the frame to the hidden rows' height.
        -- Lay out the title at its actual small size, then suppress the body.
        local changed = CollectionView.layoutIfNeeded(self)
        local contentView = self:getContentView()
        if contentView then
            contentView:setVisible(false)
            contentView:layoutIfNeeded()
        end
        local backgroundView = self:getBackgroundImageView()
        if backgroundView and backgroundView.bottomBorderView then
            backgroundView.bottomBorderView:setVisible(false)
            backgroundView.bottomBorderView:layoutIfNeeded()
        end
        return changed
    end
    return Widget.layoutIfNeeded(self)
end

function TrustStatusWidget:destroy()
    Widget.destroy(self)

    -- TODO: unregister old keybind
    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function TrustStatusWidget:setJobs(mainJobName, subJobName)
    local rowIndex = 0

    local mainJobTextItem = TextItem.new(mainJobName, TrustStatusWidget.TextSmall2)
    mainJobTextItem:setLocalizedText("Lv"..windower.ffxi.get_player().main_job_level.." "..i18n.resource('jobs', 'en', mainJobName))

    local subJobTextItem = TextItem.new(subJobName, TrustStatusWidget.TextSmall)
    subJobTextItem:setLocalizedText("Lv"..(windower.ffxi.get_player().sub_job_level or 0).." "..i18n.resource('jobs', 'en', subJobName))

    local itemsToUpdate = L{
        mainJobTextItem,
        subJobTextItem,
    }:map(function(item)
        rowIndex = rowIndex + 1
        return IndexedItem.new(item, IndexPath.new(1, rowIndex))
    end)

    self:getDataSource():updateItems(itemsToUpdate)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
end

function TrustStatusWidget:setAction(text)
    if text == nil or text:empty() then
        text = 'Idle'
    end

    if self:getDataSource():itemAtIndexPath(IndexPath.new(2, 1)):getText() == text then
        return
    end

    local actionItem = TextItem.new(text, TrustStatusWidget.Subheadline), IndexPath.new(2, 1)

    self:getDataSource():updateItem(actionItem, IndexPath.new(2, 1))

    self:layoutIfNeeded()
end

return TrustStatusWidget