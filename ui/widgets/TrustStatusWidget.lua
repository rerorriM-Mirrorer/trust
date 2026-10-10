local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ColorView = require('cylibs/ui/views/color_view')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageView = require('cylibs/ui/image_view')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')
local TargetWidget = require('ui/widgets/TargetWidget')
local CompactWidget = require('ui/widgets/CompactWidget')

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
    self.disableTitleModeToggle = true

    -- One compact control owns all three visual layers: Trust background,
    -- Party count, and Target name. Party and Target retain their own data
    -- tracking and Full views, but do not draw independent compact widgets.
    self.fullWidth = frame.width
    self.fullHeight = frame.height
    self.compactWidth = 40
    self.compactHeight = 40
    self.addonEnabled = addonEnabled
    self.currentAction = ''
    self.compactPartyCount = nil
    self.compactTargetName = ''

    self.compactGlowOuter = ColorView.new(Frame.new(0, 0, 40, 40), Color.clear)
    self.compactGlowInner = ColorView.new(Frame.new(4, 4, 32, 32), Color.clear)
    self.compactIcon = ImageView.new()
    self.compactIcon:setPosition(4, 4)
    self.compactIcon:setSize(32, 32)
    self.compactIcon:loadImage(windower.addon_path..'assets/icons/icon_timer.png')
    -- The green overlay tints the slot rather than replacing its artwork.
    self.compactTint = ColorView.new(Frame.new(4, 4, 32, 32), Color.clear)

    local countItem = TextItem.new('', TrustStatusWidget.TextSmall)
    self.compactCountCell = TextCollectionViewCell.new(countItem)
    self.compactCountCell:setPosition(2, 0)
    self.compactCountCell:setSize(32, 16)

    -- Reuse Target's exact yellow, bold-italic Arial style.
    self.compactTargetCell = TextCollectionViewCell.new(TextItem.new('', TargetWidget.Text))
    self.compactTargetCell:setPosition(0, 25)
    self.compactTargetCell:setSize(40, 14)

    self:addSubview(self.compactGlowOuter)
    self:addSubview(self.compactGlowInner)
    self:addSubview(self.compactIcon)
    self:addSubview(self.compactTint)
    self:addSubview(self.compactCountCell)
    self:addSubview(self.compactTargetCell)
    self:refreshCompactIcon()

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
        self:refreshCompactIcon()
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

    -- Compact is the default for this visual test. The widget command restores Full.
    self:setExpanded(false)

    return self
end

-- The shared compact shell is the only drag target; child labels never
-- create additional windows, hitboxes, or independent saved positions.
function TrustStatusWidget:setPosition(x, y)
    Widget.setPosition(self, x, y)
    if self.compactIcon then
        self.compactGlowOuter:setPosition(0, 0)
        self.compactGlowInner:setPosition(4, 4)
        self.compactIcon:setPosition(4, 4)
        self.compactTint:setPosition(4, 4)
        self.compactCountCell:setPosition(2, 0)
        self.compactTargetCell:setPosition(0, 25)
    end
end

function TrustStatusWidget:setExpanded(expanded)
    return self:setCompactMode(not expanded)
end

function TrustStatusWidget:setCompactMode(compact)
    Widget.setExpanded(self, not compact)
    return CompactWidget.setMode(self, compact)
end

function TrustStatusWidget:updateCompactVisibility()
    local compact = self.compactMode
    for _, view in ipairs({
        self.compactGlowOuter, self.compactGlowInner, self.compactIcon,
        self.compactTint, self.compactCountCell, self.compactTargetCell,
    }) do
        view:setVisible(compact)
        view:setNeedsLayout()
        view:layoutIfNeeded()
    end
    self:refreshCompactIcon()
    self:refreshCompactLabels()
end

function TrustStatusWidget:getCompactState()
    if not self.addonEnabled:getValue() then
        return 'off'
    elseif self.currentAction ~= '' and self.currentAction ~= 'Idle' and self.currentAction ~= 'OFF' then
        return 'active'
    end
    return 'idle'
