#include <Math.au3>
#include <ScreenCapture.au3>

; Bombie / Universal Pixel Autoclicker
; Last update: 28.12.2024
; Version 1.17


Global $noRestartCounter = 0
Global $screenShotFlag = False

Global $lastRunButtons[1] = [0]

Global $sHotKeyScreen = "{F1}" ; F1
Global $sHotKeyPause = "{F2}" ; F2
Global $sHotKeySlow = "{F3}" ; F3

Global $gPaused = False
Global $gSlowMode = False

HotKeySet($sHotKeyScreen, "toggleScreenShot")
HotKeySet($sHotKeyPause, "togglePause")
HotKeySet($sHotKeySlow, "toggleSlowMode")

Opt("WinDetectHiddenText", 1)
initConfig()

Func initConfig($configFile = getConfigFile())
    TimeLog("Using config file: " & $configFile)
    Global $winTitle = IniRead($configFile, "Settings", "winTitle", "TelegramDesktop")
    Global $searchText = IniRead($configFile, "Settings", "searchText", "Bombie")
    Global $restartHour = IniRead($configFile, "Settings", "restartHour", 3) 
    Global $loopSecs = IniRead($configFile, "Settings", "loopSecs", 60)
    Global $loopSecsSlow = IniRead($configFile, "Settings", "loopSecsSlow", 60)
    Global $closePixelRadius = IniRead($configFile, "Settings", "closePixelRadius", 30)
    Global $buttonClickXAdd = IniRead($configFile, "Settings", "buttonClickXAdd", -5) + 0
    Global $buttonClickYAdd = IniRead($configFile, "Settings", "buttonClickYAdd", 5) + 0
    Global $buttonsColor = IniReadSection($configFile, "Buttons")
EndFunc

Func restartGameAtTime($hWnd)
    if $noRestartCounter > 0 Then
	TimeLog("No restart minutes counter: " & $noRestartCounter)
	$noRestartCounter -= _Min(1, Floor($loopSecs / 60))
    Elseif @HOUR = $restartHour Then
	TimeLog("Restarting " & $searchText)
	restartGame($hWnd)
	Sleep(1000)
	$noRestartCounter = 60
	Sleep(60000)
    EndIf
EndFunc

