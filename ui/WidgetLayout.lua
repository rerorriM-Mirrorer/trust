-- A: arrange the Trust, Party and Target widgets on the left or right edge.
-- Shared by Widgets > Layout and //trust widget left|right.
local WidgetLayout = {}

WidgetLayout.margin = 16 -- pixels from the screen edge (unchanged)
WidgetLayout.gap = 5     -- pixels between stacked widgets (unchanged)

function WidgetLayout.arrange(alignment)
    if alignment ~= 'Left' and alignment ~= 'Right' then
        return false, 'Alignment must be Left or Right'
    end
    local ui = windower.trust.ui
    local settings = windower.get_windower_settings()

    -- The compact name belongs to Trust's slot: the left preset starts the
    -- text at the left sprite edge, the right preset ends it at the right edge.
    local host = ui.get_widget('trust')
    if host and host.setCompactAlignment then
        host:setCompactAlignment(alignment)
    end

    local yPos = settings.ui_y_res / 2 - 75
    for widgetName in L{ 'Trust', 'Party', 'Target' }:it() do
        local widget = ui.get_widget(widgetName)
        if widget then
            local xPos
            if alignment == 'Left' then
                xPos = WidgetLayout.margin
            else
                xPos = settings.ui_x_res - widget:getSize().width - WidgetLayout.margin
            end
            -- Editing on/off saves the new position like a drag does.
            widget:setEditing(true)
            widget:setPosition(xPos, yPos)
            widget:setEditing(false)
            widget:layoutIfNeeded()
            yPos = yPos + (widget:getMaxHeight() or widget:getSize().height) + WidgetLayout.gap
        end
    end
    return true
end

return WidgetLayout
