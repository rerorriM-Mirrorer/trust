# Starter defaults Test 1 — October 23, 2026

Author A. Cumulative Trust update over Controller Menu Test 1. Controller Lua
and the existing paired xivcrossbar / Controls 9.15-trustmenu1 remain compatible.
No new AHK update is needed for this Trust-only package.

## Requested defaults

All 22 factory job mode sets now specify AutoEngageMode Always,
AutoHealMode Emergency, AutoBuffMode Auto, AutoSkillchainMode Off,
AutoTrustsMode Off and AutoShootMode Off. SMN's factory mode set selects
Carbuncle. Built-in engagement/healing/buff fallbacks match those choices.
Positioning, follow, pulling, magic bursting and other modes retain their prior
choices. This is not an all-modes-Off preset.

All 24 factory job-settings templates containing PullSettings now have empty
target-name lists. The legacy addon-level battle.targets factory list is also
empty. Existing user files, target lists, pull distances and action rules are
not rewritten. Pull distances stay at their prior factory 20 yalms; the discussed
30-yalm/shared hunting setup and pull-list commands are deferred to a separate
small pass. No Approach action has been automatically appended.

## Installation and adopting the defaults

Back up the installed Trust folder. Unload Trust, merge the full trust folder
into Windower/addons while retaining data, and reload Trust on one character.
The package contains no installed character data. Existing named profiles keep
their previous saved choices; changing factory defaults does not overwrite them.

For an existing job/profile:

```
//trust defaults
//trust defaults apply
```

The first reports the baseline and changes nothing. Apply sets the requested
starter modes and explicitly saves those keys into the CURRENT JOB / CURRENT
MODE PROFILE, even if ordinary autosave is Off. It preserves unrelated profile
keys, including positioning, follow and pulling. Apply again after selecting
another existing job/profile if you want that profile to adopt the baseline too.
Only SMN adoption changes the avatar selection. Applying can immediately affect
enabled automation, including engagement and summoning; choose the moment as
you would when setting those modes individually.

During menus, status is immediate. Apply first validates/commits an eligible
current editor under the existing menu policy. A temporarily locked activity
such as singing rejects adoption before changing modes. An unsupported loaded
mode value also rejects the whole adoption before changing anything.

The new baseline is still factory defaults plus explicit per-profile adoption.
It is not the proposed live shared job/hunting-profile system. There is no
automatic multi-character broadcast or all-profile migration.

## Existing behavior clarified

- CombatMode Auto maintains enemy distance while locally Engaged. Mirror tracks
  the position of an engaged assist character. Neither setting selects the enemy
  or guarantees drawing weapons; engagement is controlled separately.
- Emergency healing currently uses the SAME configured healing gambits and HP
  thresholds as Auto. Normal cooldown is four seconds versus Auto's 0.5 seconds.
  HP-event dirty checks can invoke an ignore-delay path, so Emergency is not a
  strict four-second limit or a separate low-HP-only policy. Its description now
  says so; this patch does not alter healing logic.
- Engineered BRD songs use AutoSongMode, Pianissimo and song settings. Generic
  buffs use AutoBuffMode; custom gambits use AutoGambitMode. No new mutually
  exclusive song/buff controller is introduced. Whether the generic Buffer can
  safely support a chosen song needs its own status/tracking/editor tests.
- AutoSkillchainMode Off disables the automatic chain/Spam/Cleave selection.
  It does not disable independently configured weapon-skill gambits. Existing
  `//trust sc spam <weapon skill>` chooses/configures Spam behavior; repeating
  that command can toggle its mode. `//trust set AutoSkillchainMode Spam` selects
  Spam explicitly and `//trust sc off` stops it. A learned, valid weapon skill
  is required. Property mode chooses Light/Darkness preference, delay mode gives
  magic bursts time, burst modes select magic behavior, and the assistant is a
  display option. Those separate settings are not reset by this patch.
- Follow Off stops following. Always follows the assigned player while idle,
  stopping for engaged/dead/resting states and resuming as appropriate. Path is
  used by recorded path following and has different distance/target validation;
  it does not itself create or start a route. AutoZone is a separate setting.
- Pull Aggroed considers nearby engaged monsters subject to range/height/claim
  filters, exclusions and action conditions. It is not a complete enmity-list
  test for every party member. Ordinary pull gambits require an unclaimed target,
  so a candidate can be rejected rather than repeatedly pulled when already
  claimed. An empty configured name list does not disable Aggroed or All modes.
- A profile coordinates the current main job, optional subjob, weapon-skill
  settings and modes. It does not save every job for a character. Main/subjob
  are separate job files, not universally a separate file for every combination.
- Copying defaults into separate job files is duplication, not a live shared
  reference. Shared hunting targets/configuration, clear/load/add/remove list
  commands, shared job profiles and Config-scoped everyday preferences remain
  planned work. Target-list command syntax must avoid the existing pull-add
  ability-gambit command.

## Verification and live checks

Eight menu/command scripts pass under Lua 5.4 with mocked UI/file/game APIs,
including controller regressions and new starter-command checks. All 22 factory
mode sets match the starter policy. The new command tests locked/invalid refusal
before mutation, correct selected-profile persistence, unrelated-key retention,
idempotent runtime effects, explicit save and menu policy. All 24 factory pull
target lists are verified empty. All 55 changed/new Lua files parse after
temporary normalization of inherited Windower quoted-string methods.

Native Windower/FFXI execution is pending. Test defaults status/apply on one job,
reopen Modes and reload to check persistence. Check SMN Carbuncle, no automatic
NPC Trust summoning, skillchains/shooting Off, unchanged positioning/follow/pull
choices, and the existing controller menu. Check the new values on a freshly
created job mode file; do not delete personal files to simulate that test.
Emergency healing still needs ordinary gameplay observation with existing rules.

Live feedback carried forward: controller navigation works on Cioara and
Franklet after transferring the new files; no visible xivcrossbar interference
was reported. The user also reported saving on exit working in their test.
These confirmations do not establish every editor, character or mode combination.

Rollback: restore backed-up code. If defaults were explicitly applied, restore
the desired six modes (and SMN avatar) or restore the backed-up mode profile.
No existing pull list is removed by installation or defaults adoption.
