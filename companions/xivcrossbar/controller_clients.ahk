; A: the mutex prevents duplicates; this registry decides whether anyone still
; needs the shared wrapper. No heartbeat expiry: minimized clients count too.
WrapperClientsStatus() {
    global WC
    ; A: reuse the existing scan/status cadence. No extra file or owner probes.
    return "clients_reason=" . WC.reason . "`nclients_seen=" . WC.seen . "`nclients_loaded=" . WC.loaded
        . "`nclients_records=" . WC.records . "`nclients_locked=" . WC.locked . "`nclients_owner_errors=" . WC.errors
        . "`nclients_invalid_records=" . WC.invalid . "`nclients_blockers=" . WC.blockers
        . "`nclients_last_close=" . WC.latestClose . "`nclients_last_kill=" . WC.latestKill
        . "`nclients_scan_count=" . WC.scans . "`nclients_scan_tick=" . WC.lastPoll
        . "`nclients_directory=" . A_ScriptDir . "\data\controller-clients`n"
}

WrapperClientsInit() {
    global WC
    WC := {seen:false, tokens:Map(), retired:Map(), lastPoll:0, emptySince:0, lastClose:0, kill:false}
    WC.reason := "waiting-for-scan", WC.loaded := 0, WC.records := 0, WC.locked := 0, WC.errors := 0
    WC.invalid := 0, WC.blockers := "", WC.scans := 0, WC.latestClose := 0, WC.latestKill := false
}

WrapperClientsShouldExit() {
    global WC
    if (A_TickCount - WC.lastPoll < 250)
        return false
    WC.lastPoll := A_TickCount
    WC.scans += 1, WC.records := 0, WC.locked := 0, WC.errors := 0, WC.invalid := 0, WC.blockers := ""
    scanStarted := DllCall("GetTickCount64", "UInt64")
    loaded := 0
    latestClose := 0
    latestKill := false
    pattern := A_ScriptDir . "\data\controller-clients\*.ini"
    Loop Files pattern, "F"
    {
        path := A_LoopFileFullPath
        WC.records += 1
        ; Each owner token is a unique Lua session. Once its owner is closed,
        ; that session cannot return; new loads publish a new filename/token.
        if (WC.retired.Has(path)) {
            record := WC.retired[path]
            alive := false
        } else {
            readStarted := DllCall("GetTickCount64", "UInt64")
            readFailed := false, contents := ""
            try contents := FileRead(path, "CP0")
            catch
                readFailed := true
            InputTimingOperation("client-record-read", readStarted)
            record := readFailed ? false : WrapperClientRecord(contents)
            ownerStarted := DllCall("GetTickCount64", "UInt64")
            alive := WrapperOwnerAlive(path . ".owner")
            if (WC.ownerError = 32 or WC.ownerError = 33)
                WC.locked += 1
            else if (WC.ownerError and WC.ownerError != 2 and WC.ownerError != 3)
                WC.errors += 1
            if (alive and loaded < 3)
                WC.blockers .= (WC.blockers = "" ? "" : ",") . A_LoopFileName . ":" . WC.ownerError
            InputTimingOperation("client-owner-check", ownerStarted)
            if (!IsObject(record)) {
                WC.invalid += 1
                ; An uncertain live owner must not make the wrapper exit.
                if (alive) {
                    loaded++
                    WC.seen := true
                }
                continue
            }
            if (!alive)
                WC.retired[path] := record
        }
        id := record.id, state := record.state, kill := record.kill, closed := record.closed
        if (alive) {
            loaded++
            WC.seen := true
            WC.tokens[id] := {kill:kill = "true", deadAt:0}
        } else if (state = "closing") {
            if (closed + 0 >= latestClose) {
                latestClose := closed + 0
                latestKill := kill = "true"
            }
        } else if (WC.tokens.Has(id)) {
            ; Owner handles also close when a game/Lua process terminates.
            known := WC.tokens[id]
            if (!known.deadAt)
                known.deadAt := WrapperClientsClock()
            if (known.deadAt >= latestClose) {
                latestClose := known.deadAt
                latestKill := known.kill
            }
        }
    }
    InputTimingOperation("client-registry-scan", scanStarted)
    exiting := WrapperClientsDecision(WC, loaded, latestClose, latestKill, A_TickCount)
    WC.loaded := loaded, WC.latestClose := latestClose, WC.latestKill := latestKill
    WC.reason := loaded ? "clients-loaded" : !WC.seen ? "no-client-observed" : !latestKill ? "last-client-keeps-running" : exiting ? "exit-requested" : "shutdown-grace"
    return exiting
}

; A: testable lifecycle policy; native enumeration above supplies observations.
WrapperClientsDecision(state, loaded, latestClose, latestKill, now) {
    if (loaded) {
        state.emptySince := 0
        state.lastClose := 0
        return false
    }
    if (!state.seen)
        return false
    if (!state.emptySince or state.lastClose != latestClose) {
        state.emptySince := now
        state.lastClose := latestClose
    }
    return latestKill and now - state.emptySince >= 2000
}

WrapperOwnerAlive(path) {
    global WC
    WC.ownerError := 0
    ; A live Lua session holds a read handle; an exclusive open fails with 32.
    ; Access/query failures are treated as live, so uncertainty never kills it.
    handle := DllCall("CreateFileW", "WStr", path, "UInt", 0x80000000, "UInt", 0, "Ptr", 0, "UInt", 3, "UInt", 128, "Ptr", 0, "Ptr")
    if (handle = -1 or handle = 0xFFFFFFFF) {
        code := A_LastError
        WC.ownerError := code
        return code != 2 and code != 3
    }
    DllCall("CloseHandle", "Ptr", handle)
    return false
}

WrapperClientsClock() {
    stamp := A_NowUTC
    stamp := DateDiff(stamp, "19700101000000", "Seconds")
    return stamp + A_MSec / 1000
}

; A: one complete snapshot replaces five synchronous Windows INI reads.
; Lua writes this exact private format atomically. Unrelated files are ignored.
WrapperClientRecord(contents) {
    if (!RegExMatch(contents, "smi)^\[Client\]\r?\n(.*?)(?=^\[|\z)", &section))
        return false
    if (!RegExMatch(section[1], "im)^protocol=([^\r\n]+)\r?$", &protocol) or protocol[1] != "owner-file-v1")
        return false
    if (!RegExMatch(section[1], "im)^id=([A-Za-z0-9-]+)\r?$", &id)
        or !RegExMatch(section[1], "im)^state=(loaded|closing)\r?$", &state)
        or !RegExMatch(section[1], "im)^kill=(true|false)\r?$", &kill)
        or !RegExMatch(section[1], "im)^closed=([0-9]+(?:\.[0-9]+)?)\r?$", &closed))
        return false
    return {id:id[1], state:state[1], kill:kill[1], closed:closed[1] + 0}
}
