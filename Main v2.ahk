#SingleInstance Force
SetBatchLines, -1

; V2 ONLY FOR THOSE ABOVE 40 STARS!!
; No Restoration Pills, include soulr rings, lesser CD for between BTs and BT Time

; ---------------- CONFIGURABLES ----------------
currentRealm := 9                                                                  ; --- Input '2' if Realm 2
maxRealm     := 29
maxRealmBTTime := 5000                                                              ; --- Time taken to breakthrough max realm (Not Ascend)
resetAfterBT := false                                                               ; --- Reset after breakthrough [Not implemented yet]
consumePills := true                                                                ; --- Consume Pills (Soul Pills)
equipItems := true                                                                  ; --- Auto equip bracelets, rings
btIntervalInput := 0                                                                ; --- Time between each BT (prevents false BTs), set to "" for default [trainingTime + CultivationTime - 30s]
bypassBTInterval := 1                                                               ; --- Determines which realm to bypassBTInterval, BT intervals will be 1s from this realm onwards

;-- BreakThrough Formula Calculation  
noOfRealmsBTSkip := 10                                                              ; --- IMPORTANT: Breakthrough time set to 1s, min: 0 [Set value to realm where BT time <1s]
base := 12000                                                                       ; --- BT Duration: [Formula: base + ((currentRealm - offset) * step)]
step := 1000                                                                        ; --- Formula is ignored by noOfRealmsBTSkip and maxRealmBTTime
offset := 10

AscendImage := "[Your Image Path]\Ascend.png"      ;---- Provide breakthrough image path 
BTImage := "[Your Image Path]\BreakThrough.png"    ;---- Provide ascend image path 

; ---- Main loop ---- [Do NOT CONFIGURE FROM HERE ONWARDS UNLESS YOU KNOW WHAT YOU ARE DOING!]
mainState := "train_start"  -- currentAction
nextMainTime := 0

trainingTime := 120000
cultivateTime := 10000 ;
actionInterval := 1000 ;-- CD between inputs

; ---- Breakthrough ----
underBT := false     ;-- User is undergoing BT
btEnd := 0           ;-- Tracks BT time
btInterval := 0      ;-- CalculateIntervals() overwrites 

btNextAllowed := 0   ;
btDuration := 0  ; -- CalculateIntervals() overwrites 

; ---- Ascension ----
underAscend := false
ascendPhase := ""
ascendEnd := 0
nextAscendTime := 0

CoordMode, Mouse, Client
CoordMode, Pixel, Screen

;---------------- TOOLTIP INFO ---------------------
startTime := 0
currentAction := ""

; ---------------- CHECK CONFIGURATION -------------
Gosub, CheckConfiguration

; ---------------- HOTKEY HANDLER -------------------
F6::
do := !do
if (do) {
    startTime := A_TickCount
    mainState := "train_start"
    currentAction := "Starting..."
    ToolTip, %currentAction%`nMacro RUNNING - 00:00:00, 1316, 455

    getIntervals := CalculateIntervals(currentRealm)
    cultivateTime := getIntervals.cultivateTime
    btDuration := getIntervals.btDuration

    SetTimer, UpdateToolTip, 1000
    SetTimer, LoopMacro, 100
    SetTimer, CanBreakthrough, 5000
    SetTimer, CanAscend, 5000
} else {
    currentAction := "Stopped"
    ToolTip, %currentAction%`nMacro STOPPED, 1316, 455

    SetTimer, LoopMacro, Off
    SetTimer, CanBreakthrough, Off
    SetTimer, CanAscend, Off
    SetTimer, FinishBT, Off
    SetTimer, UpdateToolTip, Off
    SetTimer, RemoveToolTip, -1500
}
return
; ---------------- MAIN MACRO LOOP -------------------

LoopMacro:
if (!do || paused)
    return

if (underBT || underAscend)  ; pause macro while breakthrough active
    return

now := A_TickCount

; ---------- TRAIN ----------
if (mainState = "train_start") {
    if (now < nextTime)
        return
    currentAction := "Training..."
    SendInput, t
    nextTime := now + trainingTime
    mainState := "train_wait"
    return
}

