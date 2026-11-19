-- A: Global idle autohide for every Trust widget.
--
-- One controller, one timer, one command. It never touches an individual
-- widget's own visibility; the caller's `apply(visible)` hides or shows the
-- TrustWidgets container, so Full/Compact state, per-widget logic and any
-- widget added later are unaffected and automatically participate.
--
-- Everything the controller needs from FFXI/Windower is injected through
-- `options`, so the state machine can be tested without the game.
--
-- States (explicit rather than a handful of booleans):
--   off     autohide is disabled; widgets are shown.
--   awake   enabled and counting idle time; widgets are shown.
--   hidden  idle time elapsed; widgets are hidden until the next activity.
--
-- Modes (setting `autohide_mode`; the older `autohide` true/false is kept in step):
--   Off                 never hide.
--   On                  hide after the idle time.
--   Show When Engaged   as On, but while this character is engaged the widgets stay
--                       visible (like an open menu); the idle time restarts when the
--                       fight ends.
--
-- Only *player* activity restarts the timer: keyboard, mouse, controller
-- commands, regaining window focus, and the player's own movement. Movement
-- that Trust itself produces (follow, pathing, queued runs) is excluded, so
-- background automation never keeps the widgets on screen.

local M = {}

M.DEFAULT_SECONDS = 5
M.MODES = { 'Off', 'On', 'Show When Engaged' }
local VALID = { Off = true, On = true, ['Show When Engaged'] = true }
M.MIN_SECONDS = 1
M.MAX_SECONDS = 600

-- How often the player's position is sampled, and the per-sample distance
-- band (yalms) that counts as walking. Anything larger is a zone change or
-- teleport, not input.
local SAMPLE_INTERVAL = 0.25
local MIN_STEP = 0.05
local MAX_STEP = 10

