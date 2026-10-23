> Controller menu Test 1 (October 22, 2026): paired direct Trust navigation. See [docs/CONTROLLER-MENU-TEST1.md](docs/CONTROLLER-MENU-TEST1.md) and the current status in [TESTING.md](TESTING.md). Native acceptance pending.

# Trust

## Party song gambits test 1 — 2026-10-19

The gambit ability picker now includes beneficial Bard songs under **Add > Self**
when they are in the current job's known spell list. Singing on Self uses the
song's normal party area. Enemy songs such as Requiem retain their target choices.

Add an inverted **Has one or more songs** condition for the selected song, place
song rules ahead of unconditional enemy actions, and avoid scheduling more songs
than your current capacity. For custom-gambit testing, turn AutoSongMode Off to
avoid competition with the dedicated Singer set; keep AutoGambitMode Auto.
See [the song gambit guide](docs/PARTY-SONG-GAMBITS.md) for exact steps, installation
and the alternative dedicated Songs setup. Uploaded character settings were
inspected as context and are kept separate from this runtime package.

One runtime file changes in this batch: GambitEditorStyle.lua. Compatible Test 5
users may copy only that file; the full folder also retains cumulative changes.
The menu status still identifies Menu options Test 5. BUILD.txt identifies this
song batch. Source/static verification does not replace live Windower/FFXI testing.

## Menu options test 5 — 2026-10-18

This full testing folder targets the pinned **Trust 17.7.3** runtime with our
cumulative changes. Back up your existing folder/data and follow
`INSTALL-MENU-TEST5.txt`; the upstream installer instructions
below are retained as historical/general documentation, not this test's update path.

Open **Config > Menu** to control three saved preferences (new defaults are On):

- **Save options on exit:** ordinary toggle, slider and single-choice editors
  apply/save when returning focus to the command menu, backing out, navigating
  to another page or closing the menu. Mixed options/text panels validate the
  completed text too. Modes save to the selected named mode set; widget position
  and layout editors retain their existing storage. Unchanged exits do not save.
  When On, successful slash-command changes to loaded job/addon settings and
  ordinary modes also save, and new eligible options panes open with list focus
  (not an activated field). Off preserves original entry focus and command-specific
  save behavior; it does not disable commands that already save explicitly.
- **Place editor beside menu:** the content panel opens immediately left of the
  right-hand command menu, with an 8px gap where the client window has room.
  Off restores the original separated placement. Bounds are checked on presentation;
  reopen after changing resolution. Oversized custom panels are not automatically scaled.
- **I/J/K/L navigate menus:** I = Up, J = Left, K = Down, L = Right in focused
  Trust menus. Existing arrows still work. Chat and focused text fields retain
  letters; Shift is preserved, other modified letter shortcuts are not remapped.
  Temporary chat-closed native bindings block IJKL from gameplay while a menu
  is open. Text editing keeps literal letters. Bindings are removed when the
  menu closes; no Windows key injection or permanent IJKL bindings are installed.

Escape first leaves an actively selected field using its original behavior;
leaving the enclosing options editor saves its valid draft. A brief `Saved.`
appears in the menu information bar and `Saved menu options.` appears in chat.
Confirm/Save buttons remain available.
If automatic saving is Off, use the explicit Save button to turn it back On.

Profile creation/renaming/selection, structural gambit editors, nested multi-select
pickers, command argument forms and language changes that reload Trust retain
their explicit actions. In particular, exiting the command browser never executes
a command. Automatic saving detects conflicting profile/root/option changes rather
than overwriting a stale draft. A write/callback error retains the dirty editor;
runtime values may already have applied before a failed write, so no success is claimed.

`//trust menu close` saves eligible options and closes the menu immediately.
`//trust menu discard` closes without committing the pending editor draft;
it does not undo earlier saves or already applied runtime changes.
Both commands are permitted while the menu is open. Other existing command
restrictions remain in effect. Autosave does not run merely because chat opens
or Windows focus changes. New ordinary menu behavior does not implement Manual Override.
`//trust menu status` identifies this menu test build and its three saved options.

