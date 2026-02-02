@echo off
REM Create Desktop Shortcut for RandomDom - Windows
REM This script creates a desktop shortcut for easy one-click access

echo ========================================
echo Creating RandomDom Desktop Shortcut
echo ========================================
echo.

REM Get the current directory
set "SCRIPT_DIR=%~dp0"
set "SHORTCUT_PATH=%USERPROFILE%\Desktop\RandomDom.lnk"

REM Create the shortcut using PowerShell
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%SCRIPT_DIR%quick-start.bat'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,43'; $Shortcut.Description = 'RandomDom - Random Task Selector'; $Shortcut.Save()"

if exist "%SHORTCUT_PATH%" (
    echo.
    echo ✓ Success! Desktop shortcut created!
    echo.
    echo Shortcut location: %SHORTCUT_PATH%
    echo.
    echo You can now double-click the "RandomDom" icon on your desktop
    echo to instantly get a random task!
    echo.
) else (
    echo.
    echo ✗ Failed to create shortcut.
    echo Please create it manually:
    echo 1. Right-click on quick-start.bat
    echo 2. Select "Send to" -^> "Desktop (create shortcut)"
    echo.
)

pause
