@echo off
echo Building QuickStart installer...

:: Check if NSIS is installed
where makensis >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: NSIS not found. Please install NSIS first.
    echo Download from: https://nsis.sourceforge.io/Download
    pause
    exit /b 1
)

:: Sync version
echo Syncing version...
call dart run sync_version.dart
if %ERRORLEVEL% NEQ 0 (
    echo Error: Version synchronization failed
    pause
    exit /b 1
)




:: Build Flutter application
echo Building Flutter application...
cd ..
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

:: Compile installer
echo Compiling installer...
cd installer
makensis installer.nsi
if %ERRORLEVEL% NEQ 0 (
    echo Error: Installer compilation failed
    pause
    exit /b 1
)

echo Installer build completed!

:: Generate DSA signature
echo Generating DSA signature...
cd ..
dart run auto_updater:sign_update installer/QuickStart-1.2.0-windows-setup.exe
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Failed to generate signature
)

pause