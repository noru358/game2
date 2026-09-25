@echo off
chcp 65001 >nul
setlocal
set "MAP_ENGINE=%~dp0..\겜1\.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not "%~1"=="" set "MAP_ENGINE=%~1"
if not exist "%MAP_ENGINE%" (
  echo Godot 4.7.2 was not found. Drag its executable onto this launcher.
  pause
  exit /b 2
)
start "Altar Field Preview 03" "%MAP_ENGINE%" --path "%~dp0source_pack_v4\experiments\terrace" res://maps/map_preview.tscn -- --test --altar-focus