Func findClickInWindow($hWnd)
    Local $buttonName, $colors, $firstColorChar, $prevPixelFound, $pixelFound
    Local $preciseClick = False, $color
    Local $pixelDistance, $pixelMaxRadius = $closePixelRadius
    Local $direction, $notFlag
    ; Local $timeDiff = TimerDiff($lastRunButtons)

    TimeLog($searchText & " Window: " & $hWnd)

    WinActivate($hWnd)
    Sleep(100)
    WinWaitActive($hWnd, "", 30)

    ; restartGameAtTime($hWnd)

    If IsArray($buttonsColor) Then
	For $i = 1 To UBound($buttonsColor) - 1

	    If $gPaused Then ExitLoop
	    $buttonName = $buttonsColor[$i][0]
	    $colors = StringSplit($buttonsColor[$i][1], ",")
	    $prevPixelFound = False
	    $preciseClick = False
	    $clickNext = False
	    $notFlag = False
	    $direction = "normal"
	    $leftMaxRadius = 0
	    $topMaxRadius = 0
	    $rightMaxRadius = 0
	    $bottomMaxRadius = 0


	    For $j = 1 To Ubound($colors) - 1

		$firstColorChar = StringLeft($colors[$j], 1)
		TimeLog("Checking " & $buttonName & ": " & $colors[$j] & " First char: " & $firstColorChar)

		If $firstColorChar <> "0" Then
		    $color = StringMid($colors[$j], 2)
		Else
		    $color = $colors[$j]
		EndIf

		Switch $firstColorChar
		    Case 1 To 9
			Local $timeoutMS = $firstColorChar * 60 * 1000 
			; ConsoleWrite("1 to 9 detected: " & $firstColorChar)
			If (Ubound($lastRunButtons) <= $i) Then
			    ReDim $lastRunButtons[$i+1]
			ElseIf (TimerDiff($lastRunButtons[$i]) >= $timeoutMS) Then
			    TimeLog("LAUNCH by timer!")
			Else
			    TimeLog("Not ready by timer")
			    ExitLoop
			EndIf
			ConsoleWrite("LastRun Buttons (" & Ubound($lastRunButtons) & "): " & $lastRunButtons[0] & " ... " & $lastRunButtons[$i] & @CRLF)
			$pixelFound = findPixelByColor($hWnd, $color)
			If $pixelFound <> False Then $lastRunButtons[$i] = TimerInit()

			; Exit
		    Case "{"
			Local $keyBoardSend = $firstColorChar & $color
			TimeLog("Sending: " & $keyBoardSend)
			Send($keyBoardSend)
			ContinueLoop
		    Case "*"
			$direction = "middle"
			$pixelFound = findPixelByColor($hWnd, $color, "middle")
		    Case "&"
			$clickNext = True
			$pixelFound = findPixelByColor($hWnd, $color)
		    Case "$"
			$direction = "reverse"
			$clickNext = True
			$pixelFound = findPixelByColor($hWnd, $color, "reverse")
		    Case "#"
			$notFlag = True
			$leftMaxRadius = $pixelMaxRadius
			$topMaxRadius = $pixelMaxRadius
			$rightMaxRadius = $pixelMaxRadius
			$bottomMaxRadius = $pixelMaxRadius

			$pixelFound = findPixelByColor($hWnd, $color, "normal", $prevPixelFound, $pixelMaxRadius, $pixelMaxRadius, $pixelMaxRadius, $pixelMaxRadius)
			If $pixelFound = false Then 
			    If $prevPixelFound <> False Then
				$pixelFound = $prevPixelFound
			    Else
				ContinueLoop
			    EndIf
			Else
			    ; TimeLog("Pixel FOUND - ExitLoop!")
			    ExitLoop
			EndIf						
		    Case "!"
			$notFlag = True
			$pixelFound = findPixelByColor($hWnd, $color)
			If $pixelFound = false Then 
			    If $prevPixelFound <> False Then
				$pixelFound = $prevPixelFound
			    Else
				ContinueLoop
			    EndIf
			Else
			    ; TimeLog("Pixel FOUND - ExitLoop!")
			    ExitLoop
			EndIf
		    Case "+"
			$pixelFound = findPixelByColor($hWnd, $color)
			; if $pixelFound <> False Then $preciseClick = True
			$preciseClick = True
		    Case "~"
			$pixelFound = findPixelByColor($hWnd, $color, "normal", $prevPixelFound, $pixelMaxRadius, $pixelMaxRadius, $pixelMaxRadius, $pixelMaxRadius)
		    Case "`"
			$pixelFound = findPixelByColor($hWnd, $color, "normal", $prevPixelFound, $pixelMaxRadius, 0, 0, $pixelMaxRadius)
		    Case "-"
			$direction = "reverse"
			$pixelFound = findPixelByColor($hWnd, $color, "reverse")
		    Case Else
			$pixelFound = findPixelByColor($hWnd, $color)
			; TimeLog("First char is NOT '!'")
		EndSwitch

		if $pixelFound = False Then 
		    ; TimeLog("Pixel NOT found - ExitLoop!")
		    ExitLoop 
		EndIf
		If $j = Ubound($colors) - 1 Or $clickNext = True Then
		    If $preciseClick = False Then
			If IsNumber($buttonClickXAdd) Then $pixelFound[0] += $buttonClickXAdd
			If IsNumber($buttonClickYAdd) Then $pixelFound[1] += $buttonClickYAdd
		    EndIf
		    ; ConsoleWrite("Correcting: " & $pixelFound[0] & ", " & $pixelFound[1] & " XAdd: " & $buttonClickXAdd & " IsNumber: " & IsNumber($buttonClickXAdd) & @CRLF)

		    if clickButtonWithNameByColor($hWnd, $buttonName, $color, $pixelFound) Then Sleep(1000)
		    ; ExitLoop
		EndIf

		$prevPixelFound = $pixelFound

		; $color = $colors[$j][0] = "0" ? 
	    Next
	    ; Sleep(10000)			
	    If $screenShotFlag Then 
		makeScreenShot($hWnd)
		$screenShotFlag = False
	    EndIf
	Next
    EndIf
    ; clickYellowButton($hWnd)

    ; Sleep(1000)
EndFunc

Func doPlay()
    Local $aList = WinList($winTitle, $searchText)
    Local $hWnd

    ; Loop through the array displaying only visable windows with a title.
    ; $aList[1][1] = 1st window handle (HWND)
    For $i = 1 To $aList[0][0]
	; If $aList[$i][0] <> "" And BitAND(WinGetState($aList[$i][1]), 2) Then
	$hWnd = $aList[$i][1]
	if $hWnd Then
	    ; ConsoleWrite("Title: " & $aList[$i][0] & @CRLF & "Handle: " & $hWnd & @CRLF)
	    findClickInWindow($hWnd)
	EndIf
    Next

    if $hWnd Then
    ; 	findClickInWindow ($hWnd)
    Else
	TimeErrorLog("Window not found!")
    EndIf
