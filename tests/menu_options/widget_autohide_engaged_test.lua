-- Widget autohide modes (2026-11-19): Off / On / Show When Engaged. Host simulation of
-- the production controller (ui/WidgetAutohide.lua) with injected game doubles.
local pass, fail = 0, 0
local function check(name, ok)
    if ok then pass = pass + 1 else fail = fail + 1; print('FAIL: ' .. name) end
end
local M = dofile('ui/WidgetAutohide.lua')
local now, engaged, visible, saves = 0, false, true, 0
local values = { autohide = false, autohide_seconds = 5 }
local a = M.new({
    settings = function() return values end,
    save = function() saves = saves + 1; return true end,
    clock = function() return now end,
    focused = function() return true end,
    engaged = function() return engaged end,
    apply = function(v) visible = v end,
    position = function() return { x = 0, y = 0 } end,
    automated = function() return false end,
    suspended = function() return nil end,
})
local function run(seconds) for i = 1, seconds * 10 do now = now + 0.1; a:tick() end end

check('older settings without a mode: autohide false -> Off', a:mode() == 'Off')
values.autohide = true
check('older settings: autohide true -> On', a:mode() == 'On')
values.autohide = false

-- Show When Engaged through the command.
local ok, text = a:command('engaged')
check('command engaged -> Show When Engaged, saved', ok and a:mode() == 'Show When Engaged' and values.autohide == true and saves == 1)
check('describe mentions engaged', text:find('shown while engaged', 1, true) ~= nil)
run(6)
check('idle out of combat -> hidden', visible == false and a.state == 'hidden')
engaged = true; run(0.2)
check('engaging shows the widgets', visible == true and a.suspended_by == 'engaged')
run(30)
check('stays visible the whole fight', visible == true)
engaged = false; run(4)
check('fight over: idle time restarts from the end of the fight', visible == true)
run(1.5)
check('then hides after the idle time', visible == false)

-- Plain On hides even while engaged.
a:set_mode('On'); engaged = true; a:touch('keyboard'); run(6)
check('On: hides while engaged too', visible == false and a.suspended_by == nil)
engaged = false

-- set_enabled keeps Show When Engaged; Off and back on.
a:set_mode('Show When Engaged')
a:set_enabled(true)
check('on keeps Show When Engaged', a:mode() == 'Show When Engaged')
a:command('off')
check('off -> Off, autohide false', a:mode() == 'Off' and values.autohide == false and visible == true)
a:command('on')
check('on from Off -> On', a:mode() == 'On')
a:set_mode('Show When Engaged'); a:command('10')
check('seconds keep Show When Engaged', a:mode() == 'Show When Engaged' and values.autohide_seconds == 10)
local bad = a:set_mode('Sometimes')
check('unknown mode rejected', bad == false and a:mode() == 'Show When Engaged')
check('usage mentions engaged', select(2, a:command('maybe')):find('engaged', 1, true) ~= nil)
check('modes for the menu', #M.MODES == 3 and M.MODES[3] == 'Show When Engaged')

-- No engaged hook (older wiring): Show When Engaged behaves like On.
local values2 = { autohide = true, autohide_mode = 'Show When Engaged', autohide_seconds = 5 }
local v2 = true
local b = M.new({ settings = function() return values2 end, save = function() return true end,
    clock = function() return now end, focused = function() return true end,
    apply = function(v) v2 = v end, position = function() return nil end,
    automated = function() return false end, suspended = function() return nil end })
for i = 1, 60 do now = now + 0.1; b:tick() end
check('without an engaged hook it still hides', v2 == false)

print(string.format('widget_autohide_engaged_test: %d pass, %d fail', pass, fail))
if fail > 0 then error('widget_autohide_engaged_test failed') end
