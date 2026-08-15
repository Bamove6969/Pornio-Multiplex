# Automated Build Script for Stremio Multiview
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Set MinGW GCC, Ninja, and Qt paths
$cleanPath = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.7.2\mingw_64\bin;C:\Program Files\CMake\bin;C:\Qt\Tools\Ninja;C:\Users\User\.cargo\bin;C:\Windows\System32"
[System.Environment]::SetEnvironmentVariable('PATH', $cleanPath, [System.EnvironmentVariableTarget]::Process)

$env:CC = "C:\Qt\Tools\mingw1310_64\bin\gcc.exe"
$env:CXX = "C:\Qt\Tools\mingw1310_64\bin\g++.exe"
$env:AR = "C:\Qt\Tools\mingw1310_64\bin\ar.exe"

Write-Host "=== 1/4: Building Rust Core Library ===" -ForegroundColor Cyan
& "C:\Users\User\.cargo\bin\cargo.exe" build --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Rust build failed."
}

Write-Host "=== 2/4: Configuring CMake Build ===" -ForegroundColor Cyan
if (!(Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}
Set-Location "build"

cmake .. -G "Ninja" `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_C_COMPILER="C:/Qt/Tools/mingw1310_64/bin/gcc.exe" `
    -DCMAKE_CXX_COMPILER="C:/Qt/Tools/mingw1310_64/bin/g++.exe" `
    -DCMAKE_PREFIX_PATH="C:/Qt/6.7.2/mingw_64"

if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed."
}

Write-Host "=== 3/4: Compiling Executable ===" -ForegroundColor Cyan
& "C:\Qt\Tools\Ninja\ninja.exe"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed."
}

Write-Host "=== 4/4: Deploying Runtime Dependencies & TLS Plugins ===" -ForegroundColor Cyan
& "C:\Qt\6.7.2\mingw_64\bin\windeployqt.exe" "$projectRoot\build\stremio-multiview.exe" --qmldir "$projectRoot\qml"
Copy-Item "C:\Qt\Tools\mingw1310_64\bin\libgcc_s_seh-1.dll", "C:\Qt\Tools\mingw1310_64\bin\libstdc++-6.dll", "C:\Qt\Tools\mingw1310_64\bin\libwinpthread-1.dll", "C:\Qt\Tools\mingw1310_64\bin\libatomic-1.dll" "$projectRoot\build\" -Force
Copy-Item "C:\Qt\6.7.2\mingw_64\plugins\tls" "$projectRoot\build\tls" -Recurse -Force
Copy-Item "C:\Qt\6.7.2\mingw_64\plugins\imageformats" "$projectRoot\build\imageformats" -Recurse -Force
Copy-Item "C:\Qt\6.7.2\mingw_64\plugins\networkinformation" "$projectRoot\build\networkinformation" -Recurse -Force
Copy-Item "$projectRoot\lib\libmpv-2.dll" "$projectRoot\build\mpv-2.dll" -Force
Copy-Item "$projectRoot\lib\libmpv-2.dll" "$projectRoot\build\libmpv-2.dll" -Force
Copy-Item "$projectRoot\target\release\stremio_multiview_core.dll" "$projectRoot\build\" -Force
Copy-Item "$projectRoot\qml\*" "$projectRoot\build\qml\" -Recurse -Force

Write-Host "`nAll Done! Launch with: .\build\stremio-multiview.exe" -ForegroundColor Green
