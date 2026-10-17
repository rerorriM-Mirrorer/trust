# Menu options Test 1 — delivery record

Author: Awake. Date: October 17, 2026 (America/Chicago).

- Repository/branch: rerorriM-Mirrorer/trust, `test/menu-exit-save-20261017`.
- Exact packaged source snapshot: `73aaa3839b66ae698bc692cdf9ac721add354565`.
- Compatible original baseline: `575bf583ef41e0018f05b922c6673ab89b54af95`, Trust 17.7.3.
- Artifact: [Trust-MenuOptions-Test1-Cumulative.zip](../testing-packages/Trust-MenuOptions-Test1-Cumulative.zip).
- SHA-256: `5d11cbabd9a1dc774f7113bce824b0f65219b185a1169a0f5961e5d6683968fb`.
- ZIP size: 152,140 bytes; 47 members, all under `trust/`.
- Contents: 40 cumulative runtime/asset files, README/TESTING/WORKFLOW/AGENTS, install/build notes and SHA-256 manifest. No character data or earlier ZIPs included.
- Verification: every member passed CRC and byte comparison; packaged source/docs match the fetched published source commit. The embedded TESTING is the record from that exact source snapshot.
- Tests: 84 mocked menu/save/layout/input assertions; 24 prior quiet-movement assertions; 21 files compiled with available Lua 5.3 and documented Windower-syntax normalization. No native Lua 5.1 or Windows/FFXI acceptance claimed.
- Live status: PENDING. Follow the checklist inside the package; test one client first.

The publication commits have identical trees to the corresponding locally tested commits. Their messages retain the local commit references and authoring credit. Shell git push lacked credentials; publication used the connected GitHub service after verifying the public repository and access. No merge to main.

Cumulative source commits: `0cb4549c` (guidance), `99c9e9cd` (save/layout), `90fbc0b5` (IJKL), `73aaa383` (tests/docs/status).

This delivery commit adds the archive and its record; it does not change executable source.

