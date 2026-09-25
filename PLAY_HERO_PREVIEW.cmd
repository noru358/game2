@echo off
chcp 65001 >nul
setlocal
set "GAME_HERO_ENGINE=%~dp0..\겜1\.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not "%~1"=="" set "GAME_HERO_ENGINE=%~1"
if not exist "%GAME_HERO_ENGINE%" (
  echo Godot 4.7.2 was not found. Drag its executable onto this launcher.
  pause
  exit /b 2
)
start "Hero movement and combat" "%GAME_HERO_ENGINE%" --path "%~dp0source_pack_v4\experiments\terrace" res://lab/character_integration.tscn -- --test
endlocal
