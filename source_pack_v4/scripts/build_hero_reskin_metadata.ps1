param(
    [string]$ProjectRoot = (Join-Path $PSScriptRoot '..\experiments\terrace')
)

$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $ProjectRoot 'assets\hero'
$targetRoot = Join-Path $ProjectRoot 'assets\hero_reskin_v1'

$pairs = @(
    @{ Source = 'grove_scholar_walk_eight_v2.json'; Target = 'walk_contact.json'; Image = 'walk_contact.png' },
    @{ Source = 'grove_scholar_walk_pass_v2.json'; Target = 'walk_pass.json'; Image = 'walk_pass.png' },
    @{ Source = 'grove_scholar_run_eight_v1.json'; Target = 'run_contact.json'; Image = 'run_contact.png' },
    @{ Source = 'grove_scholar_run_pass_v1.json'; Target = 'run_pass.json'; Image = 'run_pass.png' }
)

$sheetSize = 1254
$cleanupPath = Join-Path $targetRoot 'alpha_cleanup_report.json'
if (-not (Test-Path -LiteralPath $cleanupPath)) {
    throw "Missing alpha cleanup report: $cleanupPath"
}
$cleanup = Get-Content -LiteralPath $cleanupPath -Raw | ConvertFrom-Json
$cleanupBySheet = @{}
foreach ($sheet in $cleanup.sheets) {
    $cleanupBySheet[$sheet.sheet] = $sheet
}

foreach ($pair in $pairs) {
    $sourcePath = Join-Path $sourceRoot $pair.Source
    $targetPath = Join-Path $targetRoot $pair.Target
    $frames = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json
    $sheetCleanup = $cleanupBySheet[$pair.Image]
    if ($null -eq $sheetCleanup -or $sheetCleanup.cells.Count -ne $frames.Count) {
        throw "Cleanup metadata does not match $($pair.Image)"
    }

    for ($index = 0; $index -lt $frames.Count; $index++) {
        $frame = $frames[$index]
        $column = $index % 4
        $row = [math]::Floor($index / 4)
        $cellX = [math]::Floor($column * $sheetSize / 4)
        $cellY = [math]::Floor($row * $sheetSize / 4)
        $cellRight = [math]::Floor(($column + 1) * $sheetSize / 4)
        $cellBottom = [math]::Floor(($row + 1) * $sheetSize / 4)

        $absoluteTop = [double]$frame.region[1] + [double]$frame.top
        $absoluteFoot = [double]$frame.region[1] + [double]$frame.foot
        $absoluteRoot = [double]$frame.region[0] + [double]$frame.root_x

        $box = $sheetCleanup.cells[$index].kept_box
        $padding = 2
        $cropX = $cellX + [math]::Max(0, [int]$box[0] - $padding)
        $cropY = $cellY + [math]::Max(0, [int]$box[1] - $padding)
        $cropRight = $cellX + [math]::Min($cellRight - $cellX, [int]$box[2] + $padding)
        $cropBottom = $cellY + [math]::Min($cellBottom - $cellY, [int]$box[3] + $padding)

        $frame.region = @([int]$cropX, [int]$cropY, [int]($cropRight - $cropX), [int]($cropBottom - $cropY))
        $frame.top = [math]::Round($absoluteTop - $cropY, 2)
        $frame.foot = [math]::Round($absoluteFoot - $cropY, 2)
        $frame.root_x = [math]::Round($absoluteRoot - $cropX, 2)
    }

    $json = $frames | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $targetPath -Value ($json + "`n") -Encoding utf8
}

$manifest = [ordered]@{
    status = 'RESKIN_CANDIDATE_NOT_USER_ACCEPTED'
    motion_source = 'assets/hero/grove_scholar walk/run sheets and metadata'
    appearance_source = 'docs/design_refs/hero_turnaround_approved.png'
    deprecated_motion_source = 'art_review/hero_pose_v2 walk/run frames'
    frame_contract = [ordered]@{
        directions = 8
        walk_frames_per_direction = 4
        run_frames_per_direction = 4
        old_motion_geometry_preserved = $true
        regions_trimmed_to_cleaned_alpha = $true
    }
}
Set-Content -LiteralPath (Join-Path $targetRoot 'manifest.json') -Value (($manifest | ConvertTo-Json -Depth 8) + "`n") -Encoding utf8

Write-Output 'Generated walk_contact.json, walk_pass.json, run_contact.json, run_pass.json, and manifest.json.'
