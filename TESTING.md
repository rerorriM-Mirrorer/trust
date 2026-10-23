# Current Development Status — October 23, 2026 (starter defaults Test 1)

- Repository rerorriM-Mirrorer/trust, branch test/starter-defaults-20261023. Starting published source 1662a07479ba2ec52007c930a2dec37724223dcc (controller delivery record); unchanged controller implementation retained. Native runtime remains 17.7.3; defaults command reports Starter defaults Test 1.
- User live feedback: controller navigation works on Cioara and Franklet after files were transferred; no visible xivcrossbar menu interference reported. Saving on exit worked in the user's test. This supersedes the earlier pending status for those tested cases without claiming every editor/client combination accepted. Earlier records follow unchanged.
- Requested pass: all 22 factory job mode sets now engage Always, heal Emergency, buff Auto, skillchains/Trust summoning/shooting Off; SMN avatar Carbuncle. Engagement/healing/buff built-in fallbacks match. All 24 job PullSettings templates have empty target names; the legacy addon battle-target factory list is empty. Positioning, following, pulling modes, distances and job pull actions are preserved.
- Existing saved profiles are not silently overwritten. New //trust defaults [status] reports the baseline; //trust defaults apply validates and sets requested modes, explicitly saving only those keys into the selected job/mode profile even with autosave Off. Unrelated profile keys and existing pull lists remain. Locked/invalid mode contexts reject before mutation; menu policy commits eligible drafts first.
- Verification: eight Trust menu scripts pass under Lua 5.4 with mocked APIs (existing 267 counted assertions, explicit-open/controller tests and the new starter suite). All 22 factory mode sets checked against the starter policy; all 24 factory pull target lists empty; all 55 changed/new Lua files parse with temporary Windower-syntax normalization. Git whitespace check passes. Native Windows/Windower/FFXI acceptance pending for this defaults pass. No new xivcrossbar/AHK changes or tests claimed.
- Emergency healing audit: same rule HP thresholds as Auto, ordinary cooldown four seconds vs 0.5; HP dirty-event checks may bypass delay. Corrected its misleading description, not the behavior. Songs/buff controller unification, pull list clear/load/add/remove, 30-yalm/shared hunting settings, Approach fallbacks and shared preference/job architecture remain deferred.
- Delivery: cumulative full Trust runtime, no personal data or xivcrossbar payload. Back up/merge/reload; run defaults apply only on existing profiles desired for adoption. See docs/STARTER-DEFAULTS-TEST1.md. Next: verify one-job adoption and reload, then the next small hunting/config change.

---

# Current Development Status — October 22, 2026 (controller menu Test 1)

- Repository rerorriM-Mirrorer/trust, branch test/controller-menu-20261022. Starting baseline d63baae74543d653868e0881c28682c02c5068ec; published runtime source bbe08c310016cd2ca40e44de6d64045160220cb3. Paired xivcrossbar source d85bb136259acb2678bb645b02b72f85ab88dd4a, runtime directlink1-trustmenu1, shared Controls 9.15-trustmenu1. Main and prior development branches remain unchanged.
- Request: direct controller navigation using xivcrossbar's existing AHK button receiver and menu input suppression. Added a focused Trust adapter, ephemeral server/character-specific menu lease, internal direct-action entry point and menu-status counters. Existing menu controls, draft validation and autosave policy perform the actions. No native navigation keys are generated for this direct route.
- Guards: focus/session changes, sequence/age validation, text/chat/background contexts, original-control release delivery and validated Close All. Ordinary physical keyboard input remains on its existing path. Matching xivcrossbar and AHK files are required for the direct route.
- Verification: all seven Trust menu scripts pass under Lua 5.4 with mocked UI/I/O (267 existing counted assertions plus explicit-open and new controller adapter checks). Changed Trust Lua files parse after temporary Windower quoted-string normalization. Paired xivcrossbar: 63 top-level Lua regression scripts, 146 parsed Lua sources, seven JavaScript AHK-routing suites, AHK structural/layout checks and whitespace review passed. Actual root lease reader/physical callback/context publication exercised with mocks; native Windows/AHK/Windower/FFXI unavailable.
- Live acceptance pending: single taps/repeat, no native target/menu movement, nested focus/sliders/text, R1+Square close across held R1 and validation, chat/client handoff, reload/wrapper restart and ordinary controls after closing. See docs/CONTROLLER-MENU-TEST1.md. No new live success inferred. Earlier adjacent placement has positive user feedback; the earlier Modes save-on-exit failure remains unresolved.
- Delivery: paired ZIP includes full cumulative Trust runtime and cumulative xivcrossbar code-only files for an existing DirectLink Cleanup 1 or newer install, with docs inside each addon folder and no personal data/artwork replacement in xivcrossbar. Back up, unload both addons on all clients, stop shared AHK, merge, then test one client after starting Controls 9.15 once.
- Deferred user command/menu requests recorded in docs/PENDING-USER-NOTES-20261022.md. No pull defaults, distance commands, job-role changes, menu reordering, shooter repair or empty-skillchain fix included. Next: live accept controller navigation before expanding the patch.

---

# Party song gambits Test 1 publication and package verification — 2026-10-19

Published/fetched source: `1e42f3589b8805185a1966a3c8f5748a70e83e0f`.
Full package: Trust-PartySongGambits-Test1-Full.zip, 1,475 members. CRC, every
member byte, SHA manifest and user-data exclusion checks passed. See
[the delivery record](docs/PARTY-SONG-GAMBITS-TEST1-DELIVERY.md).
One runtime file changes; native Windower/FFXI checks remain pending.
This note is later than the package pin. Historical records follow.

---

# Current Development Status — 2026-10-19 (party song gambits test 1)

- **Repository / branch:** `rerorriM-Mirrorer/trust` /
  `test/menu-exit-save-20261017`; starting source
  `a1df85b8fd080dbd86d718047da15dc3b8f655fb`.
- **Request:** Myrr can select Foe Requiem as a custom gambit, but beneficial party
  songs are absent. Make those songs available for user-authored gambits.
- **Cause:** inherited GambitEditorStyle.getAbilitiesForTargets explicitly returns
  false for every BardSong whose resource targets contain Self. The same exclusion
  is present in the pinned Trust 17.7.3 source. Enemy Requiem bypasses that exclusion.
- **Change:** remove that exception. Existing job spell/level and target matching
  then list beneficial Self songs alongside ordinary spells. No target-mask expansion,
  changes to cast/condition logic or automatic song-set selection are introduced.
- **User materials:** supplied data-trust.zip inspected in place. BRD profile has
  the reported Requiem gambit; active SongSet is NewSet with Honor March, Blade
  Madrigal and Minuets III/IV/V, NumSongs 4, AutoSongMode Auto and AutoGambitMode Auto.
  The archive does not establish learned spells, current levels or equipment.
  Character data remains user-owned and is not included in the public source/package.
- **Setup:** use Gambits > Add > Self; add an inverted Self HasSongs condition for
  the selected learned song. Put it ahead of unconditional enemy actions. For a
  custom-gambit trial, disable AutoSongMode to avoid competing song lists and use
  a pair that fits current capacity. Detailed steps: docs/PARTY-SONG-GAMBITS.md.
- **Verification:** source review confirms existing spell-list and target filters
  are retained, along with the Trust-summon exclusion and Geomancy handling.
  PASS: the changed runtime file compiles via the available Lua 5.3 runner;
  Git whitespace/diff review passes. No Lua 5.1/Windows/Windower run is claimed.
  Package verification is recorded at delivery.
  Previous 291-check suite results remain historical; no new live result is claimed.
- **Live FFXI status:** PENDING song visibility, actual casts, party-area effects,
  condition/recast behavior, order and expiry. Exact song tracking after reload or
  zoning may need checking for custom songs outside the dedicated song set.
  The earlier Modes save-on-exit failure remains unresolved; adjacent menu placement
  has the user's positive report. User also reports progression with ranged attacks,
  Requiem and Carbuncle; no broader live acceptance is inferred.
- **Next:** install on one Bard client and check the new song choices, then a
  guarded song pair. Main remains the live-accepted branch.

Earlier status and testing entries follow unchanged.

---

# Current Development Status — 2026-10-18 (attribution normalization)

- **Repository / branch:** `rerorriM-Mirrorer/trust` / `test/menu-exit-save-20261017`; starting source `e784e6eccea9b0bf3c53dbca8c392712400d7945`.
- **Change:** Normalize collaborative author references to the agreed name **A** in comments, source headers, delivery notes, and the cumulative testing record. Original upstream contributors and all testing observations remain intact.
- **Verification:** All 18 prior references removed; exact-word search, strict substitution-only diff review, and Git whitespace check passed. No runtime logic, defaults, data files, or packaged test artifacts are changed.
- **Live FFXI status:** No new in-game testing; Test 5 acceptance remains pending as documented below.
- **Next:** Retain the existing Test 5 live checks; verify the published branch head after the attribution-only commit.

---

# Test 5 publication and full-package verification — 2026-10-18

Published/fetched source: `b98b8a20905e09d74854f9294daef4d087a49ab7`.
The full ZIP passed CRC, SHA manifest and all 1,474 member-byte comparisons
against that snapshot/generated metadata. See [the delivery record](docs/MENU-OPTIONS-TEST5-DELIVERY.md).
The concurrent explicit Open addition is included. All new live acceptance is
pending. This publication note is later than the package pin.

---

# Menu options Test 5 — October 18, 2026

