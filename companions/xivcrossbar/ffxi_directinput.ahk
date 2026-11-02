#Requires AutoHotkey v2.0.19+
; A: shared controller transport; physical readers are selected at startup.
; Ordinary profiles use Apps/F1-F12; extended PS5/Xbox profiles can use messages.
#SingleInstance ignore
Persistent(true)
; A: physical modifier checks must distinguish our injected key-down.
InstallKeybdHook()
; A: the timer provides idle time. Do not add batch sleeps inside an input
; callback; slow callbacks can miss a tap or stretch an already-held key.
; Keep SendEvent's key delay unchanged, including the F8 acquisition pulse.
; v2 has no batch sleeps (equivalent to v1 SetBatchLines -1).
SetKeyDelay(10, -1) ; Preserve v1 SendEvent defaults explicitly.
SetWinDelay(100)
FileEncoding("CP0") ; Preserve v1 ANSI mailbox/log bytes without a UTF-8 BOM.
SetWorkingDir(A_ScriptDir)
; A: an installation-scoped kernel handle closes the simultaneous-launch race.
; A rejected duplicate exits before registering OnExit or touching status/input.
instanceMutex := AcquireWrapperMutex()
if (!instanceMutex)
    ExitApp
DirCreate(A_ScriptDir . "\data")
; Exit handler is registered after module initialization below.
; A: one shared process; select transport only at startup, never mid-hold.
modifierArgument := A_Args.Length >= 1 ? A_Args[1] : ""
profileArgument := A_Args.Length >= 2 ? A_Args[2] : ""
deviceArgument := A_Args.Length >= 3 ? A_Args[3] : ""
; A: use a validated startup handoff if the launcher drops script arguments.
origin := "arguments"
if (profileArgument = "") {
    launchFile := A_ScriptDir . "\data\controller-launch.ini"
    if FileExist(launchFile) {
        modifierArgument := IniRead(launchFile, "Controller", "modifier", "apps")
        profileArgument := IniRead(launchFile, "Controller", "profile", "ps5-directinput")
        deviceArgument := IniRead(launchFile, "Controller", "device", "1")
        origin := "launch-file"
    } else {
        origin := "default"
    }
}
profile := profileArgument != "" ? profileArgument : "ps5-directinput"
device := deviceArgument != "" ? deviceArgument + 0 : 1
isXInput := (profile = "xinput" or profile = "xinput-r1-chooser" or profile = "xinput-extended")
validProfile := isXInput or profile = "ps5-directinput" or profile = "ps5-extended" or profile = "f710-directinput" or profile = "fightpadpro-directinput"
if (!validProfile or device < 1 or device > (isXInput ? 4 : 16) or Mod(device, 1))
    ExitApp
joystickPrefix := device = 1 ? "" : device
xinputLibrary := 0
xinputGetState := 0
xinputGuide := false
xinputFault := false
connected := false
phase := "starting"
lastStatusTick := -1000
if (isXInput)
    xinputFault := !InitXInput()
captureKey := (modifierArgument = "ctrl") ? "LControl" : "AppsKey"
CM := 0, PC := 0, WC := 0, TM := 0, IT := 0
keys := ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
labels := ["D-pad Up/F1", "D-pad Right/F2", "D-pad Down/F3", "D-pad Left/F4", "Cross/F5", "Square/F6", "Circle/F7", "Triangle/F8", "Share/F9", "Options/F10", "L2/F11", "R2/F12"]
; Upstream PS5/F710 share assignments; FightPadPro rearranges face buttons.
joys := profile = "fightpadpro-directinput"
    ? [0, 0, 0, 0, 3, 2, 4, 1, 9, 10, 7, 8]
    : [0, 0, 0, 0, 2, 1, 3, 4, 9, 10, 7, 8]
previous := InputState()
povDirection := 0
owner := 0
ready := false
appsOwned := false
Loop 12
    previous[A_Index] := false
ControllerMessageInit()
PersonalInit(profile, joystickPrefix)
WrapperClientsInit()
; A: movement has its own per-focus latch; button neutral never rearms it.
MovementInit()
InputTraceInit()
OnExit(TransportExit)
WriteTransportStatus(true)
SetTimer(TransportPoll, 10)
return

