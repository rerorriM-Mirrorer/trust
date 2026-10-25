-- Shared per-client menu preferences. No input bindings or file writes here.
local Preferences = {}
local owner
local savedCallback

function Preferences.configure(settingsOwner, onSaved)
    owner = settingsOwner
    savedCallback = onSaved
end

function Preferences.get(key)
    local settings = owner and owner:getSettings()
    local value = settings and settings.menu and settings.menu[key]
    if value == nil then
        return true
    end
    return value == true
end

function Preferences.saved()
    if savedCallback then savedCallback() end
end

function Preferences.layout()
    local settings=owner and owner:getSettings()
    return settings and settings.menu and settings.menu.layout=='Full' and 'Full' or 'Condensed'
end

return Preferences
