; A: physical edges share one acknowledged stream, so a face button cannot
; overtake a trigger in a different channel. Personal shortcuts stay separate.
ControllerMessageInit() {
    global CM
    CM := {requested:false, token:"", seq:0, ack:0, pending:[], previous:InputState()
        , phase:"keys", seen:0, nextWrite:0, path:"", error:false, expanded:false, controlSeq:InputState(), canResume:false, lastHealthy:0}
}

ControllerMessageLease(lease, contextPath) {
    global CM
    now := DllCall("GetTickCount64", "UInt64")
    if (!RegExMatch(lease, "m)^button_mode=(messages|keys)\r?$", &mode))
        return
    requested := mode[1] = "messages"
    token := ""
    if (requested) {
        if (!RegExMatch(lease, "m)^button_token=([A-Za-z0-9-]+)\r?$", &value)
            or !RegExMatch(lease, "m)^button_ack=(\d+)\r?$", &ack))
            return
        token := value[1]
    }
    CM.seen := now
    if (requested != CM.requested or token != CM.token) {
        resume := requested and CM.requested and CM.canResume and CM.expanded
            and now - CM.lastHealthy <= 2000
            and RegExMatch(lease, "m)^bank_protocol=1\r?$")
            and CM.path = RegExReplace(contextPath, "\.ini$", ".buttons")
            and RegExMatch(lease, "m)^button_recover=1\r?$")
        controls := CM.controlSeq
        ; Finish the previous route before adopting the current client's token.
        ReleaseTransport(true)
        CM.requested := requested, CM.token := token, CM.seq := requested ? ack[1] + 0 : 0, CM.ack := 0
        CM.pending := [], CM.previous := InputState(), CM.phase := "neutral", CM.nextWrite := 0
        CM.controlSeq := resume ? controls : InputState(), CM.canResume := resume
        if (resume)
            CM.phase := "recover"
        CM.path := RegExReplace(contextPath, "\.ini$", ".buttons")
        if (requested) {
            ; A restarted writer resumes above Lua's acknowledgment and clears
            ; any former hold before accepting a new, neutral-armed gesture.
            ControllerMessageAdd("cancel", 0)
            ControllerMessageFlush(true)
        }
        InputTraceRecord("button route=" . mode[1] . " waiting-neutral")
        if (RegExMatch(lease, "m)^button_reason=([a-z-]+)\r?$", &reason))
            InputTraceRecord("button receiver reset reason=" . reason[1])
        if (resume)
            InputTraceRecord("button recovery same-client, waiting for action-button release")
    }
    if (requested) {
        CM.ack := ack[1] + 0
        retained := []
        for _, event in CM.pending
            if (event.seq > CM.ack)
                retained.Push(event)
        CM.pending := retained
    }
}

ControllerMessageHeld(index) {
    global CM
    return CM.requested and CM.previous[index]
}

ControllerMessageAdd(kind, button) {
    global CM
    CM.seq += 1
    CM.pending.Push({seq:CM.seq, kind:kind, button:button, tick:DllCall("GetTickCount64", "UInt64")})
    InputTraceRecord("message " . kind . " button=" . button . " seq=" . CM.seq)
}

ControllerMessageCancel() {
    global CM
    if (!IsObject(CM) or !CM.requested)
        return
    if (CM.phase = "messages" and (CM.pending.Length or ControllerMessageAnyHeld())) {
        ControllerMessageAdd("cancel", 0)
        ControllerMessageFlush(true)
    }
    CM.previous := InputState(), CM.phase := "neutral"
    CM.controlSeq := InputState(), CM.canResume := false
}

ControllerMessageStall() {
    global CM
    controls := CM.controlSeq, recover := CM.canResume
    ControllerMessageCancel()
    CM.controlSeq := controls, CM.canResume := recover
    ; Request a new receiver generation. Never drain an overdue action queue
    ; into the recovered hold, even if its acknowledgement arrives later.
    ControllerMessageAdd("stall", 0)
    ControllerMessageFlush(true)
}

ControllerMessageAnyHeld() {
    global CM
    Loop 14
        if (CM.previous[A_Index])
            return true
    return false
}

