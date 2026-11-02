; A: optional extended controls. PS5 and Xbox share ownership/gesture handling.
; This include owns its keys; ordinary button transport stays in the wrapper.
PersonalInit(selected, prefix) {
    global PC
    PC := {enabled:(selected = "ps5-extended" or selected = "xinput-extended")
        , xinput:selected = "xinput-extended", prefix:prefix, owner:0, ready:false
        , keys:Map(), releases:Map(), blocked:Map(), suppressed:Map(), previous:InputState(), connected:false
        , touch:{phase:"idle"}, clicks:{phase:"idle"}, r1:{phase:"idle"}
        , layer:{phase:"idle"}, layerVisible:"", context:"unknown"
        , l1:{token:"", mode:"keyboard", seq:0, ack:0, pending:[], available:false, showing:false}
        , clients:[], lastClient:0, lastOther:0, contextSeen:0, contextPaused:false, contextPauses:0
        , contextObservations:0, contextReuses:0, contextScans:0, contextFileReads:0
        , targetR2:false, targetR3:false, realDpad:false, r1Menus:false, banks:false
        , native:{token:"", ack:0, requests:[], active:Map(), keys:Map()}}
    ; Old PSHoldAction/DoubleTapMs preferences remain untouched but are dormant.
}

PersonalPoll(states, active, observation := false) {
    global PC, appsOwned, previous
    if (!PC.enabled)
        return states
    foreground := WinExist("A")
    if (active)
        PC.lastClient := active
    else if PersonalOtherWindow(foreground)
        PC.lastOther := foreground
    if (!IsObject(states)) {
        PersonalRelease()
        PC.connected := false, PC.previous := InputState()
        return states
    }
    raw := states.Clone()
    ; XInput named buttons are sampled atomically with faces/triggers. Reading
    ; JoyN here could mix in another attached controller or the wrong numbering.
    if (!PC.xinput)
        for name, button in Map("l1", 5, "l3", 11, "mute", 15, "ps", 13, "r1", 6, "r3", 12, "touch", 14)
            raw.%name% := GetKeyState(PC.prefix . "Joy" . button) ? true : false
    now := DllCall("GetTickCount64", "UInt64")
    if (!PC.connected) {
        PC.connected := true, PC.previous := raw
        PC.ready := false, PC.blocked := Map(), PC.suppressed := Map()
        return states
    }
    PersonalPS(raw.ps, foreground, active, raw.l1 or raw.r1 or raw[11] or raw[12])
    if (WinActive("ahk_class FFXiClass") != active) {
        PC.previous := raw
        return states
    }
    if (PC.owner != active) {
        PersonalRelease()
        PC.owner := active, PC.previous := raw
    }
    PersonalReleaseDue(now)
    mode := PersonalContext(active, observation)
    PC.context := mode
    if (PersonalLeasePause(mode, now, PC.contextSeen, PC.ready)) {
        if (!PC.contextPaused) {
            PC.contextPauses += 1
            InputTraceRecord("context pause; no new downs")
        }
        PC.contextPaused := true, PC.context := "updating"
        ; An uncertain lease must not authorize a deferred R on its recovery.
        PC.r1.phase := "cancelled"
        ; Keep existing transport holds only while still physically held. New
        ; downs wait for a verified current lease; releases are never delayed.
        Loop 12 {
            held := previous[A_Index] or ControllerMessageHeld(A_Index)
            states[A_Index] := states[A_Index] and held
        }
        PersonalL1Block(raw)
        if (raw.r1 and !raw.l1 and !raw[11] and !raw[12])
            for _, i in [6, 8]
                if (raw[i])
                    PC.blocked[i] := ""
        return PersonalFilter(states, raw)
    }
    if (PC.contextPaused)
        InputTraceRecord("context resume=" . mode)
    PC.contextPaused := false
    if (mode = "gameplay" or mode = "crossbar")
        PC.contextSeen := now
    contextAllowed := active and (mode = "gameplay" or mode = "crossbar" or ((mode = "cutscene" or mode = "trust" or mode = "chat") and PC.banks)) and !raw[9] and !raw[10]
    allowed := contextAllowed and mode = "gameplay" and !raw[11] and !raw[12] and !appsOwned
    neutral := !raw.l1 and !raw.r1 and !raw.l3 and !raw.r3 and !raw.touch and !raw.ps and !raw.mute
    Loop 12
        if (raw[A_Index])
            neutral := false
    if (!contextAllowed) {
        PersonalRelease()
        PC.previous := raw
        return PersonalFilter(states, raw)
    }
    if (!PC.ready) {
        if ((allowed or (contextAllowed and (mode = "cutscene" or mode = "trust" or mode = "chat") and PC.banks)) and neutral) {
            PC.ready := true
            PC.touch.phase := "idle", PC.clicks.phase := "idle", PC.r1.phase := "idle"
        }
        if (allowed)
            PersonalL1Block(raw)
        if (allowed and raw.r1 and !raw.l1)
            for _, i in [6, 8]
                if (raw[i])
                    PC.blocked[i] := ""
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    ; PS5 mute: one explicit leader handoff per fresh press. Apply before
    ; either bank path, after focus/context/neutral readiness guards.
    if (raw.mute and !PC.previous.mute and (mode = "gameplay" or mode = "crossbar"))
        MovementLeader(active)

    if (PC.banks)
        return PersonalBanksPoll(states, raw, mode, now)

    arrows := ["Up", "Right", "Down", "Left"]
    PersonalTargetTrial(raw, mode)
    layer := PersonalLayerStep(PC.layer, raw.l1, raw[11], raw.r1, raw[12])
    layerChanged := layer != PC.layerVisible
    if (layerChanged) {
        PersonalRelease(false)
        if (layer = "keyboard" or layer = "bank") {
            ; Release the old ordinary transport before revealing L1. A held
            ; slot is consumed on reveal, never executed in the new layer.
            ReleaseTransport(true)
            PersonalL1Block(raw)
            PersonalL1Event(layer = "bank" ? "bank" : "show")
        } else
            PersonalL1Event("release")
        PC.layerVisible := layer
        InputTraceRecord("layer " . layer)
    }
    if (layer = "bank" or layer = "tail")
        states[11] := false
    if (layer = "tail") {
        Loop 12
            if (raw[A_Index])
                PC.blocked[A_Index] := ""
    }
    allowed := contextAllowed and layer != "ordinary" and layer != "tail" and !raw[12] and !appsOwned
    if (!allowed) {
        PersonalRelease(false)
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    PersonalNativeDPad(states, raw, mode, now)
    taps := []
    ; Each assigned Ctrl shortcut fires once. Empty L1 slots are reserved and
    ; consume their button rather than leaking native confirm/cancel.
    if ((layer = "keyboard" or layer = "bank") and !raw.r1) {
        shortcuts := Map(1, "i", 2, "m", 3, "e", 4, "j", 5, "Space", 6, "q", 7, "", 8, "s")
        for i, key in shortcuts {
            if (!layerChanged and raw[i] and !PC.previous[i]) {
                PC.blocked[i] := key
                if (PC.l1.available and layer = "bank") {
                    slots := [4, 3, 2, 1, 6, 5, 7, 8]
                    PersonalL1Event("slot", slots[i])
                } else if (layer = "keyboard" and key != "")
                    taps.Push({key:key, modifier:"LControl"})
            }
        }
        ; A held button from before L1 is consumed, never re-fired or leaked.
        PersonalL1Block(raw)
    } else if (raw.r1 and !raw.l1) {
        Loop 4 {
            i := A_Index
            if (raw[i] and !PC.previous[i])
                PC.blocked[i] := arrows[i]
        }
        PersonalR1Menus(raw, mode, now)
        for i, key in Map(5, "Enter", 7, "Escape") {
            if (raw[i] and !PC.previous[i]) {
                PC.blocked[i] := key
                taps.Push({key:key, modifier:""})
            }
        }
    } else if (raw.l1 and raw.r1) {
        Loop 8
            if (raw[A_Index])
                PC.blocked[A_Index] := ""
        if (!PC.previous.l1 or !PC.previous.r1)
            taps.Push({key:"Tab", modifier:""})
    }
    states := PersonalFilter(states, raw)
    transportBusy := false
    Loop 12
        if (states[A_Index])
            transportBusy := true
    if (transportBusy)
        PersonalRelease(false)
    else {
        Loop 4 {
            i := A_Index
            PersonalKey(arrows[i], raw.r1 and !raw.l1 and PC.blocked.Has(i)
                and raw[i] and !PC.suppressed.Has(i))
        }
        if (taps.Length) {
            Loop 4 {
                i := A_Index
                if (PC.blocked.Get(i, "") = arrows[i]) {
                    PC.suppressed[i] := true
                    PersonalKey(arrows[i], false)
                }
            }
        }
        for _, tap in taps
            PersonalChord(tap.key, tap.modifier, now)
    }

    anyButton := false
    Loop 12
        if (raw[A_Index])
            anyButton := true
    busy := transportBusy or anyButton or raw.ps or raw.mute
    touchEvent := PersonalTouchStep(PC.touch, raw.touch, PC.previous.touch
        , busy or raw.l1 or raw.r1 or raw.l3 or raw.r3, now)
    if (touchEvent != "")
        PersonalChord(touchEvent, "", now)
    clickEvent := PersonalClicksStep(PC.clicks, raw.l3, raw.r3
        , PC.previous.l3, PC.previous.r3, busy or raw.l1 or raw.r1 or raw.touch)
    PersonalKey("vkBCsc033", clickEvent = "vkBCsc033")
    PersonalKey("vkBEsc034", clickEvent = "vkBEsc034")
    if (clickEvent = "h")
        PersonalChord(clickEvent, "", now)

    PersonalR1Tap(raw, busy or raw.l1 or raw.l3 or raw.r3 or raw.touch, now)
    PC.previous := raw
    return states
}

; A: own a fresh ordinary D-pad hold, not its DirectLink equivalent. Preserve
; native menu navigation; addon editor/chat contexts are gated by PersonalPoll.
; Once consumed, a direction stays masked until release even if a chord starts.
PersonalNativeDPad(states, raw, mode, now) {
    global PC, CM, appsOwned
    eligible := PC.realDpad and PC.ready and mode = "gameplay" and !appsOwned
        and CM.phase = "messages" and now - CM.seen <= 100
        and !raw.l1 and !raw.r1 and !raw.l3 and !raw.r3 and !raw.touch and !raw.ps and !raw.mute
    Loop 8
        if (raw[A_Index + 4])
            eligible := false
    for _, key in ["Control", "Alt", "Shift", "LWin", "RWin", "AppsKey"]
        if GetKeyState(key, "P")
            eligible := false
    for _, key in ["LControl", "RControl", "LAlt", "RAlt", "LShift", "RShift"]
        if (PC.keys.Has(key))
            eligible := false
    for i, key in Map(1, "i", 2, "l", 3, "k", 4, "j") {
        if (eligible and raw[i] and !PC.previous[i] and !PC.blocked.Has(i)) {
            PC.blocked[i] := key
            InputTraceRecord("real IJKL own " . key)
        }
        if (PC.blocked.Get(i, "") = key) {
            states[i] := false
            if (!eligible and raw[i])
                PC.suppressed[i] := true
            PersonalKey(key, eligible and raw[i] and !PC.suppressed.Has(i))
        }
    }
}

; R1 + Square/Triangle owns the face through release. Never synthesize its
; ordinary game binding or a Ctrl+Numpad shortcut alongside the direct message.
PersonalR1Menus(raw, mode, now) {
    global PC, CM, appsOwned
    eligible := PC.r1Menus and PC.ready and mode = "gameplay" and !appsOwned
        and CM.requested and CM.phase = "messages" and now - CM.seen <= 100
        and CM.pending.Length < 96 and !PC.keys.Count
        and (!CM.pending.Length or now - CM.pending[1].tick <= 350)
        and !raw.l1 and raw.r1 and !raw.l3 and !raw.r3 and !raw.touch and !raw.ps and !raw.mute
        and !(raw[6] and raw[8])
    for _, i in [1, 2, 3, 4, 5, 7, 9, 10, 11, 12]
        if (raw[i])
            eligible := false
    for _, i in [6, 8] {
        if (raw[i] and !PC.blocked.Has(i)) {
            PC.blocked[i] := ""
            if (eligible and !PC.previous[i]) {
                ControllerMessageAdd("rmenu", i)
                ControllerMessageFlush(true)
                InputTraceRecord("R1 Trust menu button=" . i)
            }
        }
    }
}

PersonalR1Tap(raw, consumed, now) {
    global PC
    ; Preserve physical keyboard ownership and avoid modified R shortcuts.
    if (PC.keys.Count)
        consumed := true
    for _, key in ["Control", "Alt", "Shift", "LWin", "RWin", "AppsKey", "r"]
        if GetKeyState(key, "P")
            consumed := true
    event := PersonalR1Step(PC.r1, raw.r1, PC.previous.r1, consumed)
    if (event = "r") {
        InputTraceRecord("r1 unused release -> r")
        PersonalChord("r", "", now)
    }
}

PersonalFilter(states, raw) {
    global PC
    if (!PC.blocked.Count)
        return states
    retired := []
    for i, key in OrderedInputMap(PC.blocked) {
        states[i] := false
        if (!raw[i]) {
            if (i <= 4)
                PersonalKey(key, false)
            retired.Push(i)
        }
    }
    ; AHK enumerators can skip the next entry if the current key is deleted.
    ; Finish masking every held button before retiring released entries.
    for _, i in retired {
        PC.blocked.Delete(i)
        if PC.suppressed.Has(i)
            PC.suppressed.Delete(i)
    }
    return states
}

PersonalContext(hwnd, observation := false) {
    global PC
    ; The caller owns this record for one poll only. Publish a result once;
    ; consumers never mutate it or reuse permission in a later poll. Key by HWND
    ; as well so an accidental cross-client request cannot share permission.
    if (IsObject(observation) and observation.HasOwnProp("context")
        and observation.context.hwnd = hwnd) {
        PC.contextReuses += 1
        return observation.context.mode
    }
    PC.contextObservations += 1
    mode := PersonalReadContext(hwnd)
    if (IsObject(observation))
        observation.context := {hwnd:hwnd, mode:mode}
    return mode
}

PersonalReadContext(hwnd) {
    global PC
    if (!hwnd)
        return "unfocused"
    title := ""
    try title := WinGetTitle("ahk_id " . hwnd)
    now := A_NowUTC
    now := DateDiff(now, "19700101000000", "Seconds")
    ; Retry the directory read once without sleeping: Lua's remove/rename
    ; publication may complete between scans. Never reuse cached permission.
    Loop 2 {
        PC.contextScans += 1
        Loop Files A_ScriptDir . "\data\personal-controls\*.ini"
        {
            timingReadStart := DllCall("GetTickCount64", "UInt64")
            PC.contextFileReads += 1
            try lease := FileRead(A_LoopFileFullPath, "CP0")
            catch
                continue
            InputTimingOperation("context-file-read", timingReadStart)
            if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", &name))
                continue
            if (!RegExMatch(title, "i)(^|[^a-z])" . name[1] . "([^a-z]|$)"))
                continue
            if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", &stamp)
                or !RegExMatch(lease, "m)^mode=([^\r\n]+)\r?$", &mode)
                or !RegExMatch(lease, "m)^END\r?$"))
                return InputTraceContextMiss("malformed")
            age := now - stamp[1]
            if (age >= -1 and age <= 2) {
                ControllerMessageLease(lease, A_LoopFileFullPath)
                PersonalBankLease(lease)
                PersonalRealKeyLease(lease)
                PersonalR1MenuLease(lease)
                PersonalL1Lease(lease, A_LoopFileFullPath)
                return mode[1]
            }
            return InputTraceContextMiss("stale")
        }
    }
    return InputTraceContextMiss("no-matching-lease")
}

; This permission is independent of L1's native-menu visibility token. Missing
; fields from an older Lua build preserve the established Lua output path.
PersonalRealKeyLease(lease) {
    global PC, CM
    enabled := CM.requested and RegExMatch(lease, "m)^dpad_output=ahk\r?$") ? true : false
    if (enabled != PC.realDpad) {
        PersonalRelease()
        PC.realDpad := enabled
        InputTraceRecord("real IJKL permission=" . enabled . " waiting-neutral")
    }
}

; A: complete mailbox snapshots; only Lua's current session token may receive
; edges. No F13/media-key experiment, synthetic menu keys or process IPC hook.
PersonalR1MenuLease(lease) {
    global PC, CM
    enabled := CM.requested and RegExMatch(lease, "m)^r1_menus=1\r?$") ? true : false
    if (enabled != PC.r1Menus) {
        PersonalRelease()
        PC.r1Menus := enabled
    }
}

PersonalL1Lease(lease, contextPath) {
    global PC
    if (PC.banks) {
        PC.l1.available := true
        PC.targetR2 := RegExMatch(lease, "m)^target_r2=1\r?$") ? true : false
        PC.targetR3 := RegExMatch(lease, "m)^target_r3=1\r?$") ? true : false
        return
    }
    ; Native menu toggles still use keyboard shortcuts on the L1 layer. Only
    ; bank events need an executable play token; text is blocked by
    ; the ordinary context gate above.
    if RegExMatch(lease, "m)^l1mode=(keyboard|bank)\r?$", &mode)
        PC.l1.mode := mode[1]
    if (!RegExMatch(lease, "m)^l1token=([A-Za-z0-9-]+)\r?$", &token)
        or !RegExMatch(lease, "m)^l1mode=(keyboard|bank)\r?$", &mode)
        or !RegExMatch(lease, "m)^l1ack=(\d+)\r?$", &ack)) {
        PC.l1.available := false
        PC.targetR2 := false, PC.targetR3 := false
        return
    }
    if (PC.l1.token != token[1]) {
        PC.l1 := {token:token[1], mode:mode[1], seq:0, ack:0, pending:[], available:true
            , path:RegExReplace(contextPath, "\.ini$", ".l1"), showing:false}
        PC.ready := false
    }
    PC.l1.available := true, PC.l1.mode := mode[1], PC.l1.ack := ack[1] + 0
    PC.targetR2 := RegExMatch(lease, "m)^target_r2=1\r?$") ? true : false
    PC.targetR3 := RegExMatch(lease, "m)^target_r3=1\r?$") ? true : false
    retained := []
    for _, event in PC.l1.pending
        if (event.seq > PC.l1.ack)
            retained.Push(event)
    PC.l1.pending := retained
}

PersonalL1Block(raw) {
    global PC
    if (raw.l1)
        Loop 8
            if (raw[A_Index] and !PC.blocked.Has(A_Index))
                PC.blocked[A_Index] := ""
}

PersonalL1Event(kind, slot := 0) {
    global PC
    if (!PC.l1.available or PC.l1.pending.Length >= 64)
        return false
    if ((kind = "release" or kind = "cancel") and !PC.l1.showing)
        return false
    PC.l1.seq += 1
    event := {seq:PC.l1.seq, kind:kind, slot:slot}
    PC.l1.pending.Push(event)
    if (kind = "show" or kind = "bank")
        PC.l1.showing := true
    else if (kind = "release" or kind = "cancel")
        PC.l1.showing := false
    stamp := A_NowUTC
    stamp := DateDiff(stamp, "19700101000000", "Seconds")
    contents := "token=" . PC.l1.token . "`nstamp=" . stamp . "`n"
    for _, edge in PC.l1.pending
        contents .= edge.seq . "," . edge.kind . "," . edge.slot . "`n"
    contents .= "END`n"
    temporary := PC.l1.path . ".tmp"
    destination := PC.l1.path
    return PublishControllerFile(temporary, destination, contents)
}

PersonalPhysicalKey(key) {
    ; Send accepts combined VK/SC names; GetKeyState does not. Keep the
    ; touchpad/stick-click send identities intact, querying physical SC only.
    physicalKey := key = "vkC0sc029" ? "sc029" : key = "vkBCsc033" ? "sc033" : key = "vkBEsc034" ? "sc034" : key
    return GetKeyState(physicalKey, "P")
}

PersonalKey(key, down) {
    global PC
    if (down) {
        if (PC.keys.Has(key) or !PC.owner or PC.owner != WinActive("ahk_class FFXiClass"))
            return
        ; A genuinely held keyboard key remains owned by the keyboard.
        if PersonalPhysicalKey(key)
            return
        PC.keys[key] := PC.owner
        InputTraceRecord("personal " . key . " down owner=" . PC.owner)
        SendEvent("{Blind}{" . key . " down}")
    } else if (PC.keys.Has(key)) {
        owner := PC.keys[key]
        InputTraceRecord("personal " . key . " up owner=" . owner)
        if (owner = WinExist("A")) {
            if (!PersonalPhysicalKey(key))
                SendEvent("{Blind}{" . key . " up}")
        } else if WinExist("ahk_id " . owner)
            try ControlSend("{" . key . " up}", , "ahk_id " . owner)
        PC.keys.Delete(key)
        if PC.releases.Has(key)
            PC.releases.Delete(key)
    }
}

; A: isolated opt-in acquisition experiment. Use the existing sender's key
; delay between F8 down/up; add no Sleep or global SetKeyDelay change. F8 is
; fully released before the ordinary Apps+F12 signal or stick-click handling.
PersonalTargetTrial(raw, mode) {
    global PC, appsOwned
    if (mode != "gameplay" or !PC.l1.available or appsOwned or ControllerMessageAnyHeld() or PC.keys.Count
        or raw.l1 or raw.r1 or raw.l3 or raw.touch or raw.ps or raw.mute)
        return
    Loop 11
        if (raw[A_Index])
            return
    source := ""
    if (PC.targetR2 and raw[12] and !PC.previous[12] and !raw.r3)
        source := "R2"
    else if (PC.targetR3 and raw.r3 and !PC.previous.r3 and !raw[12] and PC.clicks.phase = "idle")
        source := "R3"
    if (source = "")
        return
    for _, key in ["Control", "Alt", "Shift", "LWin", "RWin", "AppsKey", "F8"]
        if GetKeyState(key, "P")
            return
    InputTraceRecord("target prefire=" . source)
    PersonalKey("F8", true)
    PersonalKey("F8", false)
}

PersonalTap(key, now) {
    global PC
    PersonalKey(key, true)
    if (PC.keys.Has(key))
        PC.releases[key] := now + 40
}

PersonalChord(key, modifier, now) {
    global PC
    PersonalKey("LControl", false)
    PersonalKey("LAlt", false)
    PersonalKey("LShift", false)
    if (modifier != "")
        PersonalKey(modifier, true)
    PersonalTap(key, now)
    if (modifier != "" and PC.keys.Has(modifier))
        PC.releases[modifier] := now + 40
}

PersonalReleaseDue(now) {
    global PC
    due := []
    for key, time in OrderedInputMap(PC.releases)
        if (now >= time)
            due.Push(key)
    for _, key in due
        if (key != "LControl" and key != "LAlt" and key != "LShift")
            PersonalKey(key, false)
    for _, key in due
        if (key = "LControl" or key = "LAlt" or key = "LShift")
            PersonalKey(key, false)
}

PersonalRelease(reset := true) {
    global PC
    if (!IsObject(PC) or !PC.enabled)
        return
    if (reset) {
        PersonalNativeReset()
        PersonalL1Event("cancel")
        PC.layer.phase := "idle", PC.layerVisible := ""
        PC.contextSeen := 0, PC.contextPaused := false
    }
    keys := []
    for key in OrderedInputMap(PC.keys)
        keys.Push(key)
    for _, key in keys
        if (key != "LControl" and key != "LAlt" and key != "LShift")
            PersonalKey(key, false)
    for _, key in keys
        if (key = "LControl" or key = "LAlt" or key = "LShift")
            PersonalKey(key, false)
    for i in PC.blocked
        PC.suppressed[i] := true
    if (reset)
        PC.ready := false
    PC.touch.phase := "cancelled"
    PC.clicks.phase := "cancelled"
    PC.r1.phase := "cancelled"
}

; A: negotiated only with Lua's full-bank receiver. Missing fields retain the
; old wrapper behavior. Changing transport waits for physical neutral.
PersonalBankLease(lease) {
    global PC, CM
    enabled := CM.requested and RegExMatch(lease, "m)^bank_protocol=1\r?$") ? true : false
    if (enabled != PC.banks) {
        PersonalRelease()
        ControllerMessageCancel()
        PC.banks := enabled, CM.expanded := enabled
    }
    if (!enabled)
        return
    if (!RegExMatch(lease, "m)^bank_native_token=([A-Za-z0-9-]+)\r?$", &token)
        or !RegExMatch(lease, "m)^bank_native_base=(\d+)\r?$", &base)
        or !RegExMatch(lease, "m)^bank_native=([^\r\n]*)\r?$", &payload)) {
        PersonalNativeReset()
        return
    }
    if (PC.native.token != token[1]) {
        PersonalNativeReset()
        PC.native.token := token[1], PC.native.ack := base[1] + 0
    }
    if (StrLen(payload[1]) > 4096) {
        PersonalNativeReset()
        return
    }
    requests := [], expected := PC.native.ack + 1
    for _, row in StrSplit(payload[1], "|") {
        if (row = "")
            continue
        if (!RegExMatch(row, "^(\d+),(d|u),([a-z0-9+]+)$", &edge)
            or !IsObject(PersonalNativeSpec(edge[3]))) {
            PersonalNativeReset()
            return
        }
        if (edge[1] + 0 > PC.native.ack) {
            if (edge[1] + 0 != expected) {
                PersonalNativeReset()
                return
            }
            requests.Push({seq:edge[1] + 0, kind:edge[2], key:edge[3]})
            expected += 1
        }
    }
    PC.native.requests := requests
}

PersonalNativeSpec(value) {
    if (!RegExMatch(value, "^(?:(ctrl|alt|shift)\+)?([a-z0-9]+)$", &part))
        return false
    keys := Map("up", "Up", "right", "Right", "down", "Down", "left", "Left", "enter", "Enter", "escape", "Escape"
        , "space", "Space", "tab", "Tab", "numpadadd", "NumpadAdd")
    key := keys.Get(part[2], "")
    if (key = "" and RegExMatch(part[2], "^[a-z0-9]$"))
        key := part[2]
    if (key = "" and RegExMatch(part[2], "^f([1-9]|1[0-2])$", &fn))
        key := "F" . fn[1]
    if (key = "")
        return false
    modifiers := Map("ctrl", "LControl", "alt", "LAlt", "shift", "LShift")
    return {key:key, modifier:modifiers.Get(part[1], "")}
}

; Reconcile the union of native owners. Releasing one of two slots using the
; same key/chord must not lift the other's key or modifier.
PersonalNativeSync() {
    global PC
    desired := Map()
    for _, owner in PC.native.active {
        if (!owner.suppressed) {
            desired[owner.key] := true
            if (owner.modifier != "")
                desired[owner.modifier] := true
        }
    }
    retired := []
    for key in OrderedInputMap(PC.native.keys)
        if (!desired.Has(key))
            retired.Push(key)
    for _, key in retired
        if (key != "LControl" and key != "LAlt" and key != "LShift")
            PersonalKey(key, false)
    for _, key in retired
        if (key = "LControl" or key = "LAlt" or key = "LShift")
            PersonalKey(key, false)
    for key in OrderedInputMap(desired)
        if (key = "LControl" or key = "LAlt" or key = "LShift")
            PersonalKey(key, true)
    for key in OrderedInputMap(desired)
        if (key != "LControl" and key != "LAlt" and key != "LShift")
            PersonalKey(key, true)
    PC.native.keys := desired
}

PersonalNativeReset() {
    global PC
    if (!IsObject(PC.native))
        return
    PC.native.active := Map()
    PersonalNativeSync()
    PC.native := {token:"", ack:0, requests:[], active:Map(), keys:Map()}
}

PersonalNativePoll(now) {
    global PC, CM
    if (CM.phase != "messages" or now - CM.seen > 100)
        return PersonalNativeReset()
    ; Wait for prior input/cancel acknowledgment before adopting a key request.
    if (CM.pending.Length or !PC.native.requests.Length)
        return
    edge := PC.native.requests[1]
    if (edge.kind = "d") {
        spec := PersonalNativeSpec(edge.key)
        spec.tick := now, spec.suppressed := false
        for _, key in ["Control", "Alt", "Shift", "LWin", "RWin", "AppsKey", spec.key]
            if GetKeyState(key, "P")
                spec.suppressed := true
        for key in PC.keys
            if (!PC.native.keys.Has(key))
                spec.suppressed := true
        PC.native.active[edge.key] := spec
    } else {
        owner := PC.native.active.Get(edge.key, false)
        ; Hold a short tap long enough for the native client to observe it.
        ; No Sleep or blocking delay; release/cancellation remains immediate.
        if (IsObject(owner) and !owner.suppressed and now - owner.tick < 40)
            return
        if PC.native.active.Has(edge.key)
            PC.native.active.Delete(edge.key)
    }
    PersonalNativeSync()
    PC.native.ack := edge.seq
    PC.native.requests.RemoveAt(1)
    ControllerMessageAdd("keyack", edge.seq)
    ControllerMessageFlush(true)
    InputTraceRecord("bank native " . edge.kind . " " . edge.key . " ack=" . edge.seq)
}

PersonalBanksPoll(states, raw, mode, now) {
    global PC
    PersonalTargetTrial(raw, mode)
    PersonalNativeDPad(states, raw, mode, now)
    states := PersonalFilter(states, raw)
    states[13] := raw.l1, states[14] := raw.r1
    if (mode = "cutscene" or mode = "trust" or mode = "chat") {
        ; Lua authorizes the selected bank. Ordinary click/touch/R shortcuts
        ; and real IJKL must not acquire keys in this restricted context.
        PC.touch.phase := "cancelled", PC.clicks.phase := "cancelled", PC.r1.phase := "cancelled"
        PersonalKey("vkBCsc033", false)
        PersonalKey("vkBEsc034", false)
        PersonalNativePoll(now)
        PC.previous := raw
        return states
    }
    busy := raw.l1 or raw.r1 or raw.ps or raw.mute
    Loop 12
        if (raw[A_Index])
            busy := true
    touchEvent := PersonalTouchStep(PC.touch, raw.touch, PC.previous.touch
        , busy or raw.l3 or raw.r3, now)
    if (touchEvent != "")
        PersonalChord(touchEvent, "", now)
    clickEvent := PersonalClicksStep(PC.clicks, raw.l3, raw.r3
        , PC.previous.l3, PC.previous.r3, busy or raw.touch)
    PersonalKey("vkBCsc033", clickEvent = "vkBCsc033")
    PersonalKey("vkBEsc034", clickEvent = "vkBEsc034")
    if (clickEvent = "h")
        PersonalChord(clickEvent, "", now)
    PersonalNativePoll(now)
    PC.previous := raw
    return states
}

PersonalOtherWindow(hwnd) {
    if (!hwnd or !WinExist("ahk_id " . hwnd))
        return false
    try windowClass := WinGetClass("ahk_id " . hwnd)
    catch
        return false
    return windowClass != "FFXiClass" and windowClass != "Progman" and windowClass != "WorkerW"
        and windowClass != "Shell_TrayWnd" and windowClass != "AutoHotkey" and windowClass != "tooltips_class32"
}

PersonalPS(pressed, foreground, active, consumed) {
    global PC
    ; A single fresh press toggles focus. Holds never cycle or minimize clients.
    if (!pressed or PC.previous.ps or consumed)
        return
    target := active ? PC.lastOther : PersonalClientTarget(0)
    if (active and !PersonalOtherWindow(target)) {
        windows := WinGetList()
        for _, id in windows {
            if (PersonalOtherWindow(id)) {
                target := id
                break
            }
        }
    }
    if (!target or (active and !PersonalOtherWindow(target)))
        return
    ReleaseTransport()
    PersonalActivate(target)
}

PersonalActivate(target) {
    if (!target or !WinExist("ahk_id " . target))
        return
    try {
        minimized := WinGetMinMax("ahk_id " . target)
        if (minimized = -1)
            WinRestore("ahk_id " . target)
        WinActivate("ahk_id " . target)
    }
}

PersonalClientTarget(active, direction := 1) {
    global PC
    windows := WinGetList("ahk_class FFXiClass")
    available := Map(), ordered := []
    for _, id in windows
        available[id] := true
    for _, id in PC.clients
        if available.Has(id)
            ordered.Push(id)
    ; Append new clients without reordering existing ones on every activation.
    Loop windows.Length {
        index := windows.Length - A_Index + 1
        id := windows[index]
        found := false
        for _, existing in ordered
            if (existing = id)
                found := true
        if (!found)
            ordered.Push(id)
    }
    PC.clients := ordered
    if (!ordered.Length)
        return
    target := ordered[1]
    if (!active and available.Has(PC.lastClient))
        target := PC.lastClient
    else if (active) {
        for index, id in ordered
            if (id = active)
                target := ordered[Mod(index - 1 + direction + ordered.Length, ordered.Length) + 1]
    }
    return target
}

PersonalSwitchClient(active, direction := 1) {
    target := PersonalClientTarget(active, direction)
    if (!target or target = active)
        return
    ReleaseTransport()
    PersonalActivate(target)
}
