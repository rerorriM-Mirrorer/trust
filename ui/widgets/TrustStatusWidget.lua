local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ColorView = require('cylibs/ui/views/color_view')
local Frame = require('cylibs/ui/views/frame')
local Timer = require('cylibs/util/timers/timer')
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
local CompactTrustLook = require('ui/widgets/CompactTrustLook')
local CompactSongTimer = require('ui/widgets/CompactSongTimer')

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
    -- The widget layout preset selects the text anchor; the saved X position
    -- supplies a best-effort initial side on reload (preset itself is not saved).
    self.compactAlignment = 'Left'

    self.compactGlowOuter = ColorView.new(Frame.new(0, 0, 40, 40), Color.clear)
    self.compactGlowInner = ColorView.new(Frame.new(4, 4, 32, 32), Color.clear)
    self.compactIcon = ImageView.new()
    self.compactIcon:setPosition(4, 4)
    self.compactIcon:setSize(32, 32)
    -- A: the open book is the background in every state (CompactTrustLook).
    self.compactIcon:loadImage(windower.addon_path..'assets/icons/menu_mapsg_book.png')
    self.compactIcon.alpha = CompactTrustLook.tunables.book_alpha
    self.compactHourglass = ImageView.new()
    self.compactHourglass:setPosition(4, 4)
    self.compactHourglass:setSize(32, 32)
    self.compactHourglass:loadImage(windower.addon_path..'assets/icons/icon_timer.png')
    self.compactHourglass.alpha = 0
    self.compactCrystal = ImageView.new()
    self.compactCrystal:setPosition(4, 4)
    self.compactCrystal:setSize(32, 32)
    self.compactCrystal:loadImage(windower.addon_path..'assets/icons/menu_maphp_crystal.png')
    self.compactCrystal.alpha = 0
    -- Stop's red tint, over the book and under the hourglass.
    self.compactTint = ColorView.new(Frame.new(4, 4, 32, 32), Color.clear)

    local countItem = TextItem.new('', TrustStatusWidget.TextSmall)
    self.compactCountCell = TextCollectionViewCell.new(countItem)
    self.compactCountCell:setPosition(2, 0)
    self.compactCountCell:setSize(32, 16)

    -- BRD only (BardTrust supplies a song source): note + re-sing timer under the count.
    local song = CompactSongTimer.tunables
    self.compactSongIcon = ImageView.new()
    self.compactSongIcon:setSize(song.icon, song.icon)
    self.compactSongIcon:loadImage(windower.addon_path..'assets/icons/icon_singing_light.png')
    self.compactSongIcon.alpha = song.dim_alpha
    self.compactSongCell = TextCollectionViewCell.new(TextItem.new('', TrustStatusWidget.TextSmall))
    self.compactSongCell:setSize(30, 14)
    self:placeCompactSong()

    -- Reuse Target's exact yellow, bold-italic Arial style.
    self.compactTargetCell = TextCollectionViewCell.new(TextItem.new('', TargetWidget.Text))
    self.compactTargetCell:setPosition(0, 25)
    self.compactTargetCell:setSize(40, 14)

    self:addSubview(self.compactGlowOuter)
    self:addSubview(self.compactGlowInner)
    self:addSubview(self.compactIcon)
    self:addSubview(self.compactTint)
    self:addSubview(self.compactHourglass)
    self:addSubview(self.compactCrystal)
    self:addSubview(self.compactCountCell)
    self:addSubview(self.compactSongIcon)
    self:addSubview(self.compactSongCell)
    self:addSubview(self.compactTargetCell)

    -- One redraw timer while compact: polls the control state, cross-fades
    -- layers and runs the pulses. Cancelled in Full mode.
    self.actionQueue = actionQueue
    self.compactLayers = {}
    self.compactLookStartedAt = os.clock()
    self.compactPulseTimer = Timer.scheduledTimer(CompactTrustLook.tunables.tick)
    self:getDisposeBag():add(self.compactPulseTimer:onTimeChange():addAction(function()
        self:tickCompactLook()
    end), self.compactPulseTimer:onTimeChange())
    self:getDisposeBag():addAny(L{ self.compactPulseTimer })
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
        self.compactHourglass:setPosition(4, 4)
        self.compactCrystal:setPosition(4, 4)
        self.compactCountCell:setPosition(2, 0)
        self.compactTargetCell:setPosition(0, 25)
        self:placeCompactSong()
    end