For save diagnosis, `//trust menu trace on` enables a quiet-by-default diagnostic
session: each meaningful editor/save event prints a `[menu trace]` chat line.
The last 120 events remain in memory. Reproduce the edit/exit/reopen problem,
then `//trust menu trace dump` writes `data/logs/menu-save-<character>.log`.
`off` stops collection, `clear` clears the retained session, and `status` reports
its state. Tracing resets Off on reload; dump before reloading. Trace values are
bounded summaries; write-return events report handler completion, not disk readback.

Menus now permit help/status/version, start/stop/startall/stopall/toggle, and
existing UI commands without requiring a valid draft. Assist/follow, ordinary
`set`/`cycle`, attack controls, basic heal/pull/MB/nuke modes, and target controls
check eligible pending edits before dispatch. Heal alliance and buff/debuff auto/off
are also permitted. Clean Modes and ordinary scalar options editors then refresh
from live state, retaining cursor/scroll position and never replacing dirty drafts.
Grouped/structural editors and replaced settings roots require reopening.
Profile selection/reload and unreviewed structural commands still
require leaving the editor first. Remote recipients apply their own menu guard.
`//trust combat [auto|mirror|off]` reads or changes combat positioning; bare
`//trust combat` reports its mode. It does not implement full Manual Override.

Modes loaded for the current character also accept direct commands:

- `//trust autoraise` and `//trust AutoRaiseMode` cycle AutoRaiseMode.
- `//trust autoraise Auto` and `//trust AutoRaiseMode Off` set its value.
- Mode names and listed values are case-insensitive. Multi-word listed options
  resolve to their canonical spelling; free-form string-mode text retains case.
- Registered commands take priority. `//trust combat` keeps its reporting behavior;
  `//trust CombatMode` cycles. No additional fuzzy abbreviations are guessed.
- Ambiguous aliases are rejected. Invalid values list available options. Modes
  absent from the current job are not invented. Autocomplete includes valid forms.
- Aliases route through existing set/cycle handlers, so mode locks, menu draft
  checks and profile-switch restrictions remain in force. With Save options on exit
  On, the modes actually changed by a successful command save into the current
  named mode set without resetting it or including unrelated temporary mode values.
  With Off, aliases remain runtime-only. A pending valid menu draft may save first.

Command autosaves report `Saved command changes.` (quiet follow/assist stay quiet).
No-op and unsuccessful commands do not trigger new writes. Existing successful
explicit writes are not repeated unless the command changes settings again afterward.
Follow distance (0–50) participates; follow/assist targets and paused-follow state
remain session controls. Profile/scenario loading, lifecycle/UI commands and remote
relays retain their own behavior; receiving clients save their own successful changes.
Failures identify the affected settings owner; other owners may already have saved.
There is no automatic retry or rollback of live actions. The opt-in trace also records
command-save completion/failure. Writer completion is not disk readback verification.

The reported Modes save-on-exit revert remains unresolved pending an in-game trace.
This package also includes the controller conversation's idempotent `//trust menu open`
and existing `//trust menu close`. Matching DirectLink Controls 9.8 provides the
R1+Triangle/R1+Square bindings separately; this package does not install Lua/AHK
controller files. The earlier handoff remains in `docs/R1-SQUARE-TRUST-CLOSE.md`.

Source/mocked regression checks pass; **Windows/Windower/FFXI acceptance is pending**.
See `TESTING.md` for the exact live checklist, compatible baseline and rollback.

Test 5 includes the DirectLink Open addendum below; do not overlay an older
Test 4 MenuCommands.lua onto Test 5. Controller Lua/AHK delivery remains separate.

## DirectLink explicit Open addendum — 2026-10-18

For the R1 controller shortcuts, this source addendum adds `//trust menu open`.
It opens the main menu when closed and preserves an already open submenu/cursor/
draft. `//trust menu close` retains eligible save/validation; invalid edits can
keep the menu open. Menu status includes `explicit open: true`.

Over an existing compatible Menu options Test 4 install, update only
`commands/MenuCommands.lua` and reload Trust. Existing Test 4 BUILD/install
records remain pinned to their original ZIP. This is a source addendum, not a
new full package. The matching XIVCrossbar/Controls 9.8 update supplies R1+Triangle
Open and R1+Square Close. Windows/FFXI acceptance remains pending.

