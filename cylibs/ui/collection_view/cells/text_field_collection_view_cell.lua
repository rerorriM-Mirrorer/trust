local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local Keyboard = require('cylibs/ui/input/keyboard')
local Timer = require('cylibs/util/timers/timer')
local texts = require('texts')

local TextFieldCollectionViewCell = setmetatable({}, {__index = ButtonCollectionViewCell })
TextFieldCollectionViewCell.__index = TextFieldCollectionViewCell


function TextFieldCollectionViewCell.new(textFieldItem)
    local self = setmetatable(ButtonCollectionViewCell.new(textFieldItem), TextFieldCollectionViewCell)

    self.lastCursorUpdate = os.clock()

    self.cursorTextView = texts.new("|", textFieldItem:getTextItem():getSettings())
    self.cursorTextView:bg_alpha(0)
    self.cursorTextView:hide()

    self.cursorTimer = Timer.scheduledTimer(0.05)
    self.disposeBag:add(self.cursorTimer:onTimeChange():addAction(function(_)
        self:updateCursor()
    end), self.cursorTimer:onTimeChange())

    self:getDisposeBag():addAny(L{ self.cursorTextView, self.cursorTimer })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function TextFieldCollectionViewCell:setSelected(selected)
    if not ButtonCollectionViewCell.setSelected(self, selected) then
        return false
    end

    if selected then
        self:requestFocus()
    else
        self:resignFocus()
    end
end

function TextFieldCollectionViewCell:updateCursor()
    if self:hasFocus() then
        local textView = self.textView.textView

        self.cursorTextView:pos(textView:pos_x() + math.min(textView:extents(), math.max(0, self.textView:getSize().width - 4)), textView:pos_y() - 1)
        self.cursorTextView:visible(textView:visible())

        if os.clock() - self.lastCursorUpdate >= 0.5 then
            self.lastCursorUpdate = os.clock()
            local alpha = self.cursorTextView:alpha()
            if alpha == 255 then
                alpha = 0
            else
                alpha = 255
            end
            self.cursorTextView:alpha(alpha)
        end
    else
        self.cursorTextView:hide()
    end
end

-- Bound rendered text to the field artwork, reserving room for the caret.
function TextFieldCollectionViewCell:layoutIfNeeded()
    if not ButtonCollectionViewCell.layoutIfNeeded(self) then return false end
    local size = self:getItem():getSize()
    self.textView:setSize(math.max(1, math.min(self:getSize().width, size.width) - 14), self.textView:getSize().height)
    self.textView:setNeedsLayout()
    self.textView:layoutIfNeeded()
    return true
end

function TextFieldCollectionViewCell:onKeyboardEvent(key, pressed, flags, blocked, resolved_key)
    if blocked then return true end
    local item = self:getItem()
    if pressed and key == 28 and item.onTextSubmit then item.onTextSubmit();return true end
    if pressed and key == 1 and item.onTextCancel then item.onTextCancel();return true end
    if ButtonCollectionViewCell.onKeyboardEvent(self, key, pressed, flags, blocked, resolved_key) then return true end
    if not pressed then return true end
    local name = Keyboard.input():getKey(key, flags)
    local textItem = item:getTextItem()
    if not name or not textItem then return true end
    local currentText = textItem:getText()
    local newText
    if name == 'Backspace' then
        newText = currentText:sub(1, -2)
    elseif flags == 0 or flags == 1 then
        -- Keyboard names (Up, Down, Shift, Control...) are never characters.
        local punctuation = {Minus='-', ['Numpad-']='-', ['Numpad+']='+', ['Numpad/']='/', Equals='='}
        local char = punctuation[name] or name
        if #char == 1 and char:byte() >= 32 and char:byte() <= 126 then
            if char:match('%a') then char = flags == 1 and char:upper() or char:lower() end
            if char == '"' and flags == 0 then char = "'" end
            newText = currentText..char
        end
    end
    if newText and item:isValid(newText) then
        textItem:setText(newText)
        self:setNeedsLayout()
        self:layoutIfNeeded()
    end
    return true
end

function TextFieldCollectionViewCell:getKeyBlacklist()
    return S{ 'Left', 'Right', 'Up', 'Down', 'Escape', 'LShift', 'RShift', 'LControl', 'RControl', 'Enter' }
end

function TextFieldCollectionViewCell:acceptsTextInput()
    return true
end

function TextFieldCollectionViewCell:setCursorVisible(cursorVisible)
    if cursorVisible then
        self.cursorTimer:resume()
    else
        self.cursorTimer:pause()
        self.cursorTextView:hide()
        self.cursorTextView:alpha(255)
    end
    self:updateCursor(999)
end

function TextFieldCollectionViewCell:setHasFocus(hasFocus)
    ButtonCollectionViewCell.setHasFocus(self, hasFocus)

    self:setCursorVisible(hasFocus)

    self:layoutIfNeeded()

    Keyboard.input():setActive(self:hasFocus())
end

return TextFieldCollectionViewCell
