#SingleInstance Force
SetBatchLines, -1

do := false
image := "[Your Image Path]\BreakThrough.png"

CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

F6::
do := !do
if (do) {
    SetTimer, Main , 1000
} else {
    SetTimer, Main, Off
}
return

Main:
if !FileExist(image)
    MsgBox, Image not foundd %image%
    return

ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *20 %image%
if (ErrorLevel = 0) {
    MouseMove, %FoundX%, %FoundY%
    MsgBox, Image found at %FoundX%x%FoundY%.
} else {
    MsgBox, Image not found
}
return


TestTimer:
ToolTip, Timer running %A_TickCount%
return