Author: A. Repository: rerorriM-Mirrorer/trust.
Branch: `test/menu-exit-save-20261017`, based on Test 4 delivery
`31245d39fce64847db755e7c900d6bf111624c07`. Main is unchanged.
Also incorporates controller Open addendum `17d0f9cc1e8dd400c70ae8411e4ff805d9868129`
published concurrently; its original records are preserved below. Test 5 includes
both Open and Close Trust handlers, not the separately delivered controller files.
Package: `Trust-MenuOptions-Test5-Full.zip`, full cumulative Trust 17.7.3 folder.
BUILD.txt pins its exact published source. Preserve existing data; no personal
settings/logs or controller files are shipped.

## Implemented request

1. With Config > Menu > Save options on exit On, successful slash-command changes
   to loaded main/sub/weapon/addon settings persist. Ordinary mode deltas merge
   into the selected named mode set, not a snapshot of unrelated temporary modes.
   This path does not reload/reset TrustMode. In-memory inheritance follows the
   resulting file semantics. Existing explicit writes are recorded and not repeated
   unless there is a later mutation. The first handled return remains compatible;
   root dispatch now also receives the actual success return from command handlers.
2. No-op/failed commands do not trigger new writes. Existing explicit save behavior
   is retained when autosave is Off. Follow distance updates its existing addon
   option only when On (valid range 0-50; missing/invalid input is rejected).
   Targets and role-local paused-follow state remain transient. Profile/scenario,
   lifecycle/UI and remote relay commands retain their own behavior. Each receiving
   client handles persistence. Selector/root replacement prevents stale implicit saves.
3. Clean Modes and ordinary scalar option editors refresh after permitted tactical
   commands. Refresh does not write, preserves cached ordinary controls and cursor/
   scroll, and works with autosave Off. Dirty drafts remain untouched; normal
   conflict checks still apply. Grouped/structural editors and replaced roots are
   intentionally not rebuilt; reopen them. Heal alliance and buff/debuff auto/off
   are additional reviewed menu-safe verbs; structural verbs remain guarded.
4. With autosave On, newly entered eligible options panes focus the settings list,
   not its field. Off retains original entry focus. Chat, command browsers, profile
   forms and structural editors are excluded. Returning to existing parent menu
   levels does not deliberately steal focus back into their options.

Command-save successes use a short chat notice; quiet follow/assist do not gain
success chatter. Failures identify the affected owner and distinguish applied
runtime values from persistence. Writes are per owner, not atomic across files:
partial success is possible. No blind retry or action rollback is added. Trace has
command completion/failure events; writer returns are not disk readback verification.
Ordinary command handlers are not wrapped in pcall, preserving their yield behavior.

## Verification

PASS: **291 simulated assertions**: 103 menu/input/layout/save, 17 Modes flow,
43 trace/command policy, 71 mode aliases, 33 new command persistence and 24 quiet
movement. New tests use the actual root dispatcher, command base, TrustSettings,
TrustAddonSettings and TrustModeSettings writers with game/filesystem mocked.
They cover successful/invalid/no-op/failed commands, named-set deltas, duplicate
writes, mutation after explicit save, notification-only save, Off behavior,
root/selector replacement, save-failure feedback, quiet saves, Default inheritance,
write failure retaining stored model, follow distance, clean/dirty scalar refresh,
focus exclusions and scroll retention.
PASS: the incoming menu_open_test.lua also runs on Lua 5.3 against the combined
command base/MenuCommands/HUD paths, covering idempotent Open and guarded Close.
Its assertions are additional to the 291 counted checks above.

PASS: 16 changed/new Lua files compile with Lua 5.3 and Windower literal-method
normalization; diff/whitespace review passed. Final package-byte checks are recorded
at delivery. These checks do not establish Lua 5.1/Windows/Windower compatibility.
All new in-game acceptance is PENDING. The original Modes save-on-exit revert and
real controller IJKL capture remain unresolved; adjacent placement has positive
user feedback from Test 4. No AHK/R1+Square patch is installed by this package.

## Live checklist (one client first)

1. Back up/unload Trust, merge this full folder without replacing personal data,
   reload and check `//trust menu status` identifies Test 5.
2. With autosave On, open Modes and ordinary Combat/Follow/Config options pages:
   list should already have focus, no value should change merely by opening.
   Confirm/Save, Escape/back, right-to-command-menu and full close remain usable.
   Check command browser/profile/structural forms keep original navigation.
3. With a clean Modes page open, issue `//trust autoraise <valid displayed value>`
   or `//trust set AutoRaiseMode <value>` if that mode exists. Display should follow;
   reopening and reload should retain the value in the same named mode set.
   Check `//trust combat` still reports rather than cycling. Test non-Default too.
4. Try `//trust follow distance 3` and an existing attack-distance command; view
   should update, reopening/reload should retain values, and unchanged repetition
   should not add a new autosave notice/write. Restore original distances afterward.
   Follow/assist targets and pause remain session controls, not saved identities.
5. Turn autosave Off using explicit Save. Clean display refresh should still work;
   fresh panes should use original focus. Command-only mode/follow-distance changes
   should not auto-persist. Existing explicitly-saving commands still save. Pending
   manual drafts must not disappear when commands run; conflicted saves should warn.
6. Re-enable with explicit Save. Test invalid values and mode locks, quiet movement,
   stop/start, heal alliance and buff/debuff modes where available. Confirm failures
   never claim Saved. Watch for repeated notices or changed focus/scroll positions.
7. Trace the original menu edit/exit/reopen revert: `//trust menu trace on`, reproduce,
   `//trust menu trace dump`, then `//trust menu trace off`. Dump before reload.
   Dumps still replace the same character log; share it explicitly if desired.
8. Recheck compact widgets, adjacent placement, physical/controller IJKL versus
   gameplay bleed-through, literal chat/text and full close. Controller binding is
   separate. To roll back, unload and restore the full backed-up folder and data.
   Also test Open from closed, repeated Open in a submenu without losing its draft,
   and valid/invalid Close using the separately updated R1 controller shortcuts.

Earlier entries below are preserved as cumulative history. Test 4's runtime-only
alias description documents that earlier build; Test 5 intentionally changes it
when Save options on exit is On.

---

# Explicit menu Open for DirectLink — October 18, 2026

Author A. Branch test/menu-exit-save-20261017; base
31245d39fce64847db755e7c900d6bf111624c07. Small source addendum over the compatible
Menu options Test 4 install. This entry is later than the existing Test 4 ZIP/
BUILD pin; no new full Trust ZIP is claimed by this controller conversation.

The user requested R1+Triangle -> trust menu open and R1+Square -> trust menu close.
Close already exists. Open was not registered and fell through to the default
menu handler. Add an explicit idempotent open using the existing HUD openMenu
method, leaving a visible submenu/cursor/draft intact. It executes immediately;
the old bare menu handler retains its existing schedule and behavior. Close/save/
validation/discard, menu preferences and mode persistence are unchanged.

Only commands/MenuCommands.lua changes at runtime. Copy that file into the
compatible existing Test 4 Trust folder and reload Trust. //trust menu status
now includes explicit open: true. Existing BUILD.txt/Test 4 installer files still
identify their original full-package snapshot. This addendum is coordinated with
XIVCrossbar development/directlink Controls=9.8-r1-menus; Lua and AHK must both be
updated on that side. It does not install or edit AHK from the Trust folder.

PASS: new tests/menu_options/menu_open_test.lua executes the actual command class,
the actual HUD open method and actual base command dispatcher (including case
folding). It checks closed->open once, repeated Open preserving the current
submenu/draft, Close behavior, rejected close with invalid draft, reopening after
close and capability status. UI/state/services are controlled doubles. Syntax and
execution use Lua 5.4 through the controller project's documented runner; no
native Lua 5.1/Windower result is claimed. The broad prior 247-assertion Trust
suite was not rerun from this minimal source addendum; its prior result remains
historical below. No changes to those source paths are made.

PENDING live: Open from closed; repeated Open deep in an editor; Close with valid
and invalid drafts; both controller release orders; native menus alongside Trust;
focus/chat/text guards. Confirm that no ordinary face key or unused R1-release R
leaks from the matching controller build. Close covers Trust menus only.
Main remains unchanged. Historical records follow unchanged.

---

# Test 4 publication and full-package verification — 2026-10-18

Published/fetched source: `6d0b4713089edd370020fc78300c07233fb01c33`.
The full ZIP passed CRC and all 1,473 member-byte comparisons against its source
snapshot. See [the delivery record](docs/MENU-OPTIONS-TEST4-DELIVERY.md).
All new live acceptance remains pending. This note is later than the package pin.

---

# Menu options Test 4 — October 18, 2026 (America/Chicago)

Author: A. Repository: rerorriM-Mirrorer/trust.
Branch: `test/menu-exit-save-20261017`, based on `88fbe2b3013fa60ef32a9e6cd1956946a4afd471`.
Package: `Trust-MenuOptions-Test4-Full.zip`, full cumulative Trust 17.7.3 folder.
Exact published source is pinned in BUILD.txt; no personal settings/data/logs shipped.

## Request and implemented behavior

The user requested systematic direct mode commands and dropping the `Mode` suffix
where it does not conflict with existing commands. Both forms are now resolved
from the loaded mode registry: `//trust AutoRaiseMode` or `//trust autoraise`
cycles; adding a value delegates to existing `set`. Registered command groups and
default command words win. Exact mode names win over shortened mode names.
Ambiguous identifiers or case-folded options are rejected instead of guessed.
The existing `//trust combat` reports its mode; `//trust CombatMode` cycles it.

