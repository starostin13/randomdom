Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Get the directory where this script is located
scriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)

' Run the Python script silently (0 = hidden window, True = wait for completion)
WshShell.Run "cmd /c cd /d """ & scriptDir & """ && python randomdom.py --list main", 0, True

' Show a brief notification
WshShell.Popup "Задача выбрана! Проверьте браузер или другие приложения." & vbCrLf & "Task selected! Check your browser or other apps.", 3, "RandomDom", 64