TransportPoll() {
    global
pollStart := DllCall("GetTickCount64", "UInt64")
InputTraceStart(pollStart)
InputTimingBegin(pollStart)
if (WrapperClientsShouldExit())
    ExitApp
if FileExist(A_ScriptDir . "\data\input-stop.request") {
    try FileDelete(A_ScriptDir . "\data\input-stop.request")
    ExitApp
}
InputTimingStage("housekeeping")
active := WinActive("ahk_class FFXiClass")
; The PS button can restore a client while another application is focused.
readStart := DllCall("GetTickCount64", "UInt64")
states := ReadTransportStates()
rawBits := InputTraceMask(states)
readMs := DllCall("GetTickCount64", "UInt64") - readStart
InputTimingStage("hardware")
personalStart := DllCall("GetTickCount64", "UInt64")
; One short-lived context record for personal controls and Ready movement.
; Never retain this across timer invocations or pre-read it before input cleanup.
local contextObservation := PC.enabled ? {} : false
states := PersonalPoll(states, active, contextObservation)
personalMs := DllCall("GetTickCount64", "UInt64") - personalStart
InputTimingStage("personal-context-and-output")
InputTraceObserve(rawBits, states, active, readMs, personalMs)
current := WinActive("ahk_class FFXiClass")
MovementTick(current)
InputTimingStage("movement-tick")
if (current != active) {
    ReleaseTransport()
    ready := false
    InputTraceFinish(pollStart)
    return
}
if (!active) {
    ReleaseTransport()
    ready := false
    phase := "unfocused"
    WriteTransportStatus()
    InputTraceFinish(pollStart)
    return
}
if (owner and owner != active) {
    ReleaseTransport()
    ready := false
}
owner := active
connected := IsObject(states)
if (!connected) {
    ReleaseTransport()
    ready := false
    phase := xinputFault ? "xinput-unavailable" : "disconnected"
    WriteTransportStatus()
    InputTraceFinish(pollStart)
    return
}
MovementPoll(states, active, contextObservation)
InputTimingStage("movement-poll")
neutral := true
Loop 12 {
    if (states[A_Index])
        neutral := false
}
anyDown := !neutral
phase := ready ? "ready" : "waiting-neutral"
WriteTransportStatus()
InputTimingStage("status")
if (!ready) {
    if (neutral)
        ready := true
    InputTraceFinish(pollStart)
    return
}
; A: the experiment bypasses Apps and F-keys completely. Lua uses the same
; controller router; this branch also owns uncertain/neutral handoff intervals.
if (ControllerMessagePoll(states)) {
    InputTraceFinish(pollStart)
    return
}
if (anyDown and !appsOwned) {
    appsOwned := true
    InputTraceRecord("emit " . captureKey . " down")
    SendEvent("{Blind}{" . captureKey . " down}")
}
Loop 12 {
    i := A_Index
    if (states[i] != previous[i]) {
        key := keys[i]
        edge := states[i] ? "down" : "up"
        InputTraceRecord("emit " . key . " " . edge)
        SendEvent("{Blind}{" . key . " " . edge . "}")
        previous[i] := states[i]
    }
}
if (!anyDown and appsOwned) {
    physicallyHeld := GetKeyState(captureKey, "P")
    if (!physicallyHeld) {
        InputTraceRecord("emit " . captureKey . " up")
        SendEvent("{Blind}{" . captureKey . " up}")
    }
    appsOwned := false
}
InputTraceFinish(pollStart)
return

}

; Explicit local stop; it exits only this script, even outside FFXI.
^!F12::ExitApp

TransportExit(exitReason, exitCode) {
    global
; v2 callbacks return zero to permit termination; cleanup runs once.
ReleaseTransport()
InputTraceClose()
phase := "stopped"
WriteTransportStatus(true)
if (xinputLibrary)
    DllCall("FreeLibrary", "Ptr", xinputLibrary)
if (instanceMutex)
    DllCall("CloseHandle", "Ptr", instanceMutex)
return 0
}

