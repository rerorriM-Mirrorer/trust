-- Several Trust clients share one data/settings.xml. This test runs the real
-- settings/TrustAddonSettings.lua for three characters against a MODEL of
-- Windower's config library (addons/libs/config.lua), written from reading its
-- source: every table keeps a cache of the WHOLE file taken at load/reload, save
-- merges the caller's values into that cache and rewrites the whole file from it,
-- and reload re-parses the file (using the table's current contents as the
-- baseline for <global>). It is a model, not Windower's code; the live check in
-- TESTING.md is what confirms the real library behaves this way.
L=function(t)return t or {} end;S=L
package.loaded['cylibs/events/Luvent']={newEvent=function()return{trigger=function()end}end}
package.loaded['settings/shared_preferences']={configure=function()end}
package.loaded['cylibs/trust/commands/command_settings']={recordSaved=function()end}

local function copy(v,seen)
    if type(v)~='table' then return v end
    seen=seen or {}
    if seen[v] then return seen[v] end
    local r={};seen[v]=r
    for k,x in pairs(v) do r[copy(k,seen)]=copy(x,seen) end
    return setmetatable(r,getmetatable(v))
end
local function merge(dst,src)               -- src over dst, recursive on tables
    for k,v in pairs(src) do
        if type(v)=='table' and type(dst[k])=='table' then merge(dst[k],v) else dst[k]=copy(v) end
    end
    return dst
end
local function amend(dst,src)               -- add keys dst lacks, recursive
    for k,v in pairs(src) do
        if dst[k]==nil then dst[k]=copy(v)
        elseif type(v)=='table' and type(dst[k])=='table' then amend(dst[k],v) end
    end
end
local function diff(base,new)               -- only keys whose value differs from base
    local res={}
    for k,v in pairs(new) do
        local b=base[k]
        if b~=nil then
            if type(v)=='table' and type(b)=='table' then res[k]=diff(b,v)
            elseif b~=v then res[k]=v end
        end
    end
    return next(res)~=nil and res or nil
end

local function model(disk,getplayer)
    local C,metas={},setmetatable({},{__mode='k'})
    local function parse(settings)
        local meta=metas[settings]
        local parsed=copy(disk.data)
        meta.original={}
        for c,section in pairs(parsed) do meta.original[c]=merge(copy(settings),section) end
        for c in pairs(parsed) do
            if c~='global' then meta.original[c]=diff(meta.original.global,meta.original[c]) or {} end
        end
        local full=copy(parsed.global or {})
        local player=getplayer()                       -- nobody visible: only <global> is read
        local me=player and player.name:lower()
        if me and parsed[me] then merge(full,parsed[me]) end
        return merge(settings,full)
    end
    function C.load(defaults)
        local settings=copy(defaults)
        metas[settings]={original={global=copy(settings)}}
        return parse(settings)
    end
    function C.reload(settings)
        assert(metas[settings],'unknown settings table')
        parse(settings)
    end
    function C.save(t)
        local meta=assert(metas[t],'unknown settings table')
        local me=getplayer().name:lower()
        meta.original[me]=meta.original[me] or {}
        for k,v in pairs(t) do meta.original[me][k]=v end
        amend(meta.original.global,meta.original[me])
        meta.original[me]=diff(meta.original.global,meta.original[me])
        disk.data=copy(meta.original)        -- the whole file, from THIS client's cache
        disk.writes=disk.writes+1
    end
    return C
end

local function seed()
    -- Shaped like the real file: a <global> that says Off, and per-character sections.
    return {writes=0,data={
        global={movement={start_others=false,stop_on_movement=false,defaults_version=0}},
        clairvaux={movement={start_others=true,stop_on_movement=true,defaults_version=3}},
        myrr={movement={defaults_version=3}},
        lionstag={movement={start_others=true,stop_on_movement=true,defaults_version=3}},
    }}
end
local function client(name,disk,tweak)
    local env
    local cfg=model(disk,function()return env.windower.ffxi.get_player()end)
    if tweak then tweak(cfg) end
    env=setmetatable({config=cfg,windower={ffxi={get_player=function()return{name=name}end}}},{__index=_G})
    local Addon=assert(loadfile('settings/TrustAddonSettings.lua','t',env))()
    local a=Addon.new();a:loadSettings();a.env=env;return a
end
-- What a character will see after a reload: its own value, else <global>, else the factory On.
local function effective(disk,name,key)
    local s=disk.data[name]
    if s and s.movement and s.movement[key]~=nil then return s.movement[key] end
    local g=disk.data.global.movement
    if g and g[key]~=nil then return g[key] end
    return true
