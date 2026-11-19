-- Actual addon load/save migration, including previously saved global defaults.
L=function(t)return t or {}end;S=L
package.loaded['cylibs/events/Luvent']={newEvent=function()return{trigger=function()end}end}
package.loaded['settings/shared_preferences']={configure=function()end}
package.loaded['cylibs/trust/commands/command_settings']={recordSaved=function()end}
local function copy(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
local saved={movement={policy='Ready',stop_on_movement=false,start_others=false,auto_lockon=true,
 recovery={mode='Off',pulling=false,following=false,paths=false,diagnostics=false,interval=4}}}
local writes=0
local factory
local function merge(a,b)for k,v in pairs(b)do if type(v)=='table' and type(a[k])=='table'then merge(a[k],v)else a[k]=copy(v)end end;return a end
config={load=function(defaults)factory=defaults;return merge(copy(defaults),saved)end,
 save=function(v)writes=writes+1;saved=copy(v)end}
local Addon=require('settings/TrustAddonSettings');local owner=Addon.new()
owner:loadSettings();local m=owner:getSettings().movement
assert(m.enabled and m.policy=='Send' and m.quiet and m.stop_on_movement and not m.start_others and not m.auto_lockon)
assert(m.feedback==false,'old quiet=true becomes Request feedback off')
assert(m.recovery.mode=='Detour' and m.recovery.pulling and m.recovery.following and m.recovery.paths and m.recovery.diagnostics)
assert(m.recovery.verbose==true)
assert(m.recovery.interval==4,'migration overwrote user timing')
assert(m.defaults_version==3 and writes==1)
assert(factory.movement.stop_on_movement and not factory.movement.start_others and not factory.movement.auto_lockon and factory.movement.feedback==false)
-- The recovery master mode was removed from the factory defaults (2026-11-19).
assert(factory.movement.recovery.mode==nil and factory.movement.recovery.diagnostics)
-- A user's later opt-out is preserved, not overwritten on every job/reload.
m.stop_on_movement=false;m.start_others=false;m.auto_lockon=true;m.recovery.mode='Off';m.recovery.diagnostics=false;m.recovery.verbose=false
owner:saveSettings(true);owner:reloadSettings();m=owner:getSettings().movement
assert(writes==2 and not m.stop_on_movement and not m.start_others and m.auto_lockon and m.recovery.mode=='Off' and not m.recovery.diagnostics and not m.recovery.verbose)
-- Fresh settings receive the same defaults and an explicit applied version.
saved={};owner=Addon.new();owner:loadSettings();m=owner:getSettings().movement
assert(m.defaults_version==3 and m.recovery.mode=='Detour' and m.stop_on_movement and not m.start_others and not m.auto_lockon and m.feedback==false)
print('PASS actual fresh/existing movement defaults, one-time migration, saved opt-out and tuning preservation')

-- Updating from movement defaults v1 enables only the new verbosity flag.
saved={movement={defaults_version=1,stop_on_movement=false,start_others=false,auto_lockon=true,
 recovery={mode='Pause',verbose=false}}}
owner=Addon.new();owner:loadSettings();m=owner:getSettings().movement
assert(m.defaults_version==3 and m.recovery.verbose and m.recovery.mode=='Pause')
assert(not m.stop_on_movement and not m.start_others and m.auto_lockon)
m.recovery.verbose=false;owner:saveSettings(true);owner:reloadSettings()
assert(not owner:getSettings().movement.recovery.verbose)
print('PASS verbosity-only v1 upgrade preserves movement overrides and later quiet preference')

-- Request feedback replaces the inverted quiet key without changing anyone's behavior.
saved={movement={defaults_version=2,quiet=false,start_others=true}}
owner=Addon.new();owner:loadSettings();m=owner:getSettings().movement
assert(m.feedback==true and m.defaults_version==3,'quiet=false (feedback shown) stays shown')
assert(m.start_others==true,'an existing explicit Request others act is not overwritten')
m.feedback=false;owner:saveSettings(true);owner:reloadSettings()
assert(owner:getSettings().movement.feedback==false,'a later choice is kept, not re-derived')
saved={movement={defaults_version=2,quiet=true}}
owner=Addon.new();owner:loadSettings()
assert(owner:getSettings().movement.feedback==false)
print('PASS Request feedback migration from quiet, existing Request others act preserved')
