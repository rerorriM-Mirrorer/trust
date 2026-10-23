# Notes for later review — October 22, 2026

Recorded from the user's requests; these are proposals, not implemented by the
controller-menu test.

- Pull target shortcut such as `//trust pull add <target name>` or
  `//trust pulling add <target name>`: add to the pull list and enable Auto pulling.
  Review useful bare `//trust pull` behavior and existing enable/disable commands.
- A companion remove operation; determine the intended target/list when revisited.
- `//trust distance <x>`: select Distance combat behavior and move to that distance
  immediately. Requested default pull distance: 30 yalms.
- Explain which pulling/combat settings and gambits belong to the main job,
  subjob, named settings set or mode profile, and how those roles combine.
- Move Settings above Status on the main menu. Review each submenu for Modes
  first, shorter navigation, useful initial focus and a selected top option in
  particular deepest menus, retaining Escape/save behavior.
- `//trust buff add ...` should enable Auto buffing after a successful addition.
- Review `//trust follow` as a shorthand for `//trust follow me` and further
  consistent command shortcuts, including ambiguity with current behavior.
- Explain menu discard and save trace; retain useful `//trust mount all` discovery.
- Separate reported defects awaiting patches: empty active skill list at
  skillchainer.lua line 317; shooter clock mismatch and TP-ceiling behavior.

The current authorized implementation is controller navigation. Menu ordering,
command semantics, job defaults and the separate battle-role defects are deferred.