EndFunc

Func autoPlay()
    While True
	; Local $hWnd = WinGetHandle($winTitle, $searchText)

	If $gPaused = False Then doPlay()
	If $gSlowMode Then
	    Sleep($loopSecsSlow * 1000)
	Else
	    Sleep($loopSecs * 1000)
	EndIf
    WEnd
EndFunc
autoPlay()

Func findPixelByColor($hWnd, $expectedColor, $direction = "normal", $startPos = False, $radiusSubLeft = 0, $radiusSubTop = 0, $radiusAddRight = 0, $radiusAddBottom = 0)
    Local $pos = WinGetPos($hWnd)
    If @error Then
	ConsoleWrite("Window not found" & @CRLF)
	return false
    EndIf

    Local $x1 = $pos[0]
    Local $y1 = $pos[1]
    Local $x2 = $pos[0] + $pos[2]
    Local $y2 = $pos[1] + $pos[3]

    if IsArray($startPos) Then
	$x1 = $startPos[0] - $radiusSubLeft
	$y1 = $startPos[1] - $radiusSubTop
	$x2 = $startPos[0] + $radiusAddRight
	$y2 = $startPos[1] + $radiusAddBottom
    EndIf

    if $direction = "reverse" Then
	; ConsoleWrite("Reverse BEFORE: " & Hex($expectedColor) & " in X: " & $x1 & "-" & $x2 & ", Y: " & $y1 & "-" & $y2 & @CRLF)
	Local $temp

	$temp = $x1
	$x1 = $x2
	$x2 = $temp

	$temp = $y1
	$y1 = $y2
	$y2 = $temp
    EndIf

    if $direction = "moddle" Then
	Local $centerY = ($y2 - $y1) / 2
	$y1 = $centerY-5
	$y2 = $centerY+5
    EndIf

    ConsoleWrite("Searching: " & Hex($expectedColor) & " in X: " & $x1 & "-" & $x2 & ", Y: " & $y1 & "-" & $y2 & @CRLF)

    Local $pixelPos = PixelSearch($x1, $y1, $x2, $y2, $expectedColor, 0)

    If @error Then
	ConsoleWrite("Pixel not found" & @CRLF)
	return false
    EndIf

    return $pixelPos
EndFunc

Func clickPixelByColor($hWnd, $expectedColor, $button = "left", $direction = "normal", $pixelPos = False)
    If $pixelPos = False Then $pixelPos = findPixelByColor($hWnd, $expectedColor, $direction)
    If $pixelPos = False Then return false

    ConsoleWrite("Clicking: " & $pixelPos[0] & ", " & $pixelPos[1] & " Color: " & Hex($expectedColor) & @CRLF)

    return clickPixelByColorWindow($hWnd, $pixelPos, $button)
EndFunc

Func clickPixelByColorWindow($hWnd, $pixelPos, $button = "left")
    MouseClick($button, $pixelPos[0], $pixelPos[1])
    return true
EndFunc

Func clickPixelByColorGlobal($hWnd, $pixelPos, $expectedColor)

    Local $xClick = $pixelPos[0]
    Local $yClick = $pixelPos[1]
    ; ConsoleWrite("Window X: " & $pixelPos[0] & " Y: " & $pixelPos[1] & @CRLF)

    ; Add desktop coords
    ; $xClick += $pos[0]
    ; $yClick += $pos[1]

    ; ConsoleWrite("Absolute X: " & $pixelPos[0] & " Y: " & $pixelPos[1] & @CRLF)

    ; WinAPI 
    Local $WM_LBUTTONDOWN = 0x0201
    Local $WM_LBUTTONUP = 0x0202

    DllCall("user32.dll", "long", "SendMessage", "hwnd", $hWnd, "int", $WM_LBUTTONDOWN, "int", 1, "int", BitShift($xClick, 0) + BitShift($yClick, 16))
    ; PostMessage($hWnd, "int", $WM_LBUTTONDOWN, 1, BitShift($xClick, 0) + BitShift($yClick, 16))
    Sleep(10)
    DllCall("user32.dll", "long", "SendMessage", "hwnd", $hWnd, "int", $WM_LBUTTONUP, "int", 0, "int", BitShift($xClick, 0) + BitShift($yClick, 16))
    ; PostMessage($hWnd, "int", $WM_LBUTTONUP, 0, BitShift($xClick, 0) + BitShift($yClick, 16))
    return true
