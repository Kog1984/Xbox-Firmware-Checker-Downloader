#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Martz90-Circle-Addon1-Xbox.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;####################################################################
;# Xbox Firmware Checker & Downloader
;#
;# What does it do? Compares byte file size of OSU1 on Microsoft website vs your download version of update files, download if size difference
;#
;# BY      : KEITH HOPKINS / CONSOLE NINJA
;# WEBSITE : https://consolerepair.xyz/
;#         : https://www.consoleninja.co.uk/
;##################################################################################################################################################
#include <AutoItConstants.au3>
#include <Misc.au3>
#include <Inet.au3>
$TITLE = "Xbox Firmware Checker & Downloader"
$update_dir = @MyDocumentsDir&"\Xbox FW"

; Test to make sure there is not already an instance running.
if _Singleton($TITLE, 1) = 0 Then
    Msgbox(64, $TITLE, "The program is already running.")
    Exit
EndIf
$filename = "OSU1.zip"
$firmware_dl = "http://www.xbox.com/xboxone/osu1"
If FileExists ($update_dir) = 0 Then DirCreate ( $update_dir )
$update_zip = $update_dir & "\" & $filename
$update = $update_dir & "\$SystemUpdate"



$online_update = InetGetSize ( $firmware_dl ,1 )
If $online_update = 0 Then Exit ;Quit offline
ConsoleWrite($online_update&@CRLF);Filesize in bytes
$cache_update = FileGetSize ( $update_zip )
ConsoleWrite($cache_update&@CRLF);Filesize in bytes
If $online_update <> $cache_update Then
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	$iMsgBoxAnswer = MsgBox(8193,$TITLE,"A New Update is Available will start Downloading "&@CRLF&"Please wait this may take upto 30 mins",30)
	Select
		Case $iMsgBoxAnswer = 1 ;OK
			ConsoleWrite("Downloading Update........"&@CRLF)
			if FileExists($update_zip) = 1 Then
				If FileDelete($update_zip) = 0 Then
					MsgBox(0,"Error","Failure to delete "&$update_zip)
					Exit
				EndIf
			EndIf
			$current_download = InetGet ( $firmware_dl, $update_dir&"\"&$filename ,1,1 )
			ProgressOn($TITLE, "Downloading Firmware", "0%", -1, -1, BitOR($DLG_NOTONTOP, $DLG_MOVEABLE))
			Do
			$current_size = InetGetInfo ($current_download,0)
			$progess = round(($current_size/$online_update)*100,0)
			ProgressSet($progess,Round($current_size/1024/1024,0)&"MB of "&round($online_update/1024/1024,0)&"MB")
			;ConsoleWrite($current_size&@CRLF)
			;ConsoleWrite($progess&@CRLF)
			Sleep(2500)
				If InetGetInfo($current_download,4) <> 0 Then
					MsgBox(0,$TITLE,"An error has occurred!"&@CRLF&"Please check your internet connection and try again.")
					Exit
				EndIf
			Until InetGetInfo ($current_download,3) = "TRUE"
			ProgressSet(100, "Done", "Complete")

			; Close the progress window.
			ProgressOff()

			ConsoleWrite( "Extracting Update......" &@CRLF)
			ProgressOn($TITLE, "Extracting Firmware", "50", "Please Wait", -1, BitOR($DLG_NOTONTOP, $DLG_MOVEABLE))
			DirCreate($update_dir & "\update") ; to extract to
			_ExtractZip($update_dir & "\OSU1.zip", $update_dir & "\update")
			ConsoleWrite(@error & @CRLF)
			ProgressSet(100, "Done", "Complete")
			; Close the progress window.
			ProgressOff()
		Case $iMsgBoxAnswer = 2 ;Cancel
			Exit
	EndSelect
Else
SplashTextOn($TITLE, "OSU1 up to date", 300, 70, -1, -1, $DLG_TEXTVCENTER, "", 24)
Sleep(3000)
SplashOff()
EndIf


; #FUNCTION# ;===============================================================================
;
; Name...........: _ExtractZip
; Description ...: Extracts file/folder from ZIP compressed file
; Syntax.........: _ExtractZip($sZipFile, $sDestinationFolder)
; Parameters ....: $sZipFile - full path to the ZIP file to process
;                  $sDestinationFolder - folder to extract to. Will be created if it does not exsist exist.
; Return values .: Success - Returns 1
;                          - Sets @error to 0
;                  Failure - Returns 0 sets @error:
;                  |1 - Shell Object creation failure
;                  |2 - Destination folder is unavailable
;                  |3 - Structure within ZIP file is wrong
;                  |4 - Specified file/folder to extract not existing
; Author ........: trancexx, modifyed by corgano
;
;==========================================================================================
Func _ExtractZip($sZipFile, $sDestinationFolder, $sFolderStructure = "")

    Local $i
    Do
        $i += 1
        $sTempZipFolder = @TempDir & "\Temporary Directory " & $i & " for " & StringRegExpReplace($sZipFile, ".*\\", "")
    Until Not FileExists($sTempZipFolder) ; this folder will be created during extraction

    Local $oShell = ObjCreate("Shell.Application")

    If Not IsObj($oShell) Then
        Return SetError(1, 0, 0) ; highly unlikely but could happen
    EndIf

    Local $oDestinationFolder = $oShell.NameSpace($sDestinationFolder)
    If Not IsObj($oDestinationFolder) Then
        DirCreate($sDestinationFolder)
;~         Return SetError(2, 0, 0) ; unavailable destionation location
    EndIf

    Local $oOriginFolder = $oShell.NameSpace($sZipFile & "\" & $sFolderStructure) ; FolderStructure is overstatement because of the available depth
    If Not IsObj($oOriginFolder) Then
        Return SetError(3, 0, 0) ; unavailable location
    EndIf

    Local $oOriginFile = $oOriginFolder.Items();get all items
    If Not IsObj($oOriginFile) Then
        Return SetError(4, 0, 0) ; no such file in ZIP file
    EndIf

    ; copy content of origin to destination
    $oDestinationFolder.CopyHere($oOriginFile, 20) ; 20 means 4 and 16, replaces files if asked

    DirRemove($sTempZipFolder, 1) ; clean temp dir

    Return 1 ; All OK!

EndFunc