AcquireWrapperMutex() {
    ; Normalize case; hash keeps the name below Windows' MAX_PATH limit.
    path := A_ScriptDir
    path := StrLower(path)
    hash := 2166136261
    Loop Parse path
        hash := ((hash ^ Ord(A_LoopField)) * 16777619) & 0xFFFFFFFF
    handle := DllCall("CreateMutexW", "Ptr", 0, "Int", 0, "WStr", "Local\XIVCrossbar_" . hash, "Ptr")
    error := A_LastError
    if (!handle or error = 183) {
        if (handle)
            DllCall("CloseHandle", "Ptr", handle)
        return 0
    }
    return handle
}

ReleaseTransport(preservePersonal := false) {
    global keys, previous, owner, appsOwned, captureKey
    InputTraceRecord("transport release owner=" . owner . " preserve_personal=" . preservePersonal)
    MovementRelease()
    ControllerMessageCancel()
    if (!preservePersonal)
        PersonalRelease()
    Loop 12 {
        i := A_Index
        if (previous[i]) {
            key := keys[i]
            if (owner == WinActive("ahk_class FFXiClass")) {
                SendEvent("{Blind}{" . key . " up}")
            } else if (owner) {
                try ControlSend("{" . key . " up}", , "ahk_id " . owner)
            }
            previous[i] := false
        }
    }
    if (appsOwned) {
        if (owner == WinActive("ahk_class FFXiClass")) {
            if (!GetKeyState(captureKey, "P"))
                SendEvent("{Blind}{" . captureKey . " up}")
        } else if (owner) {
            try ControlSend("{" . captureKey . " up}", , "ahk_id " . owner)
        }
        appsOwned := false
    }
}

; A: read hardware only. Output, focus cleanup and rearming remain shared.
ReadTransportStates() {
    global isXInput, profile, device, joystickPrefix, joys, xinputGetState, xinputGuide, povDirection
    if (!isXInput) {
        if (GetKeyState(joystickPrefix . "JoyName") = "")
            return false
        pov := GetKeyState(joystickPrefix . "JoyPOV")
        global IT
        IT.pov := pov
        ; Keep one adjacent cardinal through a diagonal roll, not a neutral gap
        ; or two simultaneous crossbar slots.
        povDirection := PersonalPovDirection(pov, povDirection)
        states := InputState()
        Loop 4
            states[A_Index] := povDirection = A_Index
        Loop 8 {
            i := A_Index + 4
            states[i] := GetKeyState(joystickPrefix . "Joy" . joys[i]) ? true : false
        }
        ; A: observe analog axes without translating or swallowing movement.
        x := GetKeyState(joystickPrefix . "JoyX")
        y := GetKeyState(joystickPrefix . "JoyY")
        if (StrLen(x) and StrLen(y)) {
            states.moveX := (x - 50) / 50
            states.moveY := (y - 50) / 50
        }
        return states
    }
    if (!xinputGetState)
        return false
    state := Buffer(16, 0)
    if (DllCall(xinputGetState, "UInt", device - 1, "Ptr", state.Ptr, "UInt") != 0)
        return false
    buttons := NumGet(state, 4, "UShort")
    global IT
    IT.triggers := NumGet(state, 6, "UChar") . "/" . NumGet(state, 7, "UChar")
    return XInputStates(buttons, NumGet(state, 6, "UChar"), NumGet(state, 7, "UChar")
        , NumGet(state, 8, "Short") / 32768, NumGet(state, 10, "Short") / 32768
        , profile = "xinput-extended", xinputGuide)
}

; A: all extended hardware feeds the same positional messages and bank router.
; Keep the ordinary XInput profiles' legacy behavior for comparison.
XInputStates(buttons, leftTrigger, rightTrigger, moveX, moveY, extended, guide) {
    global profile, povDirection
    ; Logical order: Up, Right, Down, Left, bottom, left, right, top, Back, chooser.
    flags := [0x0001, 0x0008, 0x0002, 0x0004, 0x1000, 0x4000, 0x2000, 0x8000, 0x0020]
    flags.Push(profile = "xinput-r1-chooser" ? 0x0200 : 0x0010)
    states := InputState()
    for i, flag in flags
        states[i] := (buttons & flag) ? true : false
    ; Match upstream's threshold; neither trigger is derived from the other.
    states[11] := leftTrigger > 4
    states[12] := rightTrigger > 4
    states.moveX := moveX
    states.moveY := moveY
    if (extended) {
        ; Use the same one-cardinal diagonal policy as PS5 Extended. Opposite
        ; directions/invalid hats are neutral; ordinary XInput is untouched.
        angles := Map(1, 0, 9, 4500, 8, 9000, 10, 13500, 2, 18000, 6, 22500, 4, 27000, 5, 31500)
        hat := buttons & 0x000F
        pov := angles.Has(hat) ? angles[hat] : -1
        povDirection := PersonalPovDirection(pov, povDirection)
        Loop 4
            states[A_Index] := povDirection = A_Index
        states.l1 := (buttons & 0x0100) != 0
        states.r1 := (buttons & 0x0200) != 0
        states.l3 := (buttons & 0x0040) != 0
        states.r3 := (buttons & 0x0080) != 0
        ; Guide deliberately replaces touchpad, not the PS focus-toggle button.
        states.touch := guide and (buttons & 0x0400) != 0
        states.ps := false, states.mute := false
    }
    return states
}

