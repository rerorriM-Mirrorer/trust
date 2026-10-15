# Trust 17.7.3 — Manual Override and menu interaction audit (2026-10-15)

**Status:** Read-only source analysis and design. No implementation, profiling results, or live manual-control tests. Working branch `test/compact-trust-title-20261008`; `main` protected. Audit references the cumulative Trust 17.7.3 testing branch and the separate `rerorriM-Mirrorer/xivcrossbar` fork (default `master`).

## Priorities

User confirms **active crystal pulse and target-name placement work well in-game**. Do not change these widget effects without a new request. Highest next priority is **AUTO/MANUAL ownership of control**, with menu commands and autosave as independent later changes. The separate planned waypoint/pathing addon should consume a shared control handover rather than reimplement its own input detection.

## Source-verified menu behavior

- `Trust.lua` `addon_command()`: when `hud.trustMenu:isVisible()`, blocks every top-level category **except** `assist`, `send`, `sendall`, `widget`. Consequently `menu`, `stop`, `start`, `toggle`, `status`, `set`, `cycle`, `load`, `save` and `reload` are blocked. This is a coarse category allowlist, **not** a safety proof: `send` and `sendall` forward arbitrary Windower commands through IPC, potentially changing another client's menu or modes.
- `commands/MenuCommands.lua`: `//trust menu` defers opening using `coroutine.schedule(..., 0.2)`. No inline explanation for *why*. A plausible purpose is postponing focus/view mutation until after input handling. **Speculation**, not confirmed provenance. The delay is distinguishable from genuine menu CPU/render stalls.
- `ui/TrustHud.lua:toggleMenu()`: calls `closeAll()`, builds the root if necessary, then `showMenu()`. Despite its name, this method **closes and opens**, not a direct close-only toggle. `closeAllMenus()` already exists and can be used by an explicit idempotent close command.
- `cylibs/ui/menu/menu.lua`: Esc backs one menu level; at root Esc dismisses. Left/right may navigate pages or shift focus; Enter selects. While the view stack is active, binds up/down/left/right/enter/numpadenter to `block`; it unbinds while chat input opens and rebinds when chat closes. View/focus cleanup occurs via `closeAll()`. A direct close needs to handle in-progress text/focus cleanly.
- `ui/settings/editors/config/ConfigEditor.lua`: typically accumulates current cell values as **draft state**, then `onConfirmClick()` validates, applies to `configSettings`, notifies observers, and invokes `trustSettings:saveSettings(true)` where available. Generic labels `Confirm`, `Save`, and even `Search` share this handler; `Reset` is UI reload, not necessarily a persisted reset. Some nested multi-pickers change nested objects before an outer Confirm, and specialized menus call `saveSettings(true)` themselves.
- `ui/settings/menus/ModesMenuItem.lua` explicitly distinguishes **Confirm = temporary modes only until reload**, vs **Save = persist current modes to profile** through `TrustModeSettings:saveSettings(state.TrustMode.value)`. `ModeConfigEditor` applies changes through `handle_set` on its config-confirm event, while saving is separate. Thus the user's two-step impression has a real code-level basis. Elsewhere Save and Confirm can behave identically; don't impose global autosave blindly.
- `TrustModeSettings.lua` persists mode values to `data/modes/<job>_<character>.lua` for a named `TrustMode`; `TrustSettings.lua` separately persists job settings to `data/<job>_<character>.lua`. Profiles select named main-job, sub-job and weapon-skill settings; some sets may be shared across profiles. Verify whether edits should affect a shared named settings set or produce an independent profile copy **before** promising profile isolation.
- `ui/settings/menus/gambits/GambitSettingsMenuItem.lua` contains explicit add/edit/remove/toggle/move/reset handlers and nested Confirm flows. Treat as a separate persistence category. `ui/settings/editors/GambitSettingsEditor.lua` calls `onConfirmClick(true)` on focus regain, so there are implicit in-memory commits that are not file saves. Test carefully before refactoring.

## Proposed menu policy and tests

Add command metadata about effects rather than allowing/denying a handful of category strings: read-only, automation/control, UI navigation, settings mutation, profile/role reload, and remote dispatch. Permit safe read-only/status/help and `menu close`; permit reliable `manual`/emergency pause while a menu is open. Treat mode/profile mutation, reload, shortcut/widget layout changes, and arbitrary IPC as dependent on current editor focus and pending drafts. `send`/`sendall` must not bypass target-client guards.

Suggested UX changes, separately testable:
1. `//trust menu close` executes synchronously (or safe next-frame), always dismisses entire hierarchy, cleans focus, leaves menu closed. Root Esc still exits, submenu Esc still backs.
2. Change ordinary settings to validate/apply on meaningful edit completion and automatically persist to the correct currently selected named set; optional short debounce reduces file writes from held sliders or repeated picker changes. Never persist invalid/half-entered text. A pending save must be flushed/cancelled correctly on profile change, menu close, zone, and reload. Show brief saved/unsaved/error state; no chat spam.
3. Keep destructive operations (Delete, Reset, Import, profile creation, gambit structural edits as appropriate) explicitly confirmed; distinguish changing tactical **runtime modes** from persisting them into a profile.
4. Establish exact input-focus policies for chat, menu, text field, controller, and manual takeover.
5. Measure first/cached menu CPU with `//trust menuperf on`, plus actual frame timing if needed; test removing `0.2` only after demonstrating correct lifecycle.