Listed values are validated before menu preflight and matched case-insensitively
while retaining canonical spelling. Multi-word option tokens are joined only
after resolving a mode. Boolean mode values use existing on/off/true/false
spellings. Free-form string modes require a value and retain text case. Modes
not loaded for the character are unavailable. No broader abbreviations or stripping
of the `Auto` prefix is added. Autocomplete includes valid full/short forms and
options without advertising aliases that conflict with existing commands.

The root rewrites aliases to existing `set`/`cycle` before the menu command policy.
Existing mode locks remain in those original handlers. Named settings/profile
selectors retain their menu restrictions through both full/short spellings.
Invalid alias values do not commit pending edits. Aliases remain runtime changes;
they do not introduce implicit profile persistence. Earlier eligible menu drafts
may save during tactical-command preflight, retaining Test 3 behavior.

The user positively reported adjacent menu placement as more fluid. This is live
feedback about that layout, not acceptance of all menu/save/input changes.
Repeated trace dumps still replace `data/logs/menu-save-<character>.log` in this
build; unique timestamped snapshots have not been implemented. Trace dump is not
an upload and does not automatically share logs with A.

## Verification

PASS: 71 new assertions use the real Modes library, state lock/set/cycle handlers,
alias resolver, autocomplete generator and root dispatcher. UI/OS are mocked.
Coverage includes conflicts, exact-name precedence, invalid/ambiguous values,
multi-word options, boolean/string modes, job absence, mode locks, menu draft
rejection, profile guards and existing commands. PASS: 176 prior assertions
(93 menu/input, 43 trace/commands, 16 Modes flow, 24 movement): **247 total**.

PASS: four changed/new Lua files compile via Lua 5.3 with documented Windower
literal-method normalization. No Lua 5.1 or Windows/Windower execution is claimed.
Diff/whitespace review passed. Package verification is recorded in delivery docs.

PENDING: all Test 4 live FFXI acceptance, original Modes save-on-exit revert and
actual controller IJKL capture. R1 + Square remains a controller-conversation
handoff; no AHK/XIVCrossbar file changes here. Main remains unchanged.

## Next live checks

1. Back up and unload Trust; merge this full folder preserving existing data.
   Reload one client; `//trust menu status` must say Test 4.
2. Confirm the mode exists with status, then try `//trust autoraise`, the full
   `//trust AutoRaiseMode`, and a valid value displayed for that mode. Test mixed
   casing, invalid values and autocomplete. Do not assume every job loads every mode.
3. Verify `//trust combat` reports while `//trust CombatMode` cycles. Check ordinary
   stop/start/assist commands retain their meaning. Check mode locks still reject
   forbidden changes and direct/short profile selectors remain guarded in menus.
4. With a menu edit pending, a valid tactical alias should check it first; an invalid
   alias value should leave the draft alone. Recheck mode view refresh.
5. Trace the unresolved save-on-exit revert using Test 3's on/reproduce/dump/off
   procedure; dump before reload. Recheck adjacent layout, compact widgets,
   physical IJKL/chat/text and quiet handoff. Full rollback restores the backup.

Earlier entries below are retained as cumulative history.

---

# Test 3 publication and full-package verification — 2026-10-17

Source `43645774f780848b77821034f21aaebd3dd833dc` is published and fetched.
The 1,472-member full-folder ZIP passed CRC and exact member-byte checks.
See [the delivery record](docs/MENU-OPTIONS-TEST3-DELIVERY.md) for checksum and scope.
All live acceptance remains pending; source-only success does not resolve the
reported Modes revert. This note is later than the embedded package snapshot.

---

# Menu options Test 3 — October 17, 2026 (America/Chicago)

Author: A. Repository: rerorriM-Mirrorer/trust.
Branch: `test/menu-exit-save-20261017`, based on Test 2 delivery `e6576f3b39739926499d0f0f149e5f7e10d8babe`.
Package: `Trust-MenuOptions-Test3-Full.zip`, one full Trust folder assembled from
this fork's source snapshot, retaining its pinned Trust 17.7.3 baseline and all
cumulative changes. Source identity is in `trust/BUILD.txt`. No personal profiles,
character settings, trace output or user data are included. Windower dependencies
remain external. Previous packages were overlays; use this package's install guide.

## Request and observed controller mapping

The user selected save tracing and useful command access while menus are open,
and asked whether R1 + Square could close all menus from any level.

Current `xivcrossbar/development/directlink` source was read directly: the AHK
R1 layer explicitly maps normalized buttons 5/7/8 to Enter/Escape/Ctrl+NumpadAdd;
it has no dedicated Square/button-6 action. Square can continue into the ordinary
active-window transport. The requested close binding needs to consume Square and
send `//trust menu close`, avoiding ordinary Square and a later bare-R1 action.
No controller file is changed here because that shared AHK file is being developed
in the XIVCrossbar conversation. The concrete handoff is included in this package.
Close means all Trust menu levels; NPC dialogue and other addon menus are separate.
Invalid drafts still keep Trust open with feedback; discard remains explicit.

## Implemented

- `//trust menu trace [on|off|status|dump|clear]`: Off by default, prints labeled
  meaningful events when On, retains the last 120, exports on explicit dump to
  `data/logs/menu-save-<character>.log`. No background file writes. Export includes
  bounded option summaries and settings destinations; no general chat/input capture.
  Dump before reload; reload resets the in-memory session and disables tracing.
- Trace includes editor construction/policy, field completion, departure reason,
  changed scalar values, current named sets, explicit Modes destination, skips,
  conflicts, validation errors, applying, save returns and failures. Job/Modes
  writers record requested paths and return boundaries. A return is not readback
  verification of persisted bytes. No speculative autosave algorithm fix is claimed.
- Root menu command policy distinguishes immediate controls/read-only/UI commands,
  reviewed tactical verbs requiring an eligible pending-edit check, and profile/
  reload/unreviewed structural operations still blocked during menu editing.
  Stop/stopall are always accessible even with invalid drafts, using their existing
  behavior; this does not establish all-movement Manual Override. Assist/follow,
  attack controls, ordinary mode set/cycle, basic heal/pull/MB/nuke and target
  controls are available. Existing send/sendall remain; recipients enforce guards.
- `//trust combat [auto|mirror|off]` provides an explicit CombatMode shorthand;
  bare invocation reports mode. Unsupported values leave the mode unchanged.
- Clean Modes editors refresh after reviewed tactical commands and refresh their
  conflict snapshot. Immediate/read-only commands do not rebuild the editor;
  dirty drafts are never replaced by that refresh. The expanded test uncovered
  uncached-row removal/reload errors; cache lookups now tolerate unrendered rows.

## Verification

PASS: 93 existing menu/save/layout/input assertions, 16 expanded Modes flow
assertions (including actual trace events and sparse cache refresh), 43 trace/
command assertions (including the actual root dispatcher extracted from Trust.lua),
and 24 quiet-movement assertions: **176 total simulated assertions**.
OS, rendering, live mode state and persistence are mocked where documented.

PASS: 14 changed/test Lua files compile with the available Lua 5.3 runner after
normalizing Windower quoted-literal method syntax. No native Lua 5.1/Windower
execution is claimed. Diff/whitespace review passed. Source/package checksums and
full archive verification are in the Test 3 delivery record.

PENDING: all actual Windows/Windower/FFXI acceptance. The user's Modes revert
and end-to-end AHK IJKL/gameplay suppression remain unresolved until live testing.
R1 + Square is a ready-to-wire controller handoff, not an installed binding here.

## Short next in-game test

1. Back up the complete existing addon folder/data. Unload Trust. Merge this full
   package's `trust` contents into the existing compatible addon folder; preserve
   your `data` directory. Test one client first. Status must identify **Test 3**.
2. Run `//trust menu trace on`. Change one ordinary mode in the long Modes page,
   finish the selected field, back out, reopen and check the value. Run
   `//trust menu trace dump`, then `off`. Preserve the trace if the value reverts.
   Reload only after dumping; check disk persistence separately.
3. With a menu visible, try `//trust status`, `//trust stop`, `//trust start`,
   `//trust assist <party member>`, `//trust combat mirror`, and ordinary mode
   controls. A pending valid edit should save before tactical changes. Status
   and stop should work even when an edit cannot validate. Test stopall with
   other participating clients upgraded, respecting existing IPC scope settings.
4. Profile selection/reload/structural commands should explain that the menu
   must be closed. A failed validation must preserve the draft. Check a clean
   Modes page updates after commands without losing cursor/scroll usability.
5. Use `//trust menu close` deep in a submenu. Test physical IJKL, arrows, chat,
   text, held keys during close and resumed gameplay. Independently updated AHK
   input and the proposed R1 + Square chord need their own live acceptance.
6. Recheck compact widgets, adjacent layout, manual Save/Confirm and quiet handoff.

Rollback: unload and restore the backed-up complete folder/data. Do not rely on
an older overlay to remove new modules. Main and XIVCrossbar are unchanged.
Earlier testing history below is preserved and remains subject to later reports.

---

# Test 2 publication and package verification — 2026-10-17

Published source: `8b087f5329c40d2462cea54bba4de162bf007d4a`.
The cumulative ZIP passed CRC and source/doc byte comparison against the fetched
published tree. See [the delivery record](docs/MENU-OPTIONS-TEST2-DELIVERY.md).
All live Test 2 checks are pending; the reported Modes revert remains unresolved.
The embedded TESTING is pinned to the source snapshot before this publication note.

---

# Menu options Test 2 — 2026-10-17 (America/Chicago)

