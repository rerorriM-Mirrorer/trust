# AGENTS.md — machine-oriented; humans: see WORKFLOW.md

<!-- agents_shared_version: 2026-11-21.3 | canon: rerorriM-Mirrorer/ffxi-NPCmirror@main -->
<!-- SHARED:BEGIN — copy verbatim across repos; edit only in canon -->

## BOOTSTRAP (runs before R1; project instructions trigger it)
B1 Orient: newest repo/branch/commit for the addon (where work left off). Orientation only; patch base = P1.
B2 Attach every repo you will touch with access=push. A pre-authorized push for all FFXI repos (project instructions); do not ask again.
B3 Push/attach denied or git proxy 403: no retries, no workarounds. Commit locally; deliver `git format-patch` files + handoff marked NOT PUSHED (base SHA, local SHAs). First line of report says NOT PUSHED so A can re-authorize.
B4 Version check: working repo's agents_shared_version + workflow_version vs canon (R1). Project canon/ = cache only; never the reference. Repo missing/older → docs-only sync commit first (shared section + WORKFLOW verbatim; repo lines into REPO block), then task. Working repo's own shared section is never followed; canon wins. Mirror older than GitHub → refresh mirror (S2b) in passing.
B5 Claude git: `git clone --depth 1`; push with `git -c push.negotiate=true push -u origin <branch>`; verify with `git ls-remote origin <branch>`.

## READ (budgeted)
R1 Canon = rerorriM-Mirrorer/ffxi-NPCmirror@main on GitHub (attach; read access suffices unless editing canon). Read canon AGENTS.md full; follow its shared section. Working repo AGENTS.md: REPO block (bottom) + the two version lines only.
R2 Canon WORKFLOW.md: full, once/conversation. Project mirror canon/WORKFLOW.md may be read instead iff its workflow_version line == canon's.
R3 TESTING.md: lines 1..first "^---$" only. Rest: grep -n <keyword>; read hits ±40 lines. NEVER read whole.
R4 newest project handoff doc for this addon if present (claude/ffxi-*-handoff-*.md; may already be read in B1 to locate the repo) and canon/REPO_INDEX.md. On conflict with repo: trust repo, flag.
R4a Handoff OPEN_Q lines that bear on the task → ask A in one message at start, with the likely answer offered. Unrelated OPEN_Q → carry forward untouched (D7).
R5 source >800 lines: grep symbol → read region. Whole-file read only if diff touches >50% of file.

## PRECONDITIONS (all must hold before first edit; else ask, one question)
P1 installed_base = commit A has in D:\FFXI Setup\FFXI\Windower\addons\<addon>. Branch from installed_base, not newest branch. (Failure mode: patch on wrong base → withdrawn.)
P1a Source: handoff/TESTING line tagged Live, or A's word. A installs package X → installed_base = X's commit. If only Inferred/assumed: ask A once at start (one line, offer the likely SHA). Never carry "assumed" forward across 2+ batches.
P2 live_file = path actually loaded at runtime. Check REPO.LIVE_FILES and embedded/vendored copies.
P3 api_types: confirm field types in Windower docs before conditional logic. Known: get_player().autorun = {x,y,z} table|nil.
P4 interfaces: cross-addon contracts (REPO.INTERFACES, canon/REPO_INDEX.md) read from the other repo's current branch, not memory.
P5 packets: action pkt category 3 includes job abilities; filter msg 110/317. New packet facts → docs/PACKETS.md (known vs inferred).
P6 trusted branch = repo's GitHub default branch (main or master; varies). Read metadata; never assume. Default branch may be stale vs work branches (REPO.ACTIVE).

## EPISTEMIC TAGS (required on every factual claim in reports/docs)
Verified=read this session | Inferred=reasoned, untested | Live=A confirmed in FFXI | Pending=not done | Unknown=not found/unreachable.
Host sim/static pass ≠ Live. Never upgrade a tag without evidence.

