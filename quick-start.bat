@echo off
REM Quick launch script for RandomDom - Windows
REM Double-click this file to get a random task instantly!
REM No command line needed!

set "LIST_NAME=%~1"
if "%LIST_NAME%"=="" set "LIST_NAME=main"

cd /d "%~dp0"
python "%~dp0randomdom.py" --list "%LIST_NAME%"
pause
