# AGENTS.md — machine-oriented; humans: see WORKFLOW.md

<!-- agents_shared_version: 2026-11-20.1 | canon: rerorriM-Mirrorer/ffxi-NPCmirror@main -->
<!-- SHARED:BEGIN — copy verbatim across repos; edit only in canon -->

## READ (budgeted)
R1 AGENTS.md: full. Then this repo's REPO block (bottom).
R2 WORKFLOW.md: full, once/conversation. Project mirror canon/WORKFLOW.md may be read instead iff its workflow_version line == GitHub's.
R3 TESTING.md: lines 1..first "^---$" only. Rest: grep -n <keyword>; read hits ±40 lines. NEVER read whole.
R4 project handoff doc for this addon if present (claude/ffxi-*-handoff-*.md) and canon/REPO_INDEX.md. On conflict with repo: trust repo, flag.
R5 source >800 lines: grep symbol → read region. Whole-file read only if diff touches >50% of file.

## PRECONDITIONS (all must hold before first edit; else ask, one question)
P1 installed_base = commit A has in D:\FFXI Setup\FFXI\Windower\addons\<addon>. Branch from installed_base, not newest branch. (Failure mode: patch on wrong base → withdrawn.)
P2 live_file = path actually loaded at runtime. Check REPO.LIVE_FILES and embedded/vendored copies.
P3 api_types: confirm field types in Windower docs before conditional logic. Known: get_player().autorun = {x,y,z} table|nil.
P4 interfaces: cross-addon contracts (REPO.INTERFACES, canon/REPO_INDEX.md) read from the other repo's current branch, not memory.
P5 packets: action pkt category 3 includes job abilities; filter msg 110/317. New packet facts → docs/PACKETS.md (known vs inferred).
P6 trusted branch = repo's GitHub default branch (main or master; varies). Read metadata; never assume. Default branch may be stale vs work branches (REPO.ACTIVE).

## EPISTEMIC TAGS (required on every factual claim in reports/docs)
Verified=read this session | Inferred=reasoned, untested | Live=A confirmed in FFXI | Pending=not done.
Host sim/static pass ≠ Live. Never upgrade a tag without evidence.

## EXECUTION
E1 minimal diff on responsible surface; preserve known-good behavior.
E2 one concept per commit; message states intent.
E3 progress note per finding/decision; ≤3 sentences.
E4 live-only question → request specific observation (status line, log path, capture). No speculative code to compensate.
E5 FFXI chat strings ASCII only (no U+2013/U+2014).

## COST ROUTING
C1 Classify each subtask: reasoning (design, debugging, packet/timing analysis) vs mechanical (zip, TESTING entry, push, doc propagation, log extraction, rename/move).
C2 Mechanical + fully specified → no top-tier model/effort. (a) delegate to cheaper-model subagent if available, or (b) emit HANDOFF block for a separate conversation.
C2a STANDING ORDER (A): packaging (zip, BUILD_MANIFEST, file list vs installed_base) is ALWAYS delegated. Claude: subagent model=sonnet (haiku if pure copy+zip). Agents without subagents: HANDOFF block. Main thread only verifies returned file list + zip contents.
C3 HANDOFF block = repo, branch, base SHA, exact files/paths, exact commands, acceptance checks, report format. Self-contained; assume zero context.
C4 Accept a delegated report only with pushed SHA, check output, file list. Verify SHA on remote before continuing.
C5 Conversation long (>~30 turns) or batch delivered → write project handoff doc, recommend new conversation.

## DELIVERY (ordered; all required)
D1 re-read request; full diff vs installed_base.
D2 run REPO.CHECKS (default: luac -p (5.1) on changed .lua). Report exact commands + results.
D3 TESTING.md (repo): prepend "## Current Development Status — <date> (America/Chicago)": repo/branch, installed_base, changes, checks run, Live, Pending, next step. Old entries immutable; corrections = ~~old~~ + dated note.
D4 commit, push, verify remote head; report SHA.
D5 package (default) <Addon>-<ver>-Test<n>.zip → <Addon>/ containing all files changed since installed_base + README.md. "fresh install" request → complete <Addon>/ + README.md. Never zip WORKFLOW.md or TESTING.md. No ZIP-root copies.
D6 with every patch, deliver one .md in conversation: new status block + current tests as "- [ ]" checklist (what to try, what to report). No history.
D7 if work continues elsewhere: project handoff doc (repo, branch, head SHA, installed_base, Live, Pending, next).

## SELF-IMPROVEMENT
S1 Recurring failure mode or wasteful rule → append PROPOSAL to report: target (AGENTS shared | AGENTS REPO | WORKFLOW), exact diff, one-line reason. Apply only with A's approval.
S2 Approved shared changes: edit canon first, bump version line, then propagate (WORKFLOW "Shared Development Conventions"); refresh project mirrors.

## USER
Collaborative identity "A" (human + coding agents: Claude, ChatGPT, etc.). Address/attribute as A.
Explanations at learning level, conversational, minimal bullets. Lead with next action. No hedging lead-ins.
Promote to trusted branch only after A's live confirmation.

<!-- SHARED:END -->

## REPO (repo-specific; preserved on sync)
NAME: Trust (rerorriM-Mirrorer/trust, fork of upstream Trust) — party automation for multibox: Fan Out, Flank, follow, autorun, menus. Windower 4, Lua 5.1.
TRUSTED: main (default branch; stale since 2026-10-16, not the installed code).
ACTIVE: test/autohide-engaged (tip of A's install stack; branch stack from test/widget-autohide 5549371 -> ... -> test/autohide-engaged, packages cumulative). Last Live-confirmed: test/flank3 074514e (Flank3), Edge1 e094f5b partial.
LIVE_FILES: Trust.lua and cylibs/ modules under addons/Trust (Inferred); movement receiver cylibs movement_receiver.lua (Verified in handoff docs).
INTERFACES: xivcrossbar -> Trust movement signal (AHK DIK 0x7B -> movement_receiver.lua -> takeover.apply; lease policy=Send). Boom reads cylibs/res/skills.lua and cylibs/util/skillchain_util.lua (Trust skillchains must be off while Boom coordinates). Trust IPC between clients via windower.send_ipc_message / cylibs/chat/party_chat.lua.
CHECKS: luac -p (5.1) on changed .lua; TrustUnitTests.lua present (Inferred; run method not verified).