InitXInput() {
    global xinputLibrary, xinputGetState, xinputGuide, profile
    for _, dll in ["xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll"] {
        library := DllCall("LoadLibrary", "Str", dll, "Ptr")
        if (!library)
            continue
        address := DllCall("GetProcAddress", "Ptr", library, "AStr", "XInputGetState", "Ptr")
        if (address) {
            ; SDL uses ordinal 100 (GetStateEx) for Guide. It is optional and
            ; undocumented; absent support falls back to standard GetState.
            extendedAddress := profile = "xinput-extended" ? DllCall("GetProcAddress", "Ptr", library, "Ptr", 100, "Ptr") : 0
            xinputGuide := extendedAddress != 0
            xinputLibrary := library
            xinputGetState := extendedAddress ? extendedAddress : address
            return true
        }
        DllCall("FreeLibrary", "Ptr", library)
    }
    return false
}

WriteTransportStatus(force := false) {
    global profile, device, modifierArgument, phase, connected, ready, lastStatusTick, origin
    if (!force and A_TickCount - lastStatusTick < 1000)
        return
    lastStatusTick := A_TickCount
    timestamp := A_NowUTC
    timestamp := DateDiff(timestamp, "19700101000000", "Seconds")
    pid := phase = "stopped" ? 0 : DllCall("GetCurrentProcessId", "UInt")
    modifier := modifierArgument = "ctrl" ? "ctrl" : "apps"
    contents := "[Controller]`norigin=" . origin . "`nprofile=" . profile . "`ndevice=" . device . "`nmodifier=" . modifier
        . "`npid=" . pid . "`nstate=" . phase . "`nconnected=" . connected . "`nready=" . ready . "`ntimestamp=" . timestamp . "`n"
    contents .= WrapperClientsStatus()
    global PC, xinputGuide
    if (PC.enabled)
        contents .= "personal_context=" . PC.context . "`npersonal_version=9.20-diagnostics1`nhold_recovery_protocol=1`nps_action=" . (PC.xinput ? "none" : "focus-toggle") . "`nguide_touchpad=" . (PC.xinput ? (xinputGuide ? "available" : "unavailable") : "not-applicable") . "`nshoulder_double_tap=off`nctrl_pair=0`nalt_pair=0`nl1_layer=" . PC.layerVisible . "`nl1_mode=" . PC.l1.mode . "`nl1_ready=" . PC.l1.available . "`nl1_sent=" . PC.l1.seq . "`nl1_ack=" . PC.l1.ack . "`n"
            . "target_r2=" . PC.targetR2 . "`ntarget_r3=" . PC.targetR3 . "`ncontext_pauses=" . PC.contextPauses . "`n"
            . "context_poll_protocol=1`ncontext_observations=" . PC.contextObservations . "`ncontext_reuses=" . PC.contextReuses . "`ncontext_scans=" . PC.contextScans . "`ncontext_file_reads=" . PC.contextFileReads . "`n"
            . "realkeys_protocol=1`ndpad_output=" . (PC.realDpad ? "ahk" : "lua") . "`n"
            . "r1_menu_protocol=1`nr1_menus=" . PC.r1Menus . "`n"
            . "bank_protocol=1`nbanks_enabled=" . PC.banks . "`nbank_native_ack=" . PC.native.ack . "`n"
    global CM
    contents .= "button_protocol=1`nbutton_route=" . CM.phase . "`nbutton_sent=" . CM.seq . "`nbutton_ack=" . CM.ack . "`nbutton_error=" . CM.error . "`n"
    global TM
    contents .= "movement_version=0.2.1-neutral-takeover1`nmovement_policy=" . TM.policy . "`nmovement_sent=" . TM.sent . "`nmovement_reason=" . TM.reason . "`n"
    contents .= "diagnostic_protocol=1`nahk_major=2`nahk_version=" . A_AhkVersion . "`nahk_path=" . A_AhkPath . "`n"
    global IT
    contents .= "input_trace=" . IT.enabled . "`npoll_max_ms=" . IT.pollMax . "`npoll_gap_max_ms=" . IT.gapMax
        . "`nread_max_ms=" . IT.readMax . "`npersonal_max_ms=" . IT.personalMax . "`ncontext_misses=" . IT.misses . "`ntrace_error=" . IT.error . "`n"
    ; Replace the status as one file so Lua never treats a partial write as live.
    temporary := A_ScriptDir . "\data\controller-status.tmp"
    destination := A_ScriptDir . "\data\controller-status.ini"
    PublishControllerFile(temporary, destination, contents)
}

