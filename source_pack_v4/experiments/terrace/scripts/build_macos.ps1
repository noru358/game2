$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = (Resolve-Path (Join-Path $projectRoot '../..')).Path
$enginePath = Join-Path $workspaceRoot '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$templatePath = Join-Path $workspaceRoot '.tools/export/macos.zip'
$outputPath = Join-Path $projectRoot 'builds/ExperienceLab-0.10-macos-app.zip'

if (-not (Test-Path -LiteralPath $enginePath)) { throw 'Missing Godot 4.7.2 editor.' }
if (-not (Test-Path -LiteralPath $templatePath)) { throw 'Missing official Godot 4.7.2 macOS export template.' }

Push-Location -LiteralPath $projectRoot
try {
    & $enginePath --headless --path $projectRoot --editor --import
    if ($LASTEXITCODE -ne 0) { throw 'Import failed.' }

    & $enginePath --headless --path $projectRoot --export-release 'Experience Lab macOS' $outputPath
    if ($LASTEXITCODE -ne 0) { throw 'macOS export failed.' }

    python scripts/package_macos.py
    if ($LASTEXITCODE -ne 0) { throw 'macOS packaging failed.' }
} finally {
    Pop-Location
}
