#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiTreeView.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <File.au3>

; Fuzzy match rom filenames to artwork from RF Generation

Local $app_name = "RetroPie Box Art Scraper"
Local $ImageMagick_path = "C:\Program Files\ImageMagick-7.0.11-Q16-HDRI"
Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
Local $sDrive1 = "", $sDir1 = "", $sFileName1 = "", $sExtension1 = ""
Local $sDrive2 = "", $sDir2 = "", $sFileName2 = "", $sExtension2 = ""
Local $alphanumeric_arr[36] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
;Local $alphanumeric_arr[11] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A"]
Local $iStyle = BitOR($TVS_EDITLABELS, $TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS, $TVS_CHECKBOXES)

Local $emulator_folder_name = "snes"
Local $download_path = "D:\dwn\Nintendo_SNES"

Local $downloaded_images_path = "~/.emulationstation/downloaded_images/" & $emulator_folder_name
Local $roms_folder = "F:\RetroPie\home\pi\RetroPie\roms\" & $emulator_folder_name


Local $main_gui = GUICreate("RetroPie Box Art Scraper", 400, 600)
$idTreeView = GUICtrlCreateTreeView(2, 2, 396, 560, $iStyle, $WS_EX_CLIENTEDGE)
Local $merge_button = GUICtrlCreateButton("Merge", 2, 570, 80, 20)
GUISetState(@SW_SHOW)


