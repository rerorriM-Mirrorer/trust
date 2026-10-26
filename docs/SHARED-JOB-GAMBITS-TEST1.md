# Shared Job gambits — Test 1

Author A. October 26, 2026. Trust test/starter-defaults-20261023, starting
checkpoint 9735e9665b076c375b2ec2b89b055a57f5f2bb34. Personal modifications.

## Install

This is a Trust-only patch over the integrated Movement Test 1 installation.
Back up Trust, unload it on participating clients, merge this package's trust
folder into addons/trust, and reload Trust. No nested trust/trust folder.
Keep data and existing factory job files. No xivcrossbar/AHK replacement is
required. The user confirmed the previous full combined package fixed the
AHK companion mismatch and that the Condensed menu/movement following worked.

The patch intentionally omits settings/default/JOB.lua: existing shared or
manual factory job edits are not overwritten by this delivery. It includes
all 22 factory *mode* files to set the new death default. Saved character mode
profiles remain authoritative; an existing saved Auto death choice stays Auto.
For such a profile select AutoUnloadOnDeathMode Disable in the main job Modes
editor and save. Disable stops Trust on death without unloading it; restart
Trust behavior when appropriate after raising. Off and Auto remain available.

## Job and Custom

Under either main or subjob Settings > Gambits, the named Job section is first,
then Custom, then Reactions. Job opens the full editor (Add/Browse, Edit,
conditions, Remove, Copy, order, Toggle and Reset), with a shared title and
scope description. Custom stays character/job/profile-specific; its description
identifies that scope. Runtime priority stays Custom before Job.

Job edits save to settings/default/JOB.lua, specifically
Default.GambitSettings.Default, for all characters and profiles using this
installation and that job. Editing the job while it is your subjob changes the
same shared job list used when that job is main. This does not merge main and
subjob runners, deduplicate gambits or change their modes/queue ownership.
Custom rules and other factory settings are untouched.

The current client's job profiles refresh immediately after a successful save.
Other running clients reload Trust to adopt it. Separate PCs need the updated
factory file copied over. Older per-character Default lists can still exist as
legacy cached copies; startup's existing migration refreshes those from the
factory list. This patch changes the editor's authority/save destination, not
that legacy serialization format.

Job Toggle is now permanent. Existing editor save conventions still apply:
actions such as Add/Toggle/Remove save immediately; value/condition editors use
their existing Confirm/exit-save behavior. No new blanket autosave behavior is
introduced. Reset restores the original factory Job list embedded in the file
on the first shared save. It affects everyone using that installation.

## Shared-file writes

The writer retains the original factory source verbatim inside a small Lua
wrapper and writes only a serialized replacement Job list after it. It does
not serialize the entire job table, losing comments or other constructor code.
Subsequent edits replace that one generated list without nesting wrappers.

The previous file is backed up beside it as JOB.lua.job-gambits.bak before
each successful replacement attempt. Saves validate generated Lua, verify stage
bytes, and use a Windows replacement with an exclusive writer handle. A busy
file or stale editor is refused. A failed stage/replacement leaves the active
factory file intact; failures are reported in chat. Failed drafts do not become
live rules. Job > Reload discards the draft and displays current shared rules;
then reapply the intended edit.
The lock sidecar may remain on disk; its native handle, not its existence,
determines ownership and is released when saving finishes or the process exits.

These writes need Windower's Windows LuaJIT FFI support. If unavailable or the
factory directory is not writable, saving reports failure instead of falling
back to a character save. Win32 native execution still needs in-game testing.

Factory files are now user-editable shared settings. Preserve them and their
backups when applying future full addon distributions; blindly replacing a
factory job file replaces its shared edits. This patch avoids that overwrite.
To restore a previous shared list, unload clients, restore its .job-gambits.bak
file to JOB.lua, and reload. A backup is the previous save, not an unlimited
history. Back up the full folder before installing or experimenting.

## Menu cleanup and deferred work

Food, Pulling and the full Modes entry are omitted from the subjob Settings
menu in both Full and Condensed layouts. These entries remain under the main
job. If the only active pulling role belongs to the subjob, main Pulling routes
to that role's existing settings/profile; pulling storage is not made global.
Relevant smaller mode editors inside functional features remain available.

FlankMode is unchanged, including its current inactive implementation.
AutoDisengage and movement/pathing are unchanged. Investigating their interaction
with Pathfinder is deferred work; no Pathfinder integration is included here.

## Verification and live check

Sixteen Trust suites pass under Lua 5.4 with temporary Windower syntax
normalization. New tests cover shared file roundtrip, original source/other
settings preservation, local Custom isolation, separate profile objects,
backup, busy/stale rejection, failed replacement, malformed Lua, fresh reads,
Win32 backend flags/handle cleanup via mocked API, and actual Job-menu routing.
Menu tests cover both layouts, main-only entries and a subjob-owned puller.
All 22 factory death choices are checked. Prior movement/controller/menu,
quiet-feedback, database and command regressions pass. These are not native
Windows/Windower execution results.

Live acceptance: toggle one harmless Job rule, reload a second character using
that job and confirm the change; confirm a Custom rule remains local. Test a
subjob edit, reload, saved mode choices, title/scope, navigation and normal
movement follow. Try two editors opened before either saves: the second save
must report stale state, then Reload must allow a deliberate fresh edit.
No actual death is required: inspect the mode/profile setting to verify Disable.
