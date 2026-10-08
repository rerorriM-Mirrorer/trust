local Event = require('cylibs/events/Luvent')

local Mouse = {}
Mouse.__index = Mouse

Mouse.Event = {}
Mouse.Event.Move = 0
Mouse.Event.Click = 1
Mouse.Event.ClickRelease = 2
Mouse.Event.Wheel = 10

function Mouse:onMove()
    return self.move
end

function Mouse:onClick()
    return self.click
end

function Mouse:onClickRelease()
    return self.clickRelease
end

function Mouse:onMouseWheel()
    return self.mouseWheel
end

function Mouse:onMouseEvent()
    return self.mouseEvent
end

function Mouse.new()
    local self = setmetatable({}, Mouse)

    self.rootView = hud
    self.events = {}
    self.move = Event.newEvent()
    self.click = Event.newEvent()
    self.clickRelease = Event.newEvent()
    self.mouseWheel = Event.newEvent()
    self.mouseEvent = Event.newEvent()
    self.blockEvent = false
    self.mouseEventCooldown = 0.0
    self.lastMouseEvent = {}

    self.events.mouse = windower.register_event('mouse', function(type, x, y, delta, blocked)
        local lastTime = self.lastMouseEvent[type] or 0
        if os.time() - lastTime < self:getCooldown(type) then
            return true
        end
        self.lastMouseEvent[type] = os.time()

        return self:handleMouseEvent(type, x, y, delta)
    end)

    return self
end

-- Compact widgets have tiny hitboxes and do not use their old content
-- views for mouse events. Route the initial click straight to the visible
-- sprite/strip and capture subsequent motion/release until the drag ends.
-- This avoids unrelated menu/item cells swallowing part of a compact drag.
function Mouse:getCompactWidgets()
    local widgets = L{}
    local trustUi = windower.trust and windower.trust.ui
    if not trustUi or not trustUi.get_widget then
        return widgets
    end
    for _, name in ipairs({ 'trust', 'party', 'target' }) do
        local widget = trustUi.get_widget(name)
        if widget and widget.compactMode and widget:isVisible() then
            widgets:append(widget)
        end
    end
    return widgets
end

function Mouse:handleCompactWidgetMouseEvent(type, x, y, delta)
    local widgets = self:getCompactWidgets()

    -- A captured drag keeps receiving events after the pointer leaves the
    -- sprite and crosses another widget or menu view.
    if type == Mouse.Event.Move or type == Mouse.Event.ClickRelease then
        for widget in widgets:it() do
            if widget.compactDrag then
                return widget:onMouseEvent(type, x, y, delta)
            end
        end
    end

    if type ~= Mouse.Event.Click then
        return false
    end

    -- Don't steal clicks from an open menu or command picker.
    if (hud and hud.trustMenu and hud.trustMenu:isVisible())
            or (hud and hud.viewStack and hud.viewStack.currentView)
            or (command_widget and command_widget:isVisible()) then
        return false
    end

    for widget in widgets:it() do
        if widget:hitTest(x, y) then
            return widget:onMouseEvent(type, x, y, delta)
        end
    end
    return false
end

function Mouse:handleMouseEvent(type, x, y, delta)
    if self:handleCompactWidgetMouseEvent(type, x, y, delta) then
        return true
    end
    local handled
    local currentView
    local allViews = Q{ hud }
    if hud.trustMenu.menuView then
        allViews:push(hud.trustMenu.menuView)
    end
    if hud.viewStack.currentView then
        allViews:push(hud.viewStack.currentView)
    end
    allViews:push(command_widget)
    while not allViews:empty() do
        currentView = allViews:pop()
        if currentView:hitTest(x, y) then
            handled = currentView:onMouseEvent(type, x, y, delta)
            if handled then
                return true
            else
                for subview in currentView:getSubviews():it() do
                    if subview:isUserInteractionEnabled() then
                        allViews:push(subview)
                    end
                end
            end
        end
    end
    return false
end

function Mouse:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self:onMove():removeAllActions()
    self:onClick():removeAllActions()
    self:onClickRelease():removeAllActions()
    self:onMouseWheel():removeAllActions()
    self:onMouseEvent():removeAllActions()
end

function Mouse.input()
    if mouse_input == nil then
        mouse_input = Mouse.new()
    end
    return mouse_input
end



function Mouse:setMouseEventCooldown(mouseEventCooldown)
    self.mouseEventCooldown = mouseEventCooldown
end

function Mouse:getCooldown(mouseEvent)
    if L{ Mouse.Event.Click, Mouse.Event.ClickRelease }:contains(mouseEvent) then
        return self.mouseEventCooldown
    end
    return 0.0
end

return Mouse