end
local function toggle_fan(a)
    local s=a:getSettings();s.follow.fan_out=not s.follow.fan_out;a:saveSettings(true)
    s.follow.fan_out=not s.follow.fan_out;a:saveSettings(true)
end

-- Control: without the refresh (library calls unavailable) the saved Off is undone by another client.
do
    local disk=seed()
    local function old(cfg)cfg.reload=nil end
    local c,m=client('clairvaux',disk,old),client('myrr',disk,old);client('lionstag',disk,old)
    c:getSettings().movement.start_others=false;c:saveSettings(true)
    assert(effective(disk,'clairvaux','start_others')==false,'control: Off saved')
    toggle_fan(m)
    assert(effective(disk,'clairvaux','start_others')==true,
        'control must reproduce the reported bug: another client\'s unrelated save restored On')
end

-- Control 2: even ONE client is enough. Myrr only inherits <global>'s Off for Pause on
-- movement (the code default is On), yet an unrelated save by Clairvaux (old behavior)
-- writes an explicit On for Myrr, because the library compared each character against the
-- code's default instead of <global>. (Request others act used to show this too; its code
-- default is now Off, matching <global>, so Pause on movement carries the control.)
do
    local disk=seed()
    local c=client('clairvaux',disk,function(cfg)cfg.reload=nil end)
    assert(effective(disk,'myrr','stop_on_movement')==false,'control: Myrr inherits Off from <global>')
    toggle_fan(c)
    assert(effective(disk,'myrr','stop_on_movement')==true,'control must reproduce: Myrr flipped to On by someone else\'s save')
end

-- With the fix: all three clients loaded at once, then each saves in turn.
do
    local disk=seed()
    local c,m,l=client('clairvaux',disk),client('myrr',disk),client('lionstag',disk)
    local mv=c:getSettings().movement
    mv.start_others=false;c:saveSettings(true)
    assert(effective(disk,'clairvaux','start_others')==false)
    assert(c:getSettings().movement==mv and mv.start_others==false,'save never replaces the live settings tables')
    toggle_fan(m)
    assert(c.env.windower.ffxi.get_player().name=='clairvaux' and m.env.windower.ffxi.get_player().name=='myrr','player lookup is always restored')
    assert(effective(disk,'myrr','start_others')==false,"Myrr keeps inheriting <global>'s Off after saves")
    assert(effective(disk,'clairvaux','start_others')==false,"Myrr's unrelated saves must not undo Clairvaux's Off")
    assert(effective(disk,'lionstag','start_others')==true,"and must not change Lionstag's On")
    l:getSettings().movement.keep_autorun=true;l:saveSettings(true)
    assert(effective(disk,'lionstag','keep_autorun')==true,"Lionstag's own change is saved")
    assert(effective(disk,'clairvaux','start_others')==false,"Lionstag's save must not undo Clairvaux's Off")
    assert(effective(disk,'myrr','keep_autorun')==false,"Lionstag's setting must not leak to other characters")
    assert(disk.data.global.movement.keep_autorun==false,'<global> keeps the default, not one character\'s value')
    -- Both directions, repeatedly, in the opposite order too.
    m:getSettings().movement.start_others=true;m:saveSettings(true)
    c:getSettings().follow.distance=4;c:saveSettings(true)
    assert(effective(disk,'myrr','start_others')==true,"Clairvaux's later save keeps Myrr's On")
    assert(disk.data.clairvaux.follow and disk.data.clairvaux.follow.distance==4,'own unrelated change saved')
    -- A fresh load (what //am all reload trust does) sees exactly what was last saved.
    local again=client('clairvaux',disk)
    assert(again:getSettings().movement.start_others==false and again:getSettings().follow.distance==4)
    assert(client('myrr',disk):getSettings().movement.start_others==true)
    assert(client('lionstag',disk):getSettings().movement.keep_autorun==true)
end

-- One client alone no longer flips a character that inherits <global>.
do
    local disk=seed()
    local c=client('clairvaux',disk)
    toggle_fan(c)
    assert(effective(disk,'myrr','start_others')==false,'single client save leaves inherited Off alone')
    assert(effective(disk,'lionstag','start_others')==true and effective(disk,'clairvaux','start_others')==true)
end

-- If the refresh fails, the change is still saved the old way rather than lost.
do
    local disk=seed()
    local a=client('clairvaux',disk,function(cfg)cfg.reload=function()error('boom')end end)
    a:getSettings().movement.start_others=false;a:saveSettings(true)
    assert(effective(disk,'clairvaux','start_others')==false,'fallback save persisted the change')
end
print('PASS shared settings.xml: three clients saving in turn keep each other\'s values; control reproduces the old overwrite; failures fall back to the direct save')
