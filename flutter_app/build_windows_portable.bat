@echo off
setlocal

set "SRC_DIR=%~dp0"
if "%SRC_DIR:~-1%"=="\" set "SRC_DIR=%SRC_DIR:~0,-1%"

set "WORK_DIR=C:\dev\randomdom_win_build"
set "OUTPUT_DIR_PRIMARY=%SRC_DIR%\release\windows-portable"
set "OUTPUT_DIR_FALLBACK=%SRC_DIR%\release\windows-portable-new"
set "OUTPUT_DIR=%OUTPUT_DIR_PRIMARY%"
set "ANDROID_OUTPUT_DIR=%SRC_DIR%\release\android"
set "ANDROID_APK_SRC=%SRC_DIR%\build\app\outputs\flutter-apk\app-release.apk"
set "ANDROID_APK_DST=%ANDROID_OUTPUT_DIR%\randomdom-release.apk"

set "FLUTTER_CMD=C:\tools\flutter\bin\flutter.bat"
if not exist "%FLUTTER_CMD%" set "FLUTTER_CMD=flutter"

echo [1/8] Preparing local build directory...
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
mkdir "%WORK_DIR%"

echo [2/8] Copying project to local build directory (avoids OneDrive lock issues)...
robocopy "%SRC_DIR%" "%WORK_DIR%" /E /XD "%SRC_DIR%\build" "%SRC_DIR%\.dart_tool" "%SRC_DIR%\.git" "%SRC_DIR%\windows\flutter\ephemeral" >nul
if errorlevel 8 (
  echo ERROR: robocopy failed.
  exit /b 1
)

echo [3/8] Running Flutter build for Windows...
pushd "%WORK_DIR%"

if exist "%WORK_DIR%\windows\flutter\ephemeral" rmdir /s /q "%WORK_DIR%\windows\flutter\ephemeral"
if exist "%WORK_DIR%\.dart_tool" rmdir /s /q "%WORK_DIR%\.dart_tool"
if exist "%WORK_DIR%\build" rmdir /s /q "%WORK_DIR%\build"

call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  popd
  echo ERROR: flutter pub get failed.
  exit /b 1
)

call "%FLUTTER_CMD%" build windows --release
if errorlevel 1 (
  popd
  echo ERROR: flutter build windows failed.
  exit /b 1
)
popd

echo [4/8] Creating portable Windows output...
if exist "%OUTPUT_DIR_PRIMARY%" rmdir /s /q "%OUTPUT_DIR_PRIMARY%"
if exist "%OUTPUT_DIR_PRIMARY%" (
  echo Primary output is busy. Using fallback folder.
  set "OUTPUT_DIR=%OUTPUT_DIR_FALLBACK%"
)

if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

robocopy "%WORK_DIR%\build\windows\x64\runner\Release" "%OUTPUT_DIR%" /E /R:1 /W:1 >nul
if errorlevel 8 (
  echo ERROR: failed to copy Release output.
  exit /b 1
)

if exist "%SRC_DIR%\..\config.json" copy /y "%SRC_DIR%\..\config.json" "%OUTPUT_DIR%\config.json" >nul

echo [5/8] Building Android APK...
set "ANDROID_BUILD_OK=0"

call "%FLUTTER_CMD%" pub get
if not errorlevel 1 (
  call "%FLUTTER_CMD%" build apk --release
  if not errorlevel 1 set "ANDROID_BUILD_OK=1"
)

if "%ANDROID_BUILD_OK%"=="0" (
  echo Windows Android build failed. Trying WSL fallback...
  where wsl >nul 2>&1
  if errorlevel 1 (
    echo ERROR: Android build failed and WSL is not available.
    exit /b 1
  )

  wsl -d Ubuntu -- bash -lc "SRC_DIR_WSL=$(wslpath -a \"$1\"); cd \"$SRC_DIR_WSL\"; /home/starostin/flutter/bin/flutter pub get; /home/starostin/flutter/bin/flutter build apk --release" _ "%SRC_DIR%"
  if errorlevel 1 (
    echo ERROR: Android build failed in WSL fallback.
    exit /b 1
  )
)

echo [6/8] Preparing Android release output...
if exist "%ANDROID_OUTPUT_DIR%" rmdir /s /q "%ANDROID_OUTPUT_DIR%"
mkdir "%ANDROID_OUTPUT_DIR%"

echo [7/8] Copying APK...
if not exist "%ANDROID_APK_SRC%" (
  echo ERROR: APK was not found at "%ANDROID_APK_SRC%".
  exit /b 1
)
copy /y "%ANDROID_APK_SRC%" "%ANDROID_APK_DST%" >nul
if errorlevel 1 (
  echo ERROR: failed to copy APK.
  exit /b 1
)

echo [8/8] Done.
echo Portable folder: "%OUTPUT_DIR%"
echo Executable: "%OUTPUT_DIR%\randomdom_flutter.exe"
echo Android APK: "%ANDROID_APK_DST%"

endlocal
