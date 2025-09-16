@echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: QuickStart Build Script (Simplified)
:: =============================================================================

echo QuickStart Build Script
echo =======================
echo.

:: Change to script directory
cd /d "%~dp0"
if !ERRORLEVEL! neq 0 (
    echo Error: Failed to change to script directory
    exit /b 1
)

:: Check if Dart is available
call dart --version >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo Error: Dart is not installed or not in PATH
    echo Please install Dart SDK and add it to your PATH
    exit /b 1
)

:: Install Flutter dependencies
echo Installing Flutter dependencies...
cd /d "%~dp0\..\.." 
call flutter pub get
if !ERRORLEVEL! neq 0 (
    echo Error: Failed to install Flutter dependencies
    exit /b 1
)

:: Return to script directory
cd /d "%~dp0"

:: Run the Dart build script
echo Running: dart build.dart
echo.
call dart build.dart
set "BUILD_RESULT=!ERRORLEVEL!"

:: Exit with the same code as the Dart script
if !BUILD_RESULT! neq 0 (
    echo.
    echo Build failed with exit code !BUILD_RESULT!
    exit /b !BUILD_RESULT!
)

echo.
echo Build completed successfully!
exit /b 0