Author: A. Repository: `rerorriM-Mirrorer/trust`.
Branch: `test/menu-exit-save-20261017`; previous published head `1a0cdab89092a096e56f2429e18d32210db28151`.
Package: `Trust-MenuOptions-Test2-Cumulative.zip`, an overlay for the same compatible
Trust 17.7.3 baseline as Test 1. No profile/data files included. Source SHA is in
`trust/BUILD.txt` inside the ZIP. Main remains unchanged.

## User observations and unresolved issues

- The user reports XIVCrossbar-generated IJKL neither navigates Trust's menu nor
  prevents native targeting behind it. Source inspection of XIVCrossbar
  `development/directlink` at `a9b2486937ec3bbeacd545ec505d9920e0381f75`
  shows ordinary gameplay D-pad IJKL is issued by Lua via `setkey`; R1+D-pad
  arrows use AHK SendEvent. Test 1 tested the receiving Lua callback only, not
  this actual producer-to-consumer path. It did not add native IJKL binds.
- The user reports editing the first entry in the long Modes list (believed
  AutoRaiseMode, Off to On; exact displayed value not confirmed), backing out,
  seeing no saved message, and finding Off again when reopening. This is a
  live failure report, not a passing acceptance. Exact installed files/build,
  exit sequence and save preference have not yet been observed.
- Expanded simulation using the real ModeConfigEditor and ConfigEditor
  constructors, picker model, data source, Luvent and menu departure hook
  applies, saves and reopens a mode successfully. Rendering, live mode state,
  persistence and the OS are still mocked. This does not reproduce or resolve
  the user's report. No speculative mode-save algorithm change is shipped.

## Changes in Test 2

- Arrows/Enter retain scoped native menu blocking. IJKL adds unmodified and
  Shift variants when its preference is On. Native binds explicitly require
  closed chat (`%`); they are suspended for chat and removed on menu close.
  Event translation now also requires an active menu, so focused widgets alone
  cannot turn gameplay letters into directions.
- Text fields retain literal letters and their existing broad keyboard block.
  Leaving text entry restores menu arrow/IJKL binds after broad text unbinding.
  Preference changes refresh active menu bindings. Unchanged keyboard events
  do not issue repeated bind commands.
- Successful changed-editor saves emit `Saved menu options.` in chat as well as
  `Saved.` in the info bar; navigation can immediately replace the info-bar text.
  `//trust menu status` identifies Test 2 and reports editor state: pending
  changes, unchanged, disabled, nested picker, or explicit save required.
- XIVCrossbar and AHK are unchanged here. See
  [the keyboard handoff](docs/KEYBOARD-HANDOFF-20261017.md) for coordination.
  Real AHK IJKL navigation plus gameplay suppression remains unverified.

## Verification and next live checks

- PASS: 93 mocked menu/save/layout/input assertions, including native bind
  lifetime, preference/chat transitions, text departure and non-menu focus.
- PASS: 10 expanded Modes flow assertions with real editor constructors,
  data source, picker model, event dispatch and menu exit; state/storage/rendering
  mocked. This supplements the previous adapter-only tests.
- PASS: 24 existing quiet-movement integration assertions.
- Syntax/diff/package results are recorded in the delivery record. Available
  interpreter is Lua 5.3 via `luatex --luaonly`; no native Lua 5.1/Windower run.
- PENDING: Windows/FFXI testing of ALL Test 2 changes. Autosave failure unresolved.

When next at the PC, back up/unload Trust and merge this cumulative overlay into
its existing compatible folder, then reload one client. `//trust menu status`
must say **Test 2**. Keep other clients on their previous version until checked.

1. Before AHK changes, try physical IJKL and arrows in Trust menu lists, selected
   pickers and sliders. Check gameplay targeting stays still, letters type in
   chat/text fields, and gameplay keys return when Trust's menu closes.
2. In the long Modes editor, change one ordinary mode and finish its selected
   field. While the editor is still displayed, `//trust menu status` should
   say `save on exit: true` and `editor: pending changes`. Back out of the
   enclosing editor, check chat for `Saved menu options.`, and reopen it.
   Test `//trust menu close` separately, then reload to check disk persistence.
   Preserve the exact status and any error if it reverts. Do not toggle AutoRaise
   merely for diagnosis if a different ordinary mode is easier to inspect.
3. With the independently updated AHK route, repeat controller tests including
   held directions, text entry, closing menus while held and returning to gameplay.
   This package alone makes no promise about Lua `setkey` interception.
4. Recheck compact widgets, menu placement, manual Confirm/Save, named profile
   switching, validation failures and quiet movement handoff.

The earlier entries below are preserved as the historical delivery record. Their
pending live acceptance is qualified by these subsequent failure reports.

---

# Publication and package verification — 2026-10-17

Menu options Test 1 source is published at `73aaa3839b66ae698bc692cdf9ac721add354565`.
The cumulative ZIP passed CRC and exact source/doc-byte verification against the
fetched published tree. See [the delivery record](docs/MENU-OPTIONS-TEST1-DELIVERY.md)
for the manifest, checksum and package link. All new live acceptance remains pending.
The embedded TESTING is pinned to the packaged source snapshot; this publication
entry is a later documentation addition. Main was not changed or merged.

---

# Menu options Test 1 — 2026-10-17 (America/Chicago)

**Author:** A. **Repository:** `rerorriM-Mirrorer/trust`.
**Working branch:** `test/menu-exit-save-20261017`, based on the cumulative
quiet/UI candidate `9c7134166f36d99fb0fd21ab35f9eb41e534c210`.
**Original compatible runtime:** Trust 17.7.3 at
`575bf583ef41e0018f05b922c6673ab89b54af95`.
**Package:** `Trust-MenuOptions-Test1-Cumulative.zip`; exact delivery source SHA
and manifest are recorded in its `trust/BUILD.txt` and `trust/INSTALL-MENU-TEST1.txt`.
It is an overlay for an existing compatible install, not a complete upstream addon.
No character data, settings, paths or profiles are shipped or replaced.

## Request and implemented scope

The user selected menu work first: optional automatic confirm/save when leaving
ordinary options editors, an editor panel immediately left of the main menu,
and I/J/K/L directional input in Lua.

- Config > Menu supplies `save_on_exit`, `adjacent`, and `ijkl`. New defaults are
  On; existing explicit values are preserved. With autosave disabled, use Save
  to re-enable it. Confirm/Save buttons remain available; menu-entry removal is deferred.
- Ordinary toggles, sliders, single-choice options, scalar groups and mixed
  options/text panels validate before applying. Editor-to-command focus return,
  Back, page departure and explicit close commit once when changed. Callback
  requests for the same owner's save are coalesced into one final write.
- Mode edits use the named set selected when opening the editor; external mode,
  profile, root-settings and conflicting option changes block stale saves.
  Widget position/layout retain their existing persistence. Sound application
  runs from its change handler as well as the existing explicit Save action.
- Profile creation/renaming/selection, structural gambit/condition/action edits,
  command forms, language reload and nested multi-select pickers remain explicit.
  Opening chat or changing Windows focus is not treated as finishing an editor.
  A field's first Escape retains its existing deselect/finish behavior; departure
  from the enclosing editor is the save boundary. Reset/Clear/Delete/Import
  actions do not implicitly save the pending draft before running.
- Editor placement uses actual view width with an 8px gap to the command menu,
  clamped to client bounds. Presentation and parent restoration recalculate the
  position; reopen after resolution changes. Oversized custom views are not scaled.
- I/J/K/L feed Up/Left/Down/Right scan codes to focused Trust UI only. Text cells
  and chat keep letters; Shift is preserved, other modified letters are untouched.
  Owned releases return to their original recipient or are dropped if it was
  destroyed. No OS key injection or permanent IJKL bindings are added.
- `//trust menu close`, `discard`, and `status` work while the menu is visible.
  Discard closes without applying the pending editor draft; it does not undo
  already saved changes or runtime changes applied before an I/O failure.
  Other existing command restrictions are unchanged.

## Verification performed here

- **PASS:** 84 assertions executing edited Lua methods with Windower, UI rendering,
  I/O and hardware mocked: dirty/no-op saves, combined option commit, validation,
  write/callback failure and retry, owner save restoration/coalescing, settings/profile
  conflicts, actual Modes adapter, keyboard event routing, text/chat/modifier
  exclusions, held release after close, menu action guards and explicit discard.
- **PASS:** existing 24 Trust quiet-movement integration assertions.
- **PASS:** 21 changed/new Lua files compile with the available Lua 5.3 parser;
  upstream Windower quoted-literal method syntax is parenthesized for this check
  only. New code uses Lua 5.1-compatible constructs, but **no Lua 5.1/Windower
  execution is claimed**. Available runner: `luatex --luaonly`.
- **PASS:** whitespace/diff review. Main and older test branches are unchanged.
- Package manifest/source-byte and ZIP CRC verification are recorded at delivery.
- **PENDING:** all actual Windows/Windower/FFXI acceptance for this batch. Earlier
  positive compact UI/movement reports do not certify these new menu behaviors.

## Installation, rollback and live acceptance

1. Back up the complete existing compatible `Windower/addons/trust` folder,
   including its settings/data. Unload Trust on participating clients before
   extracting. Copy this ZIP's `trust` contents into the existing `addons/trust`
   folder, preserving paths; do not create `trust/trust`. No AHK/wrapper update.
2. Load/reload one client first. `//trust menu status` must identify Menu options
   Test 1 and report all three preferences. Check prior compact visuals and quiet
   handoff before adding more clients.