Minimal regression matrix: Esc from child/root, immediate close while text editor has focus, a dirty slider/picker, Save vs Confirm in Modes, profile switch while dirty, read-only command while menu open, remote IPC attempting profile/reload while menu open, Trust stop/manual despite menu focus, repeated open/close without stuck binds.

## Manual Override — source constraints

- `Trust.lua` holds `addon_enabled = ValueRelay.new(false)`. When false, its change callback disables the **main** `action_queue` (clearing pending/current actions). Main job/subjob `tic` is skipped while disabled. `//trust stop` is **not** an all-movement suspension.
- `cylibs/trust/roles/follower.lua` owns separate `walk_action_queue`. `stop_following()` disables it, but status/zone changes and follow-target events can restart it. A central suspension guard is needed at **all** automatic restart entry points, not merely on one command.
- `cylibs/trust/roles/pather.lua` owns `PathTarget` and periodic waypoint timer (`0.05` sec nominal); `stop(false)` pauses following but does not pause that independent timer. Preserve path index, forward/reverse direction, assigned player follow target and intended tactic when manual control begins; suspend the timers/events that would requeue movement.
- `cylibs/battle/approach.lua` sequences RunTo/Wait/Engage/`FollowAction`; `FollowAction` issues native `input /follow <t>`. Cancel native follow (`windower.ffxi.follow()`) during manual takeover without automatically disengaging combat. RunTo and RunToLocation use `windower.ffxi.run(...)` and may reassert movement in prerender callbacks.
- `cylibs/actions/sequence.lua:cancel()` cancels queued children **but does not explicitly cancel its currently performing `self.current_action`**. Its current child must be cancelled and any prerender listeners/timers disposed safely without racing `ActionQueue:handle_action_completed()`. Instrument and fix in a focused regression test, not as a speculative blanket rewrite.
- `cylibs/trust/roles/combat_mode.lua:face_target()` directly rotates outside the queue but checks `addon_enabled`. Other off-queue event handlers should be audited before claiming *all* automated actions stop.
- Existing `XIVCrossbar` DirectInput bridge runs `ffxi_directinput.ahk`; it already checks `WinActive("ahk_class FFXiClass")` and polls gamepad **POV/buttons**, but the observed file does **not** currently detect analog-stick axes. Windower `keyboard` events alone do not demonstrate native analog detection. Add opt-in focused-client stick-axis diagnostics with deadzone/hysteresis, and verify ownership of forwarded command before binding takeover.

## Proposed control state and transition contracts

State per character/client: `AUTO` (automation owns actions), `MANUAL` (physical player owns actions), optional `HOLD` (explicit parking that switch-away must not resume). Do not conflate `MANUAL` with permanent `//trust stop` or change tactical modes merely to indicate ownership.

**Enter MANUAL, once on deliberate focused-client directional input:**
1. Set ownership flag synchronously; gate future automated movement/action dispatch and auto-restart callbacks.
2. Disable/cancel main action queue **and** follower queue; cancel active sequence child and its effects.
3. Suspend path timer and any relevant follow/zone restart; cancel native `/follow`; cease Windower-issued run/turn commands.
4. Leave the character's engaged combat state and tactical/profile settings intact. Avoid calling `run(false)` repeatedly after the player starts moving; it may suppress manual movement.
5. Report one quiet state change, with an optional compact indicator and `status`.

**Return to AUTO explicitly:** Validate stored follow target, path, zone and current combat target. Restore eligible roles/actions under current modes; never blindly replay stale commands or attacks. If no valid objective exists, stay idle and report why.

Optional `AutoOnSwitchAway` later, per character, disabled by default. Trigger only from the **explicit window-switch macro**, not generic focus loss. Must respect HOLD, chat/menu/cutscene state, client identity, input release, and partial success across four-to-six clients.

The external input bridge should report only *physical user intention* to the correct local Trust integration; do not infer takeover from movement packets/position because Trust itself causes movement. Distinguish generated keystrokes from deliberate input.

## First prototype (before generalized controller overhaul)

1. **Instrumentation only:** one low-level physical stick threshold event in focused FFXI client, with no Trust changes; verify which client reports when switching, neutral input handling, accidental triggers.
2. **Explicit handover without controller:** `//trust manual`, `//trust auto`, `//trust control status` on one client; a single control gate suspends all specified controllers. Test player follow, native Approach, path, fight while engaged, menu open, zoning. Initial smoke test with no new path addon.
3. Integrate input bridge with takeover; confirm first physical movement yields control and the user can continue moving without stop spam.
4. Extend targeted IPC and optional switch-away return; never enable automatically until explicit handover passes.
5. Integrate new standalone path/follower addon through ownership protocol rather than reusing Trust's route player.

**Live acceptance tests:** manual input during Approach cancels native /follow; during player-follow pauses with target retained; during path stops movement and timer with waypoint retained; engagement stays engaged; AUTO validates and safely resumes; one client MANUAL while others AUTO; menu open cannot prevent emergency takeover; switch-away respects HOLD and preference; keyboard and PS5 analog test separately. No code for these is implemented yet.

## Scope note

These observations warrant targeted tests; they do not establish that every command conflicts with every editor or that the 0.2-second delay is unnecessary. Protect the test branch, preserve user data, use cumulative overlays and append TESTING.md on code deliveries.
