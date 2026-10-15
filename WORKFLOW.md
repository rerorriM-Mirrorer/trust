# WORKFLOW.md

## AGATHOS

Good grows.

Good widens the circle of possible benefit.

A seeks good until A finds good.
A makes more good possible.

Good is recognized in what gives rise to further joy, health, understanding, capacity, beauty, connection, and good.

---

## Contents

- [DESIGN](#design)
  - [Addon behavior and UI](#addon-behavior-and-ui-extend-and-enhance-ffxi-rather-than-fighting-it)
  - [Configuration](#configuration-is-interface)
  - [Multiboxing](#multiboxing-informs-engineering-priorities)
  - [Windower conventions](#windower-conventions)
  - [State and sequencing](#state-and-sequencing)
  - [Diagnostics](#diagnostics)
  - [Comments](#comments)
- [WORKFLOW](#workflow)
  - [Principles and verification](#principles)
  - [Static checking](#static-checking)
  - [Packet investigation](#packet-investigation)
  - [Testing packages and development records](#testing-packages--development-records)
  - [Authorship](#authorship)
  - [Shared development conventions](#shared-development-conventions)

---

## DESIGN

### Addon behavior and UI extend and enhance FFXI rather than fighting it
**The best state for many of these tools is almost invisible.**
Prefer FFXI-like typography, spacing, borders, and restrained visual hierarchy.

**The addon should feel as though the game gained a missing capability.**

---

### Configuration is interface

Good defaults matter more than enormous configuration files. Expose a setting because a user may reasonably want to change it. Where sensible, commands support:

`//addon command on`  
`//addon command off`  
`//addon command`

A bare command may toggle when that behavior is useful and obvious. Explicit state-setting commands should be idempotent:

`edit on` always leaves editing on and reports that state.

Help output should make `<required>` and `[optional]` parameters obvious.

Dragging and edit modes should be discoverable but disappear when not needed.

---

### Multiboxing informs engineering priorities

Assume partial success.

“Three succeeded and one did not” is a normal state that should be diagnosable, not an exceptional condition that collapses the whole operation. Where practical, commands operate independently per client and report successes and failures per character. Resolve roles dynamically—leader, `<p1>`, anchor, current party lead, configured role—inside program logic. Individual character names assigned to those roles belong in configuration. Design timing, behavior, and resource use with multiple simultaneous clients in mind.

---

### Windower conventions

- Defaults belong in the addon; `config` populates user settings.
- User-modified persistent state belongs under `data`.
- New settings merge gracefully into existing configurations.
- Use `local` variables and functions by default. Create globals only when something outside their local scope must access them.
- As commands grow, keep command parsing small and hand individual commands to separate local handler functions rather than one large `if/elseif` chain.
- Every addon provides useful `help` and `status` commands. A bare addon command may report status where appropriate.
- Prefer existing Windower libraries and definitions over recreating equivalent behavior.


---

### State and sequencing

When an addon develops several interacting modes or asynchronous steps, prefer an explicit state machine over accumulating loosely related boolean flags.

Prefer:

**observe completion of A → perform B**

over:

**wait an arbitrary time → assume A completed → perform B**

Delays remain appropriate as buffers when no reliable completion signal exists.

---

### Diagnostics

Addons should be able to report their basic running state.

Where relevant, diagnostics should answer:
- What version am I running?
- What mode am I in?
- What major toggles are active?
- Where is my UI positioned?
- What target, character, or state am I operating against?
- Is debugging enabled?

Diagnostic levels:

**Normal** — quiet except for useful user feedback.
**Debug** — explains important decisions and state changes.
**Trace** — exposes detailed state transitions, packet IDs, target data, or other investigation information.

Failures should be specific enough to identify which step or character failed.

---

### Comments

Comments explain **function, intent, and causality**, especially for someone curious about the code but not yet fluent in Lua.

Particularly comment:
- modifications from upstream
- deliberately preserved or dormant behavior
- code whose removal would have unexpected consequences

Educational comments may be reduced later when preparing a final upstream release.

---

## WORKFLOW

### Principles

**Legibility.**
1. Begin with the ideal solution as imagined or visualized.
2. Identify the established problem.
3. Read upstream code, current fork, last known-good version, and local changes before editing to establish baseline.
4. Review Windower definitions, related addons, available repositories, presented references and the [Design principles](#design) before theorizing. When uncertain, make direct observations and diagnostics.
5. Present plan for patching and development.
6. Patch the smallest responsible surface, preserving working behavior unless changing it is intentional.
7. Test in layers:
   - **Static:** does the code parse and reveal obvious mistakes?
   - **Smoke:** does it load and perform its basic function?
   - **Regression:** does previously working behavior still work?
   - **Live:** does it behave correctly under the actual conditions that motivated the change?
8. Commit coherent units of work; every conceptual change produces one comprehensible commit or small sequence of commits describing intention.
9. Preserve and tag known-good states and snapshots: `main`/`master` represents the last version trusted after live testing; Untested work remains on a working branch.
10. **Document continuously.** Keep README, defaults, help/status output, comments, diagnostics, and repeatable test instructions (`TESTING.md`) aligned with desired behavior. While developing in Codex, give frequent reports on work and thought process. Record user-visible changes in cumulative changelog included at the end of each README. Report findings and patches as work proceeds. Git history remains the complete mechanical record.


#### 11. Review Before Delivery

Before presenting a completed batch:
- Review changes against original request.
- Check for unintended changes or regressions.
- Perform appropriate static checks and available tests.
- Confirm which changes have actually been tested.
- Review documentation and comments for accuracy.
- Identify any remaining uncertainties.
- Report commit and push status.
- Suggest worthwhile follow-up improvements.

---


### Static checking

Before live testing, run Lua 5.1-aware static checks against Windower's API definitions where available. Catch syntax errors, unintended globals, API mistakes, and other obvious problems before FFXI testing. Static checking complements rather than replaces smoke, regression, and live testing.

---


### Packet investigation

Packet injection is welcome as a solution but requires stronger justification than packet observation. Determine when packet observation is warranted and ask for controlled captures when live observation is required.

For packet-dependent work, maintain `docs/PACKETS.md` recording:
- scenario/action
- incoming/outgoing direction
- packet ID
- relevant observed fields
- repeated observations and variations
- what is known versus inferred
- confidence and unresolved questions

---


### Testing Packages & Development Records

- **README.md**

   - Keep `README.md` focused on configuration and use, ending with cumulative changelog.
   - Maintain the source `README.md` at the repository root. In testing ZIPs, include its installable copy **inside the addon folder** (`AddonName/README.md`), alongside the addon code; do not duplicate it at the ZIP root.
   - Place only the consolidated `WORKFLOW.md` and cumulative `TESTING.md` at the root of the testing ZIP, alongside the installable addon folder. Do not include retired `AGATHOS.md` or `DESIGN.md` separately.

- **TESTING.md**
   
   - Maintain `TESTING.md` at the repository root as the first guide for installation, development and testing, alongside `WORKFLOW.md`. Include both documents at the root of every testing package.
      - Each testing delivery should identify its batch, associated commit(s), its contents, and any installation precautions.
      - Update `TESTING.md` before delivering a new testing batch. Include current tests first, followed by previous checks and results, a delivery register, and a record of user-provided materials, observations, and requests.
      - Preserve historical information without presenting unverified reconstruction as fact. 
      - `TESTING.md` is a cumulative record. Correct inaccurate information using strikethrough, an explanatory note, and the corrected information. Remove historical information only by mutual agreement.

---


### Authorship

**A is the collaborative authoring identity of this continuing practice.**


---


### Shared Development Conventions

Use the consolidated `WORKFLOW.md` maintained in the NPCMirror repository as the reference for shared practices across projects. It contains AGATHOS, DESIGN, and WORKFLOW in that order.

Maintain `WORKFLOW.md` and `TESTING.md` at the root of each active development repository and testing package.

Review these conventions when beginning development work or preparing a new testing batch. Preserve project-specific principles, documentation, and history when adopting shared conventions. Propagate improvements deliberately, reviewing differences rather than overwriting existing material. 

Reflect useful improvements back into the shared reference when appropriate.

---

### Shared Addon Standards

Apply these conventions to new addons and to existing addons as they are developed. Preserve established behavior; add optional features only when they serve a useful purpose.

**Commands and help**
- Provide `help`, `status`, `restart`, and `unload` commands.
- **Show help for bare or invalid commands.** Entering `//addon` alone or an unrecognized subcommand displays the command list, optionally preceded by a brief error. The only bare-command exception is an intentionally defined primary action; document that behavior in help.
- Use BattleStations-inspired, chat-only help: full `//addon command` examples, concise descriptions, `<required>` and `[optional]` arguments, and deterministic order.
- Color individual fragments using Windower's `require('chat')` and `string.color()`: separators **140**, headings **167**, `//addon` prefix and `->` arrow **200**, syntax **207**, descriptions **0** (neutral white). Emit each line with `windower.add_to_chat(0, line)`; do **not** also print normal help to the console.
- Give concise command feedback. Keep `reload` distinct from a complete `restart` when an addon uses both.

**Visual interface (where applicable)**
- Support draggable positioning, saved coordinates, edit-mode guides, lock/unlock, and recovery when a UI is positioned off-screen.
- Offer scaling, sensible minimum border widths, and layout choices suitable for small client windows and multiboxing.
- Offer contextual `show`, `hide`, and `auto` visibility when useful.
- Use restrained entrance/exit fades; support optional previews or demo states when they make tuning possible without waiting for gameplay events.
- Avoid invisible UI intercepting input, redundant rendering, unnecessary sounds, and noisy startup messages.

**Lifecycle and delivery**
- Make `restart` and `unload` graceful: report the action, fade visible elements where applicable, clean up resources, and dispatch the lifecycle command **once**.
- Commit and push coherent changes frequently. Every testing package must correspond to an identifiable Git commit on the appropriate development branch; do not present uncommitted work as published.
- Keep documentation, saved-setting compatibility, and tests aligned with changes. Distinguish simulated verification from live FFXI testing.

**Principle:** Make each addon feel like a natural extension of FFXI. Reuse proven patterns without adding complexity that serves no purpose.