3. In Config > Menu, change adjacent placement Off/On and leave the editor.
   Reopen and confirm persistence. Check small and 4K resolutions, keyboard/mouse/
   controller focus, selected row/scroll state, and reopening after resolution change.
4. In widget position or combat Config, change 2–3 options. Finish the selected
   field, leave the editor using Back/Right, close and reload Trust. Check that
   **all** edited values persisted without selecting Confirm/Save. Repeat with
   a mouse menu action and `//trust menu close`; unchanged exits should be quiet.
5. In Modes, edit ordinary modes, leave and reload. Verify the selected named
   set. Switch profiles separately and confirm no cross-profile writes. Check
   an external conflicting mode change yields a clear error; use discard/reopen.
6. Test I/J/K/L against arrows on command lists, option lists, sliders and pickers;
   Shift+J/L should retain the picker's faster stepping. Type words containing
   ijkl in chat and a text editor. Test modifier shortcuts and release after close.
7. Turn autosave Off and confirm the original explicit workflow. Turn it back On
   using Save. Test an invalid ordinary text value and confirm it blocks save.
   `//trust menu discard` must close it without executing an unrelated action.
8. Enter command forms, nested multi-selects, profile/gambit creation and language
   settings without confirming. Back out and verify none executed/saved/reloaded
   merely from leaving. Check Reset remains explicit and ordinary menus still work.
9. Repeat accepted cases across multiple clients. Verify current book/crystal/name
   placement, follow/assist quiet behavior and startup IPC guard remain unchanged.

**Rollback:** unload Trust, restore the pre-install complete folder backup, then
load again. Alternatively overwrite source files from the pinned pre-test snapshot
using the manifest; restore user settings only if deliberately reverting values.
The test writes preferences and any settings the user intentionally saves in-game.

**Live observations:** all rows above pending; record character, client count,
resolution, steps and actual result. No in-game test performed by the assistant.

## Guidance reconciliation and historical corrections

Adopted main's current AGENTS.md and WORKFLOW.md, verified against the canonical
NPCMirror workflow. This branch previously lacked AGENTS.md. Historical package-
root statements below are superseded: put WORKFLOW.md and TESTING.md **inside the
installable addon folder**, alongside README/code. Retired DESIGN/AGATHOS references
below remain historical; the current WORKFLOW.md contains the consolidated text.
Earlier local-only/publication notes remain intact as delivery-time history.

---

# Publication record — 2026-10-15

Source, tests and documentation are published on `test/movement-quiet-20261015`.
Earlier local-only/push-blocked notes below describe their delivery-time status
and are retained as history. Runtime code is unchanged by publication.

---

# Trust movement — quiet update, 0.1.1 (2026-10-15)

User live report on Test 1: "IT WORKED"; movement-generated messages from both
TrustMovement and Trust are the next requested refinement. That confirms the
working handoff, but does not individually certify every earlier checklist row.

This update leaves the proven AHK files byte-for-byte unchanged. Overlay only
addons/trust and addons/trustmovement for an existing Test 1 install. Reload
Trust with `//lua reload trust`, then `//lua reload trustmovement`, in each
participating client. Saved mode is retained; new quiet setting defaults on.
No wrapper restart is needed. Read README.md for fresh installation/rollback.

## Current checks

- PASS: 57 mocked receiver assertions, including quiet default, saved-setting
  migration, quiet on/off, idempotent settings, diagnostics, status and guards.
- PASS: 24 Trust integration assertions executing edited command/role methods,
  including IPC flag propagation, unchanged control effects, manual feedback,
  visible errors, path notices, literal arguments in other command groups,
  nested quiet scopes and cleanup after exceptions.
- PASS: Lua 5.1 syntax checks for 10 source/test files. Existing Windower
  quoted-string method syntax is normalized only for standard-parser tests.
- PASS: whitespace/diff review; original AHK wrapper/helper unchanged.
- PENDING: live quiet handoff with all recipients patched; manual commands and
  deliberate invalid-target feedback; //tm quiet off restores acknowledgments.

## Delivery register

TrustMovement 0.1.1 Quiet: cumulative movement package plus a targeted Trust
source overlay. BUILD.txt records both local source commits. Source remains
local; no new GitHub push is attempted. Rollback contains the Test 1 receiver
and unmodified Trust baseline files, plus the originally uploaded wrapper.
Trust baseline: 89939a7a26522bb92670bd000a771b235230b77d.

---

# TESTING.md — Trust

Private, cumulative development and testing record. Keep this file at the **repository root** and at the **root of every testing package**. Read it first before testing or preparing a patch batch. Exclude this internal record from public release packages unless the collaborators agree otherwise.

