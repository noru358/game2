@echo off
chcp 65001 >nul
setlocal
set "RUIN_ENGINE=%~dp0..\겜1\.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not "%~1"=="" set "RUIN_ENGINE=%~1"
if not exist "%RUIN_ENGINE%" exit /b 2
start "Ruin production A B" "%RUIN_ENGINE%" --path "%~dp0source_pack_v4\experiments\terrace" res://maps/ruin_production.tscn -- --test
