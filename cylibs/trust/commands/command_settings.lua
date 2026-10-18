-- Awake: synchronize persistent command effects without wrapping command handlers
-- in pcall (some handlers yield). Targets and role-local session state are not owners.
local Preferences = require('cylibs/ui/menu/menu_preferences')
local Trace = require('cylibs/ui/menu/menu_save_trace')
local Sync = {}
local persisted = setmetatable({}, {__mode='k'})
local selectors = {TrustMode=true, MainTrustSettingsMode=true,
    SubTrustSettingsMode=true, WeaponSkillSettingsMode=true}
local excluded = {load=true,reload=true,save=true,reset=true,unload=true,restart=true,
    profile=true,scenario=true,start=true,startall=true,stop=true,stopall=true,toggle=true,
    send=true,sendall=true,menu=true,widget=true,help=true,status=true,version=true,
    commands=true,debug=true,menuperf=true}

-- Canonical key order detects nested edits without cloning ability objects or
-- depending on pairs order. Domain objects use their existing persistence format.
local function encode(value, visiting)
    if type(value) == 'string' then return 'string:'..string.format('%q', value) end
    if type(value) ~= 'table' then return type(value)..':'..tostring(value) end
    if value.serialize then return 'object:'..value:serialize() end
    if visiting[value] then error('Cyclic settings table') end
    visiting[value] = true
    local parts = {}
    for key, item in pairs(value) do
        if key ~= 'n' then parts[#parts+1] = encode(key, visiting)..'='..encode(item, visiting) end
    end
    table.sort(parts)
    visiting[value] = nil
    return '{'..table.concat(parts, '\n')..'}'
end

local function snapshot(owner)
    local ok, result = pcall(function() return encode(owner:getSettings(), {}) end)
    if ok then return result end
    Trace.record('command-snapshot-failed', {error=result})
end

function Sync.recordSaved(owner)
    -- Called only after the existing writer returns successfully, before its
    -- notifications. This also detects a later mutation in the same command.
    persisted[owner] = snapshot(owner)
end

function Sync.capture(command, owners, modes, modeOwner, arguments)
    if excluded[command] or not Preferences.get('save_on_exit') then return nil end
    local token = {command=command, owners={}, modes={}, selectors={}, modeOwner=modeOwner}
    arguments = arguments or {}
    token.quiet = (command=='follow' or command=='assist')
        and type(arguments[#arguments])=='string' and arguments[#arguments]:lower()=='--quiet'
    local seen = {}
    for label, owner in pairs(owners) do
        if owner and owner.getSettings and owner.saveSettings and not seen[owner] then
            seen[owner] = true
            token.owners[#token.owners+1] = {label=label, owner=owner,
                root=owner:getSettings(), before=snapshot(owner)}
        end
    end
    for name, mode in pairs(modes or {}) do
        if type(mode)=='table' and mode.value ~= nil then
            if selectors[name] then token.selectors[name]=mode.value
            elseif type(mode.value)~='table' then token.modes[name]=mode.value end
        end
    end
    return token
end

function Sync.finish(token, success, modes)
    if not token or success ~= true or not Preferences.get('save_on_exit') then return end
    modes = modes or {}
    -- Profile/load commands own their persistence; never snapshot a different set.
    for name, value in pairs(token.selectors) do
        if not modes[name] or modes[name].value ~= value then
            Trace.record('command-save-skipped', {command=token.command, reason='profile changed'})
            return
        end
    end
    local saved, failed = 0, false
    local function write(label, callback)
        local ok, result, err = pcall(callback)
        if not ok or result == false then
            failed = true
            addon_system_error('Command applied, but '..label..' was not saved: '..tostring(ok and err or result))
            Trace.record('command-save-failed', {owner=label,error=ok and err or result})
        else
            saved = saved + 1
            Trace.record('command-save-returned', {owner=label,command=token.command})
        end
    end
    for _, entry in ipairs(token.owners) do
        local owner = entry.owner
        if entry.before and owner:getSettings()==entry.root then
            local after = snapshot(owner)
            if after and after ~= entry.before and after ~= persisted[owner] then
                write(entry.label, function() return owner:saveSettings(true) end)
            end
        end
    end
    local changes = {}
    for name, old in pairs(token.modes) do
        local mode = modes[name]
        if mode and mode.value ~= old then changes[name:lower()] = mode.value end
    end
    if next(changes) and token.modeOwner and token.modeOwner.saveModeChanges then
        write('modes', function()
            return token.modeOwner:saveModeChanges(token.selectors.TrustMode, changes)
        end)
    end
    if saved > 0 and not failed and not token.quiet then addon_system_message('Saved command changes.') end
end

return Sync
