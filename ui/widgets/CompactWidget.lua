-- Shared presentation behavior for the experimental compact Trust, Party and Target widgets.
-- This changes only appearance and pointer handling; the original data sources
-- remain intact so Full mode can restore their normal functionality.
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local Mouse = require('cylibs/ui/input/mouse')
local Widget = require('ui/widgets/Widget')

local CompactWidget = {}

function CompactWidget.setMode(widget, compact)
    if widget.compactMode == compact then
        return false
    end
    widget.compactDrag = nil
    widget.compactMode = compact
    if compact then
        widget:setSize(widget.compactWidth, widget.compactHeight)
    else
        widget:setSize(widget.fullWidth, widget.fullHeight)
        widget:getContentView():setVisible(true)
        widget:getBackgroundImageView():setVisible(true)
    end
    if widget.updateCompactVisibility then
        widget:updateCompactVisibility()
    end
    widget:setNeedsLayout()
    widget:layoutIfNeeded()
    return true
end

function CompactWidget.layoutIfNeeded(widget)
    if not widget.compactMode then
        return Widget.layoutIfNeeded(widget)
    end

    -- Ordinary widget layout grows to fit the hidden rows. Retain only the
    -- compact visual's actual hitbox, even when game events update rows.
    widget:setSize(widget.compactWidth, widget.compactHeight)
    local changed = CollectionView.layoutIfNeeded(widget)
    local backgroundView = widget:getBackgroundImageView()
    if backgroundView then
        backgroundView:setVisible(false)
        backgroundView:layoutIfNeeded()
    end
    local contentView = widget:getContentView()
    if contentView then
        contentView:setVisible(false)
        contentView:layoutIfNeeded()
    end
    return changed
end

function CompactWidget.hitTest(widget, x, y)
    if not widget.compactMode then
        return Widget.hitTest(widget, x, y)
    end
    if not widget:isVisible() then
        return false
    end
    -- Continue delivering motion/release events after the cursor leaves the
    -- small icon or strip; otherwise tiny widgets cannot be dragged.
    if widget.compactDrag then
        return true
    end
    local position = widget:getAbsolutePosition()
    if x >= position.x and x <= position.x + widget.compactWidth
            and y >= position.y and y <= position.y + widget.compactHeight then
        return true
    end
    -- A name may extend past the slot, but still belongs to the same drag
    -- surface. Each widget can offer its own additional compact hit region.
    return widget.compactExtraHitTest and widget:compactExtraHitTest(x, y) or false
end

function CompactWidget.onMouseEvent(widget, eventType, x, y, delta)
    if not widget.compactMode then
        return Widget.onMouseEvent(widget, eventType, x, y, delta)
    end
    if eventType == Mouse.Event.Click then
        if not CompactWidget.hitTest(widget, x, y) then
            return false
        end
        local position = widget:getPosition()
        widget.compactDrag = { mouseX = x, mouseY = y,
            x = position.x, y = position.y, moved = false }
        return true
    elseif eventType == Mouse.Event.Move and widget.compactDrag then
        local drag = widget.compactDrag
        local dx, dy = x - drag.mouseX, y - drag.mouseY
        if math.abs(dx) > 3 or math.abs(dy) > 3 then
            drag.moved = true
        end
        if drag.moved then
            widget:setPosition(drag.x + dx, drag.y + dy)
            widget:layoutIfNeeded()
        end
        return true
    elseif eventType == Mouse.Event.ClickRelease and widget.compactDrag then
        local moved = widget.compactDrag.moved
        widget.compactDrag = nil
        if moved then
            -- WidgetManager owns the existing per-character position storage.
            widget:onSettingsChanged():trigger(widget)
        end
        -- A simple click no longer changes presentation mode. Use the
        -- explicit //trust widget full|compact commands instead.
        return true
    end
    return false
end

return CompactWidget
