@echo off


set project_name=QuickStart
set project_version=1.9.0
set project_root=%~dp0..\..
set scripts_dir=%project_root%\build_tools\scripts
set key_private=%project_root%\build_tools\keys\dsa_priv.pem
set updater_dir=%project_root%\\dist\\updater
set installer_dir=%project_root%\\dist\\installer


:: 切换到 build_tools\scripts 目录
cd /d %scripts_dir%

:: 从 pubspec.yaml 提取项目信息
echo Extracting project info from pubspec.yaml...
for /f "tokens=1,2 delims==" %%a in ('dart run extract_project_info.dart') do (
    if "%%a"=="PROJECT_NAME" set project_name=%%b
    if "%%a"=="PROJECT_VERSION" set project_version=%%b
)
set project_output=%installer_dir%\%project_name%-%project_version%-windows-setup.exe

:: 打印项目信息
echo Project name: %project_name%
echo Project version: %project_version%
echo Project output: %project_output%
echo Project root directory: %project_root%
echo Scripts directory: %scripts_dir%
echo Installer directory: %installer_dir%
echo Updater directory: %updater_dir%
echo Key private: %key_private%





echo Starting %project_name% build process...


cd /d %project_root%
echo Project root: %project_root%
echo Current directory: %CD%

:: 检查环境
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter not found in PATH
    exit /b 1
)

:: 清理并构建
echo Cleaning previous build...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo Error: Flutter clean failed
    pause
    exit /b 1
)

echo Building Flutter app...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

:: 切换到 build_tools\scripts 目录
echo Switching to build_tools\scripts directory...
cd build_tools\scripts
echo Current directory: %CD%

:: 构建安装程序
echo Building installer...

:: Check if NSIS is installed
echo Checking if NSIS is installed...
where makensis >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: NSIS not found. Please install NSIS first.
    echo Download from: https://nsis.sourceforge.io/Download
    pause
    exit /b 1
)

:: Switch to project root directory
echo Switching to project root directory...
cd /d %project_root%
echo Current directory: %CD%

:: Create dist directory if it doesn't exist
if not exist "dist" (
    echo Creating dist directory...
    mkdir "dist"
)

:: Compile installer
echo Compiling installer...
cd build_tools\scripts
makensis /DPROJECT_ROOT=%project_root% /DPROJECT_OUTPUT=%project_output% installer.nsi


if %ERRORLEVEL% NEQ 0 (
    echo Error: Installer compilation failed
    pause
    exit /b 1
)

echo Installer build completed!

:: 签名更新包
echo Switching to root directory...
cd %project_root%
echo Current directory: %CD%

echo Signing update package...
:: 生成签名并捕获完整输出
echo Generating signature...
for /f "delims=" %%i in ('dart run auto_updater:sign_update "%project_output%" "%key_private%" 2^>^&1') do set "sign_output=%%i"
echo Generating signature2
if "%sign_output%"=="" (
    echo Error: Failed to generate signature
    pause
    exit /b 1
)
echo Sign output: %sign_output%

:: 生成 appcast.xml
echo Generating appcast.xml...
dart run %scripts_dir%\generate_appcast.dart "%project_output%" "%sign_output%" "%project_name%" "%project_version%" "%updater_dir%"
if %errorlevel% neq 0 (
    echo Failed to generate appcast.xml
    exit /b 1
)


echo Build completed successfully!
pause
