@echo off
setlocal

set "SRC_DIR=%~dp0"
if "%SRC_DIR:~-1%"=="\" set "SRC_DIR=%SRC_DIR:~0,-1%"

set "WORK_DIR=C:\dev\randomdom_win_build"
set "OUTPUT_DIR=%SRC_DIR%\release\windows-portable"

set "FLUTTER_CMD=C:\tools\flutter\bin\flutter.bat"
if not exist "%FLUTTER_CMD%" set "FLUTTER_CMD=flutter"

echo [1/5] Preparing local build directory...
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
mkdir "%WORK_DIR%"

echo [2/5] Copying project to local build directory (avoids OneDrive lock issues)...
robocopy "%SRC_DIR%" "%WORK_DIR%" /E /XD "%SRC_DIR%\build" "%SRC_DIR%\.dart_tool" "%SRC_DIR%\.git" "%SRC_DIR%\windows\flutter\ephemeral" >nul
if errorlevel 8 (
  echo ERROR: robocopy failed.
  exit /b 1
)

echo [3/5] Running Flutter build...
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

echo [4/5] Creating portable output...
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

robocopy "%WORK_DIR%\build\windows\x64\runner\Release" "%OUTPUT_DIR%" /E >nul
if errorlevel 8 (
  echo ERROR: failed to copy Release output.
  exit /b 1
)

if exist "%SRC_DIR%\..\config.json" copy /y "%SRC_DIR%\..\config.json" "%OUTPUT_DIR%\config.json" >nul

echo [5/5] Done.
echo Portable folder: "%OUTPUT_DIR%"
echo Executable: "%OUTPUT_DIR%\randomdom_flutter.exe"

endlocal
