@echo off
setlocal enabledelayedexpansion

:: =============================================================================
:: QuickStart Build Script - Enhanced Version
:: Description: Automated build script for QuickStart Flutter application
:: Author: Build System
:: Version: 2.0.0
:: =============================================================================

:: Initialize build configuration
call :init_config
if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!

:: Validate environment
call :validate_environment
if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!

:: Extract project information
call :extract_project_info
if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!

:: Clean and build Flutter application
call :build_flutter_app
if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!

:: Create installer
call :create_installer
if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!

:: Create installer
call :sign_and_generate_updates
if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!

:: Build completed successfully
echo ===============================================
echo Build completed successfully!
echo Project: !project_name! v!project_version!
echo Output: !installer_path!
echo ===============================================
pause
exit /b 0

:: =============================================================================
:: Function: Initialize build configuration
:: =============================================================================
:init_config
echo Initializing build configuration...

:: Set default values
set "project_name=default"
set "project_version=0.0.0"
set "installer_filename=default-0.0.0-windows-setup"

set "project_root=%~dp0..\.."
set "scripts_dir=%project_root%\build_tools\scripts"
set "updater_dir=%project_root%\dist\updater"
set "installer_dir=%project_root%\dist\installer"
set "build_dir=%project_root%\build\windows\x64\runner\Release"
set "key_private_path=%project_root%\build_tools\keys\dsa_priv.pem"
set "installer_path=%installer_dir%\!installer_filename!.exe"
set "installer_path_without_exe=%installer_dir%\!installer_filename!"

:: Create necessary directories
if not exist "!project_root!\dist" (
    echo Creating dist directory...
    mkdir "!project_root!\dist"
)
if not exist "!installer_dir!" (
    echo Creating installer directory...
    mkdir "!installer_dir!"
)
if not exist "!updater_dir!" (
    echo Creating updater directory...
    mkdir "!updater_dir!"
)

echo Initializing build configuration successfully.
exit /b 0

:: =============================================================================
:: Function: Validate build environment
:: =============================================================================
:validate_environment
echo Validating build environment...

:: Check if Flutter is installed
where flutter >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo Error: Flutter not found in PATH
    echo Please install Flutter and add it to your PATH
    echo Download from: https://flutter.dev/docs/get-started/install
    exit /b 1
)

:: Check if Dart is available
where dart >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo Error: Dart not found in PATH
    echo Dart should be included with Flutter installation
    exit /b 1
)

:: Check if Inno Setup is installed
where iscc >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo Error: Inno Setup not found in PATH
    echo Please install Inno Setup and add it to your PATH
    echo Download from: https://jrsoftware.org/isinfo.php
    exit /b 1
)

:: Check if project root exists
if not exist "!project_root!\pubspec.yaml" (
    echo Error: pubspec.yaml not found in project root
    echo Project root: !project_root!
    exit /b 1
)

:: Check if private key exists
if not exist "!key_private_path!" (
    echo Warning: Private key not found at !key_private_path!
    echo Auto-update signing will be skipped
)

echo Validating build environment successfully.
exit /b 0

:: =============================================================================
:: Function: Extract project information from pubspec.yaml
:: =============================================================================
:extract_project_info
echo Extracting project information from pubspec.yaml...

:: Change to scripts directory
cd /d "!scripts_dir!"
if !ERRORLEVEL! neq 0 (
    echo Error: Failed to change to scripts directory
    exit /b 1
)

:: Extract project info using Dart script
for /f "tokens=1,2 delims==" %%a in ('dart run extract_project_info.dart "!project_root!\pubspec.yaml"  2^>nul') do (
    if "%%a"=="PROJECT_NAME" set "project_name=%%b"
    if "%%a"=="PROJECT_VERSION" set "project_version=%%b"
    if "%%a"=="INSTALLER_FILENAME" set "installer_filename=%%b"
)

:: Validate extracted information
if "!project_name!"=="" (
    echo Error: Failed to extract project name from pubspec.yaml
    exit /b 1
)
if "!project_version!"=="" (
    echo Error: Failed to extract project version from pubspec.yaml
    exit /b 1
)
if "!installer_filename!"=="" (
    echo Error: Failed to extract installer filename from pubspec.yaml
    exit /b 1
)

