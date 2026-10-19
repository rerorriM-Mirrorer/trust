# Party songs in custom gambits

Beneficial Bard songs are now selectable in the ordinary gambit ability picker.
The picker still starts from the job's known, level-appropriate spell list and
uses each spell's normal target metadata. Enemy songs such as Requiem remain in
Enemy; beneficial songs with a Self target appear under Self. Trust summoning
spells retain the existing exclusion. Spell casting, job/level checks, recasts,
song tracking and the dedicated Singer role use their existing behavior.

## Make a simple party-song gambit

1. Open Gambits, choose Add, then Self, and select a song you have learned and
   can currently cast. A beneficial song cast on yourself affects nearby party
   members through its normal area. Check that they are in range.
2. Edit that gambit's Conditions. Add a Self condition described as
   "Has one or more songs." Edit its Song Names to contain the exact song you
   selected and Number Required to 1. Confirm the condition, then use Invert.
   The resulting rule means "Self does not have this song -> sing it on Self."
3. Put the song rule above unconditional offensive gambits. The gambiter checks
   rules in order and selects the first satisfied rule, so an earlier Requiem
   with no conditions can keep later songs from running while an enemy exists.
4. Add one other song with the same kind of missing-song condition. Start with
   a pair your current song capacity supports; if you schedule more songs than
   can coexist, they can repeatedly replace each other.
5. Keep AutoGambitMode Auto. For a clean custom-gambit trial, set AutoSongMode Off
   so the dedicated automatic song set does not compete with your custom list:
   `//trust set AutoSongMode Off`. This mode change saves when command autosave
   is On. Restore AutoSongMode Auto when returning to the dedicated Songs setup.

The song-presence condition uses existing song tracking. Check that it settles
after the first casts and notices song expiry. Tracking across reload/zone changes
also needs live verification for songs outside the configured dedicated song set.
If a song keeps repeating, disable that rule while checking its condition.

The picker does not add a missing-song condition automatically. Add it yourself
before leaving an enabled song rule running. General gambit creation/conditions
still use their explicit confirmation workflow.

## Dedicated Songs setup

The Songs menu remains an alternative to custom gambits for maintaining a set.
Choose songs you can actually cast, a number appropriate to your equipment, and
the intended SongSet. High-level defaults such as Honor March and Valor Minuet IV/V
are not usable substitutes for learned low-level songs. This patch does not rewrite
existing song sets, personal profiles or the automatic Singer configuration.

Self is the target for normal party-area singing. Casting a beneficial song
directly on another character is the separate Pianissimo path and is not enabled
or added to Ally by this change. Self checks also do not detect a party member who
missed the area while the singer still has the song; the dedicated song setup
has separate party upkeep/Pianissimo options for that behavior.

## Install and check

Unload Trust and back up your current folder/data. Merge the provided full
`trust/` folder into `Windower/addons/trust/`, preserving `data/`; avoid nesting
`trust/trust`. Reload one Bard client. This batch changes only
`ui/settings/menus/gambits/GambitEditorStyle.lua` at runtime, so existing compatible
Test 5 users may instead copy just that file and reload.

Open Add -> Self: learned beneficial songs should now be listed. Add -> Enemy
should still offer learned Requiem. Verify one guarded song gambit casts, reaches
nearby party members, stops while present and resumes after expiry. Check a pair
of songs and their ordering; watch other available spell/job/weapon actions too.
Do not expect the picker to offer songs absent from the current job's spell list.
Native Windower/FFXI verification remains pending.

Rollback: unload Trust and restore the previous GambitEditorStyle.lua. If you
changed gambits, song modes or profiles while testing, restore those separately
from your data backup or edit them back through Trust.
