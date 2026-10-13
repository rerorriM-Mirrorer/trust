# Trust gambit capability audit — 2026-10-13

**Scope:** Source-only inventory of the `test/compact-trust-title-20261008` branch of rerorriM-Mirrorer/trust, focusing on low-level and free-trial character development. **No combat code modified; no live gambit tests implied.** Main stays unchanged. This document records *what source exists*, *what menus expose*, *what can be safely planned*, and *what needs verification*.

## Executive findings

1. The repository contains **93 Lua condition modules** under `cylibs/conditions/`, **41 low-level action modules** under `cylibs/actions/`, **50 battle modules** under `cylibs/battle/` and **28 Trust role modules** under `cylibs/trust/roles/`. These counts are source files, **not** independent, usable gambit actions or promises of functional behavior.
2. The **Add Condition** menu explicitly maps **53 condition file types** in `ui/settings/menus/gambits/GambitConditionSettingsMenuItem.lua:getEditableConditionClasses()`. **40 of the 93** aren't offered directly: **11** are imported by the startup conditions include, and **29** aren't imported by that include (some may be imported directly elsewhere). Not all hidden classes should be added: some are framework primitives, internal eligibility checks, event-oriented checks, or missing editor/serialization integration.
3. Gambit actions are **not equivalent** to `cylibs/actions` classes. The user-facing action chooser in `ui/settings/menus/gambits/GambitEditorStyle.lua:getAbilitiesForTargets()` enumerates job spells, available JAs, available weapon skills, seven predefined enemy actions (Approach, RangedAttack, TurnAround, TurnToFace, RunAway, RunTo, Engage), and three predefined self actions (UseItem, SetMode, Command). The much larger `cylibs/actions/` directory mostly implements execution primitives behind these.
4. The normal menu already permits **multiple AND conditions**, **NOT** via Invert, **Self/Ally/Enemy condition targets** as allowed by each class, **rule ordering** (Move Up/Down), **enable/disable**, **copy**, and per-rule editing. The runtime additionally recognizes a **current FFXI target** target type `t`, ally priority comparators, and `ConditionalCondition` AND/OR expressions, but the standard gambit editor does not provide a general OR/group builder or ally-priority selector.
5. Low-level support exists at the **ability discovery** layer: `Job:get_spells()` consults `SpellList:getKnownSpellIds()`, which uses learned spell flags and current job level (and job points only at 99); job abilities are taken from currently available job data; menu weapon skills use `windower.ffxi.get_abilities().weapon_skills`. This does **not** automatically make high-level default profiles good beginner strategies.

## Decision pipeline — source trace

`settings/default/{JOB}.lua` and the character's saved job settings contain separate `BuffSettings.Gambits`, `CureSettings.Gambits`, `StatusRemovalSettings.Gambits`, `PullSettings.Gambits`, `GambitSettings.Gambits` (custom), `GambitSettings.Default` (job defaults), etc. Job-specific Trust role classes load those lists; these are not one global unified gambit list.

