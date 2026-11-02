; A: integrated Trust movement Send/Ready test 1, AutoHotkey v2.
; First movement per FFXI focus session hands off; later stick episodes stop
; only the local Trust. Stable neutral rearms without repeating party handoff.
MovementInit() {
    global TM
    TM := {client:0, fired:false, sent:0, signalOwner:0, due:0
        , takeoverSupported:false, episode:false, neutralSince:0, signalKey:"", nextLease:0, ready:false, policy:"Send", policies:Map(), reason:"waiting-client", threshold:0.24}
}

MovementTick(active) {
    global TM
    if (TM.signalOwner and (active != TM.signalOwner
        or DllCall("GetTickCount64", "UInt64") >= TM.due))
        MovementRelease()
    ; Keep the last FFXI identity while the desktop or another app is active.
    if (active and active != TM.client) {
        TM.client := active, TM.fired := false, TM.episode := false, TM.neutralSince := 0
        TM.nextLease := 0, TM.ready := false, TM.reason := "armed"
    }
}

MovementPoll(states, active, observation := false) {
    global TM, PC
    if (!active or !states.HasOwnProp("moveX") or !states.HasOwnProp("moveY"))
        return
    now := DllCall("GetTickCount64", "UInt64")
    magnitude := states.moveX * states.moveX + states.moveY * states.moveY
    ; Hysteresis and 100ms of observed neutral reject noise and tiny pauses.
    if (magnitude < 0.16 * 0.16) {
        if (!TM.neutralSince)
            TM.neutralSince := now
        if (now - TM.neutralSince >= 100)
            TM.episode := false
        return
    }
    TM.neutralSince := 0
    if (TM.episode or magnitude < TM.threshold * TM.threshold)
        return
    ; Existing personal controls expose addon menus as well as text entry.
    ; Holding a crossbar trigger alone still permits movement takeover.
    ready := MovementReceiverReady(active)
    if (TM.fired and !TM.takeoverSupported) {
        TM.reason := "local-takeover-unavailable"
        return
    }
    ; Send consumes the first movement even in a blocked context. Trust makes
    ; the immediate accept/ignore decision; there is no delayed retry.
    if (TM.policy = "Ready" and PC.enabled) {
        context := PersonalContext(active, observation)
        if (context != "gameplay" and context != "crossbar") {
            TM.reason := "personal-" . context
            return
        }
    }
    if (TM.policy = "Ready" and !ready)
        return
    ; Recheck immediately before injecting. Blind preserves held modifiers;
    ; this is a separate scan code, outside the wrapper's F1-F12 signals.
    if (WinActive("ahk_class FFXiClass") != active)
        return
    MovementSend(active, TM.fired)
}

; Explicit leader request uses the first-focus handoff regardless of the latch.
MovementLeader(active) {
    global TM
    MovementTick(active)
    ready := MovementReceiverReady(active)
    if (TM.policy = "Ready" and !ready)
        return
    MovementSend(active, false)
}

MovementSend(active, localOnly) {
    global TM
    if (!active or WinActive("ahk_class FFXiClass") != active)
        return
    ; SC079 is a local-only takeover; SC07B preserves first-focus handoff.
    ; Never reuse a held signal edge for a new movement episode.
    if (TM.signalOwner)
        MovementRelease()
    TM.signalKey := localOnly ? "vk1Csc079" : "vk1Dsc07B"
    TM.fired := true, TM.episode := true, TM.sent += 1, TM.reason := "sent"
    TM.signalOwner := active
    TM.due := DllCall("GetTickCount64", "UInt64") + 30
    SendEvent("{Blind}{" . TM.signalKey . " down}")
    title := ""
    try title := WinGetTitle("ahk_id " . active)
    line := A_NowUTC . " hwnd=" . active . " title=" . title . " policy=" . TM.policy . " key=" . TM.signalKey . " sent=" . TM.sent . " x=" . states.moveX . " y=" . states.moveY . "`n"
    try {
        DirCreate(A_ScriptDir . "\data\diagnostics")
        FileAppend(line, A_ScriptDir . "\data\diagnostics\trust-movement.log", "CP0")
    }
}

MovementReceiverReady(active) {
    global TM
    nowTick := DllCall("GetTickCount64", "UInt64")
    if (nowTick < TM.nextLease)
        return TM.ready
    TM.nextLease := nowTick + 100, TM.ready := false, TM.takeoverSupported := false
    ; A transient file gap must not turn an already selected Ready into Send.
    TM.policy := TM.policies.Has(active) ? TM.policies[active] : "Send"
    TM.reason := "receiver-not-ready"
    title := ""
    try title := WinGetTitle("ahk_id " . active)
    now := A_NowUTC
    now := DateDiff(now, "19700101000000", "Seconds")
    ; The receiver publishes only while its own client has focus. Match the
    ; character in the title, as the existing personal-controls bridge does.
    ; Prefer the integrated Trust receiver. RC3 remains a Ready-only fallback
    ; for users who have not migrated; never run both receivers together.
    Loop 2
    {
    folder := A_Index = 1 ? "trust\data\movement" : "trustmovement\data"
    Loop Files A_ScriptDir . "\..\" . folder . "\*.lease"
    {
        timingReadStart := DllCall("GetTickCount64", "UInt64")
        try lease := FileRead(A_LoopFileFullPath, "CP0")
        catch
            continue
        InputTimingOperation("movement-file-read", timingReadStart)
        if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", &name)
            or !RegExMatch(title, "i)(^|[^a-z])" . name[1] . "([^a-z]|$)"))
            continue
        if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", &stamp)
            or !RegExMatch(lease, "m)^ready=([01])\r?$", &ready))
            continue
        age := now - stamp[1]
        if (age < -1 or age > 2) {
            TM.reason := "receiver-stale"
            continue
        }
        if (folder = "trustmovement\data")
            TM.policy := "Ready"
        else if (RegExMatch(lease, "m)^policy=(Send|Ready)\r?$", &policy))
            TM.policy := policy[1]
        else
            continue
        TM.policies[active] := TM.policy
        TM.takeoverSupported := folder != "trustmovement\data" and RegExMatch(lease, "m)^takeover=neutral1\r?$")
        if (TM.fired and TM.takeoverSupported and RegExMatch(lease, "m)^local_ready=([01])\r?$", &localReady))
            TM.ready := localReady[1] = "1"
        else
            TM.ready := ready[1] = "1"
        TM.reason := TM.ready ? "receiver-ready" : "receiver-blocked"
        return TM.ready
    }
    }
    return false
}

MovementRelease() {
    global TM
    if (!IsObject(TM) or !TM.signalOwner)
        return
    target := TM.signalOwner
    key := TM.signalKey
    TM.signalOwner := 0
    if (target = WinActive("ahk_class FFXiClass")) {
        SendEvent("{Blind}{" . key . " up}")
    } else if WinExist("ahk_id " . target) {
        try ControlSend("{Blind}{" . key . " up}", , "ahk_id " . target)
    }
}