end

function TrustStatusWidget:placeCompactSong()
    local song = CompactSongTimer.tunables
    self.compactSongIcon:setPosition(song.x, song.y)
    self.compactSongIcon:setSize(song.icon, song.icon)
    self.compactSongCell:setPosition(song.x + song.icon + song.gap, song.y - 2)
end

-- source() -> singing (bool), seconds until re-sing (number|nil). nil removes the row.
function TrustStatusWidget:setCompactSongSource(source)
    self.compactSongSource = source
    self.compactSongShown = nil
    self.compactSongReadAt = nil
    self:refreshCompactSong(true)
end

function TrustStatusWidget:refreshCompactSong(force)
    if not self.compactSongIcon then
        return
    end
    local now = os.clock()
    if not force and self.compactSongReadAt and now - self.compactSongReadAt < CompactSongTimer.tunables.poll then
        return
    end
    self.compactSongReadAt = now
    local shown, singing, text = false, false, ''
    if self.compactMode and self.compactSongSource then
        local ok, isSinging, remaining = pcall(self.compactSongSource)
        if ok and isSinging ~= nil then
            shown, singing, text = true, isSinging and true or false, CompactSongTimer.format(remaining)
        end
    end
    local key = tostring(shown)..tostring(singing)..text
    if not force and key == self.compactSongShown then
        return
    end
    self.compactSongShown = key
    local song = CompactSongTimer.tunables
    self.compactSongIcon.alpha = singing and song.lit_alpha or song.dim_alpha
    self.compactSongIcon:setVisible(shown)
    self.compactSongIcon:setNeedsLayout()
    self.compactSongIcon:layoutIfNeeded()
    local item = TextItem.new(text, TrustStatusWidget.TextSmall)
    item:setShouldWordWrap(false)
    self.compactSongCell:setItem(item)
    self.compactSongCell:setVisible(shown and text ~= '')
    self.compactSongCell:setNeedsLayout()
    self.compactSongCell:layoutIfNeeded()
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
        self.compactTint, self.compactHourglass, self.compactCrystal, self.compactCountCell, self.compactTargetCell,
        self.compactSongIcon, self.compactSongCell,
    }) do
        view:setVisible(compact)
        view:setNeedsLayout()
        view:layoutIfNeeded()
    end
    -- Visibility was just reset for every layer; redraw all of them.
    self.compactDrawn = nil
    self:refreshCompactIcon()
    self:refreshCompactLabels()
    self:refreshCompactSong(true)
end

-- True while an action is playing (drives the green halo).
function TrustStatusWidget:isCompactActing()
    return self.currentAction ~= '' and self.currentAction ~= 'Idle' and self.currentAction ~= 'OFF'
end

