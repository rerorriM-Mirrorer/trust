-- Awake: opt-in, bounded diagnostics. Does not change save decisions or values.
-- Chat output survives menu dismissal; dump writes the retained session to data.
local Trace = {enabled=false, entries={}, limit=120, sequence=0}

local function value(v)
    if type(v)=='table' then return '<table>' end
    local text=tostring(v):gsub('[\r\n]', ' ')
    return #text>160 and text:sub(1,157)..'...' or text
end

function Trace.record(stage, fields)
    if not Trace.enabled then return end
    local keys, parts = {}, {}
    for key in pairs(fields or {}) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do parts[#parts+1]=key..'='..value(fields[key]) end
    Trace.sequence=Trace.sequence+1
    local line=string.format('%03d %s %s %s',Trace.sequence,os.date('%H:%M:%S'),stage,table.concat(parts,' | '))
    Trace.entries[#Trace.entries+1]=line
    if #Trace.entries>Trace.limit then table.remove(Trace.entries,1) end
    addon_system_message('[menu trace] '..line)
end

function Trace.editor(editor, stage, reason, draft)
    if not Trace.enabled then return end
    local fields={editor=editor.__type or 'editor',reason=reason or ''}
    local owner=editor.trustSettings
    if owner then
        fields.owner=owner.__type or owner.__class or 'settings'
        fields.job=owner.jobNameShort
        if owner.jobNameShort and owner.playerName then
            fields.path=(owner.settingsFolder or 'data/')..owner.jobNameShort..'_'..owner.playerName..'.lua'
        end
    end
    for key,v in pairs(editor.exitTraceContext or {}) do fields[key]=v end
    for _,name in ipairs({'TrustMode','MainTrustSettingsMode','SubTrustSettingsMode','WeaponSkillSettingsMode'}) do
        if state and state[name] then fields[name]=state[name].value end
    end
    local changed={}
    for key,v in pairs(draft or {}) do
        local old=editor.exitBaseline and editor.exitBaseline[key]
        if not require('cylibs/ui/menu/editor_values').equal(old,v) then
            changed[#changed+1]=key..':'..value(old)..'->'..value(v)
        end
    end
    table.sort(changed)
    if #changed>0 then fields.changes=table.concat(changed,', ') end
    Trace.record(stage,fields)
end

function Trace.setEnabled(enabled)
    Trace.enabled=enabled
    Trace.record('trace-enabled',{retained=#Trace.entries})
end

function Trace.clear()
    Trace.entries={}; Trace.sequence=0
end

function Trace.dump()
    local player=windower.ffxi.get_player()
    if not player or not player.name then return false,'Player is unavailable' end
    local directory=windower.addon_path..'data/logs/'
    local path=directory..'menu-save-'..player.name:gsub('[^%w_-]','_')..'.log'
    local ok,err=pcall(function()
        windower.create_dir(directory)
        local file,message=io.open(path,'w')
        if not file then error(message or 'Unable to open trace file') end
        local written,writeError=file:write('Trust menu save trace (last '..Trace.limit..' events)\n'..table.concat(Trace.entries,'\n')..'\n')
        local closed,closeError=file:close()
        if not written or not closed then error(writeError or closeError or 'Unable to finish trace file') end
    end)
    if not ok then return false,tostring(err) end
    return true,'Trace saved to '..path
end

return Trace
