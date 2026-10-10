# TESTING.md — Trust

Private, cumulative development and testing record. Keep this file at the **repository root** and at the **root of every testing package**. Read it first before testing or preparing a patch batch. Exclude this internal record from public release packages unless the collaborators agree otherwise.

**Reference conventions:** [NPCMirror WORKFLOW.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/WORKFLOW.md), [DESIGN.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/DESIGN.md), [AGATHOS.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/AGATHOS.md). Apply the smallest responsible change, protect known-good states, document corrections using strikethrough plus explanation, and remove historical entries only by mutual agreement.

## Current testing batch — 2026-10-10: Shared single-slot compact control (candidate)

- **User layout decision (2026-10-09 evening):** Replace the three independently positioned compact widgets with **one overlapping, draggable display**. Party numeral stays **small at upper-left** of a single 32×32 asset within a 40×40 hitbox; target name uses Trust's actual yellow bold italic Arial 9pt styling **centered on the lower edge of the same slot (not underneath)**. Target name visible only when Trust's party target exists.
- **Trust state visual:** Stopped/Off = original hourglass sprite with **very low alpha**; enabled and no active main-queue action = original `item_slot_background.png` with partial opacity; active main-queue action = same partially translucent item slot with modest green tint and halo. The number remains legible in the upper-left; status is *not* inferred from follower movement alone. No new PNG files.
- **Source design:** `ui/widgets/TrustStatusWidget.lua` owns the sprite, count text, target text and all compact dragging. `ui/widgets/PartyStatusWidget.lua` continues local-party counting but relays updates to Trust, and `ui/widgets/TargetWidget.lua` continues target/debuff tracking but relays name changes. Their **standalone compact views are hidden while hosted**. `ui/TrustWidgets.lua` wires the host on creation; previously stored positions for Party and Target remain available in Full mode but no longer affect the compact group.
- **Interaction change:** A mouse click without dragging must do **nothing**; clicking a title must not switch these three widgets between compact and full. The existing explicit commands `//trust widget full`, `compact`, `toggle` (and scoped variants) remain. Shared compact pointer capture and draggable target-name overflow still belong to Trust only.
- **Rendering:** Trust's compact slot is still 40×40 with 32×32 artwork inset by 4px. The party numeral is intentionally toward the **top-left**, not centered. Name anchors around y=25 in the same 40px box, roughly centered using existing 9px bold italic style, and may slightly overhang horizontally while remaining in Trust's click/drag region. No separate target border, no compact HP/HPP, no debuff icons in this newer compact representation.
- **Files changed vs. previous combined ZIP:** `ui/TrustWidgets.lua`, `ui/widgets/TrustStatusWidget.lua`, `ui/widgets/PartyStatusWidget.lua`, `ui/widgets/TargetWidget.lua`, `ui/widgets/CompactWidget.lua`, and `ui/widgets/Widget.lua` (small optional title-toggle guard; other widgets retain defaults). No database schema, art, combat, or path-recorder behavior changes.
- **Preserved behavior:** Three original Full widget views, player party count and Trust party-target tracking; earlier path `auto_reverse = true` default remains on this branch. Original detailed target debuff rendering is still available in Full mode.
- **Branch:** [`test/compact-trust-title-20261008`](https://github.com/rerorriM-Mirrorer/trust/tree/test/compact-trust-title-20261008). `main` stays last live-tested. This is a **new candidate**, not proof of live success.
- **Proposed drop-in overlay:** [`testing-packages/Trust-Shared-Compact-Slot-20261010.zip`](testing-packages/Trust-Shared-Compact-Slot-20261010.zip), layered over the prior `Trust-Combined-Patches-20261009.zip` installation. Contains the six updated code files, this TESTING.md and a short readme.

### Test instructions — all pending

1. Back up the installed Trust addon before replacing the **six** changed Lua files; install only on one character/client first. Keep existing assets and prior combined base files, and run `//lua r trust`.
2. Check Off, Idle and Active in actual gameplay: faint hourglass Off; semi-transparent slot Idle; green-tinted slot Active. Verify the number is small and top-left (including Off), and correctly reflects local party size after changes.
3. Acquire/clear a Trust party target: name appears **across the slot's bottom edge**, not below; no additional Target strip/window appears in compact mode. Test long names and fresh target changes; no duplicate name or residual HP text. The name should vanish on target clear.
4. Press and release on the slot **without moving**: no expansion or UI mode changes. Drag from the slot and then from any overhanging part of the visible name, release and reload: all three layers move together and position is saved once. Test near screen edges / low resolution.
5. `//trust widget full` restores all three independent detailed widgets and `//trust widget compact` restores one shared control. Test `//trust widget full target` separately and ensure no duplicated hosted name.
6. Test Trust menu clicks, other widgets, and combat actions. Compact drag routing must not intercept menu/command overlay clicks.
7. Existing **known unresolved issue**: saved positions may put widgets off-screen on some client resolutions; Widgets → Layout → Right was a user-confirmed workaround, **not a fix**.

| Test | Expected | Observed |
| --- | --- | --- |
| C2-01 | One shared 40×40 compact control; no extra Party/Target compact windows | **PENDING** |
| C2-02 | Off hourglass faint; Idle slot translucent; Active slot visibly green and still translucent | **PENDING** |
| C2-03 | Correct upper-left party count through party changes | **PENDING** |
| C2-04 | Single name centered along bottom only when party target exists; clear removes it | **PENDING** |
| C2-05 | Click alone never changes widget mode; drag saves unified position | **PENDING** |
| C2-06 | Full/compact commands restore detailed Full views and hosted compact | **PENDING** |
| C2-07 | Resolution, multi-client, menu and ghost-text regression checks | **PENDING** |

**Rollback:** Restore the six replaced files from the previous Combined-Patches ZIP or a local backup. Do not restore the entire addon settings database unless needed. Reload Trust and verify old layout. This patch is not merged to main.

---

## Previous testing batch — 2026-10-09: Combined Trust installation for Frank's PC (candidate)

**Heading correction (2026-10-10):** ~~Current testing batch — 2026-10-09: Combined Trust installation for Frank's PC (candidate)~~. The existing combined ZIP remains a pinned code snapshot for the earlier visual design; this test begins a newer, reversible compact overlay design. Preserve all earlier observations and bugs.

- **User requested a single drop-in ZIP** combining all source patches so far rather than applying individual historical overlays in order. **Source baseline:** `main` commit `575bf583ef41e0018f05b922c6673ab89b54af95`; current testing branch `test/compact-trust-title-20261008`; do not merge into `main` before live acceptance.
- **Archive:** [`testing-packages/Trust-Combined-Patches-20261009.zip`](testing-packages/Trust-Combined-Patches-20261009.zip). Complete incremental addon-source patch: exactly eight changed/new Lua files, root `TESTING.md`, and a short `INSTALL-COMBINED.txt` describing installation/rollback. **Not a complete Trust addon installation.** No old package ZIPs or duplicate paths inside.
- **Included changes:** `Trust.lua` (widget command enabled while menus open); `commands/GeneralCommands.lua` (full/compact/toggle all/one); `cylibs/paths/path_recorder.lua` (`auto_reverse=true` on *new recordings only*); `cylibs/ui/input/mouse.lua` (compact drag capture); `ui/widgets/CompactWidget.lua` (new, required); `ui/widgets/TrustStatusWidget.lua` (32px gold hourglass in 40px compact field, blue Idle, green Active, dimmed Off); `ui/widgets/PartyStatusWidget.lua` (32px item-slot with local party count); `ui/widgets/TargetWidget.lua` (264×24 white-outline single row, target name + existing seven debuff slots, no compact HP/distance).
- **Art:** Requires existing addon assets `assets/icons/icon_timer.png` and `assets/backgrounds/item_slot_background.png`, which already exist in this repo and were NOT modified by these patches.
- **Scope/compatibility:** This batch is intended for a compatible copy of the same Trust fork. Installing it over an unknown/different fork or outdated Trust version can cause missing module/API errors. Check addon baseline, back up the ENTIRE existing Trust folder, and do a one-client smoke test first.
- **Archive validation (2026-10-09):** Generated a 10-entry ZIP (eight Lua files, this TESTING.md and INSTALL-COMBINED.txt), inspected the uploaded archive, verified every member's CRC32, central directory/end record, and that the eight Lua paths match **all** Lua changes relative to main. This is an archive integrity check, **not a live FFXI test**.
- **Live status:** User confirmed smaller appearance, excellent right-aligned icon layout after manually selecting Menu Layout Right, and attractive blue/green hourglass fields. Original load placed icons completely off-screen, compact dragging was difficult, and original Target compact showed duplicate name and HP/HPP: these were **real failures**, not erased by later unverified candidate fixes. Later mouse-capture and Target row changes, and the new reverse default, still await in-game verification.
- **Docs rule:** Earlier C0/C1 test results and pending items remain in this file. The combined archive references the current cumulative testing record; it is not evidence that any pending behavior now works.

### Installing combined batch — Frank's PC

1. Confirm the target folder contains a compatible Trust install with `Trust.lua`, `commands/`, `cylibs/`, `ui/`, `assets/`. Back it up as a whole before overwriting files. Do not delete/replace settings, character profiles or existing saved paths.
2. Extract the ZIP **into the addon root**, not a nested `Trust-Combined-Patches` folder. Allow overwriting eight existing/new Lua source paths; preserve all unlisted addon files.
3. Run `//lua r trust`. If the addon will not load, restore the backup and collect the error message. If it loads, select Widgets → Layout → Right if icons appear out of view; this was a previously reported workaround, not a verified permanent fix.
4. Verify `//trust widget full`, `//trust widget compact`, and `//trust widget full target`. Check click/drag and save/reload of each widget; check target name is singular, no compact HP text, and debuff icons appear to the right. Test the Off/Idle/Active status change and changing party count.
5. Save a **new** harmless path and inspect its serialized `auto_reverse = true` before experimenting with replay. Confirm an older saved path retains its existing setting. Try only in a safe area.
6. Record resolution, character and observations. Do not proceed to all clients or merge `main` until smoke tests pass.

### Combined-batch validation status

| Test | Expected | Status |
| --- | --- | --- |
| CB-01 | Package contains eight source Lua files in correct paths plus TESTING.md and installation notes; no unrelated files | **PACKAGE VERIFIED:** 10 entries; 8 Lua files matched branch diff, all file CRC32 values passed, ZIP headers/directory verified. Live install still pending. |
| CB-02 | Loads/reloads without Lua runtime errors on Frank's PC | **PENDING** |
| CB-03 | Icons align, click, drag and persist after reload | **PENDING**; prior placement/drag issues observed |
| CB-04 | Compact Target outlined single row with one name and debuffs, no HP/HPP | **PENDING**; prior duplicate/HP issue observed |
| CB-05 | Old Full widget functionality remains available | **PENDING** |
| CB-06 | New recordings default reverse, old path files unaffected | **PENDING** |
| CB-07 | Multi-client and low/high resolution regression | **PENDING** |

---

## Previous testing batch — 2026-10-08: C1 Target compact outlined row fix (candidate)

**Heading correction (2026-10-09):** ~~Current testing batch — 2026-10-08: C1 Target compact outlined row fix (candidate)~~. Superseded by combined-installation testing batch below; target-only test status remains pending and its details are preserved.

### New path-recorder default — 2026-10-09 (SOURCE COMMITTED, LIVE TEST PENDING)

- **User request:** Make newly recorded paths save `auto_reverse = true` by default; user also tried editing a local copy but requested that we commit the fix upstream in their fork.
- **Code commit:** [`e28d6a37`](https://github.com/rerorriM-Mirrorer/trust/commit/e28d6a37cc47152565c7f302b2d5e143f68d48a3) on `test/compact-trust-title-20261008`. Only `cylibs/paths/path_recorder.lua` modified for this behavior: `Path.new(zone, actions, true, 0)` instead of `false`, plus explanatory comments.
- **Scope:** This changes the default only for future files saved by PathRecorder; it does **not** rewrite previously saved paths or change `Path.from_file`, `Path.new`, the replay menus, or `reverse_delay` (still zero).
- **Path-related follow-up discussed earlier, not part of this patch:** Source-observed stuck-path behavior, bounded recovery diagnostics, possible safe detours. Do not conflate with `auto_reverse`, which only reverses a completed path.
- **Test PATH-01:** Back up existing paths, record and save a short new path, read its generated `.lua` to check `auto_reverse = true`; play it somewhere safe to confirm it retraces at the end. **PENDING.**
- **Test PATH-02:** Load a previously saved path with `auto_reverse = false` and confirm it stays false. **PENDING.**
- **Test PATH-03:** Compare the manual replay once/repeat behaviors against the previous addon version; defaults must not force an unrelated replay command. **PENDING.**
- **Rollback:** Restore just `cylibs/paths/path_recorder.lua` from your prepatch backup. The `main` branch is untouched.



- **Branch:** [`test/compact-trust-title-20261008`](https://github.com/rerorriM-Mirrorer/trust/tree/test/compact-trust-title-20261008). Unmerged; `main` remains the last live-tested baseline.
- **USER LIVE FAILURE:** Compact Target name appears doubled, and unwanted HP/HPP and distance text from the original widget remains visible. The transparent, vertically stacked Target name/debuff design does not meet the requested presentation.
- **USER REQUEST:** A single **white-outlined rectangular field** with no filled background: exactly one Target name and its debuff icons **to the right on the same row**. Keep the field draggable, preserve Full mode and prior Trust/Party icon successes.
- **SOURCE DIAGNOSIS:** Original FFXI rows use independent Windower `texts` renderers. The generic compact view hides the content parent *after* reflow, leaving some separately rendered full-view text in place. Target had a second compact name cell, causing apparent duplication. This diagnosis matches the reported symptoms; the proposed fix is not yet verified live.
- **C1 Target-only patch:** `ui/widgets/TargetWidget.lua` changes the compact hitbox to **264×24**; draws a transparent four-line **1px white outline**; places a 120px-wide name beginning at (8,3) and the existing seven debuff slots starting at (140,5), arranged horizontally. The compact name is truncated to 15 characters if needed; Full mode retains original text and HP/distance info. Explicitly suppresses all four old Full rows (including external text renderers) during compact redraws and restores those rows on Full.
- **Scope:** One modified Lua file, **no changed assets, no changes to Trust's blue/green hourglass, Party number, mouse dispatcher, combat, or underlying target/debuff tracking.** The 7-icon limitation remains for now.
- **Static review:** Source assertions for row geometry, four white border edges, Full-mode retention, hidden old cells and drag offset restoration passed; a structural delimiter check passed. **Not a Lua 5.1 parse or in-game render test.**
- **User-facing overlay:** [`testing-packages/Trust-C1-Target-Row-Fix.zip`](testing-packages/Trust-C1-Target-Row-Fix.zip), containing `ui/widgets/TargetWidget.lua` and a copy of this `TESTING.md`. This ZIP is an **incremental overlay** on the previous C1 installation, not a fresh-install replacement.

### Installation and rollback

1. Back up your current `ui/widgets/TargetWidget.lua`. Leave the five other compact-related Lua files and the C1 mouse drag fix installed.
2. Extract `Trust-C1-Target-Row-Fix.zip` directly into the Trust addon root, preserving `ui/widgets/`; replace the existing Target widget file.
3. Run `//lua r trust`. If there is a Lua error or display regression, restore your original `ui/widgets/TargetWidget.lua`, then reload Trust.
4. For Full/Compact comparison use `//trust widget full target` and `//trust widget compact target`. No changes are intended for `//trust widget full party` or `full trust`.

### Target-specific live checks — ALL PENDING

| Test | Action | Expected | Actual |
| --- | --- | --- | --- |
| C1-TARGET-01 | Acquire a Trust party target with no tracked debuffs. | Exactly one visible name within 1px white outlined 264×24 rectangle; no HP/HPP, distance, action text, title, filled background or duplicate name. | **PENDING** |
| C1-TARGET-02 | Inflict and remove 1–7 tracked debuffs. | Debuffs appear **on same row to the right** of name; no wraps or stale icons. | **PENDING** |
| C1-TARGET-03 | Change/clear Trust's party target and target again. | Correct name; old icons and text fully vanish on switch/clear, no ghost text. | **PENDING** |
| C1-TARGET-04 | Click-drag the outlined field across the screen, including past its original bounds. | Outline, one name and debuffs move together without changing compact mode; release saves position. | **PENDING** |
| C1-TARGET-05 | Switch to Full Target then back to Compact Target. | The old full view retains HP/HPP, distance, action, information and debuffs; Compact hides them again. | **PENDING** |
| C1-TARGET-06 | Observe while skills/target info update rapidly; reload and change resolution. | No original row reappears, no duplicate or clip; saved position remains visible if in bounds. | **PENDING** |
| C1-TARGET-07 | Look at Trust and Party icons before and after patch. | Blue/green hourglass and party slot unchanged. | **PENDING** |

**Outstanding:** User-confirmed prior failures must remain recorded as failures of the **previous** C1 build until C1-TARGET tests pass. Drag reliability and initial off-screen placement are separate unresolved C1 issues.

---

## Previous testing batch — 2026-10-08: C1 three-widget compact layout (candidate)

**Heading correction (2026-10-08):** ~~Current testing batch — 2026-10-08: C1 three-widget compact layout (candidate)~~. The underlying artwork and two other widgets remain in the last C1 installation; Target compact presentation is under a focused replacement test below. All original observations, delivery notes, and pending tests remain retained.

- **Branch:** [`test/compact-trust-title-20261008`](https://github.com/rerorriM-Mirrorer/trust/tree/test/compact-trust-title-20261008); **unmerged**, keep `main` as last live-tested.
- **User-supplied assets (2026-10-08):** exact 32×32 gold hourglass `icon_timer.png` and gray `item_slot_background.png`, byte-for-byte confirmed as the existing repo assets by their Git blob hashes (`50a7568c…` and `9313124d…`). The same assets already exist; no icon image files need copying or replacing. Earlier assistant illustrative search result was **not** the real timer sprite.
- **Change C1a:** Trust status in compact view is a 40×40 timer sprite with translucent blue square halo for **Idle**, green for **Active**, and a dimmed hourglass without a halo for **Off**. It is a visual placeholder, not a claim that Trust exposes an exhaustive three-state API. **Off wins over stale action queue events; Active represents a running main-queue action (not follower locomotion alone).**
- **Change C1b:** Party in compact view is a 32×32 existing item-slot background with a numeral for actual members in local FFXI party `p0`–`p5` (including player and summoned alter egos). It is **not** the number of simultaneous Trust-addon multibox clients or everyone in the alliance.
- **Change C1c:** Target in compact view is a **transparent draggable 148×38 hitbox** showing Trust's party-target name and its existing tracked debuff icons. No HP/distance/action text, window background, title, or border. Existing seven-icon cap stays unchanged in this batch; >7 remains a later proposal.
- **Shared interaction:** Each compact view can be clicked to return **only that widget** to Full; drag >3px and release should save position with existing WidgetManager. `//trust widget full|compact|toggle [all|trust|party|target]` manages all three (defaults to all). An all-widget toggle aligns states according to Trust's current mode. The command is permitted while Trust's menu is open, with other menu restrictions unchanged.
- **Drop-in test package (2026-10-08):** [`testing-packages/Trust-CompactWidgets-C1-drop-in.zip`](testing-packages/Trust-CompactWidgets-C1-drop-in.zip), generated from the branch's six Lua source files at code snapshot `13c66c3b9c1a8b8f7a0d549c8440c3ddf8651e50`. The archive has **no enclosing folder**, so extract directly into the existing Trust addon root. ZIP contains only required six Lua files; the new `ui/widgets/CompactWidget.lua` is mandatory. The source tree's root `TESTING.md` remains the test reference, omitted from the minimal user-requested code-only ZIP by exception. Exact ZIP contents validated after upload: six entries; no extra paths. **No runtime test implied.**
- **Changed source from `main`:** `Trust.lua`, `commands/GeneralCommands.lua`, `ui/widgets/CompactWidget.lua` (new), `ui/widgets/TrustStatusWidget.lua`, `ui/widgets/PartyStatusWidget.lua`, `ui/widgets/TargetWidget.lua`. `TESTING.md` records test instructions. No EnemyBar2 or automation behavior changes.
- **Source-check status:** Read source and reviewed target/party update events, icon state priority, drag route and overlay offsets. **Not yet demonstrated in Windower; no live C1 result and no FFXI smoke test.** Do not mark implementation as working until tested.

### Installation / rollback

1. Confirm your installed Trust matches this fork's baseline. Back up **all five existing Lua files**: `Trust.lua`, `commands/GeneralCommands.lua`, `ui/widgets/TrustStatusWidget.lua`, `ui/widgets/PartyStatusWidget.lua`, `ui/widgets/TargetWidget.lua`.
2. Obtain the current testing branch's versions of these files **and new** `ui/widgets/CompactWidget.lua`. Use the six Lua files together; the shared new module is required. The two original PNG assets are already in the source tree.
3. Reload with `//lua r trust`. To restore original-sized widget presentations without reverting files: `//trust widget full`. If addon load or input fails, restore the backed-up files, remove only the newly added `CompactWidget.lua`, then reload. Keep a screenshot/log of any error.
4. On live success, test again on multiple clients; do not install on all six simultaneously before single-client smoke passes.

### C1 mouse drag recovery — 2026-10-08 (UNTESTED PATCH)

- **USER LIVE OBSERVATION:** "Having trouble dragging icons." This follows the separate live reports that the three compact designs look excellent, the hourglass's blue and green fields look good, and the **Layout Right** preset restores initially off-screen icons. The exact drag failure mode (no movement, jump, drop/collapse, etc.) has not yet been specified. Do not claim pointer fix success without user verification.
- **SOURCE DIAGNOSIS / HYPOTHESIS:** `cylibs/ui/input/mouse.lua` routes input recursively through other views each event. This can interfere with tiny compact hitboxes and pointer continuation; source review suggests a targeted pointer capture, but does not establish that this is the only cause.
- **C1-DRAG-01 candidate:** On left click of a visible compact Trust/Party/Target widget, capture that widget as the drag receiver; route mouse movement and release directly to it, including when the cursor leaves its icon. Do not intercept non-compact widget events or clicks while a menu/command overlay is open. Release the capture when the left button is released.
- **New file to replace:** `cylibs/ui/input/mouse.lua` ONLY. The previous six-file C1 package remains the baseline. Make a backup before replacing. **No changes to artwork, compact sizes, position data schema, automation, or main.**
- **C1-drag delivery:** [`testing-packages/Trust-C1-Drag-Fix.zip`](testing-packages/Trust-C1-Drag-Fix.zip) is a *follow-up overlay* for users already running the six-file C1 build. Extract into the Trust addon root; it contains just the updated `cylibs/ui/input/mouse.lua` plus this root `TESTING.md`. Do not substitute it for the original six-file package.
- **Preliminary check:** Source reviewed for captured pointer lifecycle, compact-only hit test and menu bypass; **full Windower game test PENDING**.

| ID | Test steps | Expected | Actual |
| --- | --- | --- | --- |
| C1-DRAG-01 | Close Trust's menu, press and hold the blue hourglass, move 50px, release. | Smooth drag; hourglass remains compact; "Widget settings saved." appears once on release. | **PENDING** |
| C1-DRAG-02 | Repeat on the Party count slot. | Slot and numeral move together without expanding. | **PENDING** |
| C1-DRAG-03 | Repeat on visible Target name/debuff strip, dragging beyond its 148px invisible bounds. | Name and debuff row move together, even after pointer leaves strip. | **PENDING** |
| C1-DRAG-04 | Short-click each widget without movement, then `//trust widget compact`. | Click expands; command returns to compact; no drag on short click. | **PENDING** |
| C1-DRAG-05 | Reload Trust after placing the icons and retest on small resolution. | Saved positions restore visibly; no unexpected jumps or off-screen regressions. | **PENDING** |
| C1-DRAG-06 | Open Trust menu or command picker and interact normally. | Menu/command interactions are not stolen by compact icons. | **PENDING** |

**Rollback:** Restore original `cylibs/ui/input/mouse.lua` from the last good addon backup or from the previous C1 ZIP snapshot, then `//lua r trust`. The original full/compact commands and appearance remain available.

---

### Live FFXI test record (C1 — PARTIAL USER OBSERVATIONS)

**Status correction (2026-10-08):** ~~C1 — ALL PENDING~~. The user has now tested the drop-in in FFXI and reported a positive compact layout appearance after repositioning. Click/drag, Off/Idle/Active transitions, party-count accuracy, target-debuff accuracy, menu commands, persistence, multiple clients and resolutions have **not yet been explicitly confirmed**.

**User-confirmed color check (2026-10-08):** Both the blue and green hourglass fields look good in actual gameplay. This verifies their appearance, but not every state transition or Off behavior.

**User live observation — 2026-10-08, C1 package:** "LOOKS AMAZING SO FAR." On opening the addon, the widgets/icons initially appeared shifted completely off-screen; using Trust's in-game menu to select **Menu Layout Right** brought the compact icons back into sight, neatly aligned along the right. This is a **successful visual workaround** but an unresolved initial-placement/repositioning defect. The resolution, number of clients, precise prior coordinates, and cause are not yet known. Do not attribute it to an old saved position or the compact renderer without evidence.

**Additional live observation — 2026-10-08 (C1):** User reports that the blue and green fields on the timer/hourglass look good in FFXI. **Visual appearance PASS (user-observed)** for the two colors. Automatic state transitions, correct queue mapping and Off-state appearance still need separate tests.

**Follow-up diagnostic:** If convenient, note whether the icons remain visible and aligned after `//lua r trust` or changing resolution. Check saved widget X/Y, screen bounds, and layout presets only after capturing reproduction details; ensure menu placement does not mask an off-screen hitbox.



| Test ID | Procedure | Expected result | Actual |
| --- | --- | --- | --- |
| C1-01 | Load on one low-resolution client. | 40×40 hourglass, 32×32 party item slot, transparent Target strip only when a Trust party target exists. | ~~PENDING~~ **PARTIAL USER OBSERVATION:** Compact icons look excellent and align at right after selecting *Menu Layout Right*, but startup positions were completely off-screen. Exact sizes, resolution and target behavior not verified. |
| C1-02 | `//trust stop`, `//trust start`, run an actual queued action, then let action end. | Off dimmed/unlit, Idle blue, Active green, back to Idle. Following alone may remain Idle. | **PARTIAL USER OBSERVATION:** Blue and green fields look good. Automatic Idle/Active transitions, Off rendering and mapping remain **PENDING**. |
| C1-03 | Solo and then party with 2–6 members; add/remove an alter ego or player. | Numeric local party count updates, including player. | **PENDING** |
| C1-04 | Set a Trust party target with no debuffs, then with one/multiple, then change/clear it. | Correct name and only tracked debuff icons; no stale icon/name or invisible retained hitbox. | **PENDING** |
| C1-05 | Short-click each compact widget separately. | Only clicked widget expands; `//trust widget compact` restores all three. | **PENDING** |
| C1-06 | Drag each icon/strip at least 20px, release, and reload. | Moves without expanding; internal sprite/text/icon spacing preserved; position saves. | **PENDING** |
| C1-07 | `//trust widget full`, `compact`, `toggle`; try `full target` and `compact party`. | All/full and individual commands work, and original Full controls still work. | **PENDING** |
| C1-08 | Change targets, action queue state, party composition while compact. | Compact overlays remain visible, no old body/borders popping into view, no gameplay stalls. | **PENDING** |
| C1-09 | Repeat on larger resolution and 2+ clients. | No misaligned pointer targets, repeated drawings or overlap; other addons unaffected. | **PENDING** |

### New placement issue identified (2026-10-08)

- **C1-POS-01 — USER OBSERVATION:** Immediately after addon load, compact widget positions were outside the viewable area. Preset **Menu Layout Right** repositioned them into a good-looking right-side arrangement. Treat placement as a remaining bug despite visual success.
- **Next test:** Reload using the right-side preset and check whether the widgets remain visible. If they leave the screen again, capture resolution, widget positions and whether previously saved positions predate the compact dimensions. Do not overwrite existing position settings automatically before establishing causation.
- **Design option (not implemented):** On compact-size transitions and first placement, clamp positions to reachable screen bounds or offer a one-command reset/center/preset recovery. Preserve intentional offscreen placement only if user preference explicitly calls for it.

### Known caveats to verify, not silent assumptions

- Glow is intentionally two translucent **square** halo layers behind Trust's original gold hourglass, not an externally generated smooth blur. Adjust softness after screenshots.
- Target name/debuff strip is transparent; the **rectangle is the invisible 148×38 mouse hitbox**. It only appears when Trust has a target.
- The target still tracks at most seven debuff IDs, and its source is the party target, **not necessarily the client's selected target**.
- Full mode remains accessible but is **not yet saved across reload**. All three start compact after reload. The compact mode does not repair inaccurate full-view job/level values.
- The status may remain Idle while a follower is moving, because follower movement uses a separate queue.
- All 32×32 assets are existing repo copies; there are **no new PNG dependencies or sprite-file installation requirements**.

---

## Previous testing batch — 2026-10-08: C0 iteration 2, compact click/drag recovery

**Heading correction (2026-10-08):** ~~Current testing batch — 2026-10-08: C0 iteration 2, compact click/drag recovery~~. Superseded as current by the three-widget visual experiment below; C0 user failures, repairs, and instructions are retained as historical reference.

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

**2026-10-10 C2 design test:** User requested one shared draggable 40×40 compact slot that morphs from faint hourglass when Off to translucent item slot when On, green tinted on Active. Party numeral upper left; name over lower edge only with a Trust target; clicking no longer expands. Six-code-file testing candidate, **no live test yet**. Earlier C1 visual success and failures retained.

**2026-10-09 combined install batch:** User requested one consolidated source overlay for Frank's PC. Eight Lua files from testing branch; root TESTING.md + install notes. Baseline code preserved; **live verification not yet performed**.

**2026-10-09 recorder default:** One-line behavior change in `cylibs/paths/path_recorder.lua` (plus intent comments), commit `e28d6a37`; new recordings should default to `auto_reverse = true`. **Live test pending; existing paths unchanged.**

**C1 Target row follow-up (2026-10-08):** User reported doubled target name, HP/HPP leakage in compact mode, and requested a 1px white outlined single row with debuffs after the name. Target-only code patch and cumulative test record prepared. **All new C1-TARGET live checks pending.**

**C1 mouse drag follow-up (2026-10-08):** User reported difficulty dragging compact icons; captured-pointer change committed on testing branch in `cylibs/ui/input/mouse.lua`. Previous C1 appearance feedback remains valid. **In-game verification pending.**

**C1 addition (2026-10-08):** Candidate three-widget compact visual branch; six Lua sources including one new shared helper, no modified art assets, **live outcome pending**. Previous delivery rows remain below.

**C1 package delivery (2026-10-08):** `testing-packages/Trust-CompactWidgets-C1-drop-in.zip`; six code files, verified ZIP structure and byte sizes; installation and live validation **PENDING**. Minimal-package exception: the `TESTING.md` record is maintained in the test-branch root and linked separately instead of inserted into this code-only archive.

| Date | Batch / artifact | Type | Reference | Outcome |
| --- | --- | --- | --- | --- |
| 2026-10-08 | Initial Trust `TESTING.md` | Documentation only | This file; commit available in Git history | Created from user feedback and source inspection; **no behavioral tests or installation package** |
| 2026-10-08 | Trust title-only compact placeholder | Source change on untested branch | [`f7c82c81`](https://github.com/rerorriM-Mirrorer/trust/commit/f7c82c81b556bc07b38bc01cdfc677340c5c9646) | Only `TrustStatusWidget.lua`; **live results pending**, no packaged release |
| 2026-10-08 | C0 iteration 1 user result | Live observation | This conversation | **Footprint improved; expand click FAILED; compact drag FAILED**; original code preserved in Git history |
| 2026-10-08 | C0 iteration 2 interaction and command candidate | Source changes on testing branch | `831b1fc3`, `122564e9`, `3da6873c` (commits linked above) | Mouse and commands updated; **live test pending** |
| — | Subsequent Trust patch | Not yet prepared | — | No claims of implementation |
| — | EnemyBar2 debuff prototype | Not yet prepared | Separate repository | Not started |

## User-provided materials and prior findings

**C1 user input (2026-10-08):** User supplied exact 32×32 `icon_timer.png` and `item_slot_background.png` images and requested hourglass blue/green status glow, item-slot party numeral, and transparent draggable target name/debuff strip. Source asset matches were found; no image-file changes needed.

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
