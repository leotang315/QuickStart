; QuickStart Installer Script
; Compile with NSIS 3.0+


!define APP_NAME "QuickStart"
!define APP_VERSION "1.7.0"
!define APP_PUBLISHER "Your Company Name"
!define APP_URL "https://yourcompany.com"
!define APP_EXECUTABLE "quick_start.exe"
!define APP_DESCRIPTION "QuickStart - Quick Launch Application"

; Installer properties
Name "${APP_NAME}"
OutFile "QuickStart-1.7.0-windows-setup.exe"
InstallDir "$PROGRAMFILES\${APP_NAME}"
InstallDirRegKey HKLM "Software\${APP_NAME}" "InstallPath"
RequestExecutionLevel admin

; Include file size calculation function (MUST be before using GetSize)
!include "FileFunc.nsh"
!insertmacro GetSize

; Include KillProc plugin
!include "nsProcess.nsh"

; Modern UI interface
!include "MUI2.nsh"

; UI pages
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Installation pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstallation pages
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

; Version information
VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey "ProductName" "${APP_NAME}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_DESCRIPTION}"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "© ${APP_PUBLISHER}"

; Function to close running application
Function CloseApplication
  ; Check if process is running
  ${nsProcess::FindProcess} "${APP_EXECUTABLE}" $R0
  StrCmp $R0 0 process_found process_not_found
  
  process_not_found:
    ; Process not found, continue installation
    Goto done
    
  process_found:
    ; Process found, ask user to close it
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "${APP_NAME} is currently running.$\n$\nClick 'OK' to automatically close the application, or 'Cancel' to exit installation." IDOK kill_process
    ${nsProcess::Unload}
    Abort
    
  kill_process:
    ; Try to kill the process gracefully first
    ${nsProcess::KillProcess} "${APP_EXECUTABLE}" $R0
    Sleep 2000
    
    ; Check if process is still running
    ${nsProcess::FindProcess} "${APP_EXECUTABLE}" $R0
    StrCmp $R0 0 still_running done
    
  still_running:
    MessageBox MB_OK|MB_ICONSTOP "Unable to close ${APP_NAME}. Please close the application manually and run the installer again."
    ${nsProcess::Unload}
    Abort
    
  done:
    ${nsProcess::Unload}
FunctionEnd

; Function to close running application for uninstaller
Function un.CloseApplication
  ; Check if process is running
  ${nsProcess::FindProcess} "${APP_EXECUTABLE}" $R0
  StrCmp $R0 0 process_found process_not_found
  
  process_not_found:
    ; Process not found, continue uninstallation
    Goto done
    
  process_found:
    ; Process found, ask user to close it
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "${APP_NAME} is currently running.$\n$\nClick 'OK' to automatically close the application, or 'Cancel' to exit uninstallation." IDOK kill_process
    ${nsProcess::Unload}
    Abort
    
  kill_process:
    ; Try to kill the process
    ${nsProcess::KillProcess} "${APP_EXECUTABLE}" $R0
    Sleep 2000
    
    ; Check if process is still running
    ${nsProcess::FindProcess} "${APP_EXECUTABLE}" $R0
    StrCmp $R0 0 still_running done
    
  still_running:
    MessageBox MB_OK|MB_ICONSTOP "Unable to close ${APP_NAME}. Please close the application manually and run the uninstaller again."
    ${nsProcess::Unload}
    Abort
    
  done:
    ${nsProcess::Unload}
FunctionEnd

; Installation section
Section "Main Program" SecMain
  SectionIn RO
  
  ; Close running application before installation
  Call CloseApplication
  
  ; Set output path
  SetOutPath "$INSTDIR"
  
  ; Copy main program file
  File "..\build\windows\x64\runner\Release\${APP_EXECUTABLE}"
  
  ; Copy Flutter runtime files
  File "..\build\windows\x64\runner\Release\flutter_windows.dll"
  
  ; Copy auto-updater related DLL files
  File "..\build\windows\x64\runner\Release\WinSparkle.dll"
  File "..\build\windows\x64\runner\Release\auto_updater_windows_plugin.dll"
  
  ; Copy all other plugin DLL files
  File "..\build\windows\x64\runner\Release\connectivity_plus_plugin.dll"
  File "..\build\windows\x64\runner\Release\desktop_drop_plugin.dll"
  File "..\build\windows\x64\runner\Release\hotkey_manager_plugin.dll"
  File "..\build\windows\x64\runner\Release\hotkey_manager_windows_plugin.dll"
  File "..\build\windows\x64\runner\Release\screen_retriever_plugin.dll"
  File "..\build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"
  File "..\build\windows\x64\runner\Release\window_manager_plugin.dll"
  
  ; Copy data folder
  SetOutPath "$INSTDIR\data"
  File /r "..\build\windows\x64\runner\Release\data\*"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Write to registry
  WriteRegStr HKLM "Software\${APP_NAME}" "InstallPath" "$INSTDIR"
  WriteRegStr HKLM "Software\${APP_NAME}" "Version" "${APP_VERSION}"
  
  ; Add to Control Panel programs list
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_EXECUTABLE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1
  
  ; Calculate installation size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "EstimatedSize" "$0"
SectionEnd

; Shortcuts section
Section "Desktop Shortcut" SecDesktop
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}" "" "$INSTDIR\${APP_EXECUTABLE}" 0
SectionEnd

Section "Start Menu" SecStartMenu
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}" "" "$INSTDIR\${APP_EXECUTABLE}" 0
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
SectionEnd

; Uninstallation section
Section "Uninstall"
  ; Close running application before uninstallation
  Call un.CloseApplication
  
  ; Delete main files
  Delete "$INSTDIR\${APP_EXECUTABLE}"
  Delete "$INSTDIR\flutter_windows.dll"
  
  ; Delete auto-updater related DLL files
  Delete "$INSTDIR\WinSparkle.dll"
  Delete "$INSTDIR\auto_updater_windows_plugin.dll"
  
  ; Delete all other plugin DLL files
  Delete "$INSTDIR\connectivity_plus_plugin.dll"
  Delete "$INSTDIR\desktop_drop_plugin.dll"
  Delete "$INSTDIR\hotkey_manager_plugin.dll"
  Delete "$INSTDIR\hotkey_manager_windows_plugin.dll"
  Delete "$INSTDIR\screen_retriever_plugin.dll"
  Delete "$INSTDIR\url_launcher_windows_plugin.dll"
  Delete "$INSTDIR\window_manager_plugin.dll"
  
  ; Delete uninstaller
  Delete "$INSTDIR\Uninstall.exe"
  
  ; Delete data folder
  RMDir /r "$INSTDIR\data"
  
  ; Delete shortcuts
  Delete "$DESKTOP\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"
  
  ; Delete registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
  DeleteRegKey HKLM "Software\${APP_NAME}"
  
  ; Delete installation directory
  RMDir "$INSTDIR"
SectionEnd

; Pre-installation check
Function .onInit
  ; Check if already installed
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString"
  StrCmp $R0 "" done
  
  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "${APP_NAME} is already installed.$\n$\nClick 'OK' to uninstall the previous version, or 'Cancel' to exit the installer." IDOK uninst
  Abort
  
  uninst:
    ClearErrors
    ExecWait '$R0 _?=$INSTDIR'
    
    IfErrors no_remove_uninstaller done
    no_remove_uninstaller:
  
  done:
FunctionEnd