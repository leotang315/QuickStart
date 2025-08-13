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
echo Output file: QuickStart_Setup_1.0.0.exe
pause