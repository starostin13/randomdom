@echo off
REM Build script for Windows
REM This creates a standalone executable using PyInstaller

echo Installing PyInstaller...
pip install pyinstaller

echo Building RandomDom executable...
pyinstaller --onefile --name randomdom randomdom.py

echo.
echo Build complete!
echo Executable is located in: dist\randomdom.exe
echo.
pause
