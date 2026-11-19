local Event = require('cylibs/events/Luvent')

local TrustAddonSettings = {}
TrustAddonSettings.__index = TrustAddonSettings
TrustAddonSettings.__class = "TrustAddonSettings"

local default = {}

default.battle = {}
default.battle.melee_distance = 2
default.battle.range_distance = 21
default.battle.targets = L{}
default.battle.trusts = L{'Kupipi','Joachim','Koru-Moru','Qultada','Kupofried'}
default.chat = {}
default.chat.ipc_enabled = true
default.discord = {}
default.discord.url = 'https://discord.gg/CfPxDy759J'
default.discord.channels = {}
default.discord.channels.support = 'https://discord.com/channels/1069136494616399883/1242295505334173716'
default.donate = {}
default.donate.url = 'https://www.buymeacoffee.com/cyrite'
default.updater = {}
default.updater.manifest_url = 'https://raw.githubusercontent.com/cyritegamestudios/trust/main/manifest.json'
default.follow = {}
default.follow.distance = 1
default.follow.auto_pause = false
default.follow.fan_out = true
-- Filled once from the active job, then retained across job/profile switches.
default.character_modes = {}
-- `policy` (Delivery policy) and `quiet` are legacy keys kept only so old files load:
-- the menu no longer offers a policy (the sender always gets Send), and `feedback`
-- (Request feedback, off by default) replaces the inverted `quiet`.
default.movement = {policy='Send',quiet=true,feedback=false,enabled=true,assist_others=false,stop_on_movement=true,start_others=false,auto_lockon=false,keep_autorun=false,autorun_messages=false,defaults_version=0,
    recovery={mode='Detour',pulling=true,following=true,paths=true,interval=2,min_movement=.5,
        detour_distance=2,attempts=2,pull_cooldown=30,settle_time=1,diagnostics=true,verbose=true}}
-- autohide: hide every Trust widget after `autohide_seconds` without player input.
default.widgets = {hide_pet=true,autohide=false,autohide_seconds=5}
default.flags = {}
default.flags.show_death_warning = true
default.flags.check_files = true
default.help = {}
default.help.mode_text_enabled = true
default.help.wiki_base_url = 'https://github.com/cyritegamestudios/trust/wiki'
default.logging = {}
default.logging.enabled = false
default.logging.logtofile = false
default.logging.filter_pattern = ''
default.menu_key = '%^numpad+'
-- Testing defaults; each option can be restored independently in Config > Menu.
default.menu = {}
default.menu.layout = 'Condensed'
default.menu.save_on_exit = true
default.menu.adjacent = true
default.menu.ijkl = false
default.autocomplete = {}
default.autocomplete.visible = false
default.remote_commands = {} -- can't get rid of because of migration_v27
default.remote_commands.whitelist = S{}
default.verbose = true
default.shortcuts = {}
default.shortcuts.menus = {}
default.shortcuts.menus.modes = {}
default.shortcuts.menus.modes.enabled = false
default.shortcuts.menus.modes.key = "M"
default.shortcuts.menus.modes.flags = 1
default.shortcuts.menus.gambits = {}
default.shortcuts.menus.gambits.enabled = false
default.shortcuts.menus.gambits.key = "G"
default.shortcuts.menus.gambits.flags = 1
default.shortcuts.menus.skillchains = {}
default.shortcuts.menus.skillchains.enabled = false
default.shortcuts.menus.skillchains.key = "S"
default.shortcuts.menus.skillchains.flags = 1
default.locales = {}
default.locales.font_names = {}
default.locales.font_names.english = "Arial"
default.locales.font_names.japanese = "MS Gothic"
default.locales.actions = {}
default.locales.default = ""
default.use_shared_pulling = true
default.sounds = {}
default.sounds.sound_effects = {}
default.sounds.sound_effects.disabled = true
default.gearswap = {}