-- Look name: stop | pause | act | start. A preview (//trust widget look) wins.
function TrustStatusWidget:getCompactState()
    if self.compactLookPreview then
        return self.compactLookPreview.name
    end
    local queue = self.actionQueue
    return CompactTrustLook.name_for(queue and queue.control_state, self.addonEnabled:getValue())
end

function TrustStatusWidget:setCompactLookPreview(name, acting)
    if name then
        self.compactLookPreview = { name = name, acting = acting and true or false }
    else
        self.compactLookPreview = nil
    end
    self:refreshCompactIcon()
end

-- Start or stop the redraw timer and draw one frame now.
function TrustStatusWidget:refreshCompactIcon()
    if not self.compactIcon or not self.compactPulseTimer then
        return
    end
    if self.compactMode then
        if not self.compactPulseTimer:isRunning() then
            self.compactLookTickAt = os.clock()
            self.compactPulseTimer:start()
        end
        self:tickCompactLook()
    elseif self.compactPulseTimer:isRunning() then
        self.compactPulseTimer:cancel()
    end
end

function TrustStatusWidget:tickCompactLook()
    if not self.compactMode then
        return
    end
    local tun = CompactTrustLook.tunables
    local now = os.clock()
    local dt = math.max(0, now - (self.compactLookTickAt or now))
    self.compactLookTickAt = now
    local name = self:getCompactState()
    local acting = self.compactLookPreview and self.compactLookPreview.acting or self:isCompactActing()
    local targets, pulsing = CompactTrustLook.targets(name, acting)
    -- A pulse restarts from its floor when its layer starts pulsing.
    local pulseKey = (pulsing.hourglass and 'h' or '')..(pulsing.crystal and 'c' or '')
    if pulseKey ~= self.compactPulseKey then
        self.compactPulseKey = pulseKey
        self.compactLookStartedAt = now
    end
    CompactTrustLook.step(self.compactLayers, targets, dt, tun.fade)
    local alphas = CompactTrustLook.alphas(self.compactLayers, pulsing, now - self.compactLookStartedAt, tun)
    local drawn = self.compactDrawn or {}
    self.compactDrawn = drawn
    local function image(view, key)
        if drawn[key] ~= alphas[key] then
            drawn[key] = alphas[key]
            view.alpha = alphas[key]
            view:setVisible(alphas[key] > 0)
            view:setNeedsLayout()
            view:layoutIfNeeded()
        end
    end
    local function color(view, key, r, g, b)
        if drawn[key] ~= alphas[key] then
            drawn[key] = alphas[key]
            view:setBackgroundColor(alphas[key] > 0 and Color.new(alphas[key], r, g, b) or Color.clear)
            view:setNeedsLayout()
            view:layoutIfNeeded()
        end
    end
    self:refreshCompactSong()
    image(self.compactIcon, 'book')
    image(self.compactHourglass, 'hourglass')
    image(self.compactCrystal, 'crystal')
    local red = tun.red_rgb
    color(self.compactTint, 'red', red[1], red[2], red[3])
    color(self.compactGlowOuter, 'green_outer', 23, 110, 63)
    color(self.compactGlowInner, 'green_inner', 19, 105, 58)
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

    -- Anchor against the 32px artwork, not the 40px drag field.
    -- Windower texts uses the *right edge of the screen* as its coordinate
    -- origin when right_justified(true), so compensate for screen width to
    -- place the actual glyph edge exactly at the slot's x=36.
    local targetName = self.compactTargetName or ''
    if targetName:length() > 18 then
        targetName = localization_util.truncate(targetName, 18)
    end
    local textItem = TextItem.new(targetName, TargetWidget.Text)
    textItem:setShouldWordWrap(false)
    local right = self.compactAlignment == 'Right'
    self.compactTargetCell.textView:right_justified(right)
    local screenWidth = windower.get_windower_settings().ui_x_res
    textItem:setOffset(right and (36 - screenWidth) or 4, 0)
    self.compactTargetCell:setItem(textItem)

    -- Solo mode carries no party badge; it appears only for 2–6 members.
    self.compactCountCell:setVisible(self.compactMode and
        (tonumber(self.compactPartyCount) or 0) >= 2)
    self.compactTargetCell:setVisible(self.compactMode and targetName ~= '')
    self.compactCountCell:setNeedsLayout()
    self.compactTargetCell:setNeedsLayout()
    self.compactCountCell:layoutIfNeeded()
    self.compactTargetCell:layoutIfNeeded()
end

-- The layout picker explicitly sets the edge. It has no persistent
-- alignment setting today, so infer the last Left/Right choice from the
-- restored widget position on initial load; dragging doesn't change the side.
function TrustStatusWidget:setCompactAlignment(alignment)
    if alignment ~= 'Left' and alignment ~= 'Right' then
        return
    end
    if self.compactAlignment ~= alignment then
        self.compactAlignment = alignment
        self:refreshCompactLabels()
    end
end

function TrustStatusWidget:restoreCompactAlignmentFromPosition()
    local width = windower.get_windower_settings().ui_x_res
    if width and width > 0 then
        local x = self:getPosition().x
        self:setCompactAlignment(x + self.compactWidth / 2 > width / 2 and 'Right' or 'Left')
    end
end

function TrustStatusWidget:compactExtraHitTest(x, y)
    if self.compactTargetName == '' then
        return false
    end
    local pos = self:getAbsolutePosition()
    local textWidth = self.compactTargetCell.textView:extents()
    if type(textWidth) ~= 'number' then
        textWidth = math.floor(math.min(#self.compactTargetName, 18) * 5.2 + 0.5)
    end
    local startX = self.compactAlignment == 'Right' and 36 - textWidth or 4
    return x >= pos.x + startX and x <= pos.x + startX + textWidth
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