if FileExists(@ScriptDir & "\" & $app_name & ".txt") = True Then

	; load the tree

	Local $tree_file_arr
	_FileReadToArray(@ScriptDir & "\" & $app_name & ".txt", $tree_file_arr, 0)
	Local $tree_parent_item

	_GUICtrlTreeView_BeginUpdate($idTreeView)

	for $i = 0 to (UBound($tree_file_arr) - 1)

		if StringInStr($tree_file_arr[$i], "	", 1) = 0 Then

			$tree_parent_item = _GUICtrlTreeView_Add($idTreeView, 0, $tree_file_arr[$i])
			_GUICtrlTreeView_SetStateImageIndex($idTreeView, $tree_parent_item, 0)
		Else

			Local $tree_item_part = StringSplit($tree_file_arr[$i], "	", 2)
			local $tree_item_child = _GUICtrlTreeView_AddChild($idTreeView, $tree_parent_item, $tree_item_part[1])

			if StringCompare($tree_item_part[2], "True") = 0 Then

				_GUICtrlTreeView_SetChecked($idTreeView, $tree_item_child, True)
			Else

				_GUICtrlTreeView_SetChecked($idTreeView, $tree_item_child, False)
			EndIf

		EndIf


	Next

	_GUICtrlTreeView_Expand($idTreeView)
	_GUICtrlTreeView_EndUpdate($idTreeView)
Else

	; scrape the tree

	for $k = 0 to (UBound($alphanumeric_arr) - 1)

		Local $roms_arr = _FileListToArrayRec($roms_folder, $alphanumeric_arr[$k] & "*.sfc", 1, 0, 1)
		_ArrayDelete($roms_arr, 0)
		Local $art_arr = _FileListToArrayRec("D:\dwn\Nintendo_SNES\Box", $alphanumeric_arr[$k] & "*", 1, 0, 1)
		_ArrayDelete($art_arr, 0)

		Local $tree_first_item = Null

		for $i = 0 to (UBound($roms_arr) - 1)

			_PathSplit($roms_arr[$i], $sDrive1, $sDir1, $sFileName1, $sExtension1)
			Local $sFileName1_cleaned = $sFileName1
			$sFileName1_cleaned = StringReplace($sFileName1_cleaned, "(USA)", "")
			$sFileName1_cleaned = StringReplace($sFileName1_cleaned, "(Europe)", "")
			$sFileName1_cleaned = StringStripWS($sFileName1_cleaned, 3)

			ConsoleWrite("rom " & $sFileName1 & @CRLF)
			Local $tree_parent_item = _GUICtrlTreeView_Add($idTreeView, 0, $sFileName1)
	;		$tree_file_str = $tree_file_str & $sFileName1 & @CRLF

			if $tree_first_item = Null Then

				$tree_first_item = $tree_parent_item
			EndIf

			Local $similarity_arr[0]

			for $j = 0 to (UBound($art_arr) - 1)

				_PathSplit($art_arr[$j], $sDrive2, $sDir2, $sFileName2, $sExtension2)

				Local $similarity = _Typos($sFileName1_cleaned, $sFileName2)

				if $similarity <= 0 Then

					ReDim $similarity_arr[0]
					_ArrayAdd($similarity_arr, StringFormat("%.2d", $similarity) & "|" & $sFileName2, 0, "~")
					ExitLoop
				EndIf

				if $similarity <= 10 Then

					_ArrayAdd($similarity_arr, StringFormat ( "%.2d" , $similarity ) & "|" & $sFileName2, 0, "~")
					;_ArrayDisplay($similarity_arr)

					;ConsoleWrite("   " & $similarity & "|" & $sFileName2 & @CRLF)
				EndIf

			Next

			_ArraySort($similarity_arr)

			for $j = 0 to (UBound($similarity_arr) - 1)

				Local $similarity_part = StringSplit($similarity_arr[$j], "|", 2)
				Local $treeview_child_item = _GUICtrlTreeView_AddChild($idTreeView, $tree_parent_item, $similarity_part[1])
	;			$tree_file_str = $tree_file_str & "	" & $similarity_part[1]

				if Number($similarity_part[0]) = 0 Then

					_GUICtrlTreeView_SetChecked($idTreeView, $treeview_child_item)
	;				$tree_file_str = $tree_file_str & "	GUI_CHECKED"
	;			Else

	;				$tree_file_str = $tree_file_str & "	GUI_UNCHECKED"
				EndIf

	;			$tree_file_str = $tree_file_str & @CRLF

			Next

			_GUICtrlTreeView_Expand($idTreeView, $tree_parent_item)
		Next
	Next
EndIf

_GUICtrlTreeView_SelectItem($idTreeView, _GUICtrlTreeView_GetFirstItem($idTreeView))



While True

	; GUI msg loop...
	$msg = GUIGetMsg()

	Switch $msg

		Case $GUI_EVENT_CLOSE

			GUIDelete($main_gui)
			ExitLoop

		Case $merge_button

#cs
			Local $tree_item = _GUICtrlTreeView_GetFirstItem($idTreeView)

			While $tree_item <> 0

				if _GUICtrlTreeView_Level($idTreeView, $tree_item) > 0 and _GUICtrlTreeView_GetChecked($idTreeView, $tree_item) = True Then

					local $scraped_name = _GUICtrlTreeView_GetText($idTreeView, $tree_item)
					ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $scraped_name = ' & $scraped_name & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
					local $rom_name = _GUICtrlTreeView_GetText($idTreeView, _GUICtrlTreeView_GetParentHandle($idTreeView, $tree_item))
					ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $rom_name = ' & $rom_name & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

					ShellExecuteWait("magick.exe", """" & $download_path & "\BoxBack\" & $scraped_name & ".jpg"" """ & $download_path & "\Box\" & $scraped_name & ".jpg"" +append """ & $download_path & "\Box_Full\" & $rom_name & ".jpg""", $ImageMagick_path, "", @SW_HIDE)

				EndIf

				$tree_item = _GUICtrlTreeView_GetNext($idTreeView, $tree_item)

			WEnd
			#ce

			; Create gamelist.xml


			Local $arr = _FileListToArray($roms_folder)
			_ArrayDelete($arr, 0)
			_ArraySort($arr)

			Local $xml = ""
			$xml = $xml & "<?xml version=""1.0""?>" & @CRLF
			$xml = $xml & "<gameList>" & @CRLF

			for $i = 0 to (UBound($arr) - 1)

				_PathSplit($arr[$i], $sDrive, $sDir, $sFileName, $sExtension)

				if StringCompare($sExtension, ".state") <> 0 Then

			;		ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $arr[$i] = ' & $arr[$i] & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

					$xml = $xml & "	<game>" & @CRLF
					$xml = $xml & "		<path>./" & $sFileName & $sExtension & "</path>" & @CRLF
					$xml = $xml & "		<name>" & $sFileName & "</name>" & @CRLF
					$xml = $xml & "		<image>" & $downloaded_images_path & "/" & $sFileName & ".jpg</image>" & @CRLF
					$xml = $xml & "	</game>" & @CRLF
				EndIf
			Next

			$xml = $xml & "</gameList>" & @CRLF

			if FileExists($download_path & "\gamelist.xml") = True Then

				FileDelete($download_path & "\gamelist.xml")
			EndIf

			FileWrite($download_path & "\gamelist.xml", $xml)

			ConsoleWrite("Manually copy " & $download_path & "\Box_Full\*.jpg to /opt/retropie/configs/all/emulationstation/downloaded_images/" & $emulator_folder_name & @CRLF)
			ConsoleWrite("Manually copy " & $download_path & "\gamelist.xml to /opt/retropie/configs/all/emulationstation/gamelists/" & $emulator_folder_name & @CRLF)



			Exit

	EndSwitch
WEnd



; save the tree

Local $tree_file_str = ""
Local $tree_item = _GUICtrlTreeView_GetFirstItem($idTreeView)

while $tree_item <> 0

	local $text = _GUICtrlTreeView_GetText($idTreeView, $tree_item)
	$tree_file_str = $tree_file_str & $text & @CRLF
	Local $tree_item_child = _GUICtrlTreeView_GetFirstChild($idTreeView, $tree_item)
	Local $tree_item_last_child = _GUICtrlTreeView_GetLastChild($idTreeView, $tree_item)

	while $tree_item_child <> 0

		Local $text = _GUICtrlTreeView_GetText($idTreeView, $tree_item_child)
		$tree_file_str = $tree_file_str & "	" & $text
		Local $checked = _GUICtrlTreeView_GetChecked($idTreeView, $tree_item_child)
		$tree_file_str = $tree_file_str & "	" & $checked & @CRLF

		if $tree_item_child = $tree_item_last_child Then

			ExitLoop
		EndIf

		$tree_item_child = _GUICtrlTreeView_GetNextSibling($idTreeView, $tree_item_child)
	wend

	$tree_item = _GUICtrlTreeView_GetNextSibling($idTreeView, $tree_item)
wend

FileDelete(@ScriptDir & "\" & $app_name & ".txt")
FileWrite(@ScriptDir & "\" & $app_name & ".txt", $tree_file_str)



GUIDelete()





; Computes the number of typos (Damerau-Levenshtein distance) between two short strings.
; Four types of differences are counted:
;       insertion of a character,     abcd     ab#cd
;       deletion of a character,      abcd     acd
;       exchange of a character       abcd     ab$d
;       inversion of adjacent chars   abcd     acbd
;
; This function does NOT satisfy the so-called "triangle inequality", which means
; more simply that it makes NO attempt to compute the MINIMUM edit distance in all
; cases.  If you need that, you should use more complex algorithms.
;
; This simple function allows a fuzzy compare for e.g. recovering from typical
; human typos in short strings like names, address, cities... while getting rid of
; minor scripting differences.
;
; Strings are lowercased.
; String $st2 can be used as a pattern similar to the SQL 'LIKE' operator:
; '_' and trailing '%' act as in LIKE. These wildcards can be passed as parameters
; but these should contain exactly one character for the function to work properly.
;
; Complexity is in O(n^2) so don't use with long strings!
;
Func _Typos(Const $st1, Const $st2, $anychar = '_', $anytail = '%')
	Local $s1, $s2, $pen, $del, $ins, $subst
	If Not IsString($st1) Then Return SetError(-1, -1, -1)
	If Not IsString($st2) Then Return SetError(-2, -2, -1)
	If $st2 = '' Then Return StringLen($st1)
	If $st2 == $anytail Then Return 0
	If $st1 = '' Then
		Return(StringInStr($st2 & $anytail, $anytail, 1) - 1)
	EndIf
;~ 	$s1 = StringSplit(_LowerUnaccent($st1)), "", 2)		;; _LowerUnaccent() addon function not available here
;~ 	$s2 = StringSplit(_LowerUnaccent($st2)), "", 2)		;; _LowerUnaccent() addon function not available here
	$s1 = StringSplit(StringLower($st1), "", 2)
	$s2 = StringSplit(StringLower($st2), "", 2)
	Local $l1 = UBound($s1), $l2 = UBound($s2)
	Local $r[$l1 + 1][$l2 + 1]
	For $x = 0 To $l2 - 1
		Switch $s2[$x]
			Case $anychar
				If $x < $l1 Then
					$s2[$x] = $s1[$x]
				EndIf
			Case $anytail
				$l2 = $x
				If $l1 > $l2 Then
					$l1 = $l2
				EndIf
				ExitLoop
		EndSwitch
		$r[0][$x] = $x
	Next
	$r[0][$l2] = $l2
	For $x = 0 To $l1
		$r[$x][0] = $x
	Next
    For $x = 1 To $l1
        For $y = 1 To $l2
			$pen = Not ($s1[$x - 1] == $s2[$y - 1])
			$del = $r[$x-1][$y] + 1
			$ins = $r[$x][$y-1] + 1
			$subst = $r[$x-1][$y-1] + $pen
			If $del > $ins Then $del = $ins
			If $del > $subst Then $del = $subst
			$r[$x][$y] = $del
			If ($pen And $x > 1 And $y > 1 And $s1[$x-1] == $s2[$y-2] And $s1[$x-2] == $s2[$y-1]) Then
				If $r[$x][$y] >= $r[$x-2][$y-2] Then $r[$x][$y] = $r[$x-2][$y-2] + 1
				$r[$x-1][$y-1] = $r[$x][$y]
			EndIf
		Next
	Next
    Return ($r[$l1][$l2])
EndFunc