:: Set output file path
set "installer_path=%installer_dir%\!installer_filename!.exe"
set "installer_path_without_exe=%installer_dir%\!installer_filename!"

:: Display project information
echo.
echo ===============================================
echo Project Information:
echo   Name: !project_name!
echo   Version: !project_version!
echo   Installer Filename: !installer_filename!

echo   Project Root: !project_root!
echo   Installer Dir: !installer_dir!
echo   Updater Dir: !updater_dir!
echo   Build Dir: !build_dir!
echo   Key Private Path: !key_private_path!
echo   Installer Path: !installer_path!
echo   Installer Path Without EXE: !installer_path_without_exe!
echo ===============================================
echo.

exit /b 0

:: =============================================================================
:: Function: Build Flutter application
:: =============================================================================
:build_flutter_app
echo Building Flutter application...

:: Change to project root
cd /d "!project_root!"
if !ERRORLEVEL! neq 0 (
    echo Error: Failed to change to project root directory
    exit /b 1
)

:: Clean previous build
echo Cleaning previous build...
call flutter clean
if !ERRORLEVEL! neq 0 (
    echo Error: Flutter clean failed
    exit /b 1
)

:: Get dependencies
echo Getting Flutter dependencies...
call flutter pub get
if !ERRORLEVEL! neq 0 (
    echo Error: Flutter pub get failed
    exit /b 1
)

:: Build Windows release
echo Building Windows release...
call flutter build windows --release
if !ERRORLEVEL! neq 0 (
    echo Error: Flutter build failed
    exit /b 1
)

:: Verify build output
if not exist "!build_dir!\!project_name!.exe" (
    echo Error: Build output not found at !build_dir!\!project_name!.exe
    exit /b 1
)

echo Building Flutter application successfully.
exit /b 0

:: =============================================================================
:: Function: Create installer using Inno Setup
:: =============================================================================
:create_installer
echo Creating installer...

:: Change to scripts directory
cd /d "!scripts_dir!"
if !ERRORLEVEL! neq 0 (
    echo Error: Failed to change to scripts directory
    exit /b 1
)

:: Compile installer with Inno Setup
echo Compiling installer with Inno Setup...
iscc /DPROJECT_ROOT="!project_root!" /DPROJECT_OUTPUT="!installer_path_without_exe!" installer.iss
if !ERRORLEVEL! neq 0 (
    echo Error: Inno Setup installer compilation failed
    exit /b 1
)

:: Verify installer was created
if not exist "!installer_path!" (
    echo Error: Installer file not found at !installer_path!
    exit /b 1
)

:: Get installer file size
for %%F in ("!installer_path!") do set "installer_size=%%~zF"
echo Creating installer successfully (Size: !installer_size! bytes)

exit /b 0



:: =============================================================================
:: Function: Sign update package and generate appcast
:: =============================================================================
:sign_and_generate_updates
echo Processing auto-update files...

:: Check if private key exists
if not exist "!key_private_path!" (
    echo Warning: Private key not found, skipping auto-update signing
    exit /b 0
)

:: Change to project root
cd /d "!project_root!"
if !ERRORLEVEL! neq 0 (
    echo Error: Failed to change to project root directory
    exit /b 1
)

:: Generate signature
echo Generating update signature...
for /f "delims=" %%i in ('dart run auto_updater:sign_update "!installer_path!" "!key_private_path!" 2^>^&1') do set "sign_output=%%i"

if "!sign_output!"=="" (
    echo Error: Failed to generate signature
    exit /b 1
)

echo Signature generated: !sign_output!

:: Generate appcast.xml
echo Generating appcast.xml...
call dart run "!scripts_dir!\generate_appcast.dart" "!installer_path!" "!sign_output!" "!project_name!" "!project_version!" "!updater_dir!"
if !errorlevel! neq 0 (
    echo Error: Failed to generate appcast.xml
    exit /b 1
)

echo Auto-update files generated successfully.
exit /b 0

:: =============================================================================
:: End of script
:: =============================================================================