ControllerMessageFlush(force := false) {
    global CM
    if (!CM.requested or CM.token = "" or CM.path = "")
        return false
    now := DllCall("GetTickCount64", "UInt64")
    if (!force and now < CM.nextWrite)
        return true
    CM.nextWrite := now + 100
    stamp := A_NowUTC
    stamp := DateDiff(stamp, "19700101000000", "Seconds")
    contents := "token=" . CM.token . "`nstamp=" . stamp . "`nbeat=" . now . "`n"
    for _, event in CM.pending
        contents .= event.seq . "," . event.kind . "," . event.button . "`n"
    contents .= "END`n"
    temporary := CM.path . ".tmp"
    destination := CM.path
    timingWriteStart := DllCall("GetTickCount64", "UInt64")
    CM.error := !PublishControllerFile(temporary, destination, contents)
    InputTimingOperation("button-file-write", timingWriteStart)
    return !CM.error
}

; Return true whenever this stream owns input, including neutral handoffs and
; uncertain reads. A failed write must never fall through into keyboard output.
ControllerMessagePoll(states) {
    global CM
    neutral := true
    Loop 14
        if (states[A_Index])
            neutral := false
    now := DllCall("GetTickCount64", "UInt64")
    if (CM.requested and now - CM.seen > 100) {
        if (CM.phase = "messages" or CM.phase = "recover") {
            InputTraceRecord("button stall reason=lease-gap")
            ControllerMessageStall()
        }
        CM.phase := "uncertain"
        ; An unloaded/logged-out client can return to its old login controls,
        ; only after a complete neutral interval and expiry of the old lease.
        if (neutral and now - CM.seen > 2500) {
            CM.requested := false, CM.token := "", CM.phase := "keys"
        }
        return true
    }
    if (CM.phase = "neutral" or CM.phase = "uncertain") {
        if (neutral) {
            CM.phase := CM.requested ? "messages" : "keys"
            if (CM.requested and CM.expanded)
                ControllerMessageAdd("banks", 0)
        }
        ControllerMessageFlush()
        return true
    }
    if (!CM.requested)
        return false
    if (CM.phase = "recover") {
        if (now - CM.lastHealthy > 2000) {
            CM.phase := "neutral", CM.controlSeq := InputState(), CM.canResume := false
            InputTraceRecord("button recovery expired, waiting-neutral")
            ControllerMessageFlush(true)
            return true
        }
        ; Never replay face/D-pad/menu presses. Only the original still-held
        ; controls can recover, after all action buttons have been released.
        quiet := true
        Loop 10
            if (states[A_Index])
                quiet := false
        for _, i in [11, 12, 13, 14] {
            if (states[i] and !CM.controlSeq[i])
                quiet := false
        }
        if (quiet) {
            restored := InputState()
            ControllerMessageAdd("banks", 0)
            Loop 4 {
                selected := 0, first := 2147483647
                for _, i in [11, 12, 13, 14] {
                    if (CM.controlSeq[i] and CM.controlSeq[i] < first) {
                        selected := i, first := CM.controlSeq[i]
                    }
                }
                if (selected) {
                    CM.controlSeq[selected] := 0
                    if (states[selected]) {
                        ControllerMessageAdd("resume", selected)
                        CM.previous[selected] := true
                        restored[selected] := CM.seq
                    }
                }
            }
            CM.controlSeq := restored
            CM.phase := "messages", CM.canResume := true, CM.lastHealthy := now
            InputTraceRecord("button recovery complete, no action replay")
        }
        ControllerMessageFlush(true)
        return true
    }
    if (CM.phase != "backpressure" and (CM.pending.Length > 96
        or (CM.pending.Length and now - CM.pending[1].tick > 350))) {
        InputTraceRecord("button stall reason=ack-backlog")
        ControllerMessageStall()
        CM.phase := "backpressure"
        return true
    }
    if (CM.phase = "backpressure") {
        if (neutral and !CM.pending.Length) {
            CM.phase := "messages"
            if (CM.expanded)
                ControllerMessageAdd("banks", 0)
        }
        ControllerMessageFlush()
        return true
    }
    changed := false
    ; Releases finish the previous gesture. New trigger downs precede new slots
    ; sampled together; a truly simultaneous pair has deterministic L2 priority.
    Loop 14 {
        i := A_Index
        if (CM.previous[i] and !states[i]) {
            ControllerMessageAdd("up", i)
            CM.previous[i] := false, changed := true
            if (i >= 11)
                CM.controlSeq[i] := 0
        }
    }
    for _, i in [11, 12, 13, 14, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8] {
        if ((i <= 12 or CM.expanded) and states[i] and !CM.previous[i]) {
            ControllerMessageAdd("down", i)
            CM.previous[i] := true, changed := true
            if (i >= 11)
                CM.controlSeq[i] := CM.seq
        }
    }
    ControllerMessageFlush(changed)
    CM.canResume := true, CM.lastHealthy := now
    return true
}
