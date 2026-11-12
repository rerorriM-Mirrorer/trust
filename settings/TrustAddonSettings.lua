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
default.movement = {policy='Send',enabled=true,quiet=true,assist_others=false,stop_on_movement=true,start_others=true,auto_lockon=false,defaults_version=0,
    recovery={mode='Detour',pulling=true,following=true,paths=true,interval=2,min_movement=.5,
        detour_distance=2,attempts=2,pull_cooldown=30,diagnostics=true,verbose=true}}
default.widgets = {hide_pet=true}
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
    settings.menu = settings.menu or {}
    for key, value in pairs(default.menu) do
        if settings.menu[key] == nil then settings.menu[key] = value end
    end
    -- A: apply the explicitly requested movement defaults once to existing
    -- characters too. The saved version keeps later user choices intact.
    local movement=settings.movement
    local movementDefaultsChanged=false
    if (tonumber(movement.defaults_version) or 0)<1 then
        movement.stop_on_movement=true;movement.start_others=true;movement.auto_lockon=false
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
    if movementDefaultsChanged then config.save(settings) end
    self.settings = settings
    require('settings/shared_preferences').configure(self)
    self:onSettingsChanged():trigger(self.settings)
    return self.settings
end

function TrustAddonSettings:reloadSettings()
    return self:loadSettings()
end

function TrustAddonSettings:saveSettings(saveToFile)
    config.save(self.settings)
    require('cylibs/trust/commands/command_settings').recordSaved(self)
    self:onSettingsChanged():trigger(self.settings)
end

function TrustAddonSettings:getSettings()
    return self.settings
end

return TrustAddonSettings
