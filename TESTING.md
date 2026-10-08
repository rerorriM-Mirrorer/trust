# TESTING.md — Trust

Private, cumulative development and testing record. Keep this file at the **repository root** and at the **root of every testing package**. Read it first before testing or preparing a patch batch. Exclude this internal record from public release packages unless the collaborators agree otherwise.

**Reference conventions:** [NPCMirror WORKFLOW.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/WORKFLOW.md), [DESIGN.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/DESIGN.md), [AGATHOS.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/AGATHOS.md). Apply the smallest responsible change, protect known-good states, document corrections using strikethrough plus explanation, and remove historical entries only by mutual agreement.

## Current testing batch — 2026-10-08: C0 iteration 2, compact click/drag recovery

- **Branch:** [`test/compact-trust-title-20261008`](https://github.com/rerorriM-Mirrorer/trust/tree/test/compact-trust-title-20261008). `main` remains last trusted live-tested code.
- **Code commits:** [`831b1fc3`](https://github.com/rerorriM-Mirrorer/trust/commit/831b1fc3647d8152c1aee96077a367d6777db939) (compact click/drag), [`122564e9`](https://github.com/rerorriM-Mirrorer/trust/commit/122564e973130432f2b36cb7053a00947ece1151) (commands), [`3da6873c`](https://github.com/rerorriM-Mirrorer/trust/commit/3da6873cb215398f279683aba0210f0e18e156c3) (menu command exception).
- **Changed files:** `ui/widgets/TrustStatusWidget.lua`, `commands/GeneralCommands.lua`, `Trust.lua`, and this `TESTING.md` (documentation only). No Party/Target/EnemyBar2 or automation-behavior changes.
- **USER LIVE REPORT on C0 iteration 1:** Compact footprint is noticeably improved and liked; **click did not expand**, **dragging was difficult/nonfunctional**. Resolution, input method and screenshots were not supplied. Preserve as failed tests; do not claim iteration 1 passed interactive tests.
- **SOURCE-CONFIRMED issue:** Base `Widget:onMouseEvent` starts a drag only when `isExpanded()` is true. Compact mode inherited that restriction; the original title click was not a safe sole recovery method. `//trust menu` opens Trust's menu but **does not expand** the widget.
- **Current candidate fix:** Custom compact `hitTest` and `onMouseEvent` distinguish click vs movement beyond 3 pixels, allow dragging the title tab, save position on release, and expand on short click. Full mode keeps the upstream mouse code. Add `//trust widget full`, `//trust widget compact`, `//trust widget toggle` (or `//trust widget`), permitted even while the menu is open.
- **Live status:** **PENDING.** Do not report runtime success until the user tests the revised files. No changes to the originally desired small 104×14 default.

### Install / rollback

1. Back up these **three** installed source files: `Trust.lua`, `commands/GeneralCommands.lua`, and `ui/widgets/TrustStatusWidget.lua`. Check that the installed Trust matches this repository's base before replacing source; this is a candidate fork branch, not a public release.
2. Replace all three using the files from the **same branch revision**. Reload with `//lua r trust`. If something breaks, restore all backups, then reload again.
3. The full display can now be requested with `//trust widget full`; return to the small tab with `//trust widget compact`. The regular `//trust menu` still opens the settings menu.

### Test plan (all new results PENDING)

1. **C0-7 command escape:** Run `//trust widget full`, `//trust widget compact`, `//trust widget toggle` and `//trust widget`. Verify reliable size changes, no automation state changes, and a clear usage error on invalid arguments.
2. **C0-8 compact short click:** Click tab once without moving; verify Full returns without double-click or focus anomalies. To recover if click fails, use `//trust widget full` and capture the result.
3. **C0-9 compact drag:** Hold on the tab, drag at least 20 pixels, release. Check that it moved rather than expanded; reload to confirm position was saved.
4. **C0-10 bounds and multi-resolution:** Test moving past the original narrow rectangle during drag; repeat at the laptop's small resolution and a large one. Report any drag loss, offsets or off-screen behavior.
5. **C0-11 full regression:** Return to Full and verify original row functionality and dragging. Confirm other widgets are unchanged.
6. **C0-12 menu coexistence:** With settings menu open, run `//trust widget full` and `compact`; verify they are not blocked, and other command restrictions remain as before.

### Candidate hazards

- Interacting with the shared mouse input/focus routing may interfere with compact clicks; source review cannot demonstrate Windower behavior. Test on one client before multiple.
- With a 3-pixel movement threshold, subtle pointer jitter may sometimes count as drag; measure before modifying threshold.
- Commands are available only after **all three source files** are updated and Trust is reloaded. An old `Trust.lua` or `GeneralCommands.lua` will not recognize them.

---

## Previous testing batch — 2026-10-08: Trust title-only compact placeholder (candidate)

**Heading correction (2026-10-08):** ~~Current testing batch — 2026-10-08: Trust title-only compact placeholder (candidate)~~. Superseded by C0-iteration 2 below; candidate code and all original test steps retained for history.

- **Status:** TEST C0 candidate committed on a testing branch; **no live FFXI results reported**. This is a deliberately narrow visual experiment, not the complete Compact mode described later in this record.
- **Branch:** [`test/compact-trust-title-20261008`](https://github.com/rerorriM-Mirrorer/trust/tree/test/compact-trust-title-20261008), branched from `main`. Do not merge into `main` until live-tested.
- **Code commit:** [`f7c82c81`](https://github.com/rerorriM-Mirrorer/trust/commit/f7c82c81b556bc07b38bc01cdfc677340c5c9646).
- **Modified source:** `ui/widgets/TrustStatusWidget.lua` only. No Party, Target, EnemyBar2, combat, follower or settings schema changes.
- **Change:** Trust widget begins as a 104×14 title-only tab reusing its existing "Trust" title border. The default title-click callback toggles back to the full widget and back again. The body rows and bottom border are suppressed while compact. This is a **placeholder tab**, not yet a true 20×20 icon; the existing four fixed-width title-border pieces make an icon-width shrink unsafe without changing the renderer.
- **Deferred:** Gray/blue/green state tint, persistent Full/Compact setting, Party hiding, debuff overlays, menu UX and other requests remain pending as documented below. The action queue and its current state tracking are untouched.
- **Static check (2026-10-08):** New Lua methods loaded with `texlua` (Lua syntax check). An isolated mock test passed compact → full → compact switching, size selection and visibility calls. These checks do **not** exercise the real Windower renderer, mouse dispatch or Lua 5.1 environment. Full-addon parsing, smoke and live tests remain **PENDING**.

### Live installation and test instructions (all PENDING)

0. Make a backup of your existing `Windower/addons/Trust/ui/widgets/TrustStatusWidget.lua` (actual Windower folder may differ). Only copy the **candidate branch's** replacement file if the local Trust version matches the examined fork; do not replace the rest of the addon. Reload Trust with `//lua r trust`. If the layout breaks, restore the backup and reload again.
1. **C0-1 — Startup:** Verify there is only a narrow `Trust` title tab, no job/level/profile/action rows and no dangling body/bottom border. Record screen resolution and observed dimensions. **Result: PENDING.**
2. **C0-2 — Toggle:** Click/tap the `Trust` title: full window should return; click again: title-only tab. Repeat several times. Confirm no blank widgets or stuck keyboard focus. **Result: PENDING.**
3. **C0-3 — Activity:** In compact mode, run `//trust stop` then `//trust start`, and perform a normal action. Confirm automation still runs and the title remains compact. **Result: PENDING.**
4. **C0-4 — Position and reload:** Drag when full, collapse, change resolution, reload, and observe tab placement and recovery. The current patch has **no new persistence code**, so compact-on-reload is intentional but positions follow existing widget settings. **Result: PENDING.**
5. **C0-5 — Multi-client:** If single-client passes, inspect the title tab on one small-resolution client and one larger client, then several clients. Do not infer multiclient success from source review. **Result: PENDING.**
6. **C0-6 — Regression:** Ensure Party and Target windows and menus behave as before. Those widgets are **not** hidden by this particular experiment. **Result: PENDING.**

### Candidate hazards to watch

- Whether shrinking the base widget and reusing its title-border cells causes flicker, misplaced artwork, a ghost bottom border, or an unexpectedly large mouse hitbox.
- Whether hiding the content view is undone by action-queue updates, and whether restoring Full reveals every original row correctly.
- Whether clicking the title works in compact mode with controller/mouse and across window focus changes. If not, restore the backup; no independent command toggle was added in this experiment.
- Because compact is the **default on each load**, Full is currently session-only. State colors are not yet implemented; don't mistake this placeholder for the final icon.

---

## Previous testing batch — 2026-10-08: UX and integration proposals

**Historical heading preserved:** ~~Current testing batch — 2026-10-08: UX and integration proposals~~. It was a documentation-only baseline; it is now superseded as *current*, but its source observations, proposals, and notes are retained below.

- **Package / batch:** Documentation-only baseline. No testing package.
- **Repository:** `rerorriM-Mirrorer/trust`, default branch `main`; baseline examined at commit `9a7de430c622b8565edcf3667e72b4d5ca317e46`. Source identifies itself as Trust 17.7.3. Verify baseline again before coding.
- **Status:** Code inspected; issues and desired changes recorded. **No implementation, static test, automated runtime test, or live FFXI test conducted for this entry.**
- **Files affected by this batch:** `TESTING.md` only. No behavioral changes; no change to EnemyBar2, XIVCrossbar, or installed game files.
- **Purpose:** Make Trust quieter and faster to operate; provide an almost invisible compact UI; explore debuff rendering through EnemyBar2; shorten the settings-commit workflow; and prepare safe follow/path troubleshooting.
- **Read before testing:** All new menu, widget, and integration behavior below is a **proposal**, not an installed feature.

### Evidence and status language

- **USER OBSERVATION** = user-reported experience in live FFXI, not independently reproduced by the developer.
- **SOURCE-CONFIRMED** = verified by reading a named code path, not necessarily working as intended at runtime.
- **HYPOTHESIS** = possible cause, awaiting instrumentation/controlled reproduction.
- **PROPOSAL** = desired behavior or candidate implementation, not yet coded.
- **PENDING** = test not run. Do not mark an observed symptom as a passing implementation test.
- Record test date, character/client count, resolution, profile, steps, actual outcome, screenshots/logs if available, regression notes, and commit/package reference.

### User observations / requests (2026-10-08)

1. **Chat:** `//trust set PartyChatMode Off` is an acceptable no-code workaround for repetitive “I can't find you. Whatever happened to no Trust left behind?” and related conversational chat, provided it works in-game. No chat rewrite requested for now.
2. **Command browser and menus:** The command browser is jarring on opening and visibly hitches when drawn. Other Trust menus also hitch; consider restrained fade-in/out like XIVCrossbar's autohide animation. Do not assume a fade eliminates rendering cost.
3. **Trust widget:** Displayed main/subjob levels are often incorrect. In **Compact** mode show **only one icon**, colored **gray Off**, **blue Idle**, **green Active**, using the previously discussed palette. No additional proposed “Moving / Attention / Error” colors in this compact design.
4. **Party widget:** Hide the entire Party window in Compact mode. At most place a small count of in-party Trust members beside the Trust icon. Clarify later whether “Trust members” means multibox clients running the addon, summoned alter egos, or another subset; do not silently substitute total party size.
5. **Target widget:** Keep a small transparent/floating target indicator + target name + visible debuff icons; remove redundant HP% and distance in Compact mode because EnemyBar2 covers these. More than seven/eight icons if supported cleanly. No enclosing background; emulate the restrained appearance of FFXI status icons.
6. **EnemyBar2 integration:** Link Trust's *party combat target* to EnemyBar2 by **entity ID**, not by name. When the Trust target matches the current game target, draw debuff icons above/below/alongside EnemyBar2's **main target** bar; when different, draw them at an EnemyBar2 **focus-target** bar. Avoid duplicated HP/name/distance. Alternatively first test standalone EnemyBar2 debuff icons using its existing tracking/assets, then integrate Trust's fuller tracking. Preserve the possibility that the compact Trust Target widget remains as an independent icon/name strip.
7. **Menu editing:** Current settings may require leaving an editor, navigating to Save, saving separately, and closing the menu before issuing commands. Desired behavior: change list/toggle selections without repeatedly pressing Enter; a single **Enter** commits *all* pending edits in the current editor, persists them to the correct settings/profile, and returns **one menu level**. No deep backtracking. Verify behavior with controller, keyboard, validation errors, and unchanged fields.
8. **Commands with menu open:** Prior observation: blocking most commands when a menu is visible discourages use of the menu. Essential Stop/Hold/menu-close should remain reachable. Prevent contradictory edits rather than imposing a blanket prohibition.
9. **On-demand automation:** Interested in adjusting individual buffs/heal frequency or temporarily overriding unsuccessful gambits in play, not necessarily building elaborate permanent party patterns. Distinguish temporary override, one-shot action, and persistent profile edit.
10. **Following/pathing:** Followers can remain caught on terrain. Investigate stuck detection using position/progress when out of combat, then a bounded, reversible side-step/arc/spiral-like recovery with retry; monitor only before enabling autonomous corrections.
11. **Documentation:** Keep `TESTING.md` at the repository/testing-package root and maintain observations, hypotheses, tests, previous records, corrections and delivery history.

## Source-confirmed baseline (not live-tested here)

| Area | Current source behavior | File / reference |
| --- | --- | --- |
| Party chat | `PartyChatMode` has `Private`, `Party`, `Off` values. The warning passes `follower_follow_failure` with a 30-second throttle. `Off` suppresses ordinary party-chat messages; separate logger/system errors may remain. | [party_chat.lua](cylibs/chat/party_chat.lua); [follower.lua](cylibs/trust/roles/follower.lua) |
| Trust status | The widget observes addon enabled/disabled and the **main action queue**; empty action text becomes `Idle`, disabled shows `OFF`, and active action text shows the specific action. This is **not an explicit three-value status enum**; following uses a separate queue. | [TrustStatusWidget.lua](ui/widgets/TrustStatusWidget.lua); [follower.lua](cylibs/trust/roles/follower.lua) |
| Job levels | `setJobs()` reads `windower.ffxi.get_player().main_job_level` and `sub_job_level`. It is invoked during construction, player-level events and zone changes. Whether stale Windower data, update timing, or missed events explain incorrect values remains **unknown**. | [TrustStatusWidget.lua](ui/widgets/TrustStatusWidget.lua) |
| Party window | Clicking player/member rows opens player or member menus, and highlighting a member can show buff icons. It also provides alliance navigation and assist/command operations. These functions must remain accessible in Full mode. | [PartyStatusWidget.lua](ui/widgets/PartyStatusWidget.lua) |
| Trust target | `TargetWidget` receives `party:on_party_target_change` and target-tracker events; it does not directly use the client's `get_mob_by_target('t')` to decide the displayed target. Party assist-target tracking and game events feed this state. | [TargetWidget.lua](ui/widgets/TargetWidget.lua); [party_target.lua](cylibs/entity/party/party_target.lua) |
| Debuff icons | Trust has `self.maxNumDebuffs = 7`. It renders tracked debuff IDs from its monster/debuff tracker and responds to gain/loss events. | [TargetWidget.lua](ui/widgets/TargetWidget.lua) |
| Existing EnemyBar2 | [EnemyBar2 fork](https://github.com/rerorriM-Mirrorer/enemybar2) supports target/subtarget/focus/aggro bars and `//eb ft`; its `show_debuff` currently covers selected crowd-control status icons, **not** Trust's multi-icon tracked debuff row. | [enemybar2.lua](https://github.com/rerorriM-Mirrorer/enemybar2/blob/master/enemybar2.lua); [bars.lua](https://github.com/rerorriM-Mirrorer/enemybar2/blob/master/bars.lua) |
| Widget visibility | Widget settings database contains a `visible` field, but the manager initializes widgets visible; Party and Target logic can show them again on updates. Persistent visibility must be respected by render/update flows, not patched by a one-off hide. | [settings/settings.lua](settings/settings.lua); [WidgetManager.lua](ui/widgets/WidgetManager.lua); [PartyStatusWidget.lua](ui/widgets/PartyStatusWidget.lua); [TargetWidget.lua](ui/widgets/TargetWidget.lua) |
| Browser/menu hitch | The command-menu system dynamically creates menu items/editor views. The code suggests possible layout or creation cost, but the actual hitch cause is **unverified**. | [CommandsMenuItem.lua](ui/settings/menus/commands/CommandsMenuItem.lua); [menu.lua](cylibs/ui/menu/menu.lua); [TrustHud.lua](ui/TrustHud.lua) |
| Menu saving | `ModeConfigEditor` applies changes on confirmation; `ModesMenuItem` has a separate explicit `Save` action to persist modes to the selected profile. Other ConfigEditor instances may save owning settings when confirming. Save semantics differ between editors. | [ModeConfigEditor.lua](ui/settings/editors/config/ModeConfigEditor.lua); [ConfigEditor.lua](ui/settings/editors/config/ConfigEditor.lua); [ModesMenuItem.lua](ui/settings/menus/ModesMenuItem.lua) |
| Menu command restriction | Trust refuses nearly all addon commands when `hud.trustMenu:isVisible()`, except `assist`, `send`, `sendall`. Reason for this rule is **undocumented in the inspected code**. | [Trust.lua](Trust.lua) |
| Pathing | `RunToLocationAction` keeps steering directly toward a point and defines a 10-second max duration. `Pather` advances to its next waypoint when within roughly one yalm. No dedicated stuck/recovery planner was identified in the inspected path. | [runtolocation.lua](cylibs/actions/runtolocation.lua); [pather.lua](cylibs/trust/roles/pather.lua) |
| Healing | `AutoHealMode` includes `Auto`, `Emergency`, `Off`. An explicit FIXME in `Healer:get_cooldown()` notes that Emergency does not yet consistently implement a separate HP threshold and instead uses a longer cooldown in that path. | [healer.lua](cylibs/trust/roles/healer.lua) |

### Clarifications / corrections kept in the record

- ~~Trust exposes an explicit three-state `Off` / `Idle` / `Active` status enum.~~ **Correction (2026-10-08):** Those are the *proposed compact labels derived from* addon-enabled state and the action queue. Preserve Off's priority over late action-end events; do not claim they enumerate all automation activity.
- ~~Trust Target displays up to eight debuff icons by default.~~ **Correction (2026-10-08):** Source sets `maxNumDebuffs = 7`. Increasing the limit, layout, data completeness, and performance require tests.
- ~~A slow fade fixes the opening hitch.~~ **Correction (2026-10-08):** A fade can improve perceptual transition but may not reduce synchronous work. Profile render/layout cost independently.

## Proposed UX design and acceptance tests

### A. Menus, command browser, smooth appearance

**PROPOSAL:** Make opening and dismissing menus visually gentle (brief fade-in, perhaps 120–180 ms initially; fine-tune live), without delayed key handling or interaction. Consider incremental/lazy construction, caching, or prewarming to address real hitch. No new animation during gameplay cutscenes, and avoid unnecessary per-frame work with six clients.

**Test A1:** On one client, record open/close behavior for regular menu and `//trust commands`; note frozen frames, control responsiveness, transient blank/white regions, and memory/CPU impact. Repeat several times to separate first-open cost from repeated-open cost.

**Test A2:** Repeat at a small laptop resolution and a larger modern resolution; repeat with four and six clients. Compare baseline against **fade only**, **construction optimization only**, and **both**, where feasible.

**Pass criteria:** Menus appear/disappear smoothly; keyboard/controller focus works immediately; no uncommanded click, input capture, major repeated hitch, or animation when hidden. Performance claims require observed timings/frame data, not impressions alone.

### B. Enter-to-commit and faster settings navigation

**PROPOSAL:** For an editor with editable rows, arrows/selection changes adjust **staged values** without an additional Enter per toggle. A single Enter validates and commits **all** staged changes, persists to the correct file/profile, and returns to the immediately preceding menu. Support a clear outcome on invalid edits. The mode editor must handle both runtime state and saved profile, instead of retaining the current surprise separation of Confirm vs Save.

**Design questions to resolve during implementation:** Define Escape when edits are dirty (discard/confirm/cancel); distinguish text editing's Enter from editor-wide commit; choose whether intentional *temporary* changes need a separate “Apply temporarily” command; avoid overwriting unsaved edits when another controller/client issues changes.

**Test B1:** Change 2–3 independent settings including boolean, list/picker, and numeric; press Enter once. Verify all changes survive addon reload/relogin and focus returns exactly one level.

**Test B2:** Attempt invalid value, Escape, a no-op Enter, and rapid repeated Enter; verify no partial save or duplicate event, and no keybind remains captured.

**Test B3:** Repeat in Mods/Modes, gambit, healing, and other representative editors. Ensure pre-existing, separately persistent per-job and per-profile settings stay correctly scoped.

### C. Compact status / Party widget

**PROPOSAL:** Add `Full` and `Compact` visual modes, persisted per character or an explicitly chosen scope. In Compact show *only* the Trust icon: **gray Off**, **blue Idle**, **green Active**. No job/level/profile labels. Prioritize Off over queue updates; Active means the main action queue currently executes an action, not that a follower is moving. Provide tooltip/help and at least one non-color indicator for accessibility if possible.

**Party:** Hide Party window in Compact, with **optional** unobtrusive numerical count beside Trust icon only once its meaning is agreed. Full mode retains member-menu/assist/buff interactions.

**Test C1:** Start, stop, queue/complete a combat action, follow someone while otherwise Idle, zone, die, and reload. Verify status transitions and consistent Off priority.

**Test C2:** Check that Full/Compact changes neither automation nor Party controls; switching back restores position and access. Verify profile persistence and appearance at different UI scales.

**Test C3 (job level bug):** Record displayed values and compare with FFXI status window + `windower.ffxi.get_player()` values at login, job change, subjob change, level gain, zone, and UI-mode switch. Identify whether display is stale or data itself incorrect before choosing a fix. **The compact icon simply removes the misleading labels; it does not fix the underlying bug.**

### D. Minimal floating target and debuff icons

**PROPOSAL:** Compact Trust Target becomes a transparent floating row: target icon + short target name + up to configurable number of debuff icons, with no HP%, distance or enclosing panel. Preserve detailed target/skillchain info in Full mode, or in an explicit expanded view. Support more than seven icons, using wrapping or a configurable cap rather than clipping or crossing screen bounds.

**Test D1:** Zero, one, seven, eight, twelve and sixteen simultaneous trackable debuffs (if safely reproducible); check icon order, icon fallbacks, wrapping, update events, and target switches. Do not invent absent debuffs.

**Test D2:** Compare client's direct FFXI target to Trust party target while assisting another player, solo, in a party, with multiple enemies, after enemy KO, zoning and Trust reload. Confirm the label is driven by the party target, not merely by local selection.

**Test D3:** Test transparent overlay, hover/click/hitboxes, cutscene hiding, full/compact transitions, overlapping XIVCrossbar, and small resolutions.

### E. EnemyBar2 integration (independent repository; no changes yet)

**First experiment (low risk):** In EnemyBar2 alone, prototype a transparent row of actual status/debuff icons over or below its main target bar. Reuse its current mob-ID tracking and assets only where suitable; its existing `tracked_debuff` is not guaranteed to supply the same complete set as Trust. Evaluate accuracy and performance before adding a dependency.

**Second experiment (optional integration):** Expose Trust's party target and tracked debuffs as a *read-only optional source* (or a small shared adapter); EnemyBar2 resolves **mob ID** to:
- Trust target ID == live selected target ID → icons attached to EnemyBar2's **main target bar**.
- Trust target ID != selected target ID → icons on the **focus-target bar** for Trust's party target (do not take over the user's manually selected focus silently; define override policy).
- No valid Trust target / Trust unloaded / cross-zone stale data → no orphan overlay; EnemyBar2 standalone functions normally.

**Test E1:** Exact ID comparisons including index→ID conversion, despawn/reuse, multiple mobs with the same name, and party-assist changes. Never match only by name.

**Test E2:** Trust unloaded, EnemyBar2 unloaded/reloaded, either addon missing, target change during cast/debuff, selected target not equal party target, pre-existing user focus target, and multiple clients with different targets.

**Test E3:** Compare Trust's known debuff icons with EnemyBar2's crowd-control status indicators; distinguish confirmed, expired, resisted, overwritten, and unavailable effects. No false “all debuffs known” promise.

**Ownership:** Any EnemyBar2 code change belongs in `rerorriM-Mirrorer/enemybar2` with **its own** root `TESTING.md`/commit and an explicit cross-link here; don't mix repository changes in Trust's test package.

### F. Commands with menu open; on-demand gambit/buff/heal changes

**PROPOSAL:** Make emergency Stop/Hold and menu close work while a menu is open; restrict only genuinely conflicting editor operations. Keep controls reversible, scope command to the correct character, and report partial success across clients.

**Candidate one-shot/temporary behavior:** Briefly lower healing activity, request a specific available buff on a valid recipient, or temporarily disable/replace a problematic gambit. Do **not** persist temporary changes unless requested. The existing `heal`/`buff`/`debuff` command handlers support mode changes and gambit list/add/remove/enable/disable; some **persist** edits and are not equivalent to temporary overrides.

**Test F1:** Open each major menu while issuing Stop, a safe status command, an edit to the currently displayed setting, and a cross-client command. Record which are blocked and whether queued actions continue.

**Test F2:** For a future override, verify spell/ability recast, target validity, job availability, rollback/revert behavior, profile stability, and one concise explanation on failure. Test separately from permanent gambit edits.

### G. Stuck-path diagnostics (no autonomous recovery in first test)

**PROPOSAL:** Observe recent position, distance-to-waypoint and movement request while not in battle, cutscene, zone transition, or manual override. Report “possible stuck” only after a configurable interval with insufficient **net progress toward the goal**. Suppress repeats; keep first batch diagnostic-only.

**Later experimental recovery:** Suspend the competing path/follow command before a short, bounded lateral step or arc (spiral-like if safely constrained); retry the same waypoint. Limit attempts and displacement, avoid ledges/hazardous terrain as far as feasible, and give up with one clear message. No unlimited oscillation. Distinguish following another player vs replaying a recorded path.

**Test G1:** Deliberately walk into flat wall, corner, obstacle, harmless tight turn and normal slow movement. Check false positives, time-to-detection, action-queue arbitration, and no effect while stationary by intention.

**Test G2 (only after diagnostic tests pass):** Try single-client opt-in recovery; preserve original path index; disable on combat/cutscene/manual movement; guarantee finite retries and a stop command; then test multiclient behavior.

## Immediate baseline checks (no code patch required)

| ID | Procedure | Expected / question | Result |
| --- | --- | --- | --- |
| B-01 | On one client run `//trust set PartyChatMode Off`; reproduce failed follow; check local/other-client messages. | Conversational warning suppressed; system/error messages remain. Other clients may need their own mode setting. | **PENDING** |
| B-02 | Run `//trust status` before and after chat setting; inspect `PartyChatMode`. | Verify value and whether it survives reload/profile changes. | **PENDING** |
| B-03 | Open regular Trust menus and `//trust commands`; repeat open/close and note visual hitch. | Baseline reproduction with resolution/client count and load timing. | **USER OBSERVATION; structured reproduction PENDING** |
| B-04 | Compare Trust job/subjob levels with FFXI status and Windower data. | Is issue refresh/timing or incorrect source data? | **USER OBSERVATION; structured reproduction PENDING** |
| B-05 | Open Modes editor, alter multiple modes, Confirm, then save profile, reload. | Record which changes are immediate, temporary, or persistent. | **USER OBSERVATION; structured reproduction PENDING** |
| B-06 | Compare visible Trust target and current game target; use `//eb ft` in EnemyBar2. | Determine correct target ID and focus behavior; do not change persistent focus unexpectedly. | **SOURCE PATH IDENTIFIED; live reproduction PENDING** |
| B-07 | Have a follower become stuck on terrain while safe; capture position/goal over time. | Establish positive and negative cases for detector. | **USER OBSERVATION; controlled trace PENDING** |

## Delivery and test ledger

| Date | Batch / artifact | Type | Reference | Outcome |
| --- | --- | --- | --- | --- |
| 2026-10-08 | Initial Trust `TESTING.md` | Documentation only | This file; commit available in Git history | Created from user feedback and source inspection; **no behavioral tests or installation package** |
| 2026-10-08 | Trust title-only compact placeholder | Source change on untested branch | [`f7c82c81`](https://github.com/rerorriM-Mirrorer/trust/commit/f7c82c81b556bc07b38bc01cdfc677340c5c9646) | Only `TrustStatusWidget.lua`; **live results pending**, no packaged release |
| 2026-10-08 | C0 iteration 1 user result | Live observation | This conversation | **Footprint improved; expand click FAILED; compact drag FAILED**; original code preserved in Git history |
| 2026-10-08 | C0 iteration 2 interaction and command candidate | Source changes on testing branch | `831b1fc3`, `122564e9`, `3da6873c` (commits linked above) | Mouse and commands updated; **live test pending** |
| — | Subsequent Trust patch | Not yet prepared | — | No claims of implementation |
| — | EnemyBar2 debuff prototype | Not yet prepared | Separate repository | Not started |

## User-provided materials and prior findings

| Date | Item | Origin / reference | Preservation note |
| --- | --- | --- | --- |
| 2026-10-08 | Compact icon colors and three simple labels; Party removed in compact; transparent target name/debuff icons | Current project conversation | Desired design; do not expand the icon's state/color scheme without agreement |
| 2026-10-08 | Urgent small-resolution Trust widget footprint; request to reuse existing top Trust title border as first compact icon | This conversation | Implement separately as reversible candidate C0; later features remain pending |
| 2026-10-08 | Command browser/menu visual hitch; inaccurate displayed job levels; single-Enter auto-commit, navigation improvements | Current project conversation | User observations requiring controlled tests |
| 2026-10-08 | EnemyBar2 link by target ID; main vs focus debuff overlays; optional EnemyBar2-only prototype | Current project conversation; [EnemyBar2](https://github.com/rerorriM-Mirrorer/enemybar2) | Cross-repository idea; no integration implemented |
| 2026-10-08 | Quiet-mode workaround; follower warnings; manual behavior overrides; path-stuck recovery | Current and previous Trust discussion | Some source behaviors confirmed; live behavior remains to be measured |
| 2026-10-07 | Shared workflow/testing conventions | [NPCMirror root documents](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror) | Cumulative records, testing-package roots, strikethrough corrections; historical deletion only by agreement |

## Next development sequence (not authorization to implement everything at once)

1. **Baseline and diagnostics:** reproduce the browser hitch, level mismatch and menu persistence; keep a known-good snapshot.
2. **Menu UX patch:** fix the most reproducible render hitch separately from fade; single-Enter staged commit/save/back with regression tests; minimal command exceptions while editing.
3. **Compact Trust UI:** icon + optional agreed count; Party hidden; minimal transparent Target row; preserve Full mode functionality.
4. **EnemyBar2-first debuff test:** in its own repository, trial floating icons on the main bar; afterward evaluate optional Trust target/debuff adapter and focus fallback.
5. **Behavior controls and movement:** add only demonstrated-needed one-shot overrides, then diagnostic-only stuck detection; recovery after safe live validation.

**Before delivering any future test package:** update this record with package name, branch/commit, changed files, rollback procedure, exact test instructions, static/smoke results, expected outcomes, and blank spaces for live observations. Include the document at package root; omit it from public release artifacts until agreed otherwise. Correct inaccurate entries using ~~strikethrough~~, a dated note, and replacement text; do not erase history unilaterally.
