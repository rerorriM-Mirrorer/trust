# Character-wide settings investigation — October 25, 2026

Requested direction: direct main/subjob Settings, full Modes last; investigate
moving everyday automation to a character-wide main-menu area. This pass changes
navigation/display only; no saved settings migrate or change ownership.

| Area | Current ownership | Character-wide work |
| --- | --- | --- |
| Pulling | Targets, Blacklist, Distance, MaxNumTargets and pull Gambits belong to named job settings in data/JOB_Character.lua | Extract common hunting values into character configuration, retain job Pulling Actions; route every editor/command read and write to the correct owner |
| Following | Distance/auto-pause already addon preferences; target/pause include session state; mode stored in job mode profiles | Persist selected follow modes at character scope and reapply after job-role rebuilding; decide whether session follow target should survive reload |
| Alter Egos | Summon list already addon battle.trusts; AutoTrustsMode remains job-profile state | Move mode preference to character scope while retaining job/zone/summoning availability checks |
| Paths | Recorded resources already in data/paths; movement has runtime role state and follow interactions | Preserve character-wide choice/control modes without resuming an old path unintentionally after a job change |
| Food | Rules/items currently job GambitSettings with job conditions; AutoFoodMode saved per job mode set | A character-wide food selection needs character-owned rules, inventory checks, and an explicit policy for job-qualified existing rules |
| Gambits | Named main/subjob settings; each job has a separate custom Gambiter | A shared rules list needs ability eligibility checks and one execution owner to avoid main/subjob duplication; retain job-authored rules separately |

Suggested first experiment: a main-menu Character area exposing Following,
Alter Egos and Paths with their existing resources, then move selected mode
persistence. Pulling common values can follow with job Pulling Actions kept
separate. Food and Gambits should follow only after clear ownership/eligibility.
Moving a menu alone does not make its settings character-wide.

The broader global-profile redesign remains deferred per the earlier decision
to improve defaults and copy established setups. Character-wide means one
character across jobs, not automatically every character or another computer.

AUTO/MANUAL movement integration is a separate pending change: built into Trust,
Send default, Ready legacy option, one first-movement signal after client switch,
immediate accept/ignore, no deferred action. Need current running AHK and includes
to patch its actual sender rather than the older local controller checkout.