-- A: several clients share one data/settings.xml, and Windower's config library
-- has two habits that together made saved settings flip back on their own (for
-- example "Others act on movement" returning to On after //am all reload):
--
--  1. config.save does not re-read the file. It merges this character's values
--     into the copy of the WHOLE file parsed when this client loaded, then writes
--     that copy back, so every other character's section is rewritten from this
--     client's older copy and a newer save by another client is undone.
--  2. When it parses the file it builds each character's section from the code's
--     defaults, not from <global>, then compares against <global>. A character
--     that merely inherits a <global> value that differs from today's default
--     (this file's <global> still holds an older Off) therefore looks like it chose
--     the default, and the next save writes that choice out for it.
--
-- Saves now go through a private "writer" table registered with the library. Before
-- each write it is reset to the defaults, reloaded twice, and then given our values:
-- the first reload runs with no character visible so the table becomes defaults +
-- <global>, the baseline the library should have used; the second is the normal
-- reload, so every character's section is current and compared against that
-- baseline. The live settings table is never touched, so menus holding references
-- to its inner tables keep working. If the library lacks these calls or fails, the
-- old direct save is used so a change is never lost.
local function deep_copy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do copy[deep_copy(k, seen)] = deep_copy(v, seen) end
    return setmetatable(copy, getmetatable(value))
end

-- Runs fn while windower.ffxi.get_player() reports nobody, always restoring it.
local function without_character(fn)
    local ffxi = windower.ffxi
    local real = ffxi.get_player
    ffxi.get_player = function() return nil end
    local ok, err = pcall(fn)
    ffxi.get_player = real
    if not ok then error(err, 0) end
end

local function refresh_writer(writer)
    for key in pairs(writer) do writer[key] = nil end
    for key, value in pairs(deep_copy(default)) do writer[key] = value end
    without_character(function() config.reload(writer) end)
    config.reload(writer)
end

local function save_with_fresh_file(owner, settings)
    if type(config.load) == 'function' and type(config.reload) == 'function' then
        local ok = pcall(function()
            local writer = owner.file_writer
            if not writer then
                writer = config.load(default)
                owner.file_writer = writer
            end
            refresh_writer(writer)
            for key, value in pairs(settings) do writer[key] = value end
            config.save(writer)
        end)
        if ok then return end
    end
    config.save(settings)
end

function TrustAddonSettings:onSettingsChanged()
    return self.settingsChanged
end

function TrustAddonSettings.new()
    local self = setmetatable({}, TrustAddonSettings)

    self.settingsChanged = Event.newEvent()
    self.settings = {}

    return self
end

function TrustAddonSettings:loadFile()
    return coroutine.create(function()
        local settings = config.load(default)
        coroutine.yield(settings)
    end)
end

function TrustAddonSettings:loadSettings()
    local _, settings = coroutine.resume(self:loadFile())
    -- A: settings files saved before autohide existed gain its defaults without
    -- disturbing any other widget preference.
    settings.widgets = settings.widgets or {}
    for _, key in ipairs({'autohide','autohide_seconds'}) do
        if settings.widgets[key] == nil then settings.widgets[key] = default.widgets[key] end
    end
    settings.menu = settings.menu or {}
    for key, value in pairs(default.menu) do
        if settings.menu[key] == nil then settings.menu[key] = value end
    end
    -- A: apply the explicitly requested movement defaults once to existing
    -- characters too. The saved version keeps later user choices intact.
    local movement=settings.movement
    local movementDefaultsChanged=false
    if (tonumber(movement.defaults_version) or 0)<1 then
        movement.stop_on_movement=true;movement.start_others=false;movement.auto_lockon=false
        movement.enabled=true;movement.policy='Send';movement.quiet=true
        movement.recovery.mode='Detour';movement.recovery.pulling=true
        movement.recovery.following=true;movement.recovery.paths=true
        movement.recovery.diagnostics=true;movement.defaults_version=1
        movementDefaultsChanged=true
    end
    if (tonumber(movement.defaults_version) or 0)<2 then
        movement.recovery.verbose=true;movement.defaults_version=2
        movementDefaultsChanged=true
    end
    if (tonumber(movement.defaults_version) or 0)<3 then
        -- Request feedback replaces the inverted `quiet` key; carry each character's
        -- existing choice across so nobody's behavior changes.
        movement.feedback=(movement.quiet==false)
        movement.defaults_version=3
        movementDefaultsChanged=true
    end
    if movementDefaultsChanged then save_with_fresh_file(self, settings) end
    self.settings = settings
    require('settings/shared_preferences').configure(self)
    self:onSettingsChanged():trigger(self.settings)
    return self.settings
end

function TrustAddonSettings:reloadSettings()
    return self:loadSettings()
end

function TrustAddonSettings:saveSettings(saveToFile)
    save_with_fresh_file(self, self.settings)
    require('cylibs/trust/commands/command_settings').recordSaved(self)
    self:onSettingsChanged():trigger(self.settings)
end

function TrustAddonSettings:getSettings()
    return self.settings
end

return TrustAddonSettings
