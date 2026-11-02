; A: gesture decisions contain no keyboard/Windows calls. The wrapper applies
; their results only to the current FFXI owner, and cancels them on context loss.
; A: a missing file during a complete lease swap is an uncertain observation,
; not permission to emit a new action and not yet a lost controller session.
PersonalLeasePause(mode, now, seen, ready) {
    return ready and mode = "unknown" and seen > 0 and now >= seen and now - seen <= 100
}

; A: defer R until release so every R1 chord can consume the whole hold. Once
; consumed, releasing the other button cannot revive that same R1 tap.
PersonalR1Step(g, pressed, previous, consumed) {
    if (consumed) {
        g.phase := pressed ? "cancelled" : "idle"
        return ""
    }
    if (pressed and !previous and g.phase = "idle")
        g.phase := "armed"
    if (!pressed) {
        phase := g.phase, g.phase := "idle"
        if (previous and phase = "armed")
            return "r"
    }
    return ""
}

PersonalTouchStep(g, pressed, previous, consumed, now) {
    if (consumed) {
        g.phase := pressed ? "cancelled" : "idle"
        return ""
    }
    if (pressed and !previous)
        g.phase := "timing", g.started := now
    if (pressed and g.phase = "timing" and now - g.started >= 500) {
        g.phase := "fired"
        return "vkC0sc029"
    }
    if (!pressed and previous) {
        phase := g.phase, g.phase := "idle"
        if (phase = "timing")
            return "vkC0sc029"
        if (phase = "fired")
            return "Escape"
    }
    return ""
}

; A: order owns the chord. Same-sample presses choose ordinary L2 safely.
; The tail consumes L2 after releasing L1, so it cannot open a second bar.
PersonalLayerStep(g, l1, l2, r1, r2) {
    if (r2 or r1) {
        g.phase := l2 ? "ordinary" : "idle"
        return l2 or r2 ? "ordinary" : ""
    }
    if (g.phase = "tail") {
        if (l2)
            return "tail"
        g.phase := "idle"
    }
    if (g.phase = "ordinary") {
        if (l2)
            return "ordinary"
        g.phase := l1 ? "keyboard" : "idle"
    } else if (g.phase = "bank") {
        if (!l1)
            g.phase := l2 ? "tail" : "idle"
        else if (!l2)
            g.phase := "keyboard"
    } else if (g.phase = "keyboard") {
        if (!l1)
            g.phase := l2 ? "ordinary" : "idle"
        else if (l2)
            g.phase := "bank"
    } else {
        g.phase := l2 ? "ordinary" : (l1 ? "keyboard" : "idle")
    }
    return g.phase = "idle" ? "" : g.phase
}

PersonalClicksStep(g, l3, r3, previousL3, previousR3, consumed) {
    if (consumed) {
        g.phase := l3 or r3 ? "cancelled" : "idle"
        return ""
    }
    phase := g.phase
    if (phase = "idle") {
        ; Simultaneous samples establish no order, so produce no guessed chord.
        if (l3 and r3)
            g.phase := "cancelled"
        else if (l3 and !previousL3)
            g.phase := "l3"
        else if (r3 and !previousR3)
            g.phase := "r3"
    } else if (phase = "l3" and l3 and r3 and !previousR3) {
        g.phase := "period"
    } else if (phase = "r3" and r3 and l3 and !previousL3) {
        g.phase := "comma"
    }
    ; A: the second click owns the held zoom key. Releasing the first click
    ; does not interrupt it; once the second releases, both must return neutral.
    if (g.phase = "comma" and l3)
        return "vkBCsc033"
    if (g.phase = "period" and r3)
        return "vkBEsc034"
    if (g.phase = "comma" or g.phase = "period")
        g.phase := "cancelled"
    if (!l3 and !r3) {
        g.phase := "idle"
        if (phase = "l3")
            return "h"
        ; R3 retains fresh-press F8 acquisition in PersonalTargetTrial. A bare
        ; release must not also toggle autorun (applies to Xbox stick click too).
    }
    ; Releasing the first click while the other remains held cancels the pair.
    if ((phase = "l3" and !l3 and r3) or (phase = "r3" and !r3 and l3))
        g.phase := "cancelled"
    return ""
}


PersonalPovDirection(pov, previous) {
    if (pov = 0)
        return 1
    if (pov = 9000)
        return 2
    if (pov = 18000)
        return 3
    if (pov = 27000)
        return 4
    if (pov = 4500)
        return previous = 2 ? 2 : 1
    if (pov = 13500)
        return previous = 3 ? 3 : 2
    if (pov = 22500)
        return previous = 4 ? 4 : 3
    if (pov = 31500)
        return previous = 1 ? 1 : 4
    return 0
}
