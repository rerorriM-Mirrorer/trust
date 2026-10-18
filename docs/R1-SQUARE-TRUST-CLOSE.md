# R1 + Square — controller handoff for Trust close

A, October 17, 2026. Trust command available: `//trust menu close`.
It closes all Trust menu levels after committing eligible valid edits. Invalid
edits retain the menu with an error. `//trust menu discard` is a separate explicit
choice and should not be silently substituted for a normal close.

Observed source in `rerorriM-Mirrorer/xivcrossbar`, `development/directlink`:
`personal_controls.ahk` blob `8cf181f068ad4c32ca3fd83b12e607b0df248d10`.
The R1 branch maps normalized 5/7/8 to Enter/Escape/Ctrl+NumpadAdd; 6 (Square)
is not assigned there. `controller_transport.lua` blob
`a8bb0fa7824ba54e20c35533352c7ac56e6a8ef5` maps ordinary Square to active-window
Numpad+, so the new chord must consume the ordinary button path.

Requested implementation in the active XIVCrossbar/controller work:

- On a fresh Square press while R1 is held, under the same valid focused-client
  context as existing R1 menu navigation, send Trust `menu close` exactly once.
- Consume Square until release, suppress its ordinary active-window output and
  the bare-R1 release action. Do not send repeated Esc presses.
- Preserve trigger/L1/other reserved chord ownership, text/menu context guards,
  physical keyboard ownership and client identity. Use the established command
  transport; do not type a command into game chat as synthetic text.
- Verify held-button/context/focus transitions. A close must never reopen Trust.
- Scope is Trust menus. NPC dialogue and XIVCrossbar's own menus have separate
  ownership and should not be dismissed as an unintended side effect.

This Trust package does not change or overwrite any AHK/XIVCrossbar file. The
other conversation owns that shared active source. Existing Ctrl+NumpadAdd still
opens Trust through its current path; R1 + Square is the proposed explicit close.
