-- Exercise real focus, view teardown, and scrolling methods without Windower rendering.
local methods = {}
function L(items) return setmetatable(items or {}, { __index = methods }) end
function methods:length() return #self end
function methods:last() return self[#self] end
function methods:append(item) self[#self + 1] = item end
function methods:remove(index) return table.remove(self, index) end
function methods:it()
    local index = 0
    return function() index = index + 1; return self[index] end
end

local paths = {
    'cylibs/ui/views/view.lua',
    'cylibs/ui/collection_view/collection_view_delegate.lua',
    'cylibs/ui/scroll_view/scroll_view.lua',
    'cylibs/ui/menu/menu.lua',
}
for _, path in ipairs(paths) do
    local file = assert(io.open(path))
    for module in file:read('*a'):gmatch("require%('([^']+)'%)") do
        package.loaded[module] = package.loaded[module] or {}
    end
    file:close()
end
local focus = dofile('cylibs/ui/focus/focus_manager.lua')
package.loaded['cylibs/ui/focus/focus_manager'] = focus
package.loaded['cylibs/ui/views/color'].new = function() return {} end
package.loaded['cylibs/ui/views/frame'].new = function(...) return {...} end
package.loaded['cylibs/events/dispose_bag'].new = function()
    return { addAny = function() end, destroy = function() end }
end
local View = dofile(paths[1])
local Delegate = dofile(paths[2])
local ScrollView = dofile(paths[3])
local Menu = dofile(paths[4])
local manager = focus.shared()

-- Model the direct picker taking focus and synchronously replacing itself.
-- Also exercise a focused field with a covered editor in the stack.
local function view()
    local result = View.new({})
    result.setHasFocus = function(self, enabled)
        assert(not self.destroyed, 'Focus callback on disposed view')
        View.setHasFocus(self, enabled)
    end
    return result
end
local menu, picker, list, field = view(), view(), view(), view()
assert(menu:requestFocus() and picker:requestFocus())
picker:destroy()
assert(manager:getFocusable() == menu and menu:hasFocus())
assert(not picker:requestFocus() and not picker:hasFocus())
assert(list:requestFocus() and field:requestFocus())
field:setShouldResignFocus(false)
list:destroy()
assert(manager:getFocusable() == field)
field:destroy()
assert(manager:getFocusable() == menu and menu:hasFocus())
menu:destroy()
assert(manager:getFocusable() == nil)

-- Multiple rows created in a single tick must all attach to their parent.
local random = math.random
math.random = function() return 42 end
local parent, weaponskills, food, gambits = view(), view(), view(), view()
math.random = random
for _, row in ipairs({ weaponskills, food, gambits }) do parent:addSubview(row) end
assert(#parent:getSubviews() == 3 and food.superview == parent)
food:destroy()
assert(#parent:getSubviews() == 2 and gambits.superview == parent)

-- Fixed menus have no scrollbars. Up and Down can still move their cursor.
local fixed = setmetatable({ scrollEnabled = false }, ScrollView)
assert(not fixed:scrollUp() and not fixed:scrollDown())
local calls = 0
local scroll = { trigger = function() calls = calls + 1 end }
local enabled = setmetatable({
    scrollEnabled = true, lastScrollTime = -1, scrollCooldown = 0,
    verticalScrollBar = {
        onScrollBackClick = function() return scroll end,
        onScrollForwardClick = function() return scroll end,
    },
}, ScrollView)
assert(enabled:scrollUp() and enabled:scrollDown() and calls == 2)

local path = { section = 1, row = 2 }
local removed = setmetatable({}, Delegate)
removed:setCursorIndexPath(path)
local active = setmetatable({
    collectionView = { getDataSource = function()
        return { itemAtIndexPath = function() return nil end }
    end },
}, Delegate)
active:setCursorIndexPath(path)
assert(active:getCursorIndexPath() == nil)
local forwarded = setmetatable({
    viewStack = { getCurrentView = function() return picker end },
}, Menu)
forwarded:setHasFocus(true)
assert(forwarded:hasFocus() and not picker:hasFocus())

print('PASS: direct picker and nested focus teardown, unique sibling rows, fixed menu scrolling, and retired cursor guards')