end

function TrustStatusWidget:refreshCompactIcon()
    if not self.compactIcon then
        return
    end
    local status = self:getCompactState()
    local stopped = status == 'off'
    local path = stopped and 'assets/icons/icon_timer.png'
        or 'assets/backgrounds/item_slot_background.png'

    self.compactIcon:loadImage(windower.addon_path..path)
    -- Stopped: barely-visible hourglass. Idle: translucent slot.
    -- Active: translucent slot with subtle green tint and halo.
    self.compactIcon.alpha = stopped and 75 or 185
    local active = status == 'active'
    self.compactGlowOuter:setBackgroundColor(active and Color.new(26, 26, 163, 80) or Color.clear)
    self.compactGlowInner:setBackgroundColor(active and Color.new(42, 18, 145, 70) or Color.clear)
    self.compactTint:setBackgroundColor(active and Color.new(63, 37, 160, 62) or Color.clear)

    for _, view in ipairs({
        self.compactIcon, self.compactGlowOuter, self.compactGlowInner, self.compactTint,
    }) do
        view:setNeedsLayout()
        view:layoutIfNeeded()
    end
end

function TrustStatusWidget:setCompactPartyCount(count)
    local value = count and tostring(count) or ''
    if self.compactPartyCount == value then
        return
    end
    self.compactPartyCount = value
    self:refreshCompactLabels()
end

function TrustStatusWidget:setCompactTargetName(name)
    local value = name or ''
    if self.compactTargetName == value then
        return
    end
    self.compactTargetName = value
    self:refreshCompactLabels()
end

function TrustStatusWidget:refreshCompactLabels()
    if not self.compactCountCell or not self.compactTargetCell then
        return
    end
    local countItem = TextItem.new(self.compactPartyCount or '', TrustStatusWidget.TextSmall)
    countItem:setOffset(4, 0)
    self.compactCountCell:setItem(countItem)

    -- Center the single name across the slot's lower edge. The text can
    -- extend to either side while remaining part of this one draggable widget.
    local targetName = self.compactTargetName or ''
    if targetName:length() > 18 then
        targetName = localization_util.truncate(targetName, 18)
    end
    local textItem = TextItem.new(targetName, TargetWidget.Text)
    textItem:setShouldWordWrap(false)
    textItem:setOffset(math.floor((self.compactWidth - #targetName * 5.2) / 2), 0)
    self.compactTargetCell:setItem(textItem)

    self.compactCountCell:setVisible(self.compactMode and (self.compactPartyCount or '') ~= '')
    self.compactTargetCell:setVisible(self.compactMode and targetName ~= '')
    self.compactCountCell:setNeedsLayout()
    self.compactTargetCell:setNeedsLayout()
    self.compactCountCell:layoutIfNeeded()
    self.compactTargetCell:layoutIfNeeded()
end

function TrustStatusWidget:compactExtraHitTest(x, y)
    if self.compactTargetName == '' then
        return false
    end
    local pos = self:getAbsolutePosition()
    local width = math.min(#self.compactTargetName, 18) * 6
    return x >= pos.x + 20 - width / 2 and x <= pos.x + 20 + width / 2
        and y >= pos.y + 25 and y <= pos.y + 40
end

function TrustStatusWidget:hitTest(x, y)
    return CompactWidget.hitTest(self, x, y)
end

function TrustStatusWidget:onMouseEvent(type, x, y, delta)
    return CompactWidget.onMouseEvent(self, type, x, y, delta)
end

function TrustStatusWidget:layoutIfNeeded()
    return CompactWidget.layoutIfNeeded(self)
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

    self.currentAction = text
    self:refreshCompactIcon()
    if self:getDataSource():itemAtIndexPath(IndexPath.new(2, 1)):getText() == text then
        return
    end

    local actionItem = TextItem.new(text, TrustStatusWidget.Subheadline), IndexPath.new(2, 1)

    self:getDataSource():updateItem(actionItem, IndexPath.new(2, 1))

    self:layoutIfNeeded()
end

return TrustStatusWidget