EndFunc

Func clickButtonByColorAtPos($hWnd, $xCoord, $yCoord, $expectedColor)
    If $hWnd Then

	Local $windowText = WinGetText($hWnd)

	; ConsoleWrite("Window found. Text:" & @CRLF & $windowText & @CRLF)

	Local $pixelColor = PixelGetColor($xCoord, $yCoord)


        If $pixelColor = $expectedColor Then
	    ConsoleWrite("Clicking: " & Hex($pixelColor) & @CRLF)
	    MouseClick("left", $xCoord, $yCoord)
	    return true
	Else
	    ConsoleWrite("Click not done. Color: " & Hex($pixelColor) & @CRLF)
	EndIf
    Else
	ConsoleWriteError("Window not found!")
    EndIf
    return false
EndFunc

; Func clickYellowButton($hWnd)
;	ConsoleWrite("Clicking yellow button - ")
;	return clickPixelByColor($hWnd, $buttonColor)
; EndFunc

Func clickButtonWithNameByColor($hWnd, $buttonName, $color, $pixelPos = False, $direction = "normal")
    ConsoleWrite("Clicking button " & $buttonName & " - ")
    return clickPixelByColor($hWnd, $color, "left", $direction, $pixelPos)
EndFunc


Func toggleSlowMode()
    If $gSlowMode Then 
	$gSlowMode = False
    Else 
	$gSlowMode = True
    EndIf
    TimeLog("Set slow mode: " & $gSlowMode)
EndFunc

Func togglePause()
    If $gPaused Then 
	initConfig()
	$gPaused = False
    Else 
	$gPaused = True
    EndIf
    TimeLog("Set pause: " & $gPaused)
EndFunc

Func toggleScreenShot()
    If $screenShotFlag Then 
	TimeLog("Screenshot cancelled...")
	$screenShotFlag = False
    Else
	TimeLog("Screenshot will be taken in few seconds...")
	$screenShotFlag = True
    EndIf
EndFunc


Func CalculateDistance($pixel1, $pixel2)
    Local $x1 = $pixel1[0], $y1 = $pixel1[1]
    Local $x2 = $pixel2[0], $y2 = $pixel2[1]

    Local $distance = Sqrt((($x2 - $x1) ^ 2) + (($y2 - $y1) ^ 2))
    Return $distance
EndFunc

Func addTime()
    return "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] "
EndFunc

Func findWindow()
    Local $aList = WinList($winTitle, $searchText)

    ; Loop through the array displaying only visable windows with a title.
    ; $aList[1][1] = 1st window handle (HWND)
    For $i = 1 To $aList[0][0]
	If $aList[$i][0] <> "" And BitAND(WinGetState($aList[$i][1]), 2) Then
	    ConsoleWrite("Title: " & $aList[$i][0] & @CRLF & "Handle: " & $aList[$i][1] & @CRLF)
	    ; clickYellowButton($aList[$i][1])
	EndIf
    Next
EndFunc


Func TimeErrorLog($text)
    ConsoleWriteError(addTime() & $text & @CRLF)
EndFunc

Func TimeLog($text)
    ConsoleWrite(addTime() & $text & @CRLF)
EndFunc

Func getConfigFile()
    If $CmdLine[0] > 0 Then return $CmdLine[1]
    return StringSplit(@ScriptName, ".")[1] & ".ini"
EndFunc

Func restartGame($hWnd)
    send("^R")
    ; Sleep(500)
    ; makeScreenShot($hWnd)
EndFunc

Func makeScreenShot($hWnd)
    Local $pos = WinGetPos($hWnd)
    If @error Then
	ConsoleWrite("[makeScreenShot] Window not found" & @CRLF)
	return false
    EndIf


    Local $x1 = $pos[0]
    Local $y1 = $pos[1]
    Local $x2 = $pos[0] + $pos[2]
    Local $y2 = $pos[1] + $pos[3]

    Local $screenPath = @MyDocumentsDir & "/" & $searchText & "_Screen.jpg"
    $hBmp = _ScreenCapture_Capture($screenPath, $x1, $y1, $x2, $y2)
    ShellExecute($screenPath)
EndFunc

