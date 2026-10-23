# Trust controller menu Test 1

Author A. Paired with xivcrossbar directlink1-trustmenu1 and shared Controls
9.15-trustmenu1. Native Windows/Windower/FFXI acceptance is pending.

## Install

Back up both installed addon folders. Unload Trust and xivcrossbar on every
client and stop the shared AHK wrapper. Merge the package's trust and xivcrossbar
folders into Windower/addons, preserving existing data, bindings and artwork.
Trust is a full runtime payload. xivcrossbar is a cumulative code-only payload
for an existing DirectLink Cleanup 1 or newer installation; keep its images.
Load both on one client first and start the shared wrapper once with neutral
controls. This paired update needs both Lua reloads and the AHK restart.

Use the existing PS5 Extended/profile x message route. Check
`//xb controller status` for Controls 9.15-trustmenu1 and the message route.
`//trust menu status` identifies Menu controller Test 1 and reports accepted and
rejected direct actions. Other controller profiles retain their existing route.

## Controls

Open with `//trust menu open` or the existing configured controller shortcut.
While the menu owns focus, ordinary D-pad presses navigate directly, without
holding the navigation-bank chord. Configured Confirm/Back buttons work; the
usual defaults are Cross/Circle. R1 + Square closes all levels through Trust's
existing save/validation path. An invalid draft can keep the menu open.

D-pad repeat begins after 0.4 seconds and repeats every 0.1 seconds. Confirm,
Back and Close fire once per press. A held direction does not carry into a new
focused control. Release and press again after entering another control.
Other face-button presses are consumed while Trust owns the menu. Existing
Share/Options behavior is retained; this trial does not assign them Trust actions.

Keyboard text entry remains available. Controller directions are suppressed in
text fields; Confirm/Back still reach the field. Chat and background-client
contexts suppress direct menu actions. Trust does not need to be automating
combat for its menu to accept controller navigation.

## Live checks

1. Open the main menu and tap each direction once. Check Trust moves once and
   the game target/native menu does not move underneath it.
2. Hold a direction, release it, and check repeat stops. Enter a submenu or
   slider while holding a direction; release/repress before navigating there.
3. Test a toggle, a slider, a picker and a deep gambit editor. Confirm/Back
   should follow their ordinary keyboard behavior. Check cursor/focus placement.
4. Back out of an eligible settings editor and reopen it. Controller navigation
   preserves the existing autosave policy; the previously reported Modes
   save-on-exit failure remains unresolved and is not claimed fixed here.
5. Hold R1 across a submenu change, then press Square. Check all Trust levels
   close once and no native cancel/target action occurs. Try an invalid draft.
6. Open a text field and type physical IJKL. Test controller Confirm and Back.
   Open chat while the menu is visible: controller presses must not navigate it.
7. Switch client focus during a held direction. Only the foreground client may
   respond; no old presses may replay on returning. Repeat after reloading Trust,
   reloading xivcrossbar, restarting AHK and closing Trust with a command.
8. With Trust closed, check normal target selection, ordinary crossbar actions,
   the configured R1 banks and a native menu. Check the other clients afterward.

For a report, include both status outputs, the exact control/menu tested, whether
a button was held, and any console error. Status counters reset on addon reload.
The existing controller trace can still diagnose the shared AHK stream.

`//trust menu discard` closes without applying the current editor draft; it does
not undo changes already saved. `//trust menu trace on` enables the separate
120-event save trace; `//trust menu trace dump` writes its current buffer.

## Implementation and limits

Trust publishes a bounded character/server-specific context lease under its
own data folder. The existing xivcrossbar message receiver consumes physical
navigation and sends logical actions to Trust's internal addon-command handler.
Trust checks its current focus/session, sequence and a 0.35-second age limit
before delivering both edges to the original focused control. No native arrow,
IJKL, Enter or Escape is generated for these menu actions. The AHK Trust context
suppresses its ordinary targeting/touch/stick-click shortcuts.

Sessions change on focus/context transitions. Duplicate, old and queued stale
actions are rejected, including old actions after a reload. Complete cached
leases tolerate a short file-write gap only until their original expiry. The
lease is ephemeral state, not a saved preference. This does not add a second
AHK wrapper or an IPC broadcast to other characters. Direct delivery is queued
locally and not transactional; an expired action can be dropped rather than
executed late. Live latency and navigation feel still need testing.

Rollback: restore both backed-up addon code versions and restart the previous
shared wrapper. No user settings are migrated by the Trust adapter.
