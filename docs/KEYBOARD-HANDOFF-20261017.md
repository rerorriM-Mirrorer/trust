# Trust / XIVCrossbar keyboard handoff — October 17, 2026

Author: A. Intended split agreed with the user: XIVCrossbar/AHK owns producing
real key events in the appropriate controller context; Trust owns receiving them
as menu directions and blocking native gameplay input while its menus are open.
The end-to-end path must still be tested on Windows/FFXI.

## Observed source

XIVCrossbar `development/directlink` at `a9b2486937ec3bbeacd545ec505d9920e0381f75`:
`controller_transport.lua:gameplay_key` maps ordinary D-pad to I/J/K/L under the
IJKL setting; `xivcrossbar.lua:message_button` issues Windower `setkey` down/up.
The DirectLink AHK route supplies logical controller signals. By contrast,
`personal_controls.ahk` sends actual arrows for R1+D-pad via SendEvent.
This source observation is not proof of the exact installed PC version.

Windower documents modifiers and chat state prefixes at
https://docs.windower.net/commands/input/ . It documents `setkey` as setting a key
state; the documentation does not establish whether that route invokes keyboard
callbacks or native binding interception. Do not claim it does or does not based
only on the symptoms.

## Producer requirements for the separate XIVCrossbar conversation

- A real AHK IJKL route should replace the Lua `setkey` emission for the same
  owned D-pad edge, avoiding duplicate native input.
- Preserve Lua's current context decisions for gameplay, its own menus, text
  editing, trigger chords, native-menu guards and controller ownership. AHK
  needs an agreed context signal if it becomes the final sender; raw controller
  state alone cannot distinguish addon UI/text contexts.
- Use paired key-down/up events, release on context change/focus loss/restart,
  and preserve physical key ownership. Verify held-repeat behavior in Trust.
- Keep the existing R1+D-pad arrow route unless that conversation explicitly
  changes it. Coordinate against its current head; this Trust patch changes no
  XIVCrossbar or AHK source.

## Consumer behavior in Trust Test 2

I/J/K/L map to Up/Left/Down/Right in an active Trust menu. The keyboard callback
consumes owned down/up edges. Temporary chat-closed native block bindings apply
to arrows/Enter and unmodified/Shift IJKL; IJKL preference Off removes only the
letter blocks. Chat keeps typing. Focused Trust text fields retain literal letters
and the existing broad block; departure restores menu binds. Menu close removes
menu binds so gameplay can resume. Other modified letter shortcuts are not remapped.

First test physical keys, then real AHK keys, checking both UI navigation and
lack of native targeting. Include holds, text fields and menu close while held.
Test 1's adapter-only mocked input tests were insufficient for this actual route.