if (mainState = "train_wait") {
    if (now < nextTime)
        return
    SendInput, t
    nextTime := now + actionInterval
    mainState := "cultivate_start"
    return
}

; ---------- CULTIVATE ----------
if (mainState = "cultivate_start") {
    if (now < nextTime)
        return
    currentAction := "Cultivating..."
    SendInput, c
    nextTime := now + cultivateTime
    mainState := "cultivate_wait"
    return
}

if (mainState = "cultivate_wait") {
    if (now < nextTime)
        return
    SendInput, c
    nextTime := now + actionInterval
    mainState := "train_start"
    return
}
return

; ---------------- BREAKTHROUGH CHECK ----------------
CanBreakthrough:
    if (!do || underBT || underAscend || paused)
        return
    if (A_TickCount < btNextAllowed)
        return
    ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, %btImage%
    if (ErrorLevel = 0) {
        underBT := true
        currentAction := "Breaking through..."
        Click, 979, 789
        btNextAllowed := A_TickCount + btInterval
        btEnd := A_TickCount + btDuration
        SetTimer, FinishBT, 100
    }
return

; ---------------- FINISH BREAKTHROUGH ----------------
FinishBT:
    if (A_TickCount < btEnd)
        return

    ;-- Recalculates intervals
    currentRealm++
    intervals := CalculateIntervals(currentRealm)
    cultivateTime := intervals.cultivateTime
    btDuration := intervals.btDuration
    btInterval := intervals.btInterval

    underBT := false
    SetTimer, FinishBT, Off
    mainState := "cultivate_start"
    nextTime := A_TickCount + actionInterval
   
return

; ---------------- ASCENSION CHECK -----------------------
CanAscend:
    if (!do || underBT || underAscend)
        return

    ImageSearch, x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, %AscendImage%
    if (ErrorLevel = 0) {
        underAscend := true
        ascendPhase := "attempt_ascend"
        currentAction := "Preparing Ascension"

        SetTimer, AscendHandler, 200
        SetTimer, FindAscensionStatus, 200
    }
return

; ---------------- ASCENSION HANDLER ---------------------

AscendHandler:
    if (!underAscend)
        return

    now := A_TickCount

    ; ----- ATTEMPT -----
    if (ascendPhase = "attempt_ascend") {
        currentAction := "Ascending..."
        gosub, EquipSoulStars
        gosub, EatSoulChancePill

        Click, 979, 789
        Sleep, 500 
        Click, 1293, 764
        Sleep, 500 

        ascendEnd := now + 80000
        ascendPhase := "waiting"
        return
    }

    ; ----- WAIT -----
    if (ascendPhase = "waiting" && now > ascendEnd) {
        ascendPhase := "recover_train"
        nextAscendTime := now
        return
    }

    ; ----- RECOVER TRAIN -----
    if (ascendPhase = "recover_train" && now >= nextAscendTime) {
        currentAction := "Recovering (Train)"
        SendInput, t
        nextAscendTime := now + trainingTime
        ascendPhase := "wait_recover_train"
        return
    }

    ; ----- WAIT RECOVER TRAIN -----
    if (ascendPhase = "wait_recover_train" && now >= nextAscendTime) {
        currentAction := "Waiting to Cultivate"
        SendInput, t
        nextAscendTime := now + actionInterval
        ascendPhase := "recover_cultivate"
        return
    }

    ; ----- RECOVER CULTIVATE -----
    if (ascendPhase = "recover_cultivate" && now >= nextAscendTime) {
        currentAction := "Recovering (Cultivate)"
        SendInput, c
        nextAscendTime := now + cultivateTime
        ascendPhase := "wait_recover_cultivate"
        return
    }

    ; ----- WAIT RECOVER CULTIVATE -----
    if (ascendPhase = "wait_recover_cultivate" && now >= nextAscendTime) {
        currentAction := "Waiting to Train"
        SendInput, c
        nextAscendTime := now + actionInterval
        ascendPhase := "recover_train"
        return
    }
return

