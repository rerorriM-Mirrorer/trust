# Fresh installation for Killala and Franklet — October 23, 2026

This complete cumulative Trust folder includes the current menu autosave,
adjacent menus, command aliases/persistence, party-song gambit choices,
controller adapter and starter defaults. It includes runtime images, sounds,
fonts and bundled libraries; no old character data or nested packages.

1. Unload Trust on every client using this Windower installation.
2. Rename the existing addons/trust folder to trust-backup-20261023 (or another
   unused name). Keep the backup intact; do not delete it.
3. Extract the supplied trust folder directly into Windower/addons. Confirm
   addons/trust/Trust.lua exists, rather than addons/trust/trust/Trust.lua.
4. Load Trust on Killala first with //lua load trust. Allow initialization to
   finish, then run //trust defaults and open the menu. Repeat on Franklet.
5. Do not copy the old data folder back when testing the fresh baseline. Trust
   will generate its own new settings. Roll back by unloading Trust and restoring
   the backed-up folder if desired.

One addon folder serves all characters in the same Windower installation.
Separate Windower installations each need their own copy. This resets the
Trust configuration for every character using that folder, not only these two;
the original settings remain in the renamed backup.

Factory modes across 22 jobs: engage Always, healing Emergency, buffs Auto,
automatic skillchains/NPC Trust summoning/shooting Off; SMN avatar Carbuncle.
Default pull target lists are empty. Other job defaults remain as authored;
this is not an all-modes-Off preset. A fresh install does not require defaults
apply. That command is for explicit adoption into an existing saved profile.

Menu save-on-exit and adjacent submenu placement default On. Existing matching
xivcrossbar DirectLink / Controls 9.15-trustmenu1 or newer compatible controls
remain required for controller navigation. This package does not reset or
replace xivcrossbar, the AHK wrapper, other addons or Windower itself.

The runtime still reports upstream version 17.7.3. FRESH-BUILD.json identifies
this exact package. Defaults status reports Starter defaults Test 1.

Startup hardening: the defaults command now requires its module explicitly
instead of depending on an include-created global. Mouse routing ignores input
until the HUD exists and does not enqueue a missing command overlay. The latest
uploaded console showed a missing DefaultsCommands global followed by repeated
mouse errors. Mixed installed files were a hypothesis, not a confirmed cause.

Nine menu/command regression scripts pass with mocked game/UI/disk APIs under
Lua 5.4. Changed Lua files parse with temporary Windower syntax normalization.
Native Windower/FFXI acceptance is pending. Test menu open/close, one saved
option after reload, controller navigation, and the intended mode values on
each character. Emergency retains the same healing-rule thresholds as Auto;
it uses slower regular checks with HP-event bypasses.

Discussed shared profiles, pull-list clear/load commands, BRD Dummy-mode repair
and other roadmap items remain planned, not shipped features. Earlier known
skillchainer errors are not repaired by this installation pass.