function M.new(options)
    local self = {
        state = 'off',
        last = 0,
        source = 'none',
        suspended_by = nil,
        touches = 0,
        hides = 0,
        last_position = nil,
        next_sample = 0,
    }

    local function settings()
        return options.settings()
    end

    function self:mode()
        local values = settings()
        if VALID[values.autohide_mode] then
            return values.autohide_mode
        end
        return values.autohide == true and 'On' or 'Off'
    end

    function self:is_enabled()
        return self:mode() ~= 'Off'
    end

    function self:seconds()
        local value = tonumber(settings().autohide_seconds)
        if not value or value < M.MIN_SECONDS or value > M.MAX_SECONDS then
            return M.DEFAULT_SECONDS
        end
        return value
    end

    local function show(self)
        self.state = 'awake'
        options.apply(true)
    end

    -- Register player activity. `requires_focus` is for sources that can reach
    -- an unfocused client (mouse moving across its window); only the client
    -- the player is actually using should wake up.
    function self:touch(source, requires_focus)
        if not self:is_enabled() then
            return false
        end
        if requires_focus and not options.focused() then
            return false
        end
        self.last = options.clock()
        self.source = source or 'unknown'
        self.touches = self.touches + 1
        if self.state == 'hidden' then
            show(self)
        end
        return true
    end

    -- Walking by the player's own hand counts; walking Trust asked for does not.
    local function sample_movement(self, now)
        if now < self.next_sample then
            return
        end
        self.next_sample = now + SAMPLE_INTERVAL
        local position = options.position()
        local previous = self.last_position
        self.last_position = position
        if not position or not previous then
            return
        end
        local dx, dy = position.x - previous.x, position.y - previous.y
        local step = math.sqrt(dx * dx + dy * dy)
        if step > MIN_STEP and step < MAX_STEP and not options.automated() then
            self:touch('movement')
        end
    end

    -- Called every frame; cheap when nothing changes.
    function self:tick()
        local now = options.clock()
        if not self:is_enabled() then
            if self.state == 'hidden' then
                options.apply(true)
            end
            self.state = 'off'
            self.suspended_by = nil
            self.last_position = nil
            return
        end
        if self.state == 'off' then
            -- Fresh timer whenever autohide is switched on.
            self.state = 'awake'
            self.last = now
            self.source = 'enabled'
        end
        sample_movement(self, now)

        -- Menus and widget edit/drag/focus pause the countdown; the timer
        -- restarts from the moment they end.
        local reason = options.suspended()
        if reason then
            self.suspended_by = reason
            self.last = now
            if self.state == 'hidden' then
                show(self)
            end
            return
        end
        -- Show When Engaged: a fight holds the widgets up just like a menu does.
        if self:mode() == 'Show When Engaged' and options.engaged and options.engaged() then
            self.suspended_by = 'engaged'
            self.last = now
            if self.state == 'hidden' then
                show(self)
            end
            return
        end
        self.suspended_by = nil

        if self.state == 'awake' and now - self.last >= self:seconds() then
            self.state = 'hidden'
            self.hides = self.hides + 1
            options.apply(false)
        end
    end

    local function persist()
        local ok, why = options.save()
        if ok == false then
            return false, why or 'Unable to save autohide settings.'
        end
        return true
    end

    function self:set_mode(mode)
        if not VALID[mode] then
            return false, 'Autohide must be Off, On or Show When Engaged'
        end
        local values = settings()
        local enabled = mode ~= 'Off'
        if values.autohide_mode ~= mode or values.autohide ~= enabled then
            values.autohide_mode = mode
            values.autohide = enabled
            local ok, why = persist()
            if not ok then
                return false, why
            end
        end
        -- Apply right away rather than waiting for the next frame.
        self:tick()
        return true
    end

    -- On keeps Show When Engaged if that is already chosen.
    function self:set_enabled(enabled)
        if not enabled then
            return self:set_mode('Off')
        end
        local current = self:mode()
        return self:set_mode(current ~= 'Off' and current or 'On')
    end

    -- A duration also turns autohide on, as in `//trust autohide 10`.
    function self:set_seconds(value)
        local seconds = tonumber(value)
        if not seconds or seconds < M.MIN_SECONDS or seconds > M.MAX_SECONDS then
            return false, 'Seconds must be '..M.MIN_SECONDS..'-'..M.MAX_SECONDS
        end
        local values = settings()
        local mode = self:mode() ~= 'Off' and self:mode() or 'On'
        local changed = values.autohide_seconds ~= seconds or values.autohide ~= true or values.autohide_mode ~= mode
        values.autohide_seconds = seconds
        values.autohide = true
        values.autohide_mode = mode
        if changed then
            local ok, why = persist()
            if not ok then
                return false, why
            end
        end
        self.last = options.clock()
        self:tick()
        return true
    end

    function self:describe()
        if not self:is_enabled() then
            return 'OFF'
        end
        local text = 'ON, hide after '..self:seconds()..'s'
        if self:mode() == 'Show When Engaged' then
            text = text..', shown while engaged'
        end
        return text
    end

    -- //trust autohide [on|off|engaged|<seconds>]
    -- A bare command toggles. Explicit on/off/<seconds> are idempotent.
    function self:command(value)
        local ok, why
        if value == nil then
            ok, why = self:set_enabled(not self:is_enabled())
        else
            local text = tostring(value):lower()
            if text == 'on' then
                ok, why = self:set_enabled(true)
            elseif text == 'off' then
                ok, why = self:set_enabled(false)
            elseif text == 'engaged' or text == 'combat' then
                ok, why = self:set_mode('Show When Engaged')
            elseif tonumber(text) then
                ok, why = self:set_seconds(tonumber(text))
            else
                return false, 'Usage: //trust autohide [on|off|engaged|<seconds>]'
            end
        end
        if not ok then
            return false, why
        end
        return true, 'Widget autohide '..self:describe()
    end

    function self:status()
        local text = self:describe()
        if self:is_enabled() then
            text = text..' | '..self.state
            if self.suspended_by then
                text = text..' (paused: '..self.suspended_by..')'
            end
            text = text..' | last activity: '..self.source
                ..' | activity '..self.touches..' | hides '..self.hides
        end
        return text
    end

    -- Never leave widgets hidden behind an unloaded controller.
    function self:close()
        if self.state == 'hidden' then
            options.apply(true)
        end
        self.state = 'off'
    end

    return self
end

return M
