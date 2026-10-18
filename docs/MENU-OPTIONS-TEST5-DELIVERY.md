# Menu options Test 5 full-folder delivery — October 18, 2026

Author: Awake. Repository: rerorriM-Mirrorer/trust.
Branch: `test/menu-exit-save-20261017`; main untouched by this work.

- Exact published packaged source: `b98b8a20905e09d74854f9294daef4d087a49ab7`.
- Source commits: `aba213c1` (command settings autosave), `389c7ee4` (clean options
  refresh/list entry focus), `b98b8a20` (Test 5 documentation/status).
  Published trees match the locally tested trees; source was fetched and verified.
- Incorporates concurrent controller-conversation commit `17d0f9cc` rather than
  overwriting it: explicit idempotent Open and the existing guarded Close handler.
  Its regression runs against the combined source. No controller Lua/AHK is shipped.
- Artifact: `Trust-MenuOptions-Test5-Full.zip`, saved successfully.
- SHA-256: `9fe768eb2d89856b1a484fb10837d709a29ffaa9295f839d42d3f6cb99784171`.
- Size: 5,288,665 bytes; 1,474 ZIP members, all inside `trust/`.
- Full cumulative Trust 17.7.3 runtime/assets/source folder, same runtime scope as
  Test 4 plus the command settings synchronizer. Personal data/logs, Git metadata,
  installer, historical archives and tests directory are excluded. Windower
  dependencies remain separate. BUILD/install/manifest pin the exact source.
- PASS: CRC, every member byte compared against the pinned snapshot/generated
  metadata, SHA manifest, required paths and absence of personal data/logs.
- PASS: 291 simulated assertions plus the incoming explicit Open/Close regression.
  16 changed/new Lua files compile on Lua 5.3 with Windower literal-method
  normalization. Diff/whitespace review passed. No native Lua 5.1 or FFXI run claimed.
- New successful-command autosaves respect the existing preference, avoid duplicate
  explicit writes and merge only changed modes into the selected set without a
  runtime profile reload. Existing command-specific writes still occur with Off.
  Failed/no-op commands do not trigger new implicit saves; quiet feedback survives.
- Clean scalar option controls follow permitted commands without replacing dirty
  drafts; new eligible panes focus their options list, not an activated field.
  Command/profile/structural forms retain their entry behavior. Grouped/structural
  refresh and replaced roots remain conservative and require reopening.
- PENDING: all new Windows/Windower/FFXI acceptance, original Modes save-on-exit
  revert, actual physical/AHK IJKL capture, controller release-order behavior,
  named-set persistence after reload and navigation/focus across real panels.
- Partial save success across owners is possible. No rollback/retry is added.
  Trace remains bounded and opt-in; repeated dumps replace the same character log.

Install/rollback instructions and the current live checklist are inside the ZIP.
This delivery record is later than the packaged source; it does not retroactively
change the embedded testing record. The main branch remains the live-accepted line.