FindAscensionStatus:
    if (!underAscend || !do)
        return

    ; ===== SUCCESS =====
    ImageSearch, x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, %btImage%
    if (ErrorLevel = 0) {
        currentAction := "Ascension Successful"
        SetTimer, AscendHandler, Off
        SetTimer, FindAscensionStatus, Off
        gosub, FinishAscend
        return
    }

    ; ===== RECOVERED (Ascend button back) =====
    ImageSearch, x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, %AscendImage%
    if (ErrorLevel = 0) {
        ascendPhase := "attempt_ascend"
        return
    }

    ; =====  Failed BT or awaiting status =====
    if (ascendPhase = "waiting" && A_TickCount > ascendEnd) {
        currentAction := "Checking Ascend Status"
        gosub, EquipSoulRings
        nextTime := A_TickCount   
        ascendPhase := "ascend_train_start"
        return
    }
    
return

; ---------------- ASCENSION FINISH -----------------------

FinishAscend:
    if(!do)
        return
        
    currentRealm := 1
    maxRealm++
    intervals := CalculateIntervals(currentRealm)
    cultivateTime := intervals.cultivateTime
    btDuration := intervals.btDuration
    btInterval := intervals.btInterval

    underAscend := false
    main_state := "train_start"
    nextTime := A_TickCount + actionInterval
return

; ---------------- TOOLTIP ----------------
UpdateToolTip:
    elapsed := (A_TickCount - startTime) // 1000

    hrs  := Floor(elapsed / 3600)
    mins := Floor(Mod(elapsed, 3600) / 60)
    secs := Mod(elapsed, 60)

    hrs  := (hrs  < 10 ? "0" . hrs  : hrs)
    mins := (mins < 10 ? "0" . mins : mins)
    secs := (secs < 10 ? "0" . secs : secs)

    fTrainTime := MsToHMS(trainingTime)
    fCultivateTime := MsToHMS(cultivateTime)
    fBTTime := MsToHMS(btDuration)
    fBTInterval := MsToHMS(btInterval)

    ToolTip, Macro RUNNING - %hrs%:%mins%:%secs% `nCurrent Action: %currentAction% `nRealm: %currentRealm% `nTraining: %fTrainTime% Cultivate: %fCultivateTime% `nBT Time: %fBTTime% `nBT Interval: %fBTInterval%, 1316, 455
return

RemoveToolTip:
    ToolTip
return

; ---------------- Functions -------------
; General Guide 
; Higher realm - lower Cultivation time, Higher BreakThrough time

CalculateIntervals(realm) {
    global trainingTime, maxRealmBTTime, noOfRealmsBTSkip, bypassBTInterval, base, offset, step, maxRealm, btIntervalInput

    ; --- Handles Cultivation Duration
    cultivateTime := 10000

    ; --- Handles Breakthough Duration
    if (noOfRealmsBTSkip > 0 && realm <= noOfRealmsBTSkip)
        btDuration := 1000
    else if (realm == maxRealm)
        btDuration := maxRealmBTTime
    else
        btDuration := base + ((realm - offset) * step)

    ; --- Handles Breakthough Interval 
    if (realm >= bypassBTInterval)
        btInterval := 1000
    else if (btIntervalInput == "")
        btInterval := cultivateTime + trainingTime - 30000
    else
        btInterval := btIntervalInput
    

    return { cultivateTime: cultivateTime, btDuration: btDuration, btInterval: btInterval}
}

MsToHMS(ms) {
    totalSec := ms // 1000
    hrs := Floor(totalSec / 3600)
    mins := Floor(Mod(totalSec, 3600) / 60)
    secs := Mod(totalSec, 60)

    hrs  := (hrs  < 10 ? "0" . hrs  : hrs)
    mins := (mins < 10 ? "0" . mins : mins)
    secs := (secs < 10 ? "0" . secs : secs)

    return hrs ":" mins ":" secs
}

; ---------------- CONFIGURATION CHECK ---------------
CheckConfiguration:
    ; Check BT and Ascend images
    if !FileExist(BTImage) {
        MsgBox, 16, Configuration Error, BT Image cannot be retrieved:`n%BTImage%
        ExitApp
    }

    if !FileExist(AscendImage) {
        MsgBox, 16, Configuration Error, Ascend Image cannot be retrieved:`n%AscendImage%
        ExitApp
    }

    ; Check currentRealm
    if (currentRealm = "" || currentRealm < 1) {
        MsgBox, 16, Configuration Error, Current Realm is not set or invalid:`nCurrent Realm: %currentRealm%
        ExitApp
    }
