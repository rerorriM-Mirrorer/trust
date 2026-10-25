# Integrated movement — Send/Ready Test 1

Author A. October 25, 2026. Ported behavior from TrustMovement 0.1.1 RC3
Companion. Personal xivcrossbar sender based on development/directlink
7959a99d9871b00e18bd3faaf4b3946c85595fc1. Public beta unchanged.

## Install

Back up the installed Trust and xivcrossbar folders. On all participating
clients unload the separate trustmovement addon and remove it from autoload;
do not run both receivers. Stop the shared wrapper with //xb controller stop,
unload Trust, merge this package's trust and xivcrossbar folders into addons,
retaining existing data and xivcrossbar images. Load Trust, reload xivcrossbar
on participating clients and start its shared wrapper once. The Trust payload
is complete; xivcrossbar is cumulative personal code/docs, requiring the
existing personal DirectLink artwork/install. It is not the separate public beta.

The package also includes previously queued Trust defaults, Full/Condensed
menus, action-first gambit descriptions and character-wide follow/Alter Ego
modes. Existing data is not included or replaced. Full/Condensed changes menu
navigation only, not mode ownership. First character-mode adoption and job
switch/reload checks remain part of native acceptance.

## Use

Main menu > Movement: First movement signal Send (default) or Ready;
enabled On and quiet feedback On by default. Save changes using normal menu
autosave/Save. Movement > Status reports policy, received, accepted, ignored,
current block and last outcome. Switch to another FFXI client and back to rearm.

AHK observes joystick magnitude >= 0.24. One signal per observed FFXI client
change; returning from desktop to the same client, releasing buttons, neutral
or controller reconnection do not rearm it. Send consumes that first movement
without waiting for readiness, including blocked menus/chat; Trust immediately
accepts or ignores. Closing a blocked menu does not replay the signal. Ready
waits for a fresh ready receiver and allowed personal context while movement
continues. Policy updates are polled; switch clients after selecting a policy.

The physical transport remains RC3's private NOCONVERT key (AHK vk1Dsc07B,
DIK 0x7B). This migration does not change it to the button message protocol.
The integrated receiver publishes policy/readiness in data/movement/NAME.lease.
The sender prefers that fresh Trust record; a legacy RC3 record remains a
Ready-only fallback. With no receiver record it defaults to Send, so no receiver
means no Trust action. No queued/deferred takeover or retry is implemented.

On acceptance Trust calls Follow me, then Assist me internally, with RC3 quiet
feedback propagation. This clears the local follow target and sends existing
follow/assist instructions over Trust IPC to the other clients. IpcMode must be
All or Send. This is not a new Trust Start/Stop or path-stop policy; those were
not RC3's actions. The other clients must have Trust loaded and permit reception;
accepted means requests issued, not all remote clients acknowledged execution.

Receiver guards retain RC3 focus, login, chat input, native menu, character and
cutscene checks, and additionally refuse Trust's own menu and incompatible IPC.
Disabled receivers consume/ignore the special key. Held downs are debounced;
focus changes, job replacement and unload reset/clean the receiver and its file.

## Diagnostics and verification

Trust Movement > Status counters are per runtime receiver (reset on job reload).
The wrapper's data/trust-movement.log appends each sent signal with policy and
sender count; controller-status.ini adds movement_version 0.2.0-trust1,
movement_policy, movement_sent and movement_reason. Controls remains
9.19-lifecycle1; movement has its own version field.

Fourteen Trust suites passed with mocked Windower/UI/disk APIs under Lua 5.4,
including actual root receiver wiring, quiet action order, immediate rejection,
debounce, no retry, IPC/menu guards, replacement and previous menu/mode/database
regressions. All nine actual-AHK-function JS suites passed, including movement
Send/Ready and focus-latch decisions; lexical/include checks passed. Changed Lua
parsing uses temporary normalization of Windower string-method syntax. These
are not native Windows/AHK/Windower execution results.

Live check: two clients; Send and Ready each once, blocked first movement,
follow/assist recipients, quiet feedback, job changes/reload, menu controller
and no effect from continued joystick movement after the first accepted signal.
Rollback: restore backed-up code, disable integrated Movement or unload Trust,
then restore/load RC3 and its matching sender. Do not enable both receivers.
