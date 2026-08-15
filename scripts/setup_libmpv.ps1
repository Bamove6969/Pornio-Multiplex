# Download and setup prebuilt libmpv headers for Windows
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$libDir = Join-Path $projectRoot "lib"
$includeDir = Join-Path $libDir "include\mpv"

if (!(Test-Path $includeDir)) {
    New-Item -ItemType Directory -Force -Path $includeDir | Out-Null
}

Write-Host "=== Setting up libmpv development files for Windows ===" -ForegroundColor Cyan

# Official libmpv C headers from mpv-player repository
$clientHeaderUrl = "https://raw.githubusercontent.com/mpv-player/mpv/master/include/mpv/client.h"
$renderHeaderUrl = "https://raw.githubusercontent.com/mpv-player/mpv/master/include/mpv/render.h"
$renderGlHeaderUrl = "https://raw.githubusercontent.com/mpv-player/mpv/master/include/mpv/render_gl.h"

Write-Host "Downloading libmpv headers from GitHub..."
Invoke-WebRequest -Uri $clientHeaderUrl -OutFile (Join-Path $includeDir "client.h")
Invoke-WebRequest -Uri $renderHeaderUrl -OutFile (Join-Path $includeDir "render.h")
Invoke-WebRequest -Uri $renderGlHeaderUrl -OutFile (Join-Path $includeDir "render_gl.h")

Write-Host "Headers successfully saved to $includeDir" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Cyan
