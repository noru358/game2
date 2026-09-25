@echo off
setlocal
set "ROOTS_ENGINE=C:\Users\User\Documents\ChatGPT\°×1\.tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%ROOTS_ENGINE%" set "ROOTS_ENGINE=C:\Users\User\Documents\ChatGPT\°×1\.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
start "Roots Terrace" "%ROOTS_ENGINE%" --path "C:\Users\User\Downloads\ROOTS_TERRACE_BLOCKOUT_V01"
