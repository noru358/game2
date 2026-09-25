@echo off
chcp 65001 >nul
setlocal
set "WATER_ENTRY_ENGINE=%~dp0..\겜1\.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not "%~1"=="" set "WATER_ENTRY_ENGINE=%~1"
if not exist "%WATER_ENTRY_ENGINE%" (
  echo Godot 4.7.2 was not found. Drag its executable onto this launcher.
  pause
  exit /b 2
)
start "Water entry direction" "%WATER_ENTRY_ENGINE%" --path "%~dp0source_pack_v4\experiments\terrace" res://maps/water_entry_direction.tscn -- --test
endlocal
