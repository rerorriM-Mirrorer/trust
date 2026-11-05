# Combat observation — AutoEngage Aggro Test 1 (November 4, 2026)

No new packet parsing or injection. Source-confirmed existing `cylibs/Cylibs-Windower-Events.lua` parses incoming 0x028 with Windower's action parser and emits `WindowerEvents.Action`. Aggro subscribes to that existing event alongside MobTracker. It reads actor_id, category and targets[].id; entity ID/index, claim_id, status, distance, valid_target and target_index come from existing Windower entity APIs.

Accepted categories: 1 melee, 2 ranged finish, 3 weaponskill finish, 4 spell finish, 7 ability/weaponskill start, 8 spell start, 11 monster TP finish, 12 ranged start. Meanings were checked against `cylibs/conditions/action.lua`, `cylibs/util/action_message_util.lua` and the existing event dispatcher. Observation requires a valid monster actor and a current living party victim. No action-message numeric values, damage thresholds or hidden hate ranking are inferred.

This is evidence of an observable threat, not proof of server hate. A targeted attempt, miss or interrupted windup can still justify a bounded eight-second defensive memory. No controlled live captures were collected in this batch; category coverage and action-target completeness in live aggro, AoE and alter-ego scenarios remain unresolved. All verification is source inspection or host simulation. Record repeated live variations and confidence here when available.


# Retreat control — Act / Pause / Retreat Test 1 (November 4, 2026)

No new packet observation, parsing or injection. Public Stop issues native `/attack off` when the character reports engaged and native SMN `/pet "Retreat" <me>` or BST `/pet "Heel" <me>` for a present pet. Existing Trust DisengageAction uses outgoing 0x01A/category 0x04, but this batch does not add or directly inject that packet. Existing player-status and follower events determine when following can start after disengage; dispatch alone is not confirmation. Server acceptance during casts/action locks, pet behavior and summoned alter-ego following require controlled live observations. No such captures or in-game tests were performed here.
