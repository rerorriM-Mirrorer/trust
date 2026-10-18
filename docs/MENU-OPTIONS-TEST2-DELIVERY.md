# Menu options Test 2 delivery — October 17, 2026

Author: Awake. Repository: rerorriM-Mirrorer/trust.
Branch: `test/menu-exit-save-20261017`; main unchanged.

- Published source: `8b087f5329c40d2462cea54bba4de162bf007d4a`.
- Local implementation tree matched the published Git tree exactly.
- Package: [Trust-MenuOptions-Test2-Cumulative.zip](../testing-packages/Trust-MenuOptions-Test2-Cumulative.zip).
- SHA-256: `52201f5fd316f6fa6fae00fa2770a7825f3464e8f34b9ecaaeb6eb67b6dcf5d5`.
- Size: 156,770 bytes; 48 members under `trust/`.
- Contents: 40 cumulative runtime/assets, README/WORKFLOW/TESTING/AGENTS,
  keyboard handoff, installation/build notes, SHA-256 manifest. No user data.
- PASS: ZIP CRC, member byte checks and all source/docs against the fetched
  published source. Embedded TESTING is pinned to that source commit.
- PASS: 93 mocked menu/save/layout/input assertions, 10 expanded Modes flow
  checks, 24 existing quiet-movement assertions. OS/rendering/state/persistence
  remain mocked where documented. Seven changed/test files compile with Lua
  5.3 after Windower quoted-literal normalization; no native Lua 5.1 execution.
- PENDING: all Test 2 Windows/Windower/FFXI acceptance, real AHK input delivery.
- UNRESOLVED: user's Modes edit reverted on exit. Test 2 adds durable save
  feedback and pending-draft status; it does not claim to fix that live report.

Install/rollback and the next focused test are inside the ZIP. Source publication
used the connected GitHub service; package is committed separately after source
publication. No XIVCrossbar/AHK files are changed in this repository.