; A: observation only. Opt-in 30-second capture; no key delays, debounce,
; device thresholds or input decisions are changed by this diagnostic.
InputTraceInit() {
    global IT
    IT := {enabled:false, deadline:0, nextRequest:0, buffer:"", signature:"", previous:0
        , gapMax:0, pollMax:0, readMax:0, personalMax:0, misses:0, error:false, pov:"", triggers:"", path:"", captureId:"", stages:"", stageTick:0}
}

InputTraceStart(now) {
    global IT, profile, device
    if (IT.previous) {
        gap := now - IT.previous
        IT.gapMax := Max(IT.gapMax, gap)
        if (gap > 30)
            InputTraceRecord("poll start_gap_ms=" . gap)
    }
    IT.previous := now
    if (IT.enabled and now >= IT.deadline) {
        InputTraceRecord("capture auto-stopped after 30 seconds")
        InputTraceClose()
    }
    if (now < IT.nextRequest)
        return
    IT.nextRequest := now + 250
    path := A_ScriptDir . "\data\controller-trace.request"
    if (!FileExist(path))
        return
    try request := FileRead(path, "CP0")
    catch
        return
    try FileDelete(path)
    request := Trim(request, " `t`r`n")
    captureId := ""
    if (RegExMatch(request, "^(on|off)\n([A-Za-z0-9-]{1,120})$", &capture)) {
        request := capture[1], captureId := capture[2]
    }
    if (request = "on") {
        InputTraceClose()
        IT.captureId := captureId
        try DirCreate(A_ScriptDir . "\data\diagnostics")
        catch {
            IT.error := true
            return
        }
        IT.path := A_ScriptDir . "\data\diagnostics\" . (captureId != "" ? captureId . "-ahk.log" : "controller-input-trace.log")
        IT.enabled := true, IT.deadline := now + 30000, IT.signature := "", IT.error := false
        InputTraceRecord("capture start utc=" . A_NowUTC . " profile=" . profile . " device=" . device . " controls=9.20-diagnostics1 id=" . captureId)
        InputTraceRecord("runtime ahk=" . A_AhkVersion . " batch_lines=" . "none-v2"
            . " key_delay=" . A_KeyDelay . " key_duration=" . A_KeyDuration . " requested_timer_ms=10")
    } else if (request = "off" and (captureId = "" or captureId = IT.captureId)) {
        InputTraceRecord("capture manually stopped")
        InputTraceClose()
    }
}

InputTraceMask(states) {
    global IT
    if (!IT.enabled)
        return ""
    if (!IsObject(states))
        return "disconnected"
    mask := ""
    Loop 12
        mask .= states[A_Index] ? "1" : "0"
    return mask
}

