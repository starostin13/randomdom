@echo off
REM Quick launch script for RandomDom - Windows
REM Double-click this file to get a random task instantly!
REM No command line needed!

cd /d "%~dp0"
python "%~dp0randomdom.py" --list main
pause
