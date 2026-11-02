# Trust controller integration — Neutral Takeover 1

This is a matched companion overlay for the existing personal AHK v2 XIVCrossbar installation. It is not a standalone addon or a complete XIVCrossbar installation.

Stop the running AHK wrapper and unload Trust on all clients. Back up both addons' code. Copy the trust/ and xivcrossbar/ folders in the testing ZIP over the matching existing addon folders, restart the wrapper through XIVCrossbar, and reload Trust. All six AHK files are included together to avoid mixed companion versions. Saved settings and bindings are not included or reset. Keep the standalone TrustMovement addon unloaded when using Trust's integrated receiver.

- First joystick movement after switching to another FFXI client requests the existing leader handoff.
- Return the stick below 0.16 magnitude for at least 100ms; the next movement at 0.24 magnitude or greater requests local Trust Stop only. Continued held movement does not repeat requests.
- PS5 Extended mute (Joy15) requests the leader handoff explicitly, once per fresh press in gameplay/crossbar context. This chooses the automation leader; it does not change the game's party leader.
- Current Trust Movement options govern actions. Defaults stop self, clear local follow, and request others follow/assist/start. Local Stop pauses the whole addon, including casting. Explicit Trust Start resumes eligible automation.
- Menu/chat/cutscene guards remain. Send ignores blocked episodes without later retry; Ready retains its readiness behavior. The new local-only pulse requires this version's Trust receiver capability; old receivers keep first-focus behavior.

Provenance: six AHK v2 files from XIVCrossbar-AHKv2-PetActions1-Cumulative.zip. Changes are limited to movement_signal.ahk, personal_controls.ahk mute routing, and ffxi_directinput.ahk movement-version reporting. This integration snapshot is tracked in the Trust development branch under companions/xivcrossbar; it has not been merged to the separate XIVCrossbar branch. Public AHK v1 builds are not compatible.

Automated checks cover sender decision branches with narrow AHK-to-JS translation, lexical/include/helper closure, and actual Trust receiver/Stop wiring in simulated Lua. Native Windows/AHK/controller/FFXI testing is pending. Stop and restart on the same focused character, repeat neutral/move, verify others receive no repeated handoff, and test mute press/hold plus menu/chat/focus changes. Restore both backed-up code folders to roll back.

The accompanying TESTING.md and WORKFLOW.md describe the complete Trust integration batch; prior pulling and message-format work remains as recorded there.