`Gambiter:on_add()` starts a **one-second timer**. `Gambiter:check_gambits()` visits enabled rules **in order** and stops at the first eligible one per invocation. `Gambit:isSatisfied()` requires *every* configured condition to pass (and checks the action's associated conditions). `Gambiter:perform_gambit()` calls the selected battle ability's `to_action(...)` and queues the resulting low-level action. Specialized healer/nuker/reaction roles can have additional logic and timing, so don't extrapolate a one-second response guarantee to all roles.

`GambitTargetGroup` supplies Self/Enemy/current-target and iterates Ally candidates. Each `GambitCondition` separately specifies the evaluated target type. Runtime code can sort ally candidates with a `gambit:getPriorityComparator()` function; there is no corresponding ordinary menu control for choosing **lowest-HP ally**, **closest ally**, etc., found in the standard editor. Do not assume “Ally HP < X” always picks the party member with the lowest HP; it tests eligible allies in its current target order unless custom sorting is provided.

`DefaultGambiter` appends **noneditable** job/ability prerequisites via `Job:get_conditions_for_ability()`, such as spell MP, whether the character has stopped moving, and ability conditions. These hidden prerequisites must not be confused with missing menu features. `Gambit:isValid()` is used for menu validity labels, but `Gambiter:check_gambits()` does not explicitly call it before attempting evaluation; test unavailable/default high-level actions before assuming they are harmless.

## Existing abilities that already serve low-level characters

| Category | Existing menu/engine capability | Low-level application |
| --- | --- | --- |
| HP/MP/TP | HPP thresholds/ranges, MP/MPP thresholds, TP thresholds | Cure decisions, avoid draining MP, Chakra after HP loss, weapon skills only with sufficient TP |
| Party-aware | Party member count, party HP range, party main job; ally-targeted conditions | Different solo/group behavior, healer vs melee buff priorities |
| Buff/status | Has Buff(s), Has Debuff, gained debuff, status, in battle, idle | Protect, Poisona, avoid recasting a buff, restrict offensive actions |
| Identity/modes | Main/Sub Job, Job, Mode, target name, in town, zone | Avoid actions outside suitable contexts; user-selectable behavior profiles |
| Spatial | Max Distance, Nearby Enemies, pet HP/TP/status, current target internally | Stay in spell range, avoid some overcrowded situations |
| Battle timing | Ready/Finish Ability, skillchain window/property/step, action start | Reactive fighting and skillchain-sensitive choices; many are advanced and need timing validation |
| Action targets | Self, Ally, Enemy; internal current target `t` | Cast on ally/enemy/self; don't assume t is fully exposed in standard new-rule editor |
| Action picker | Known spells, known JAs, available WS, item, mode, Windower command; select movement/combat actions | Tiny WAR/WHM/BLM/MNK starter rules without hardcoded endgame spells |

### Hidden condition modules worth considering

These are implemented *conditions*, not yet proven complete as safely editable/persistent user features:

- **Party claim / targeting:** `party_claimed.lua`, `party_targeted.lua`, `is_assist_target.lua`, `aggroed.lua`, `claimed.lua`, `unclaimed.lua`. Valuable for multibox safety and not stealing claims; currently NOT in Add Condition picker. `unclaimed.lua` is imported by the main conditions loader, most others are not.
- **Movement/range:** `is_standing.lua`, `distance.lua`, `max_height_distance.lua`, `pet_distance.lua`. Useful for stop-moving-before-cast and horizontal/elevation guardrails. `pet_distance` is already imported but not menu-listed.
- **Ability timing:** `job_ability_recast_ready.lua`, `spell_recast_ready.lua`, `cooldown.lua`. These exist; the first two are imported. The `CooldownCondition` reads a named timestamp table, but this audit has NOT verified a producer that calls `set_timestamp`; do not expose it without checking the update lifecycle.
- **Other potentially useful:** `num_buffs.lua`, `has_alter_ego.lua`, `has_status_effect.lua`, `is_standing.lua`, `is_assist_target.lua`, `target_names.lua`. Context-specific usefulness varies.
- **Advanced / job-specific:** song-count and remaining-duration checks, roll number, attachments, spell immunity, pet and terrain/elevation checks. More relevant when a particular character develops that role.
- **Internal/compositional:** `condition.lua` (base), `not_condition.lua` (already supported through Invert), `conditional.lua` (nested AND/OR implementation), `never.lua`, `valid_target.lua`, `zone_change.lua` and targeting guards. Don't casually add these to the public picker.

**Persistence caveat:** `Condition.defaultSerializableConditionClasses()` is a separate whitelist from the 53-type menu list. Several appealing hidden classes (party claim/target, spell/JA recast, cooldown, conditional OR) are **not in its default serializable list**. Merely adding picker entries would risk losing those conditions on save/reload. Check import, constructor defaults, valid target types, `get_config_items()`, serialization, *and the role's settings reload path* before exposing any one.

## Source-supported but not standard-menu-supported

- **General OR expressions:** `ConditionalCondition` implements AND/OR, and `Spell:get_default_conditions()` uses OR internally for MP-cost vs Manafont. But the standard editor concatenates gambit conditions as AND and only offers single-condition Invert, not a safe nested OR builder or its save/reload integration.
- **Smart Ally sorting:** `Gambit:setPriorityComparator()` and `Gambiter:is_gambit_satisfied()` support a comparator in memory, but standard menu edits don't expose one, and the saved gambit serializer doesn't serialize the comparator. “Heal the lowest-HP ally” needs either a tested comparator/selector implementation or a different role-specific priority system.
- **Action composition:** `cylibs/battle/sequence.lua` and `wait.lua` can represent compositions, while `cylibs/actions/sequence.lua`, `wait.lua`, etc. perform low-level steps. The generic action picker does not offer a Sequence/Wait creation editor. `cylibs/battle/script.lua` exists too, but exposing arbitrary scripts is not suitable as a first-pass beginner feature.
- **GambitGroup:** A class exists, but `Gambiter:check_gambits()` assumes methods such as `getPriorityComparator()` and `getAbilityTarget()` that the group class does not provide. Its mere presence does NOT prove group execution works; it needs a dedicated integration test before supporting it.
- **Contextual diagnostics:** logger has condition-failure traces when enabled, but no friendly **“Why this rule didn't fire”** explanation in the standard editor. A read-only diagnostic/inspector could clarify unknown spells, disabled roles, unsuccessful target selection, cooldown, MP, missing buff/recast, and rule priority.

## Specific beginner strategy ideas (design, NOT executable presets yet)

1. **WHM or a healer subjob — minimal triage:** Prefer an available stronger Cure at a lower HP threshold, then a cheaper learned Cure at a higher threshold; include Ally HP, distance and MP guards. Separate Self if necessary; keep common status removal (e.g. Poisona) only when learned. Check the dedicated `CureSettings` role first so we do not create competing generic Cure gambits. Later add explicit lowest-HP prioritization if tests show normal ally ordering insufficient.
2. **WAR — safe Provoke:** Provoke only on an intended party enemy when the ability is known and available; optional separate rule if a party member is threatened. The current `GambitSettings.Default` includes Provoke behind AutoTankMode/InBattle, while `PullSettings` also includes Provoke. A new party-claim/party-target condition could prevent unsafe pulling, but needs full persistence tests before activation.
3. **BLM — learned nuke selection:** Don't start with the BLM default's tier-IV–VI spell ordering. Use just a handful of spells the character actually knows, gated by MP and intended/claimed enemy status; keep debuffs and nukes in their dedicated roles when possible. Avoid casting into a target somebody else has claimed.
4. **MNK — small reactive skills:** Chakra only when HP is low and the ability is learned, Focus when available and appropriate, and no high-level JAs in the starter strategy. Existing `GambitSettings.Default` already demonstrates HP and melee-accuracy conditions.
5. **Solo vs grouped:** Use the existing `PartyMemberCountCondition` and `ModeCondition` to vary buffs/engagement behavior by party count; no new predicate required.

### Why endgame defaults feel mismatched

Sample source: `settings/default/BLM.lua` includes Thunder VI and other tier-IV–VI nukes; `settings/default/WHM.lua` lists Cure III–V, Curaga III–IV, high-level buffs, and Arise; `settings/default/WAR.lua` includes Blood Rage/Restraint and a pull-target list of Locus enemies. Those are not starter strategies. Although the editor queries known spells/JAs, **an existing saved high-level rule may still be listed (as unavailable)**. The correct near-term work is a cautious, character/job/level-aware preset **builder**, not globally changing everyone's defaults.

## Recommendations ranked for our project

**P0 — No combat behavior change:** first make a *read-only gambit trace/inspector* (rule order, action known/valid, role/mode enabled, target resolved, failing condition, available MP/TP, movement/range where applicable). Behind a diagnostics toggle, report only changed reasons to avoid log spam. Profile its overhead with six clients.

**P1 — Beginner templates:** one small editable profile per current job/level range, generated from verified known spells, available JAs and learned WS, with explicit target/MP/HP thresholds; backup existing character settings before saving. Test one character at a time. Keep healing/buffs in the existing specialist roles and generic gambits in Custom.

**P2 — Limited menu exposure:** add `PartyClaimedCondition`, `PartyTargetedCondition` and possibly `IsAssistTargetCondition` first, with imports and serialization, plus a safe preview/validation of a single selected rule before save. Second tier: `DistanceCondition`, `IsStandingCondition`, explicit recast-ready guards. Resist adding all hidden classes indiscriminately.

**P3 — Composition:** a nested **Any / All / Not** condition group editor, and an explicit ally priority policy (e.g. lowest HPP) with serialization, lifecycle safety, and bounded selection. Only after P0–P2 should we build a formal multi-step action/Sequence editor.

**Later:** path recovery diagnostics and bounded safety controls (project priority 6). Party-wide profile aliases remain deferred.

## File-level evidence

- `cylibs/gambits/gambit.lua`, `gambit_condition.lua`, `gambit_target_group.lua` — decision data model
- `cylibs/trust/roles/gambiter.lua` — timer, ordered evaluation, ally iteration, queueing
- `cylibs/conditions/condition.lua`, `includes/Trust-Cylibs-Conditions-Include.lua` — operators, default serialization whitelist, imported classes
- `ui/settings/menus/gambits/GambitConditionSettingsMenuItem.lua` — 53 exposed picker types, editor actions
- `ui/settings/menus/gambits/GambitEditorStyle.lua`, `GambitSettingsMenuItem.lua`, `ui/settings/editors/GambitSettingsEditor.lua` — action list, editing, targets and tags
- `cylibs/entity/jobs/job.lua`, `cylibs/util/spell_list.lua` — current-level/known spell gating
- `settings/default/{WAR,WHM,BLM,MNK}.lua`, `cylibs/trust/data/{WAR,WHM}.lua` — illustrative defaults and role wiring
- `cylibs/battle/{spell,command,sequence,wait,script}.lua` — action eligibility and composition
- `ui/settings/menus/gambits/library/GambitLibrary.lua` — prebuilt gambit examples

**Verification status:** Source audited; no live FFXI gambit execution tested during maintenance. Neither current character's exact level/learned spells nor their personalized saved Trust job settings were inspected, so the beginner designs are conditional suggestions, not confirmed working profiles.

## Appendix A — Complete condition module index (93)

**Menu picker** is source-confirmed in `getEditableConditionClasses()`. **Loaded, not picked** means registered by the main conditions include without an Add Condition entry. **Other module** means not in either list; it might still be required directly elsewhere. These are exposure indicators, *not* a functionality or persistence certification.

| Condition file | Exposure |
| --- | --- |
| `action.lua` | Menu picker |
| `aggroed.lua` | Other module (no auto-import) |
| `begin_cast.lua` | Menu picker |
| `buff_conflicts.lua` | Other module (no auto-import) |
| `can_equip_set.lua` | Other module (no auto-import) |
| `claimed.lua` | Other module (no auto-import) |
| `cluster_hpp_range.lua` | Menu picker |
| `combat_skills.lua` | Menu picker |
| `condition.lua` | Loaded, not picked |
| `conditional.lua` | Other module (no auto-import) |
| `cooldown.lua` | Other module (no auto-import) |
| `distance.lua` | Other module (no auto-import) |
| `enemies_nearby.lua` | Menu picker |
| `finish_ability.lua` | Menu picker |
| `gain_debuff.lua` | Menu picker |
| `has_alter_ego.lua` | Other module (no auto-import) |
| `has_attachments_condition.lua` | Loaded, not picked |
| `has_buff_condition.lua` | Menu picker |
| `has_buffs.lua` | Menu picker |
| `has_cumulative_magic_effect.lua` | Menu picker |
| `has_daze.lua` | Menu picker |
| `has_debuff.lua` | Menu picker |
| `has_key_items.lua` | Menu picker |
| `has_max_num_alter_egos.lua` | Other module (no auto-import) |
| `has_max_num_songs.lua` | Other module (no auto-import) |
| `has_pet.lua` | Menu picker |
| `has_raise.lua` | Menu picker |
| `has_roll.lua` | Other module (no auto-import) |
| `has_runes.lua` | Menu picker |
| `has_songs.lua` | Menu picker |
| `has_status_effect.lua` | Other module (no auto-import) |
| `has_weapon_skill.lua` | Other module (no auto-import) |
| `hpp_range.lua` | Menu picker |
| `idle.lua` | Menu picker |
| `immune.lua` | Other module (no auto-import) |
| `in_battle.lua` | Menu picker |
| `in_mog_house.lua` | Loaded, not picked |
| `in_town.lua` | Menu picker |
| `is_alter_ego.lua` | Menu picker |
| `is_assist_target.lua` | Other module (no auto-import) |
| `is_standing.lua` | Other module (no auto-import) |
| `item_count.lua` | Menu picker |
| `job.lua` | Menu picker |
| `job_ability_recast_ready.lua` | Loaded, not picked |
| `main_job.lua` | Menu picker |
| `max_distance.lua` | Menu picker |
| `max_height_distance.lua` | Other module (no auto-import) |
| `max_hpp.lua` | Menu picker |
| `max_mpp.lua` | Menu picker |
| `max_num_songs.lua` | Other module (no auto-import) |
| `max_tp.lua` | Menu picker |
| `melee_accuracy.lua` | Menu picker |
| `min_hpp.lua` | Menu picker |
| `min_mp.lua` | Menu picker |
| `min_mpp.lua` | Menu picker |
| `min_tp.lua` | Menu picker |
| `mode.lua` | Menu picker |
| `never.lua` | Loaded, not picked |
| `not_condition.lua` | Loaded, not picked |
| `num_buffs.lua` | Other module (no auto-import) |
| `num_expiring_songs.lua` | Other module (no auto-import) |
| `num_resists.lua` | Menu picker |
| `num_songs.lua` | Other module (no auto-import) |
| `party_claimed.lua` | Other module (no auto-import) |
| `party_has_main_job.lua` | Menu picker |
| `party_hpp_range.lua` | Menu picker |
| `party_leader.lua` | Other module (no auto-import) |
| `party_member_count.lua` | Menu picker |
| `party_targeted.lua` | Other module (no auto-import) |
| `pet_distance.lua` | Loaded, not picked |
| `pet_hpp.lua` | Menu picker |
| `pet_status.lua` | Menu picker |
| `pet_tp.lua` | Menu picker |
| `ready_ability.lua` | Menu picker |
| `ready_charges.lua` | Menu picker |
| `skillchain_ability.lua` | Menu picker |
| `skillchain_property.lua` | Menu picker |
| `skillchain_step.lua` | Menu picker |
| `skillchain_window.lua` | Menu picker |
| `song_duration.lua` | Other module (no auto-import) |
| `spell_recast_ready.lua` | Loaded, not picked |
| `status.lua` | Menu picker |
| `strategem_count.lua` | Menu picker |
| `sub_job.lua` | Menu picker |
| `target_ids.lua` | Other module (no auto-import) |
| `target_mismatch.lua` | Other module (no auto-import) |
| `target_name.lua` | Menu picker |
| `target_names.lua` | Other module (no auto-import) |
| `unclaimed.lua` | Loaded, not picked |
| `valid_spell_target.lua` | Other module (no auto-import) |
| `valid_target.lua` | Loaded, not picked |
| `zone.lua` | Menu picker |
| `zone_change.lua` | Loaded, not picked |

## Appendix B — Complete low-level action index (41)

These are runtime execution primitives, NOT a list of selectable gambit actions. Many are reachable indirectly from a higher-level `battle/*:to_action()` wrapper. Do not add these directly to the gambit picker without a valid action wrapper.

`action.lua` · `action_queue.lua` · `block.lua` · `blood_pact_rage.lua` · `blood_pact_ward.lua` · `command.lua` · `disengage.lua` · `dismount.lua` · `engage.lua` · `equip_attachment.lua` · `equip_set.lua` · `equip_spell.lua` · `flourish.lua` · `follow.lua` · `import_action.lua` · `job_ability.lua` · `key.lua` · `mount.lua` · `npc.lua` · `party_chat_message.lua` · `ranged_attack.lua` · `runaway.lua` · `runbehind.lua` · `runto.lua` · `runtolocation.lua` · `sequence.lua` · `spell.lua` · `status_removal.lua` · `strategem.lua` · `switch_target.lua` · `trade_accept.lua` · `trade_confirm.lua` · `trade_npc.lua` · `trade_offer.lua` · `trade_request.lua` · `turn.lua` · `ui/debug_view.lua` · `wait.lua` · `walk.lua` · `waltz.lua` · `weapon_skill.lua`

## Appendix C — Complete battle module index (50)

“Direct gambit choice” is listed in `GambitEditorStyle:getAbilitiesForTargets()`. “Dynamic” is selected from current job/spell/ability data. All other modules may still be used by specialist roles or as execution infrastructure.

| Battle module | User-facing action chooser |
| --- | --- |
| `abilities/blood_pact_magic.lua` | Specialized ability/spell wrapper |
| `abilities/blood_pact_rage.lua` | Specialized ability/spell wrapper |
| `abilities/blood_pact_ward.lua` | Specialized ability/spell wrapper |
| `abilities/elemental_magic.lua` | Specialized ability/spell wrapper |
| `abilities/job_ability.lua` | Dynamic gambit choice |
| `abilities/phantom_roll.lua` | Specialized ability/spell wrapper |
| `abilities/ready_move.lua` | Specialized ability/spell wrapper |
| `abilities/weapon_skill.lua` | Dynamic gambit choice |
| `approach.lua` | Direct gambit choice |
| `aura_tracker.lua` | Support, role, tracker or other |
| `battle_stat_tracker.lua` | Support, role, tracker or other |
| `buff_record.lua` | Support, role, tracker or other |
| `buff_tracker.lua` | Support, role, tracker or other |
| `command.lua` | Direct gambit choice |
| `disengage.lua` | Support, role, tracker or other |
| `engage.lua` | Direct gambit choice |
| `equip_set.lua` | Support, role, tracker or other |
| `healing/status_removal.lua` | Support, role, tracker or other |
| `monster.lua` | Support, role, tracker or other |
| `monster_buff_tracker.lua` | Support, role, tracker or other |
| `monsters/mob_filter.lua` | Support, role, tracker or other |
| `monsters/mob_tracker.lua` | Support, role, tracker or other |
| `monsters/ui/target_info_view.lua` | Support, role, tracker or other |
| `ranged_attack.lua` | Direct gambit choice |
| `resist_tracker.lua` | Support, role, tracker or other |
| `roll.lua` | Support, role, tracker or other |
| `run_away.lua` | Direct gambit choice |
| `run_to.lua` | Direct gambit choice |
| `script.lua` | Action wrapper, not in picker |
| `sequence.lua` | Action wrapper, not in picker |
| `skillchains/abilities/skillchain_ability.lua` | Support, role, tracker or other |
| `skillchains/element.lua` | Support, role, tracker or other |
| `skillchains/skillchain_builder.lua` | Support, role, tracker or other |
| `skillchains/skillchain_step.lua` | Support, role, tracker or other |
| `skillchains/skillchain_tracker.lua` | Support, role, tracker or other |
| `song_tracker.lua` | Support, role, tracker or other |
| `songs/song_record.lua` | Support, role, tracker or other |
| `spell.lua` | Dynamic gambit choice |
| `spells/buff.lua` | Specialized ability/spell wrapper |
| `spells/debuff.lua` | Specialized ability/spell wrapper |
| `status_ailment.lua` | Support, role, tracker or other |
| `target.lua` | Support, role, tracker or other |
| `trackers/cumulative_magic_tracker.lua` | Support, role, tracker or other |
| `trackers/debuff_tracker.lua` | Support, role, tracker or other |
| `trackers/step_tracker.lua` | Support, role, tracker or other |
| `turn_around.lua` | Direct gambit choice |
| `turn_to_face.lua` | Direct gambit choice |
| `use_item.lua` | Direct gambit choice |
| `wait.lua` | Action wrapper, not in picker |
| `weapons/weapon.lua` | Support, role, tracker or other |

**Related ability outside battle directory:** `cylibs/gambits/abilities/set_mode.lua` is also directly exposed under Self actions.
