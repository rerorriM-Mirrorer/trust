# Shared Pulling and sounds — Test 1

Author A. October 31, 2026. Trust branch test/starter-defaults-20261023,
starting checkpoint 96314920c6c8ccaab3e89e80585b40042e040c62.

## Install

Back up Trust and unload it on participating clients. Merge this cumulative
patch's trust folder into the existing addons/trust folder, then reload Trust.
No AHK/xivcrossbar update is required, including for the newer AHK v2 wrapper.
Requires the integrated Trust Movement Test 1 installation. This patch includes
the previous Shared Job editor changes, so that intermediate patch is optional.
It omits personal data and factory job files; existing shared Job edits survive.
Factory mode files are included for the previous Disable-on-death defaults.
Existing saved character mode profiles remain authoritative.

## Scope

data/shared-preferences.lua contains one shared Pulling setup (target names,
target IDs, exclusions, detection distance and pull delay) and one shared Sounds
disabled switch. It is installation-wide, shared across characters/jobs/profiles,
not automatically synchronized between separate computers.

The new setup starts with empty target/exclusion lists, 30-yalm detection and
zero delay. It does not import whichever character loads first. Original job
lists remain untouched. 30 is the search preference; spell/ability range and
other target eligibility checks still apply. Clearing targets does not turn
AutoPullMode Off; existing Auto behavior may still handle party-aggroed mobs.

Job pulling gambits/actions, RandomizeTarget and other unshared job fields stay
job-owned. AutoPullMode, PullActionMode and camp behavior remain independent per
client; editing a shared list does not enable pulling on everyone. Existing
follow/Alter Ego mode ownership, action queues and combat logic are unchanged.

Clients poll shared preferences roughly once per wall-clock second. Sound
playback updates, and pulling roles refresh on their next role tick, including
while pulling Off. Target selection otherwise retains existing behavior: an
active valid target need not be abandoned just because the shared list changed.

## Menus

Condensed order: Main Job, Sub Job, Pulling, Following, Paths, Alter Egos, Config.
Movement is inside Config in both layouts. Profiles remains accessible through
Config (and at the root in Full). Full retains its other legacy navigation.

Main Pulling edits shared Targets, Target IDs, Exclusions and Config, with:

- Source: use shared pulling on this character; Off restores legacy job/profile
  settings. Save, then close/reopen menus to rebuild the relevant job controls.
- Import Job: explicitly replace the shared list/config from the current main
  job's selected profile. No actions are imported, and no pulling mode changes.
- Clear Targets: empty names and IDs while retaining exclusions/config/actions.
- Reload: read fresh shared values after a stale-edit rejection.

Shared mode leaves Actions, Modes and job Config (randomization) in the main
job's Pulling menu. If the active pulling role is owned by the subjob, that
entry still routes to its owner. Legacy source restores the older job pulling
menu's targets/config controls. The subjob Settings shortcut remains hidden as
in the previous patch. Main shared Pulling still edits the shared setup even
when this character has selected Legacy; its title/scope identifies that.

Config > Sounds and //trust sounds operate on the same shared saved switch.
Factory shared sounds are Off. Old per-character XML sound choices no longer
control playback. Commands update the current player immediately; other clients
update via polling. The command remains usable with Trust menus open, subject
to normal draft-save validation.

## Commands

- //trust pull target add <name or <t>>: add a target and set AutoPullMode Auto
  on the requesting client only, after the list saves successfully.
- //trust pull target remove <name>: remove a target, case-insensitively.
- //trust pull target clear (or //trust pull clear): clear target names and IDs.
- //trust pull distance <0-50>: set detection distance; decimals accepted.
- //trust pull ignore <name or <t>>: add an exclusion.
- //trust pull delay <0-50>: set seconds between pulls.
- //trust sounds enable / disable: save the installation preference.
- //trust sounds: toggle the latest shared saved sound preference.

Existing //trust pull add/remove still edit ability gambits. Those command names
were already occupied, so target-list editing uses the explicit target word.
Distance/target/exclusion/delay commands write to the legacy active pulling
owner when Source is Legacy. Randomize remains job-owned in either source.
Named pulling profiles, automatic cross-PC synchronization, recovery/Pathfinder,
flanking, revised AutoDisengage and SMN changes remain future work.

## Saves and testing

Saves use the previous Windows exclusive-handle/atomic-replacement backend,
validate and verify staged bytes, preserve unrelated sections and create a .bak
of the previous shared file. Menu drafts reject stale file contents; reopen or
Reload, then reapply the edit. Commands fail instead of silently overwriting a
concurrent change. Malformed/inaccessible files report errors and are not
replaced by defaults. Already loaded clients retain their last valid runtime
state until a valid update is available. Backups/lock sidecars are not personal
profiles and must be preserved with the shared file when moving installations.

Twenty suites pass under Lua 5.4 with temporary Windower literal-method syntax
normalization. They cover real temporary-file persistence/refresh/failures,
stale writes, validation, backups, shared vs legacy overlays, action isolation,
command routing and local activation, actual menu owner wiring and root order,
actual pull-role refresh, previous shared Job tests and controller/movement/menu/
command/database regressions. Changed Lua sources parse and whitespace checks
pass. Renderer/Windower/Win32 observations are mocked; native game acceptance
and Windows file saves still need testing.

Live check: two clients, pulling Off initially; edit one shared target/distance,
confirm the other adopts it; toggle sound and reload both; change jobs/profiles;
switch one client to Legacy and verify its original list/actions return. Test
Import and stale-editor refusal deliberately. No death/pathing test is needed.
Rollback restores backed-up code, preserving data/shared-preferences.lua for
future use; the previous build ignores that file.
