; QuickStart Installer Script for Inno Setup
; Compile with Inno Setup 6.0+

#ifndef PROJECT_ROOT
  #define PROJECT_ROOT "..\.." 
#endif

#ifndef PROJECT_OUTPUT
  #define PROJECT_OUTPUT PROJECT_ROOT + "\\dist\\QuickStart-1.8.0-windows-setup.exe"
#endif

#define APP_NAME "QuickStart"
#define APP_VERSION "1.8.0"
#define APP_PUBLISHER "Your Company Name"
#define APP_URL "https://yourcompany.com"
#define APP_EXECUTABLE "quick_start.exe"
#define APP_DESCRIPTION "QuickStart - Quick Launch Application"

[Setup]
AppName={#APP_NAME}
AppVersion={#APP_VERSION}
AppPublisher={#APP_PUBLISHER}
AppPublisherURL={#APP_URL}
AppSupportURL={#APP_URL}
AppUpdatesURL={#APP_URL}
DefaultDirName={autopf}\{#APP_NAME}
DefaultGroupName={#APP_NAME}
AllowNoIcons=yes
LicenseFile={#PROJECT_ROOT}\build_tools\config\license.txt
OutputDir={#ExtractFileDir(PROJECT_OUTPUT)}
OutputBaseFilename={#ExtractFileName(PROJECT_OUTPUT)}
SetupIconFile={#PROJECT_ROOT}\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; Note: ChineseSimplified.isl may not be available in all Inno Setup installations
; Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; Main executable
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\{#APP_EXECUTABLE}"; DestDir: "{app}"; Flags: ignoreversion

; Flutter runtime files
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Auto-updater related DLL files
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\WinSparkle.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\auto_updater_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion

; Plugin DLL files
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\connectivity_plus_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\desktop_drop_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\hotkey_manager_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\screen_retriever_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data folder
Source: "{#PROJECT_ROOT}\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#APP_NAME}"; Filename: "{app}\{#APP_EXECUTABLE}"
Name: "{group}\{cm:UninstallProgram,{#APP_NAME}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#APP_NAME}"; Filename: "{app}\{#APP_EXECUTABLE}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#APP_NAME}"; Filename: "{app}\{#APP_EXECUTABLE}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#APP_EXECUTABLE}"; Description: "{cm:LaunchProgram,{#StringChange(APP_NAME, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
; Application registry entries
Root: HKLM; Subkey: "Software\{#APP_NAME}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKLM; Subkey: "Software\{#APP_NAME}"; ValueType: string; ValueName: "Version"; ValueData: "{#APP_VERSION}"

[Code]
// Function to check if application is running
function IsAppRunning(): Boolean;
var
  WbemLocator: Variant;
  WMIService: Variant;
  WbemObjectSet: Variant;
begin
  Result := false;
  try
    WbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    WMIService := WbemLocator.ConnectServer('', 'root\cimv2', '', '');
    WbemObjectSet := WMIService.ExecQuery('SELECT * FROM Win32_Process WHERE Name="{#APP_EXECUTABLE}"');
    Result := (WbemObjectSet.Count > 0);
  except
    // If WMI fails, assume app is not running
    Result := false;
  end;
end;

// Function to terminate application using taskkill command
function TerminateApp(): Boolean;
var
  ResultCode: Integer;
begin
  Result := true;
  try
    // Use taskkill command to terminate the process
    if not Exec('taskkill', '/F /IM "{#APP_EXECUTABLE}"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      Result := false
    else
      Result := (ResultCode = 0);
  except
    Result := false;
  end;
end;

// Function to handle running application before installation
function CloseApplication(): Boolean;
var
  Counter: Integer;
begin
  Result := true;
  
  if not IsAppRunning() then
    Exit;
    
  if MsgBox('{#APP_NAME} is currently running.' + #13#10 + #13#10 + 
            'Click ''Yes'' to automatically close the application, or ''No'' to exit installation.', 
            mbConfirmation, MB_YESNO) = IDNO then
  begin
    Result := false;
    Exit;
  end;
  
  // Try to terminate the application
  if not TerminateApp() then
  begin
    MsgBox('Unable to close {#APP_NAME}. Please close the application manually and run the installer again.', 
           mbError, MB_OK);
    Result := false;
    Exit;
  end;
  
  // Wait for application to close (max 10 seconds)
  Counter := 0;
  while IsAppRunning() and (Counter < 100) do
  begin
    Sleep(100);
    Counter := Counter + 1;
  end;
  
  if IsAppRunning() then
  begin
    MsgBox('Unable to close {#APP_NAME}. Please close the application manually and run the installer again.', 
           mbError, MB_OK);
    Result := false;
  end;
end;

// Pre-installation initialization
function InitializeSetup(): Boolean;
var
  UninstallString: String;
  ErrorCode: Integer;
begin
  Result := true;
  
  // Check if application is running
  if not CloseApplication() then
  begin
    Result := false;
    Exit;
  end;
  
  // Check if already installed
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#APP_NAME}_is1', 
                         'UninstallString', UninstallString) then
  begin
    if MsgBox('{#APP_NAME} is already installed.' + #13#10 + #13#10 + 
              'Click ''Yes'' to uninstall the previous version, or ''No'' to exit the installer.', 
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      if not Exec(RemoveQuotes(UninstallString), '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode) then
      begin
        MsgBox('Failed to uninstall the previous version.', mbError, MB_OK);
        Result := false;
      end;
    end
    else
    begin
      Result := false;
    end;
  end;
end;

// Pre-uninstallation check
function InitializeUninstall(): Boolean;
begin
  Result := CloseApplication();
end;

[CustomMessages]
english.LaunchProgram=Launch {#APP_NAME}
; Note: Chinese messages removed since Chinese language is not configured
; chinesesimplified.LaunchProgram=启动 {#APP_NAME}

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"