## Summary

Trust is a Windower 4 addon for FFXI that turns your character into a Trust. It works for all [22 jobs](https://github.com/cyritegamestudios/trust/wiki/Trusts) and can attack, nuke, pull, skillchain, follow, roll, sing, and more, consolidating the functionality of EasyFarm, Cure Please, Rollbot, FastFollow and [many others](https://github.com/cyritegamestudios/trust/wiki#why-use-trust) into a single add-on. これは日本語でも機能します!

![image](https://github.com/user-attachments/assets/176fdd32-3d10-4664-8941-93f5c2887e73)
![image](https://github.com/user-attachments/assets/dd62282d-3424-4a34-9842-d33bd2049cb5)


## Donate
:star: Trust is a completely free addon maintained as a hobby project. If you're enjoying using Trust, consider [**donating**](https://www.buymeacoffee.com/cyrite) to show your support and keep it going! :star:

--------------------------------------------------------------------------------

## Support

Get help or request a feature in the [Cyrite Game Studios Discord](https://discord.gg/CfPxDy759J). Do NOT ask questions about Trust in game.

## Setup
You will need the latest version of [Trust](https://github.com/cyritegamestudios/trust) in order to use Trust.

### Recommended
1. Download and launch the Trust [installer](https://github.com/cyritegamestudios/trust/blob/main/Setup/TrustInstaller.zip). If you running Trust v10.0.8+, the installer should be in your `addons/trust/Setup` folder already. **Please move it to your Desktop. If you run the installer from within the Trust folder it will not work.**
2. If a Windows security popup appears, click "More Info" and "Run Anyway".
3. **Unload Trust from all characters (// lua unload trust).**
4. Follow the instructions in the installer.
5. To update, launch the installer again.

![image](https://github.com/user-attachments/assets/06b59159-b92e-483e-8f3e-7d9b5c32026d)


### Manual
1. Download the latest release of [Trust](https://github.com/cyritegamestudios/trust/releases) from GitHub (trust.zip under `Assets` at the bottom of the release page).
2. Unzip `trust.zip`, right click the `trust` folder, copy it and paste it into the `Windower/addons` folder. Note that this will *not* override your entire existing `trust` folder, only changed files.
3. If you have downloaded multiple copies of `trust`, the name of your folder might be `trust (2)`, `trust (3)`, etc. Rename this folder to be **Trust** if needed.
4. To update your version of Trust, repeat steps 1-3 above.

### Git
1. Create a folder named `Trust` in your `Windower/addons` folder.
2. Run `git clone git@github.com:cyritegamestudios/trust.git .` in that folder.
3. To update, do a `git pull`.

## Dependencies

Trust also requires the following addons, which can be installed through [Windower](https://docs.windower.net/addons/). **After installing all dependencies, run the `// lua list` command and ensure both appear in the list of loaded addons**:
* [Gearswap](https://docs.windower.net/addons/gearswap/) (vanilla or Selendrile)

If you are multi-boxing, you also need the following plugins:
* [dgVoodoo](https://www.bg-wiki.com/ffxi/DgVoodoo_Setup_Guide)
* [Sandbox](https://docs.windower.net/plugins/sandbox/)

## Post Install
1. Double check that the `Windower/addons/trust` folder exists.
2. Run `// lua r trust` and you're ready to get started!
3. _**You can configure your Trust through the menu by pressing down Control and the Numpad+ buttons.**_

## 日本のゲームクライアント
日本語版のGearSwap（`set_language('japanese')`）を使用している場合は、Config > GearSwapの下にある言語を日本語に更新し、保存してください。

![image](https://github.com/user-attachments/assets/e59c6cca-dc68-4828-94ac-e0453af15cb3)

Trustを日本語に翻訳したい場合は、Config > Languageの下で言語を日本語に更新し、保存してください。

![image](https://github.com/user-attachments/assets/e15a9bd1-bd9e-42b4-a7ff-c130eaa23e7a)


### Optional

6. Override [job settings](https://github.com/cyritegamestudios/trust/wiki/Job-Settings) to customize what your trust does using the [menu](https://github.com/cyritegamestudios/trust/wiki/Menu).

### Commands
See [Windower Commands](https://github.com/cyritegamestudios/trust/wiki/Commands), [Shortcuts](https://github.com/cyritegamestudios/trust/wiki/Shortcuts)

## User Guide

![image](https://github.com/user-attachments/assets/2824d737-d4f3-4f23-8c35-8527916bd175)

**NEW!** Trust documentation is now available at the [**Wiki**](https://github.com/cyritegamestudios/trust/wiki).

* [**Getting Started**](https://github.com/cyritegamestudios/trust/wiki/Getting-Started)
    * [**Menu**](https://github.com/cyritegamestudios/trust/wiki/Menu)
    * [**Commands**](https://github.com/cyritegamestudios/trust/wiki/Commands)
    * [**Shortcuts**](https://github.com/cyritegamestudios/trust/wiki/Shortcuts)
* [**How To**](https://github.com/cyritegamestudios/trust/wiki/How-To)
  * [Multi-Boxing](https://github.com/cyritegamestudios/trust/wiki/Multi-Boxing)
* [**Settings**](https://github.com/cyritegamestudios/trust/wiki/Settings)
    * [**Job Settings**](https://github.com/cyritegamestudios/trust/wiki/Job-Settings)
    * [**Conditions**](https://github.com/cyritegamestudios/trust/wiki/Conditions)
* [**Modes**](https://github.com/cyritegamestudios/trust/wiki/Modes)
  * [AutoEngageMode](https://github.com/cyritegamestudios/trust/wiki/AutoEngageMode)
  * [AutoBuffMode](https://github.com/cyritegamestudios/trust/wiki/AutoBuffMode)
  * [AutoFaceMobMode](https://github.com/cyritegamestudios/trust/wiki/AutoFaceMobMode)
  * [AutoDebuffMode](https://github.com/cyritegamestudios/trust/wiki/AutoDebuffMode)
  * [AutoSilenceMode](https://github.com/cyritegamestudios/trust/wiki/AutoSilenceMode)
  * [AutoSleepMode](https://github.com/cyritegamestudios/trust/wiki/AutoSleepMode)
  * [AutoDispelMode](https://github.com/cyritegamestudios/trust/wiki/AutoDispelMode)
  * [AutoEnableMode](https://github.com/cyritegamestudios/trust/wiki/AutoEnableMode)
  * [AutoFoodMode](https://github.com/cyritegamestudios/trust/wiki/AutoFoodMode)
  * [AutoAvoidAggroMode](https://github.com/cyritegamestudios/trust/wiki/AutoAvoidAggroMode)
  * [AutoFollowMode](https://github.com/cyritegamestudios/trust/wiki/AutoFollowMode)
  * [AutoHealMode](https://github.com/cyritegamestudios/trust/wiki/AutoHealMode)
  * [AutoDetectAuraMode](https://github.com/cyritegamestudios/trust/wiki/AutoDetectAuraMode)
  * [AutoMagicBurstMode](https://github.com/cyritegamestudios/trust/wiki/AutoMagicBurstMode)
  * [AutoNukeMode](https://github.com/cyritegamestudios/trust/wiki/AutoNukeMode)
  * [AutoPianissimoMode](https://github.com/cyritegamestudios/trust/wiki/AutoPianissimoMode)
  * [AutoPullMode](https://github.com/cyritegamestudios/trust/wiki/AutoPullMode)
  * [AutoRaiseMode](https://github.com/cyritegamestudios/trust/wiki/AutoRaiseMode)
  * [AutoRestoreManaMode](https://github.com/cyritegamestudios/trust/wiki/AutoRestoreManaMode)
  * [AutoRollMode](https://github.com/cyritegamestudios/trust/wiki/AutoRollMode)
  * [AutoShootMode](https://github.com/cyritegamestudios/trust/wiki/AutoShootMode)
  * [AutoSongMode](https://github.com/cyritegamestudios/trust/wiki/AutoSongMode)
  * [AutoSkillchainMode](https://github.com/cyritegamestudios/trust/wiki/AutoSkillchainMode)
  * [AutoStatusRemovalMode](https://github.com/cyritegamestudios/trust/wiki/AutoStatusRemovalMode)
  * [AutoAftermathMode](https://github.com/cyritegamestudios/trust/wiki/AutoAftermathMode)
  * [AutoTankMode](https://github.com/cyritegamestudios/trust/wiki/AutoTankMode)
  * [AutoTargetMode](https://github.com/cyritegamestudios/trust/wiki/AutoTargetMode)
  * [AutoTrustsMode](https://github.com/cyritegamestudios/trust/wiki/AutoTrustsMode)
  * [AutoZoneMode](https://github.com/cyritegamestudios/trust/wiki/AutoZoneMode)
  * [CombatMode](https://github.com/cyritegamestudios/trust/wiki/AutoCombatMode)
  * [FlankMode](https://github.com/cyritegamestudios/trust/wiki/FlankMode)
  * [IpcMode](https://github.com/cyritegamestudios/trust/wiki/IpcMode)
  * [SkillchainPropertyMode](https://github.com/cyritegamestudios/trust/wiki/SkillchainPropertyMode)
* [**Trusts**](https://github.com/cyritegamestudios/trust/wiki/Trusts)
    * [Bard](https://github.com/cyritegamestudios/trust/wiki/Bard)
    * [Beastmaster](https://github.com/cyritegamestudios/trust/wiki/Beastmaster)
    * [Black Mage](https://github.com/cyritegamestudios/trust/wiki/Black-Mage)
    * [Blue Mage](https://github.com/cyritegamestudios/trust/wiki/Blue-Mage)
    * [Corsair](https://github.com/cyritegamestudios/trust/wiki/Corsair)
    * [Dancer](https://github.com/cyritegamestudios/trust/wiki/Dancer)
    * [Dark Knight](https://github.com/cyritegamestudios/trust/wiki/Dark-Knight)
    * [Dragoon](https://github.com/cyritegamestudios/trust/wiki/Dragoon)
    * [Geomancer](https://github.com/cyritegamestudios/trust/wiki/Geomancer)
    * [Monk](https://github.com/cyritegamestudios/trust/wiki/Monk)
    * [Ninja](https://github.com/cyritegamestudios/trust/wiki/Ninja)
    * [Paladin](https://github.com/cyritegamestudios/trust/wiki/Paladin)
    * [Puppetmaster](https://github.com/cyritegamestudios/trust/wiki/Puppetmaster)
    * [Ranger](https://github.com/cyritegamestudios/trust/wiki/Ranger)
    * [Red Mage](https://github.com/cyritegamestudios/trust/wiki/Red-Mage)
    * [Rune Fencer](https://github.com/cyritegamestudios/trust/wiki/Rune-Fencer)
    * [Samurai](https://github.com/cyritegamestudios/trust/wiki/Samurai)
    * [Scholar](https://github.com/cyritegamestudios/trust/wiki/Scholar)
    * [Summoner](https://github.com/cyritegamestudios/trust/wiki/Summoner)
    * [Thief](https://github.com/cyritegamestudios/trust/wiki/Thief)
    * [Warrior](https://github.com/cyritegamestudios/trust/wiki/Warrior)
    * [White Mage](https://github.com/cyritegamestudios/trust/wiki/White-Mage)
* [**Roles**](https://github.com/cyritegamestudios/trust/wiki/Roles)
    * [Attacker](https://github.com/cyritegamestudios/trust/wiki/Attacker)
    * [BloodPacter](https://github.com/cyritegamestudios/trust/wiki/BloodPacter)
    * [Buffer](https://github.com/cyritegamestudios/trust/wiki/Buffer)
    * [CombatMode](https://github.com/cyritegamestudios/trust/wiki/CombatMode)
    * [Debuffer](https://github.com/cyritegamestudios/trust/wiki/Debuffer)
    * [Dispeler](https://github.com/cyritegamestudios/trust/wiki/Dispeler)
    * [Eater](https://github.com/cyritegamestudios/trust/wiki/Eater)
    * [Evader](https://github.com/cyritegamestudios/trust/wiki/Evader)
    * [Follower](https://github.com/cyritegamestudios/trust/wiki/Follower)
    * [Healer](https://github.com/cyritegamestudios/trust/wiki/Healer)
    * [Nuker](https://github.com/cyritegamestudios/trust/wiki/Nuker)
    * [Puller](https://github.com/cyritegamestudios/trust/wiki/Puller)
    * [Raiser](https://github.com/cyritegamestudios/trust/wiki/Raiser)
    * [Roller](https://github.com/cyritegamestudios/trust/wiki/Roller)
    * [Shooter](https://github.com/cyritegamestudios/trust/wiki/Shooter)
    * [Singer](https://github.com/cyritegamestudios/trust/wiki/Singer)
    * [Skillchainer](https://github.com/cyritegamestudios/trust/wiki/Skillchainer)
    * [Sleeper](https://github.com/cyritegamestudios/trust/wiki/Sleeper)
    * [StatusRemover](https://github.com/cyritegamestudios/trust/wiki/StatusRemover)
    * [Tank](https://github.com/cyritegamestudios/trust/wiki/Tank)
    * [Targeter](https://github.com/cyritegamestudios/trust/wiki/Targeter)
    * [Truster](https://github.com/cyritegamestudios/trust/wiki/Truster)




## Movement handoff quiet update (2026-10-15)

Follow/assist commands accept an optional trailing `--quiet`, for example
`//trust follow me --quiet` and `//trust assist me --quiet`. This suppresses
routine success acknowledgments locally and propagates quiet to IPC recipients.
Normal commands retain feedback; validation/IPC errors remain visible. Install
on each participating client. TrustMovement 0.1.1 enables quiet by default and
provides `//tm quiet off` for troubleshooting. Source/API behavior otherwise
remains unchanged; see TESTING.md for verification and the live-testing status.

TrustMovement's source is maintained with the controller transport in the
[XIVCrossbar fork](https://github.com/rerorriM-Mirrorer/xivcrossbar), under
`companions/trustmovement/`. Its movement bridge is `movement_signal.ahk` beside
the shared AHK wrapper. At installation, `trustmovement`, `xivcrossbar` and
`trust` are sibling folders under `Windower/addons`. Trust owns the optional
quiet follow/assist API; the companion owns movement-triggered invocation.

## Fork development changelog

- **2026-10-19 — Party song gambits test 1:** remove the inherited beneficial-song
  exclusion from the ordinary gambit picker; use existing job spell/target filters.
  Add setup guidance for self-area singing, song conditions and gambit priority.
- **2026-10-18 — Menu options test 5:** successful command settings/mode autosaves
  under the existing preference, named-set/runtime preservation, duplicate-write
  avoidance and quiet feedback; clean scalar editor refresh and options-list entry
  focus; preserve explicit structural/profile actions and manual drafts.
- **2026-10-18 — Menu options test 4:** full and suffix-free mode aliases with
  existing-command precedence, option validation and autocomplete. Preserve
  set/cycle locks, menu/profile guards and runtime persistence semantics.
- **2026-10-17 — Menu options test 3:** bounded opt-in save trace and export;
  menu-aware runtime command policy; combat positioning shorthand; clean Modes
  refresh after tactical commands; guard removal/reload of uncached list rows.
  Full source folder package; original autosave failure awaits live trace.
- **2026-10-17 — Menu options test 2:** scope native IJKL blocking to open menus,
  alongside arrows; restore menu bindings after text entry; add durable save
  feedback and editor draft state to menu status. Reported Modes save-on-exit
  failure remains under investigation; real AHK controller delivery is unverified.
- **2026-10-17 — Menu options test 1:** optional save-on-exit with validation,
  named-set/conflict guards and one owner write per changed departure; adjacent
  editor placement; text-aware IJKL directional input; menu close/discard;
  cumulative overlay retains earlier compact UI and quiet handoff support.
- **2026-10-15 — Quiet movement API:** opt-in quiet follow/assist flags across IPC;
  preserve ordinary command feedback and meaningful errors (details above).

- **2026-10-18 — DirectLink explicit Open:** add idempotent menu open for controller callers; preserve visible editors and existing close validation. Source addendum; native tests pending.


### October 22, 2026 — controller menu Test 1

Added paired direct controller navigation for Trust, contextual native-input suppression, session/release guards and status diagnostics. See docs/CONTROLLER-MENU-TEST1.md.
