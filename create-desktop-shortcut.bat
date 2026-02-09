@echo off
REM Create Desktop Shortcut for RandomDom - Windows
REM This script creates a desktop shortcut for easy one-click access

echo ========================================
echo Creating RandomDom Desktop Shortcut
echo ========================================
echo.

REM Get the current directory
set "SCRIPT_DIR=%~dp0"
REM Use short path to avoid Unicode issues in the PowerShell command
set "SCRIPT_DIR_SHORT=%~sdp0"

REM Create the shortcut using PowerShell (resolve the real Desktop path)
powershell -NoProfile -Command "try { $desktop = [Environment]::GetFolderPath('Desktop'); $shortcutPath = Join-Path $desktop 'RandomDom.lnk'; $targetPath = Join-Path '%SCRIPT_DIR_SHORT%' 'quick-start.bat'; $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut($shortcutPath); $Shortcut.TargetPath = $targetPath; $Shortcut.WorkingDirectory = '%SCRIPT_DIR_SHORT%'; $Shortcut.IconLocation = 'C:\Windows\System32\shell32.dll,43'; $Shortcut.Description = 'RandomDom - Random Task Selector'; $Shortcut.Save(); exit 0 } catch { try { $desktop = [Environment]::GetFolderPath('Desktop'); $cmdPath = Join-Path $desktop 'RandomDom.cmd'; $lines = @('@echo off', ('cd /d "' + $env:SCRIPT_DIR_SHORT + '"'), ('call "' + $env:SCRIPT_DIR_SHORT + 'quick-start.bat"')); Set-Content -Path $cmdPath -Value $lines -Encoding ASCII; exit 2 } catch { Write-Error $_; exit 1 } }"

if %errorlevel%==0 (
    echo.
    echo Success! Desktop shortcut created!
    echo.
    echo You can now double-click the "RandomDom" icon on your desktop
    echo to instantly get a random task!
    echo.
) else if %errorlevel%==2 (
    echo.
    echo Shortcut creation failed due to Unicode path issues.
    echo Created desktop launcher: RandomDom.cmd
    echo Double-click it to instantly get a random task!
    echo.
) else (
    echo.
    echo Failed to create shortcut.
    echo Please create it manually:
    echo 1. Right-click on quick-start.bat
    echo 2. Select "Send to" -^> "Desktop (create shortcut)"
    echo.
)

pause
