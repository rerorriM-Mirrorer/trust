local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local Event = require('cylibs/events/Luvent')
local Frame = require('cylibs/ui/views/frame')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local SearchBarView = setmetatable({}, {__index = ConfigEditor })
SearchBarView.__index = SearchBarView

function SearchBarView:onSearchQueryChanged()
    return self.searchQueryChanged
end

function SearchBarView.new()
    local configItems = L{
        TextInputConfigItem.new('query', '', 'Enter: apply | Esc: cancel', function(text) return #text <= 24 end, 260, 24)
    }
    local searchResults = {
        query = ''
    }

    local self = setmetatable(ConfigEditor.new(nil, searchResults, configItems, nil, nil, nil, Frame.new(0, 0, 300, 70), "Filter"), SearchBarView)
    self:setTitle("Filter", 100)

    self.resignFocusKeys = L{ 1, 28 }
    self.searchQueryChanged = Event.newEvent()

    self:onConfigItemChanged():addAction(function(key, currentValue, initialValue)
        if not self.cancelSearch then self:onSearchQueryChanged():trigger(self, currentValue, initialValue) end
    end)

    local item = self:getDataSource():itemAtIndexPath({section=1, row=1})
    item.onTextSubmit = function()
        self:onSearchQueryChanged():trigger(self, self:readDraft().query)
        self:resignFirstResponder()
        self:resignFocus()
    end
    item.onTextCancel = function()
        self.cancelSearch = true
        self:resignFirstResponder()
        self:resignFocus()
        self.cancelSearch = false
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SearchBarView:destroy()
    ConfigEditor.destroy(self)

    self.searchQueryChanged:removeAllActions()
end

return SearchBarView