**Reference conventions:** [NPCMirror WORKFLOW.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/WORKFLOW.md), [DESIGN.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/DESIGN.md), [AGATHOS.md](https://github.com/rerorriM-Mirrorer/ffxi-NPCmirror/blob/main/AGATHOS.md). Apply the smallest responsible change, protect known-good states, document corrections using strikethrough plus explanation, and remove historical entries only by mutual agreement.

## Research and live feedback — 2026-10-15: Menu safety, autosave, Manual Override

- **User live confirmation:** The active-crystal pulse and widget target placement look great on current client(s). Previous ledger records listing those exact effects as untested are now superseded **for the character(s) observed**, not necessarily all four characters. No UI changes requested.
- **Read-only source audit:** [Manual Override and Menu Interaction Audit](docs/MANUAL-OVERRIDE-MENU-AUDIT-20261015.md). Reviewed broad command blocker, menu focus/escape, 0.2-second scheduled opener (original rationale unknown), ConfigEditor draft/Confirm/Save path, Modes temporary Confirm vs profile Save, job-vs-mode persistence, and upstream movement cancellation limitations. No runtime files changed.
- **Priority selected:** Prototype AUTO/MANUAL movement ownership first. Later: test command-effect classification instead of category allowlist, immediate menu close, valid-change autosave to the selected named set, pending draft/profile transitions, and menu timing. Controller detection should instrument actual PS5 analog input through XIVCrossbar's existing AutoHotkey DirectInput bridge; it currently observes gamepad buttons/POV, not analog stick takeover.
- **Status:** Design/research only. No manual control or autosave implementation, no in-game test of such functions.

---

## Current testing delivery — 2026-10-15: Trust 17.7.3 cumulative overlay (Cioara and companions)

**Purpose:** One install package for compatible **Cyrite Trust 17.7.3** addon folders, regardless of which earlier incremental Trust test patches were installed. The literal `_addon.version = '17.7.3'` line stays unchanged across these test patches; this version string **cannot** identify patch status. The user reported this exact header on Cioara and three companion clients.

**Source baseline:** pinned original commit `575bf583ef41e0018f05b922c6673ab89b54af95` (Trust 17.7.3). **Patch source snapshot:** `2aa54f0cad8ad4a2aa2a59c5f799bd83f68adda4`, branch `test/compact-trust-title-20261008`. No 2026-10-13 Manual Override, custom waypoint recorder, or Gambit Inspector implementation is included; those are **discussion and research only**.

**Package name:** `testing-packages/Trust-Cumulative-17.7.3-20261015.zip`. Planned overlay manifest (18 live files) from exact baseline comparison: `Trust.lua`; `assets/icons/menu_maphp_crystal.png`; `assets/icons/menu_mapsg_book.png`; `commands/GeneralCommands.lua`; `cylibs/Cylibs-Windower-Events.lua`; `cylibs/paths/path_recorder.lua`; `cylibs/trust/commands/trust_commands.lua`; `cylibs/ui/input/autocomplete/chat_auto_completer.lua`; `cylibs/ui/input/autocomplete/command_trie.lua`; `cylibs/ui/input/mouse.lua`; `ui/TrustHud.lua`; `ui/TrustWidgets.lua`; `ui/settings/menus/widgets/WidgetSettingsMenuItem.lua`; `ui/widgets/CompactWidget.lua`; `ui/widgets/PartyStatusWidget.lua`; `ui/widgets/TargetWidget.lua`; `ui/widgets/TrustStatusWidget.lua`; `ui/widgets/Widget.lua`. Documentation: `INSTALL-CUMULATIVE.txt`, `TESTING.md`, `WORKFLOW.md`. These docs are not addon runtime components.

**Published artifact:** [`Trust-Cumulative-17.7.3-20261015.zip`](testing-packages/Trust-Cumulative-17.7.3-20261015.zip), published in test-branch commit `415850754ebb584175eb84f692747fe88d535f47`. ZIP **318,758 bytes**, 21 entries (18 live source/assets, `TESTING.md`, `WORKFLOW.md`, `INSTALL-CUMULATIVE.txt`). Uploaded Git blob SHA-1: `29977a2785a3972e3d808fe331a64b8c4b0fe172`; whole-file CRC32 `0xb855dd44`. The remote GitHub upload was fetched again and fully checked: ZIP EOCD, exact central and local headers, all 21 member CRC32 values, names and paths, complete manifest, and exact byte equality against the 18 pinned source files and both pinned documentation files. **All passed.** This is not an in-game smoke test. Because the archive embeds the build-time `TESTING.md`, that copy still lists CUM-01 as pending; this online ledger contains the later, verified result.

**Major cumulative patches:** compact Trust/Party/Target widgets with shared slot, book/crystal icons and animation candidates, command execution and autocomplete case folding, multi-client IPC reload guard, configurable widget/drag input refinements, menu CPU profiling behind `//trust menuperf on`, newly recorded paths defaulting to `auto_reverse = true`. Existing path files remain intact.

**Install:** Back up the **entire** existing `addons/trust` directory (including `data/`), close or unload Trust, extract the overlay into that same folder (the directory already containing `Trust.lua`), preserve hierarchy and allow replacement of the 15 modified live files. The three added live files are two PNGs and `ui/widgets/CompactWidget.lua`. The ZIP intentionally does not include the source installation's unchanged dependencies or any saved profile/settings/path files. Start with one character (prefer Cioara), then roll out the identical package to the companions. To restore prior behavior, use the backed-up folder; restore only the source files if intentionally keeping newer user data.

| Test | Expected | Status |
| --- | --- | --- |
| CUM-01 | ZIP local headers, central directory/EOCD, CRC32, manifest and uploaded artifact match source snapshot | **PASS — POST-UPLOAD STATIC / ARCHIVE VERIFICATION** |
| CUM-02 | One client loads; known prior case-insensitive commands and menu/UI interactions work | **PENDING IN-GAME** |
| CUM-03 | Crystal pulse and anchored target names work in actual active Trust state | **PENDING IN-GAME** |
| CUM-04 | Autocomplete works with mixed case; menu performance timings available only when enabled | **PENDING IN-GAME** |
| CUM-05 | Three companion clients load independently; no IPC reload race; independent character data unaffected | **PENDING IN-GAME** |
| CUM-06 | Existing recorded paths not changed; any newly recorded path defaults to reverse; path stop/clear semantics unchanged | **PENDING IN-GAME** |

**Compatibility limitation:** This is an overwrite-only overlay for Trust source based on the specified original snapshot. It cannot automatically remove obsolete files or guarantee compatibility with unrelated modified forks. Static ZIP integrity is not an in-game success claim. `main` remains unchanged by this delivery.

---

## Research audit — 2026-10-13: Gambit/condition capabilities for low-level characters

Source-only investigation during FFXI maintenance. [Read the complete Gambit capability audit](docs/GAMBIT-CAPABILITY-AUDIT-20261013.md) and its full 93-condition / 41-low-level-action / 50-battle-module inventories. **No game/automation code changed; no claim of successful live gambit testing.** Findings: 53 conditions are in the picker; 11 condition modules imported but unlisted; 29 modules neither imported in the main conditions include nor listed; the user-facing action chooser is much narrower than the underlying low-level action directory. Generic gambits are evaluated in priority order, usually on a 1-second role timer; missing OR/ally comparator editors and some condition serializers limit safe exposure. Current BLM, WHM, WAR and MNK default job gambits are notably oriented to higher-level play. Recommended order: read-only gambit diagnostics, beginner-level templates based on learned abilities and job roles, carefully selected condition exposure, then OR/priority composition. Existing path-follow recovery remains the subsequent project priority; party-wide profile aliases stay deferred.

---

## Packaging standard — cumulative testing overlays (adopted 2026-10-13)

**Decision:** All **future** Trust test ZIPs are cumulative over a single pinned original baseline, rather than depending on a sequence of old patch ZIPs. The baseline is original `main` commit `575bf583ef41e0018f05b922c6673ab89b54af95` (Trust 17.7.3). Git `main` itself is protected and remains last live-tested. Each ZIP is still an **overlay for an installed compatible Trust**; it is not a complete standalone copy of upstream Trust.

**Composition and compatibility**
1. Compare the selected testing-branch snapshot against that pinned baseline. Include **every added or modified live addon source and asset file** from the comparison, preserving exact addon-root paths (e.g. `Trust.lua`, `commands/`, `cylibs/`, `ui/`, `assets/`). At adoption time the comparison reports **18 live files**, including two new PNGs and `ui/widgets/CompactWidget.lua`. Do **not** assemble a package by simply layering previous ZIPs because those may be older or malformed.
2. Exclude earlier `testing-packages/` artifacts, generated logs, cache, and all untouched/private `data/`, `settings/`, `profiles/`, saved paths and user customization files. Include a short root `INSTALL-CUMULATIVE.txt` with the pinned baseline SHA, target testing commit SHA, exact file list, install and rollback guidance, and the link to this cumulative `TESTING.md`. This test ledger stays in the repo (avoid re-embedding a giant history file if it makes the ZIP fragile).
3. **Idempotent extraction:** The latest overlay can be applied once or repeatedly on a matching original or previously patched install. Replacing files with the same bytes has no new effect beyond normal reload. Never silently delete installed files, change user data, or assume extraction solves an older incompatible upstream installation.
4. **Deletions and migrations:** Overwrite-only ZIPs do not remove obsolete files; if an actual source deletion, rename, or settings migration becomes necessary, call it out explicitly and provide a separate, reversible migration/cleanup step. Do not auto-delete a user's files.
5. **Verification:** Re-fetch the uploaded GitHub artifact, verify ZIP local headers, central-directory/EOCD, complete manifest and each member's CRC32, and ensure contents match the testing-branch source snapshot. If the archive fails, **do not ship the link**; replace it and verify again. This confirms archive integrity, **not** live in-game correctness.
6. Install by backing up the addon folder, extracting the latest ZIP to the existing folder containing `Trust.lua`, preserving paths, then `//lua r trust` on one client before multiclient. Rollback should use the pre-install backup or a separately pinned previous cumulative version. **Never merge to main** until accepted in-game.

**Historical deliveries:** Earlier incremental C1/C2/C3/command/diagnostic ZIPs remain documented for provenance; they are not the new distribution format. Future fixes and features produce **one cumulative ZIP** each. File-level and commit-level granularity is retained for code review and regression isolation, not as a prerequisite install chain.

---

## Current testing batch — 2026-10-12: Case-insensitive command lookup and menu-open hitch diagnostics

**User live report:** The previous command dispatcher case-insensitivity works well; the book/compact icons look good. The crystal's Active animation and anchored target name have not yet been observed during live action and remain pending. Preserve this difference between confirmed and untested states.

### Autocomplete — case-insensitive lookup (candidate)

- **Source inspection:** `cylibs/ui/input/autocomplete/chat_auto_completer.lua` previously checked only lowercase `//trust` or `// trust` as raw substrings. Its `CommandTrie` stores exact characters as keys, so case-mismatched prefixes such as `//TRUST FOLL` or `//trust wIdGeT` do not match. This is separate from the command execution dispatch (already user-confirmed).
- **Small change:** Index and search trie nodes with lowercase lookup keys while storing each leaf's original command string for display. Recognize the case-insensitive `//TRUST` prefix only at start of the chat input, and pass the suffix in its original case to the trie. No change to command execution, profile names, path filenames, or existing capitalization in suggestions.
- **Source files:** `cylibs/ui/input/autocomplete/command_trie.lua` and `cylibs/ui/input/autocomplete/chat_auto_completer.lua`. Case folding is limited to prefix matching.
- **Patch:** [`testing-packages/Trust-Case-Insensitive-Lookup-20261012.zip`](testing-packages/Trust-Case-Insensitive-Lookup-20261012.zip). Requires previous command-dispatch patch; may be installed independently of the menu diagnostics. Root TESTING.md is the source of historical results.

| Lookup test | In-game expected | Status |
| --- | --- | --- |
| LOOKUP-01 | `//TRUST WID` suggests normal widget commands, preserving display case | **PENDING** |
| LOOKUP-02 | `//tRuSt fOlLoW`, `// TRUST SET auto`, and lowercase forms match the same set | **PENDING** |
| LOOKUP-03 | Names/values remain canonical in suggestion and selecting one inserts a valid command | **PENDING** |
| LOOKUP-04 | Unrelated chat lines containing `//trust` no longer show popup; no odd behavior with autocomplete when chat closes | **PENDING** |

### Menu hitch — evidence and opt-in CPU probe (candidate)

- **First-open source finding:** `ui/TrustHud.lua:getMainMenuItem()` lazily creates the root `MenuItem`, immediately runs `reloadJobMenuItems()` to build main/sub-job settings, and creates the full Commands menu. Job settings eagerly construct role menus and Gambits submenus. These allocations can generate a first-open CPU spike; **cause not proven without timings**.
- **Every-open source finding:** `TrustHud:toggleMenu()` calls `Menu:closeAll()` then `Menu:showMenu()`; the latter creates a new `MenuView` when the previous was destroyed, populates cells, sets up FFXI backgrounds/layout, presents it, and plays the menu sound. Even when the menu tree is cached, the view is rebuilt. This is a plausible repeat-open hitch, not confirmed as causal. `MenuCommands:handle_toggle_menu()` schedules menu opening after a 0.2-second coroutine delay; that delay alone is not the graphical stall.
- **No speculative optimization yet.** Instrument `TrustHud:toggleMenu()` with opt-in `os.clock()` phase timing for `close`, `build`, `show`, and total, noting first vs cached. Use `//trust menuperf on` to enable, `//trust menuperf off` to disable (or no argument to report status). Normal menu opens have no log and only a constant flag check. Timings represent Lua CPU time, not GPU presentation or render-frame duration; if a visible hitch persists with small numbers, follow-up renderer/frame diagnostics are needed.
- **Source files:** `commands/GeneralCommands.lua` and `ui/TrustHud.lua`. Does not change the menu's appearance, creation strategy, keybindings, or menu actions.
- **Patches (both required):** [`Trust-Menu-Profiler-Command-20261012.zip`](testing-packages/Trust-Menu-Profiler-Command-20261012.zip) registers the diagnostic command and [`Trust-Menu-Profiler-HUD-20261012.zip`](testing-packages/Trust-Menu-Profiler-HUD-20261012.zip) instruments menu opens. Both are independent of the autocomplete patch. Root TESTING.md is the source of historical results. The earlier combined profiler ZIP failed ZIP verification and is removed; do not install it.

| Menu test | In-game steps | Status |
| --- | --- | --- |
| MENU-01 | Enable `//trust menuperf on`, then close/reopen menu 3 times and copy the timings | **PENDING** |
| MENU-02 | Reload and measure first opening vs subsequent openings; compare if hitch only on first | **PENDING** |
| MENU-03 | Note whether hitch is limited to visually drawing menu, navigating job Settings/Gambits, or both | **PENDING** |
| MENU-04 | Disable probe; confirm old menu navigation, no timing logs, no unexpected cursor/focus issues | **PENDING** |

**Installation/rollback:** Each small ZIP contains its changed Lua files plus installation notes; the authoritative cumulative TESTING.md stays linked in the testing branch root. The originally uploaded ZIPs containing the long record **failed post-upload CRC validation and must not be used**; they are replaced with newly verified compact archives. Extract at Trust root after a backup, preserving the paths. Roll back lookup by restoring the two autocomplete files; roll back the CPU probe by restoring `commands/GeneralCommands.lua` and `ui/TrustHud.lua`. Install both small profiler ZIPs before testing `//trust menuperf on`. `main` stays unchanged.

**Archive verification (2026-10-12):** The uploaded autocomplete ZIP (`Trust-Case-Insensitive-Lookup-20261012.zip`) and two small diagnostic ZIPs (`Trust-Menu-Profiler-Command-20261012.zip`, `Trust-Menu-Profiler-HUD-20261012.zip`) were re-fetched from GitHub and passed per-entry CRC32, ZIP central-directory/end-record, and file-list checks. The earlier large malformed diagnostic archive was removed; the earlier large malformed lookup archive was overwritten. The new archives deliberately link to this authoritative cumulative `TESTING.md` instead of embedding it. **Package integrity is confirmed, but no new live tests have yet been reported.**

**Priority:** Measure the hitch before restructuring menu construction. Later project priorities remain the action/gambit capability audit and then path/follow recovery; party-wide aliases are deferred by agreement.

---

## Previous testing batch — 2026-10-12: C3 sprites and case-insensitive command dispatch

**Heading correction (2026-10-12):** ~~Current testing batch — 2026-10-12: C3 sprites and case-insensitive command dispatch~~. The source tests remain recorded below. User subsequently confirmed case-insensitive execution and the appearance of the basic compact icons; live Active crystal and Target-name behavior are still pending.

**Two separate change sets, each independently reversible.** Baseline: test branch `test/compact-trust-title-20261008`, including successful earlier IPC startup guard and C2 shared compact slot/edge alignment. `main` remains unmerged.

### C3 — Original book/crystal compact visual (SOURCE PATCHED, LIVE TEST PENDING)

- **User-supplied authentic sprites, 32×32 RGBA:** `55_menu-mapsg(2).png` (open book) committed byte-for-byte as `assets/icons/menu_mapsg_book.png`; `54_menu-maphp.png` (blue crystal) committed byte-for-byte as `assets/icons/menu_maphp_crystal.png`. SHA-1 Git blobs: `5ebcad212e9acdb7c6e724c1e827e9f66b120f2e` and `8d6707b60ab12849c14d419c5eb7ab0107925839`, checked against local uploaded PNGs. Existing hourglass remains `assets/icons/icon_timer.png`.
- **Visual states:** Trust Off = same faint 32px hourglass alpha 75; Idle = the book sprite alpha 185; Active = **same book underneath** plus crystal on a separate `ImageView` pulsing alpha 24–220. A restrained green halo remains active behind the sprite; the old filled tint is disabled. The period is **2.4 seconds** with a smooth sinusoidal opacity curve and updates at ~10 Hz.
- **Lifecycle:** `Timer.scheduledTimer(0.1)` is attached to TrustStatusWidget's existing dispose bag and **starts only in compact Active**, cancelling for Idle/Off/Full. The item background doesn't reload each animation frame, only on state transitions; image alpha itself is applied by `ImageView:layoutIfNeeded()`.
- **Party badge:** Show the small numeral in the slot's top-left only when the local party count is **2 or more**; when solo, show no numeral and no red glow. The target name still uses the existing Left/Right-aligned label on the lower sprite edge only when a target exists. Click remains inert, dragging moves one unified control.
- **C3 source changed:** `ui/widgets/TrustStatusWidget.lua` plus two new image assets. No changes to movement, combat, AutoEnable, state definitions, saved positions, Target/Party data trackers, or underlying path default.
- **C3 ZIP:** [`testing-packages/Trust-C3-Book-Crystal-20261012.zip`](testing-packages/Trust-C3-Book-Crystal-20261012.zip). Extract over the installed C2+edge shared-slot build, backup `ui/widgets/TrustStatusWidget.lua` first. Contains 1 Lua, two assets, this document and `INSTALL-C3.txt`.

| C3 test | In-game check | Expected | Result |
| --- | --- | --- | --- |
| C3-01 | Trust stopped | Faint hourglass (no book or crystal) | **PENDING** |
| C3-02 | Trust enabled and idle | Stable translucent book, no crystal | **PENDING** |
| C3-03 | Active main action followed by idle | Crystal fades smoothly above visible book and disappears when idle | **PENDING** |
| C3-04 | Toggle Full/Compact, zone, reload, multiple clients | No extra timer callbacks, stale overlays, crashes or sprite flicker | **PENDING** |
| C3-05 | Solo vs party of 2–6 | Number invisible solo, small upper-left number for 2–6 | **PENDING** |
| C3-06 | Acquire/clear targets, choose Layout Left/Right, drag | Name on correct edge; no duplicate or missing label, one drag surface | **PENDING** |

### CMD — Case-insensitive command words (SOURCE PATCHED, LIVE TEST PENDING)

- **Scope:** In `Trust.lua`, lowercase only the root command category (e.g. `WIDGET`, `FOLLOW`, `PROFILE`, `SET`). In `cylibs/trust/commands/trust_commands.lua`, case-insensitively match a **registered subcommand** (e.g. `STOP`, `CLEAR`, `CREATE`, `START`) and pass its canonical lowercase spelling to the original handler. Unknown first arguments to `default` handlers are **not modified**. Complete multiword registered command names can be matched case-insensitively, without rewriting arbitrary payloads. Full vararg count preserved.
- **Existing support discovered:** `cylibs/util/States.lua:get_state()` already searches state names case-insensitively, and `cylibs/util/Modes.lua:M:set()` already accepts list-mode values case-insensitively. Thus commands like `//trust SET autoengagemode off` should work through the existing mode code without extending scope.
- **Preserve case:** Do not modify player names, free-form item names, profile names being created, path filenames, message payloads or IPC forwarded commands. This batch **does not** implement fuzzy/case-insensitive filesystem path lookup or aliases for party-wide profile maps.
- **CMD source changed:** `Trust.lua`, `cylibs/trust/commands/trust_commands.lua`. No new commands, no change to underlying permission/menu restrictions, job actions, stored profiles or settings.
- **CMD ZIP:** [`testing-packages/Trust-Case-Insensitive-Commands-20261012.zip`](testing-packages/Trust-Case-Insensitive-Commands-20261012.zip). Extract over same baseline, backup both files first; includes this document and `INSTALL-COMMANDS.txt`.

| CMD test | Command and expectation | Result |
| --- | --- | --- |
| CMD-01 | `//trust STOP`, `//trust StArT`, `//trust WIDGET FULL`, `//trust widget COMPACT` work as lowercase | **PENDING** |
| CMD-02 | `//trust FOLLOW STOP`, `//trust follow START`, `//trust PROFILE CREATE ExampleCase` recognize subverb without mangling `ExampleCase` | **PENDING** |
| CMD-03 | `//trust SET autoengagemode off`, `//trust CYCLE AutoEngageMode` and mixed-case enum values behave like canonical settings | **PENDING** |
| CMD-04 | `//trust PATH save MySpecificPath` retains filename casing; `//trust sendall /echo MixedCase` retains forwarded text | **PENDING** |
| CMD-05 | Unknown verbs, menu-open restrictions, autocomplete, IPC messaging and all lower-case commands behave as before | **PENDING** |

**Installation/rollback:** Treat these as independent overlays. Back up the existing Trust folder, apply C3 and/or CMD ZIP(s) to the folder containing `Trust.lua`, preserving paths, reload one client before multiclient. To roll back C3, restore only `ui/widgets/TrustStatusWidget.lua` (unused new PNGs may remain). To roll back CMD, restore only `Trust.lua` and `cylibs/trust/commands/trust_commands.lua`. Keep your prior IPC reload guard.

**Next after C3 and CMD:** 5) inventory of existing action/gambit classes vs exposed menus; 6) safe diagnostics for stuck following/path replay. Party-wide profile aliases explicitly deferred by user.

