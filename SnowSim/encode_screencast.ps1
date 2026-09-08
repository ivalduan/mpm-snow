<#
.SYNOPSIS
    Encode the SnowSim screencast PNG frames into a video (or GIF).

.DESCRIPTION
    The simulator writes frames as t_0000.png, t_0001.png, ... into SCREENCAST_DIR
    ("../screencast/" relative to the executable's working directory). This script
    stitches them together with ffmpeg.

    Playing back at FRAMERATE (60) reproduces simulated time at real speed.

.EXAMPLE
    .\encode_screencast.ps1
    Encodes ..\screencast\t_*.png into ..\screencast\snowsim.mp4 at 60 fps.

.EXAMPLE
    .\encode_screencast.ps1 -Fps 30 -Crf 20 -Force

.EXAMPLE
    .\encode_screencast.ps1 -Gif -Fps 30 -Output ..\screencast\snowsim.gif
#>
[CmdletBinding()]
param(
    # Directory containing the t_%04d.png frames.
    [string]$FramesDir = (Join-Path $PSScriptRoot '..\screencast'),

    # Output file. Extension is respected (.mp4, .mov, .mkv, .webm, .gif).
    [string]$Output,

    # Playback frame rate. 60 matches the sim's FRAMERATE constant.
    [int]$Fps = 60,

    # x264 quality: lower = better/larger. 18 is visually lossless-ish.
    [ValidateRange(0, 51)]
    [int]$Crf = 18,

    # x264 speed/efficiency tradeoff.
    [ValidateSet('ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow')]
    [string]$Preset = 'slow',

    # First frame index to start from (default 0).
    [int]$StartNumber = 0,

    # Emit an animated GIF instead of H.264, via a two-pass palette for quality.
    [switch]$Gif,

    # Overwrite the output file if it already exists.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# --- locate ffmpeg -----------------------------------------------------------
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Error @"
ffmpeg was not found on PATH. Install it, then re-run:
  winget install --id Gyan.FFmpeg -e
or grab a static build from https://www.gyan.dev/ffmpeg/builds/ and add its
bin\ folder to PATH (restart the shell afterwards).
"@
    exit 1
}

# --- validate frames -------------------------------------------------------
if (-not (Test-Path -LiteralPath $FramesDir -PathType Container)) {
    Write-Error "Frames directory not found: $FramesDir`nRun the simulator with screencast enabled first."
    exit 1
}
$FramesDir = (Resolve-Path -LiteralPath $FramesDir).Path

$frames = Get-ChildItem -LiteralPath $FramesDir -Filter 't_*.png' | Sort-Object Name
if ($frames.Count -eq 0) {
    Write-Error "No t_*.png frames in $FramesDir"
    exit 1
}
Write-Host ("Found {0} frames ({1} .. {2})" -f $frames.Count, $frames[0].Name, $frames[-1].Name)

# --- default output path -------------------------------------------------------
if (-not $Output) {
    $ext = if ($Gif) { 'gif' } else { 'mp4' }
    $Output = Join-Path $FramesDir "snowsim.$ext"
}
if ((Test-Path -LiteralPath $Output) -and -not $Force) {
    Write-Error "Output exists: $Output  (pass -Force to overwrite)"
    exit 1
}
$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$pattern = Join-Path $FramesDir 't_%04d.png'
$overwrite = if ($Force) { '-y' } else { '-n' }

# --- encode ------------------------------------------------------------------
if ($Gif) {
    $palette = Join-Path $env:TEMP ("snowsim_palette_{0}.png" -f ([guid]::NewGuid().ToString('N')))
    try {
        Write-Host "Pass 1/2: generating palette..."
        & ffmpeg -y -framerate $Fps -start_number $StartNumber -i $pattern `
            -vf "fps=$Fps,scale=trunc(iw/2)*2:-1:flags=lanczos,palettegen=stats_mode=diff" `
            $palette
        if ($LASTEXITCODE -ne 0) { throw "palettegen failed (exit $LASTEXITCODE)" }

        Write-Host "Pass 2/2: encoding GIF..."
        & ffmpeg $overwrite -framerate $Fps -start_number $StartNumber -i $pattern -i $palette `
            -lavfi "fps=$Fps,scale=trunc(iw/2)*2:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" `
            $Output
        if ($LASTEXITCODE -ne 0) { throw "GIF encode failed (exit $LASTEXITCODE)" }
    }
    finally {
        if (Test-Path -LiteralPath $palette) { Remove-Item -LiteralPath $palette -Force }
    }
}
else {
    & ffmpeg $overwrite -framerate $Fps -start_number $StartNumber -i $pattern `
        -c:v libx264 -preset $Preset -crf $Crf -pix_fmt yuv420p `
        -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" `
        -movflags +faststart `
        $Output
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ffmpeg failed (exit $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
}

$size = (Get-Item -LiteralPath $Output).Length
Write-Host ("Done: {0} ({1:N1} MB, {2} frames @ {3} fps)" -f $Output, ($size / 1MB), $frames.Count, $Fps)