InputTraceObserve(raw, routed, active, readMs, personalMs) {
    global IT, PC, CM, appsOwned, ready
    IT.readMax := Max(IT.readMax, readMs), IT.personalMax := Max(IT.personalMax, personalMs)
    if (!IT.enabled)
        return
    signature := "hwnd=" . active . " raw=" . raw . " routed=" . InputTraceMask(routed)
        . " pov=" . IT.pov . " triggers=" . IT.triggers . " apps=" . appsOwned . " base_ready=" . ready
        . " context=" . PC.context . " personal_ready=" . PC.ready
        . " route=" . CM.phase . " messages_requested=" . CM.requested
    if (PC.enabled)
        signature .= " l1=" . PC.previous.l1 . " r1=" . PC.previous.r1
    if (signature != IT.signature or readMs > 30 or personalMs > 30) {
        IT.signature := signature
        InputTraceRecord(signature . " read_ms=" . readMs . " personal_ms=" . personalMs)
    }
}

InputTraceFinish(started) {
    global IT
    InputTimingStage("routing-and-message-write")
    elapsed := DllCall("GetTickCount64", "UInt64") - started
    IT.pollMax := Max(IT.pollMax, elapsed)
    if (elapsed > 30)
        InputTraceRecord("slow poll_ms=" . elapsed . " stages=" . IT.stages)
    if (StrLen(IT.buffer) > 65536)
        InputTraceFlush()
}

InputTraceRecord(message) {
    global IT
    if (IsObject(IT) and IT.enabled)
        IT.buffer .= DllCall("GetTickCount64", "UInt64") . " " . message . "`n"
}

InputTraceFlush() {
    global IT
    if (IT.buffer = "")
        return
    path := IT.path
    text := IT.buffer
    IT.buffer := ""
    try FileAppend(text, path, "CP0")
    catch
        IT.error := true, IT.enabled := false
}

InputTraceClose() {
    global IT
    if (!IsObject(IT))
        return
    InputTraceFlush()
    IT.enabled := false
}

InputTraceContextMiss(reason) {
    global IT
    IT.misses += 1
    InputTraceRecord("context lease miss=" . reason)
    return reason = "stale" ? "stale" : "unknown"
}

#Include %A_ScriptDir%\controller_messages.ahk
#Include %A_ScriptDir%\personal_controls.ahk
#Include %A_ScriptDir%\personal_gestures.ahk

#Include %A_ScriptDir%\controller_clients.ahk

#Include %A_ScriptDir%\movement_signal.ahk

; A: elapsed stage timings are observations, including any Windows scheduling
; pauses inside a stage. They do not claim CPU time or individual I/O latency.
InputTimingBegin(now) {
    global IT
    IT.stageTick := now, IT.stages := ""
}
InputTimingStage(name) {
    global IT
    if (!IT.enabled)
        return
    now := DllCall("GetTickCount64", "UInt64")
    IT.stages .= name . ":" . (now - IT.stageTick) . ","
    IT.stageTick := now
}

InputTimingOperation(name, started) {
    global IT
    if (!IT.enabled)
        return
    elapsed := DllCall("GetTickCount64", "UInt64") - started
    if (elapsed > 10)
        InputTraceRecord("operation=" . name . " elapsed_ms=" . elapsed)
}

; Native v2 sparse button/control state. Missing positions are released, never
; inferred from Array.Length; named hardware flags are explicit own properties.
InputState() {
    state := Map()
    state.Default := false
    state.l1 := false, state.r1 := false, state.l3 := false, state.r3 := false
    state.ps := false, state.touch := false, state.mute := false
    return state
}

; v1 file commands signalled errors without throwing. Keep failure local to
; the existing retry/uncertainty policy; do not terminate the polling timer.
PublishControllerFile(temporary, destination, contents) {
    try {
        if FileExist(temporary)
            FileDelete(temporary)
        FileAppend(contents, temporary, "CP0")
        FileMove(temporary, destination, 1)
        return true
    } catch {
        return false
    }
}

; v1 object enumeration orders integer keys before ordinal string keys. Native
; Map insertion order differs; preserve release/key acquisition order explicitly.
OrderedInputMap(source) {
    keys := []
    for key in source {
        position := keys.Length + 1
        for index, existing in keys {
            numeric := Type(key) = "Integer", otherNumeric := Type(existing) = "Integer"
            if ((numeric and !otherNumeric) or (numeric = otherNumeric
                and (numeric ? key < existing : StrCompare(key, existing, true) < 0))) {
                position := index
                break
            }
        }
        keys.InsertAt(position, key)
    }
    ordered := Map()
    for _, key in keys
        ordered[key] := source[key]
    return ordered
}
