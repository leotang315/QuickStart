@echo off
setlocal enabledelayedexpansion

echo Synchronizing metadata from pubspec.yaml...

:: Read version from pubspec.yaml
set "VERSION="
for /f "tokens=2 delims: " %%a in ('findstr "^version:" ..\pubspec.yaml') do (

    set "VERSION=%%a"
)

if "%VERSION%"=="" (
    echo Error: Could not read version from pubspec.yaml
    exit /b 1
)

echo Found version: %VERSION%

:: Update installer.nsi
echo Updating installer.nsi...
if exist "installer.nsi.bak" del "installer.nsi.bak"
copy "installer.nsi" "installer.nsi.bak" >nul

:: Create temporary file for sed-like replacement
set "TEMP_FILE=%TEMP%\installer_temp.nsi"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

:: Replace version in installer.nsi
for /f "delims=" %%i in (installer.nsi) do (
    set "line=%%i"
    if "!line:~0,19!"=="!define APP_VERSION " (
        echo !define APP_VERSION "%VERSION%">>%TEMP_FILE%
    ) else if "!line:~0,8!"=="OutFile " (
        echo OutFile "QuickStart-%VERSION%-windows-setup.exe">>%TEMP_FILE%
    ) else (
        echo !line!>>%TEMP_FILE%
    )
)

move "%TEMP_FILE%" "installer.nsi" >nul

:: Update build_installer.bat output message
echo Updating build_installer.bat...
if exist "build_installer.bat.bak" del "build_installer.bat.bak"
copy "build_installer.bat" "build_installer.bat.bak" >nul

set "TEMP_FILE=%TEMP%\build_installer_temp.bat"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

for /f "delims=" %%i in (build_installer.bat) do (
    set "line=%%i"
    if "!line:~0,17!"=="echo Output file: " (
        echo echo Output file: QuickStart-%VERSION%-windows-setup.exe>>%TEMP_FILE%
    ) else if "!line:~0,35!"=="dart run auto_updater:sign_update " (
        echo dart run auto_updater:sign_update installer/QuickStart-%VERSION%-windows-setup.exe>>%TEMP_FILE%
    ) else (
        echo !line!>>%TEMP_FILE%
    )
)

move "%TEMP_FILE%" "build_installer.bat" >nul

echo.
echo Metadata synchronization completed!
echo Version %VERSION% has been applied to:
echo   - installer.nsi
echo   - build_installer.bat
echo.
echo Note: Windows and Android versions will be automatically
echo       synchronized when you run 'flutter build'
echo.