return

; ---------------- ITEM / BACKPACK HELPERS ------------------

BackPackFilter(itemType, returnToAll := false) {

    clicks := 0

    switch itemType {
        case "herbs":        
            clicks := 1
        case "pills":        
            clicks := 2
        case "manuals":      
            clicks := 3
        case "techniques":   
            clicks := 4
        case "artifacts":    
            clicks := 5
        case "weights":      
            clicks := 6
        case "auras":        
            clicks := 7
        case "bone marrows": 
            clicks := 8
        case "all":          
            clicks := 9
        default:
            MsgBox, 16, Error, Invalid itemType: %itemType%
            return
    }
   
    ; ---- Go back to ALL ----
    if (returnToAll && itemType != "all") {
        Loop, % 9 - clicks {
            Click, 1394, 319
            Sleep, 500
        }
    }else{
        Loop, %clicks% {
        Click, 1394, 319
        Sleep, 500
        }
    }
}

SelectItem(option){
    
    switch option {
    case 1 :
        Sleep, 100        
        MouseMove, 1656, 472
        Sleep, 1000
        Click
    case 2 :
        Sleep, 100        
        MouseMove, 1656, 538
        Sleep, 1000
        Click  
    case 3 :
        Sleep, 100        
        MouseMove, 1656, 598
        Sleep, 1000
        Click  
    case 4 :
        Sleep, 100        
        MouseMove, 1656, 655 
        Sleep, 1000
        Click  
    default:
            MsgBox, 16, Error, Invalid itemType: %option%
            return
    }
}

UseItem(){
    Sleep, 100
    Click, 1455, 811
    Sleep, 1000
}
    
RemoveQiItems:
    Sleep, 1000
    Click, 77, 745
    Sleep, 1000
    Click, 692, 816
    Sleep, 1000
    Click, 1210, 816
    Sleep, 1000
    Click, 77, 745
    Sleep, 1000
return

EatSoulChancePill:
    if(!consumePills)
        return
    Click, 78, 932 
    Sleep, 1000
    BackPackFilter("pills", false)
    Click, 448, 416   ; Click first item to prevent double clicking
    Sleep, 1000
    Click, 916, 413
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    BackPackFilter("pills", true)
    Click, 1651, 274
    Sleep, 500
return

EquipSoulBracelets:
    if(!equipItems)
        return
    gosub, RemoveQiItems
    Sleep, 1000
    Click, 78, 932
    Sleep, 1000
    BackPackFilter("artifacts", false)
    Click, 448, 416   ; Click first item to prevent double clicking
    Sleep, 1000
    Click, 803, 674
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    BackPackFilter("artifacts", true)
    Click, 1651, 274
    Sleep, 500
return

EquipSoulRings:
    if(!equipItems)
        return
    gosub, RemoveQiItems
    Sleep, 1000
    Click, 78, 932
    Sleep, 1000
    BackPackFilter("artifacts", false)
    Click, 448, 416   ; Click first item to prevent double clicking
    Sleep, 1000
    Click, 1038, 407
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    BackPackFilter("artifacts", true)
    Click, 1651, 274
    Sleep, 1000
return

EquipSoulStars:
    if(!do || !equipItems)
        return
    gosub, RemoveQiItems
    Sleep, 1000
    Click, 78, 932
    Sleep, 1000
    BackPackFilter("artifacts", false)
    Click, 448, 416   ; Click first item to prevent double clicking
    Sleep, 1500
    Click, 563, 416   ; Click Item
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    Sleep, 1000
    SelectItem(1)
    Sleep, 1000
    UseItem()
    BackPackFilter("artifacts", true)
    Click, 1651, 274
    Sleep, 1000
return