## EXECUTION
E1 minimal diff on responsible surface; preserve known-good behavior.
E2 one concept per commit; message states intent.
E3 progress note per finding/decision; ≤3 sentences.
E4 live-only question → request specific observation (status line, log path, capture). No speculative code to compensate.
E4a live failure report → first confirm conditions (package installed on which clients, party/alliance membership, zone, settings/toggles) before diagnosing code. (Failure mode: "commands reached nobody" = clients not in party.)
E4b A tests UI/animation/timing through preview/demo commands: every such change must also work on the preview path; test it there.
E5 FFXI chat strings ASCII only (no U+2013/U+2014).
E6 Visual/timing/feel constants → named tunables grouped at the top of their block (comment = unit + default); expose a setting or `//addon <cmd> <value>` when A will tune it live. List tunable names + defaults in status block and handoff.
E7 New effect that changes an existing look/feel → own on/off toggle from the first build; say its default in the checklist so A can flip it without a new batch.

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
D2a New/changed failures only matter. Known pre-existing failures live in REPO.KNOWN_FAILS; compare against it, don't re-investigate. Working host setup found (e.g. `pip install lupa`, runner script) or new pre-existing failure → add to REPO.CHECKS / REPO.KNOWN_FAILS in the delivery commit.
D3 TESTING.md (repo): prepend "## Current Development Status — <date> (America/Chicago)": repo/branch, installed_base, changes, checks run, Live, Pending, next step. Old entries immutable; corrections = ~~old~~ + dated note.
D4 commit, push, verify remote head; report SHA.
D5 package (default) <Addon>-<ver>-Test<n>.zip → <Addon>/ containing all files changed since installed_base + README.md. "fresh install" request → complete <Addon>/ + README.md. Never zip WORKFLOW.md or TESTING.md. No ZIP-root copies.
D6 with every patch, deliver one .md in conversation: new status block + current tests as "- [ ]" checklist (what to try, what to report). No history.
D7 if work continues elsewhere: project handoff doc (repo, branch, head SHA, pushed y/n, installed_base + its tag, package name, Live, Pending, next, A's backlog, OPEN_Q). Self-contained: carry forward every still-valid line from the previous handoff; never "rest of <older doc> still holds". Next agent reads only the newest one.
D7a STACK: when branches build on unmerged branches, list the chain base→head as `branch@sha` (one line) in the handoff and the TESTING status block. Package = cumulative since installed_base, regardless of stack depth.
D7b OPEN_Q: every question asked of A and not yet answered = one line `OPEN_Q <topic>: <question> (likely: <answer>)`. Remove only when A answers; record the answer where it applies.

## SELF-IMPROVEMENT
S1 Recurring failure mode or wasteful rule → append PROPOSAL to report: target (AGENTS shared | AGENTS REPO | WORKFLOW), exact diff, one-line reason. Apply only with A's approval.
S2 Approved shared changes: edit canon first, bump version line, then propagate (WORKFLOW "Shared Development Conventions"); refresh project mirrors.
S2b Mirror refresh = project_write canon/AGENTS.md (+ canon/WORKFLOW.md if changed) from the pushed canon commit, then project_read and confirm the version line. Write the canon/SYNC_LOG.md entry only after that readback; never log a refresh that was not read back. (Failure mode 2026-11-21: SYNC_LOG said refreshed, but a read of the mirror at 16:08 returned 11-20.1; a later read returned 11-21.1. Cause Unknown, so check against GitHub.)

## USER
Collaborative identity "A" (human + coding agents: Claude, ChatGPT, etc.). Address/attribute as A.
Explanations at learning level, conversational, minimal bullets. Lead with next action. No hedging lead-ins.
Promote to trusted branch only after A's live confirmation.

<!-- SHARED:END -->

## REPO (repo-specific; preserved on sync)
NAME: Trust (rerorriM-Mirrorer/trust, fork of upstream Trust) — party automation for multibox: Fan Out, Flank, follow, autorun, menus. Windower 4, Lua 5.1.
TRUSTED: main (default branch; stale since 2026-10-16, not the installed code).
ACTIVE: test/manual-input (Manual1, on top of test/setnames-errfix b8c6b0d = Test11 installed; tip of A's install stack: test/autohide-engaged d5228fd -> test/act-state -> test/control-publish -> test/mode-shortnames -> test/engage-aggressive -> test/party-broadcast -> test/party-broadcast-noparty -> test/widget-states -> test/setnames-errfix; packages cumulative). Last Live-confirmed: test/autohide-engaged d5228fd.
LIVE_FILES: Trust.lua and cylibs/ modules under addons/Trust (Inferred); movement receiver cylibs movement_receiver.lua (Verified in handoff docs).
INTERFACES: Trust -> xivcrossbar control state: data/control-state-<server>-<id>.txt (trust-control1, id, state act|start|pause|stop|retreat, intent act|start|pause|stop|none, os.time stamp, END; heartbeat 5 s) read by xivcrossbar libs/trust_control.lua. xivcrossbar -> Trust movement signal (AHK DIK 0x7B -> movement_receiver.lua -> takeover.apply; lease policy=Send). Boom reads cylibs/res/skills.lua and cylibs/util/skillchain_util.lua (Trust skillchains must be off while Boom coordinates). Trust IPC between clients via windower.send_ipc_message / cylibs/chat/party_chat.lua.
CHECKS: Lua 5.1 syntax via tests/menu_options/check_syntax.lua under python lupa (pip install lupa --break-system-packages; lupa.lua51); host tests: python lupa LuaJIT 2.1 with package.path='./?.lua' running tests/menu_options/*_test.lua and tests/aggro. TrustUnitTests.lua present (run method not verified).
KNOWN_FAILS: 9 pre-existing (was 11 before 2026-11-23) host-Lua failures in tests/menu_options + tests/aggro (Windower quoted-string methods, unpack, sqlite3, quiet_test register_event mock, pull_attempt, shared_file_backend); compare count, don't re-investigate. 2026-11-24: a plain lupa runner (each file in a fresh luajit21 runtime, cwd = repo) gives 11 failing files on b8c6b0d (adds approach_responsiveness, trace_commands); compare against the same runner.
