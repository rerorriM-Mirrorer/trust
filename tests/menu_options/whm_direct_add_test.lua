-- Host regression for the WHM menu flow and Buffer's runtime target expansion.
local list_methods = {}
local list_mt = { __index = list_methods }
function list_mt.__add(left, right)
    local result = L{}
    for value in left:it() do result:append(value) end
    for value in right:it() do result:append(value) end
    return result
end
function L(values) return setmetatable(values or {}, list_mt) end
function list_methods:append(value) self[#self + 1] = value end
function list_methods:length() return #self end
function list_methods:remove(index) return table.remove(self, index) end
function list_methods:it()
    local index = 0
    return function() index = index + 1; return self[index] end
end
function list_methods:filter(predicate)
    local result = L{}
    for item in self:it() do if predicate(item) then result:append(item) end end
    return result
end
function list_methods:firstWhere(predicate)
    for item in self:it() do if predicate(item) then return item end end
end
function list_methods:map(transform)
    local result = L{}
    for item in self:it() do result:append(transform(item)) end
    return result
end
function list_methods:unique()
    local result = L{}
    for value in self:it() do
        if not result:contains(value) then result:append(value) end
    end
    return result
end
function list_methods:contains(value)
    return self:firstWhere(function(item) return item == value end) ~= nil
end

local function stub_dependencies(path)
    local file = assert(io.open(path))
    local source = file:read('*a')
    file:close()
    for name in source:gmatch("require%('([^']+)'%)") do
        package.loaded[name] = package.loaded[name] or {}
    end
end

local menu_path = 'ui/settings/menus/gambits/GambitSettingsMenuItem.lua'
local buffer_path = 'cylibs/trust/roles/buffer.lua'
local editor_path = 'ui/settings/editors/GambitSettingsEditor.lua'
stub_dependencies(menu_path)
stub_dependencies(buffer_path)
stub_dependencies(editor_path)
package.loaded['cylibs/gambits/gambit_target'].TargetType = { Self = 'Self', Ally = 'Ally', Enemy = 'Enemy' }
package.loaded['cylibs/ui/collection_view/index_path'].new = function(section, row)
    return { section = section, row = row }
end
package.loaded['cylibs/ui/collection_view/items/button_item'].localized = function(label) return label end
package.loaded['cylibs/ui/menu/menu_item'].new = function(buttons, _, content)
    return { buttons = buttons, content = content, setChildMenuItem = function(self, name, child)
        self[name] = child
    end }
end
package.loaded['ui/settings/editors/config/PickerConfigItem'].new = function(key, initial, choices)
    return { key = key, initial = initial, choices = choices }
end
package.loaded['ui/settings/editors/config/MultiPickerConfigItem'].new = function()
    return { setNumItemsRequired = function() end }
end
package.loaded['cylibs/gambits/gambit'].new = function(target, _, ability)
    return { target = target, ability = ability }
end
i18n = { translate = function(key) return key end }
local function event()
    return { addAction = function(self, action) self.action = action; return action end,
        trigger = function(self, ...) if self.action then self.action(...) end end }
end
local pick = event()
package.loaded['ui/themes/ffxi/FFXIFastPickerView'].new = function()
    return {
        setPickOnSelect = function(self, enabled) self.pickOnSelect = enabled end,
        on_pick_items = function() return pick end,
        getDisposeBag = function() return { add = function() end } end,
    }
end
local category = { getName = function() return 'Heals' end }
local library = package.loaded['ui/settings/menus/gambits/GambitLibraryMenuItem']
library.getGambitCategories = function() return L{ category } end
library.getGambitCategoryMenuItem = function(item, add)
    assert(item == category)
    return { add = add }
end

library.new = function(_, add) return { add = add } end
package.loaded['ui/settings/menus/gambits/GambitEditorStyle'].Permissions = { New = 'New' }
local GambitSettingsMenuItem = dofile(menu_path)
local save_count, cursor, selected, offset, focused, shown = 0
local gambits = L{ 'existing' }
local delegate = {
    setCursorIndexPath = function(_, path) cursor = path.row end,
    selectItemAtIndexPath = function(_, path) selected = path.row end,
}
local editor_view = {
    getContentSize = function() return { height = 160 } end,
    getPadding = function() return { bottom = 8 } end,
    getSize = function() return { height = 100 } end,
    getContentOffset = function() return { x = 0 } end,
    setContentOffset = function(_, _, y) offset = y end,
    requestFocus = function() focused = true end,
    getDelegate = function() return delegate end,
}
local menu = setmetatable({
    getTitleText = function() return 'Test' end,
    editorConfig = { getDescription = function() return 'action' end },
    gambitCreated = event(),
    buttonItems = L{}, childMenuItems = {},
    getSettings = function() return { Gambits = gambits } end,
    setChildMenuItem = function(self, name, item) self[name] = item end,
    getAbilitiesByTargetType = function() return { Self = L{ 'Protect' }, Enemy = L{ 'Dia' } } end,
    trustSettings = { saveSettings = function() save_count = save_count + 1 end },
    gambitSettingsEditor = editor_view,
}, GambitSettingsMenuItem)
local function show_menu(item) assert(item == menu); shown = true end

menu:enableDirectAdd('Self')
local picker = menu.Add.content(nil, nil, show_menu)
assert(picker.pickOnSelect and #menu.Add.buttons == 1 and not shown and save_count == 0)
pick:trigger(picker, L{ 'Protect' })
assert(gambits[2].target == 'Self' and gambits[2].ability == 'Protect')
assert(shown and not focused and cursor == 2 and selected == 2 and offset == -68 and save_count == 1)
menu:enableDirectAdd('Enemy')
picker = menu.Add.content(nil, nil, show_menu)
pick:trigger(picker, L{ 'Dia' })
assert(gambits[3].target == 'Enemy' and cursor == 3 and save_count == 2)
menu:enableDirectAdd(nil, 'Heals')
local preset = { conditions = L{ 'HP threshold' } }
menu.Add.add(preset, show_menu)
assert(gambits[4] == preset and selected == 4 and save_count == 3)
menu.trustSettings.saveSettings = function() return false, 'write failed' end
addon_system_error = function(message) assert(message == 'write failed') end
shown = false
menu.Add.add({ conditions = L{} }, show_menu)
assert(#gambits == 4 and not shown and selected == 4)

menu.directAddCategory = nil
menu.editorConfig.hasEditPermission = function() return true end
menu.abilityTargets = L{ 'Enemy', 'Self' }
menu.trustSettings.saveSettings = function() save_count = save_count + 1 end
local add = menu:getAddAbilityMenuItem()
assert(add.Self and add.Enemy and add.Browse and not add.New and not add.Ally)
local targetPicker = add.Enemy.content(nil, nil, show_menu)
assert(targetPicker.pickOnSelect)
pick:trigger(targetPicker, L{ 'Dia' })
assert(gambits[5].ability == 'Dia' and cursor == 5 and selected == 5 and not focused)
add.Browse.add(preset, show_menu)
assert(gambits[6] == preset and cursor == 6 and selected == 6)
menu.editorConfig.hasEditPermission = function() return false end
add = menu:getAddAbilityMenuItem()
assert(add.Browse and not add.Self and not add.Enemy)

local Editor = dofile(editor_path)
local function target_choices(ability, current)
    local gambit = {
        target = current, conditions = L{}, tags = L{},
        getAbilityTarget = function(self) return self.target end,
        getAbility = function() return ability end,
    }
    return Editor.configItems(gambit, { Self = L{ 'Protect', 'Aquaveil' },
        Ally = L{ 'Protect' }, Both = L{ 'Protect' } }, L{ 'Self', 'Ally', 'Both' }, nil, L{}, nil, true)
end
local choices = target_choices('Protect', 'Self')[1]
assert(choices.key == 'target' and table.concat(choices.choices, ',') == 'Self,Ally,Both')
assert(target_choices('Aquaveil', 'Self')[1].key == 'ability')

local Buffer = dofile(buffer_path)
Buff = { __type = 'Buff' }
windower = { ffxi = { get_party = function()
    return { p1 = { mob = { id = 20 } }, p2 = { mob = { id = 10 } } }
end } }
local function condition(name, editable)
    return { name = name, is_editable = function() return editable end,
        set_editable = function(_, value) editable = value end }
end
local function buff(target, conditions)
    return {
        target = target, conditions = conditions, enabled = false,
        getAbility = function() return {} end,
        getAbilityTarget = function(self) return self.target end,
        addCondition = function(self, value) self.conditions:append(value) end,
        setPriorityComparator = function(self, comparator) self.order = comparator end,
        copy = function(self)
            local result = {}
            for key, value in pairs(self) do result[key] = value end
            return result
        end,
    }
end
local role = setmetatable({
    get_default_conditions = function(_, item) return L{ condition(item.target, false) } end,
    set_gambit_settings = function(self, settings) self.runtime = settings.Gambits end,
}, Buffer)
local single = buff('Self', L{})
local both = buff('Both', L{ condition('Custom', true), condition('Old default', false) })
role:set_buff_settings({ Gambits = L{ single, both } })
local self_buff, ally_buff = role.runtime[2], role.runtime[3]
assert(#role.runtime == 3 and role.runtime[1] == single)
assert(self_buff.target == 'Self' and ally_buff.target == 'Ally')
assert(not self_buff.enabled and not ally_buff.enabled and both.target == 'Both')
assert(self_buff.conditions[1].name == 'Custom' and self_buff.conditions[2].name == 'Self')
assert(ally_buff.conditions[1].name == 'Custom' and ally_buff.conditions[2].name == 'Ally')
assert(#both.conditions == 1 and both.conditions[1].name == 'Custom')
local first = { get_id = function() return 20 end }
local second = { get_id = function() return 10 end }
assert(ally_buff.order(first, second) and not ally_buff.order(second, first))

print('PASS: WHM direct add, cursor restoration, compatible buff targets, and Both runtime expansion')