---

## Previous testing batch — 2026-10-12: IPC follower lookup startup/reload guard

**Heading/status correction (2026-10-12):** ~~Current testing batch — 2026-10-12: IPC follower lookup startup/reload guard (candidate)~~. After installing the guard, the user reported Trust **loading smoothly across multiple clients**. This confirms multi-client startup/reload success at that time. Follow-target fallback during missing-mob IPC, low-resolution behavior and other regression checks remain pending. Keep the original failure report and diagnosis below.

- **User live failure:** Reloading two Trust instances after installing the new compact Target name alignment patch produces `cylibs/Cylibs-Windower-Events.lua:660: attempt to index field 'trust'`. Treat this as an observed runtime exception; no success has been reported yet.
- **Source-confirmed cause:** In the `MobUpdateMessage` IPC handler, if `windower.ffxi.get_mob_by_name()` returns `nil`, the code unconditionally calls `player.trust.main_job:role_with_type('follower')`. During startup/reload, `player = {}` precedes settings and job creation, so `player.trust` or `player.trust.main_job` can be absent while other clients publish IPC messages. The unsafe line is **identical on `main` and the testing branch before this patch**; it is not caused by the compact visual changes.
- **Smallest change:** `cylibs/Cylibs-Windower-Events.lua`: `local main_job = player and player.trust and player.trust.main_job`; `local follower = main_job and main_job:role_with_type("follower")`. Existing follow-target and position-change dispatch logic remains unchanged when roles exist. When they do not, only the optional unavailable-mob follower fallback is skipped until ready. No new logging or globals.
- **Code commit:** [`da9e69f3`](https://github.com/rerorriM-Mirrorer/trust/commit/da9e69f3231ea1444194bba8fbfd35edf38c9258) on `test/compact-trust-title-20261008`. The `main` branch remains unchanged.
- **Minimal patch ZIP:** [`testing-packages/Trust-IPC-Reload-Guard-20261012.zip`](testing-packages/Trust-IPC-Reload-Guard-20261012.zip) with only the changed Lua file, this cumulative TESTING.md and INSTALL-IPC-GUARD.txt. This is an overlay for the **existing** Trust install, not an addon distribution and not a replacement for the prior compact/edge patches.
- **Install:** Back up `cylibs/Cylibs-Windower-Events.lua` on each client. Unzip at Trust addon root, replacing only that code file, and `//lua r trust` on one client, then the next. With multiple instances running simultaneously, stagger reloads and repeat concurrent IPC as a regression test. Restore only this Lua file to roll back.
- **Static verification:** Guarded source code reviewed. No actual Windower 4/FFXI runtime test has been performed by the assistant. **Live test pending.**

| Test ID | Steps | Expected | Live status |
| --- | --- | --- | --- |
| IPC-01 | Reload Trust on one client while another is running and sending follow/position IPC updates. | No `attempt to index field 'trust'` during initialization. | **PENDING** |
| IPC-02 | Reload two Trust instances close together, including another active IPC sender. | Both initialize without a Lua error. | **USER CONFIRMED PARTIAL PASS:** Trust now loads smoothly across multiple clients after installing the guard. Exact simultaneous IPC conditions not separately instrumented. |
| IPC-03 | After full init, follow another player and observe position updates. | Normal follower fallback still works when game mob lookup returns nil. | **PENDING** |
| IPC-04 | Repeat startup on low-resolution client using latest compact Target patch. | Widgets continue to render and update without changing position/saved settings. | **PENDING** |

**Separate startup finding:** The local `ImportAction` invokes `require()` for bundled modules during boot, rather than downloading a remote automation engine. `check_version()` makes a delayed HTTPS manifest request to **check for updates only**. This is independent of the reported IPC exception.

---

## Previous testing batch — 2026-10-12: Compact target-name edge anchoring (candidate)

**Heading correction (2026-10-12):** ~~Current testing batch — 2026-10-12: Compact target-name edge anchoring (candidate)~~. The new IPC startup guard is an independent candidate; all prior Target alignment tests and observations are retained unchanged.

- **User observation:** The centered target name at the bottom edge of the shared 40×40 compact slot was visually unsatisfactory. Requested: **Left** widget-layout preset makes the target name begin at the lower **left edge of the 32×32 sprite**; **Right** preset makes the name end at the lower **right edge** of that sprite. The name is still drawn only when Trust has a target, and the entire compact assembly remains draggable.
- **Source adjustment:** `ui/widgets/TrustStatusWidget.lua` now places the name at x=4 (Left) or uses Windower `texts:right_justified(true)` and compensates for the screen-width coordinate origin to **end at x=36 (Right)**, relative to the 40px hitbox. This uses the native text renderer rather than estimating variable-width glyphs. The additional drag hitbox uses `texts:extents()` for actual rendered width, with a safe estimate as fallback. Both positions are relative to the original 32px artwork inset 4px inside the 40px field; visual verification on clients/fonts remains pending.
- **Layout picker wiring:** `ui/settings/menus/widgets/WidgetSettingsMenuItem.lua` calls `TrustStatusWidget:setCompactAlignment('Left'|'Right')` when the preset is confirmed, and the picker reflects the most recently chosen in-session value instead of always starting at Left. This does **not** change the positions of other widgets beyond existing layout behavior.
- **Initialization:** `ui/TrustWidgets.lua` calls `restoreCompactAlignmentFromPosition()` **after** WidgetManager restores the saved Trust widget X position. Since the existing Layout picker persists only widget X/Y, not a distinct Alignment key, a saved position on the left/right half of the current screen is used to infer the intended side after reload. Dragging does not automatically switch the anchor; explicitly selecting Left/Right does.
- **Files changed vs. preceding C2 ZIP:** `ui/widgets/TrustStatusWidget.lua`, `ui/TrustWidgets.lua`, `ui/settings/menus/widgets/WidgetSettingsMenuItem.lua`, and this cumulative `TESTING.md`. No sprite, path recorder, combat, gambit, or command dispatch modifications. The new book/crystal overlay scheme and hiding party numeral for solo were **discussed proposals, not coded as part of this batch**.
- **Other checks on 2026-10-12:** Previous source patches remain present: old Target rows suppressed in hosted compact mode (earlier duplicate-name issue), click-to-toggle removed, and new recorded paths use `auto_reverse=true`. These are source-confirmed; full multi-client regression and recorded-path replay tests remain pending.
- **Startup finding:** `Trust.lua:loaded()` schedules six actions through `loading/Trust-Init-Include.lua`: import `includes/*` via local `require`, load settings, language, globals, logger and theme. `ImportAction:perform()` schedules sequential `require` calls. Only after initialization does the addon create Trust role instances, widgets, commands, and event handlers. A **separate** delayed updater `check_version()` requests a manifest over HTTPS, checks version, and prints an advisory; it is not a remote code loader. Full startup behavior was inspected from source, not profiled live.
- **Build:** [`testing-packages/Trust-Target-Name-Edge-Alignment-20261012.zip`](testing-packages/Trust-Target-Name-Edge-Alignment-20261012.zip). Incremental patch for the preceding [C2 shared-slot ZIP](testing-packages/Trust-Shared-Compact-Slot-20261010.zip); no separate C1 install required if already on current combined+C2 build. Unmerged testing branch `test/compact-trust-title-20261008`. `main` is unchanged.

### Installation / live checks

Back up the addon and extract into the folder containing `Trust.lua`, overwriting the three specified Lua files while keeping the other C2 files and assets. Reload `//lua r trust`. For rollback, restore just the three files from the preceding C2 version and reload.

| ID | Steps | Expected | Status |
| --- | --- | --- | --- |
| C2-EDGE-01 | Set Widgets → Layout → Left and acquire/change a long Trust target | Name begins at the lower-left of the sprite (x=4), not centered; no extra window | **PENDING** |
| C2-EDGE-02 | Set Widgets → Layout → Right and acquire/change targets | Name **ends** at sprite lower-right (x=36) and visually grows leftward; no screen-edge clipping | **PENDING** |
| C2-EDGE-03 | Drag the shared compact control; click without movement; change target | All layers move as one; clicks don't expand; single name updates without duplicated HP or ghost text | **PENDING** |
| C2-EDGE-04 | Reload on saved right-hand layout and reopen layout picker | Right-hand anchor recovered from saved X; picker displays Right; no unintended repositioning | **PENDING** |
| C2-EDGE-05 | Switch Full ↔ Compact with commands; test small/high resolutions and multiclient | Original Full widget contents still work and compact has no extra independent Party/Target window | **PENDING** |

**Known uncertainty:** Right-side text uses Windower's native right justification, but has not yet been visually tested. The old preset doesn't retain a durable separate `Alignment` setting; the saved X position infers the side on reload. Treat any font-specific discrepancy or nonstandard screen placement as a test result; do not silently mark it passed.

---

## Previous testing batch — 2026-10-10: Shared single-slot compact control (candidate)

**Heading correction (2026-10-12):** ~~Current testing batch — 2026-10-10: Shared single-slot compact control (candidate)~~. This layout remains the base; only the target-name alignment is superseded. Prior C2 observations and pending tests below are historical, not erased.

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

**2026-10-12 lookup/menu:** User likes the now case-insensitive command execution and compact icons; awaiting live Active crystal and Target label observations. New lookup casefold patch prepared, plus opt-in menu CPU timing to investigate first-open lazy settings/gambit menus and per-open view reconstruction. Neither new patch live-tested yet. Previous confirmed IPC multi-client reload remains passed.


**2026-10-12 C3/CMD:** User confirmed smoother Trust loads across multiple clients after the IPC fix. Separate source commits for original book/crystal sprite pulse + solo count hidden and case-insensitive registered commands. Both **await FFXI visual/command tests**. Next priorities: gambit/action menu audit, then path recovery; party-wide profile aliases deferred.


**2026-10-12 IPC reload guard:** User reproduced `Cylibs-Windower-Events.lua:660` nil `player.trust` when reloading two clients. Source bug existed unchanged on main. Guard added in testing branch commit `da9e69f3`; one-file install overlay planned. **Live retest pending.**


**2026-10-12 edge alignment:** User requested compact Target name left/right anchored to the icon artwork according to Widgets → Layout Left/Right. Three targeted Lua changes committed, archive planned. Previous fixes for click-to-expand, duplicate target row and new path auto-reverse remain in source. **Live visual confirmation pending.**


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
