@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM CorridorKey Deadline automation launcher
REM - Accepts a target path (drag/drop clip folder or shot root)
REM - Accepts an optional config file (.json or key=value text)
REM - Preloads environment values and runs CorridorKey non-interactively

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%~2"
set "TARGET_PATH=%~1"

if "%TARGET_PATH%"=="" (
    echo [ERROR] No target path provided.
    echo Usage:
    echo   CorridorKey_Deadline_AutoRun.bat "D:\Shots\Shot010" "D:\cfg\corridorkey_deadline.json"
    echo   ^(You can also drag-drop a folder as the first argument.^)
    pause
    exit /b 1
)

if "%CONFIG_FILE%"=="" set "CONFIG_FILE=%SCRIPT_DIR%CorridorKey_Deadline_Config.json"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found: "%CONFIG_FILE%"
    pause
    exit /b 1
)

REM Defaults (used when config is missing a key)
set "DEVICE=auto"
set "BACKEND=auto"
set "LINEAR=false"
set "DESPILL=5"
set "DESPECKLE=true"
set "DESPECKLE_SIZE=400"
set "REFINER=1.0"
set "SKIP_EXISTING=true"
set "MAX_FRAMES="
set "GENERATE_COMP=true"
set "GPU_POST=false"

REM Parse JSON with PowerShell if extension is .json
for %%I in ("%CONFIG_FILE%") do set "CONFIG_EXT=%%~xI"
if /I "%CONFIG_EXT%"==".json" (
    for /f "usebackq delims=" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $c = Get-Content -Raw -Path '%CONFIG_FILE%' ^| ConvertFrom-Json; if($c.device){'DEVICE=' + $c.device}; if($c.backend){'BACKEND=' + $c.backend}; if($null -ne $c.linear){'LINEAR=' + $c.linear.ToString().ToLower()}; if($null -ne $c.despill){'DESPILL=' + $c.despill}; if($null -ne $c.despeckle){'DESPECKLE=' + $c.despeckle.ToString().ToLower()}; if($null -ne $c.despeckle_size){'DESPECKLE_SIZE=' + $c.despeckle_size}; if($null -ne $c.refiner){'REFINER=' + $c.refiner}; if($null -ne $c.skip_existing){'SKIP_EXISTING=' + $c.skip_existing.ToString().ToLower()}; if($null -ne $c.max_frames){'MAX_FRAMES=' + $c.max_frames}; if($null -ne $c.generate_comp){'GENERATE_COMP=' + $c.generate_comp.ToString().ToLower()}; if($null -ne $c.gpu_post){'GPU_POST=' + $c.gpu_post.ToString().ToLower()} } catch { Write-Error $_; exit 1 }"`) do (
        set "%%A"
    )
) else (
    REM key=value text file fallback
    for /f "usebackq tokens=1,* delims==" %%K in ("%CONFIG_FILE%") do (
        if /I "%%K"=="device" set "DEVICE=%%L"
        if /I "%%K"=="backend" set "BACKEND=%%L"
        if /I "%%K"=="linear" set "LINEAR=%%L"
        if /I "%%K"=="despill" set "DESPILL=%%L"
        if /I "%%K"=="despeckle" set "DESPECKLE=%%L"
        if /I "%%K"=="despeckle_size" set "DESPECKLE_SIZE=%%L"
        if /I "%%K"=="refiner" set "REFINER=%%L"
        if /I "%%K"=="skip_existing" set "SKIP_EXISTING=%%L"
        if /I "%%K"=="max_frames" set "MAX_FRAMES=%%L"
        if /I "%%K"=="generate_comp" set "GENERATE_COMP=%%L"
        if /I "%%K"=="gpu_post" set "GPU_POST=%%L"
    )
)

set "LINEAR_FLAG=--srgb"
if /I "%LINEAR%"=="true" set "LINEAR_FLAG=--linear"

set "DESPECKLE_FLAG=--no-despeckle"
if /I "%DESPECKLE%"=="true" set "DESPECKLE_FLAG=--despeckle"

set "SKIP_EXISTING_FLAG="
if /I "%SKIP_EXISTING%"=="true" set "SKIP_EXISTING_FLAG=--skip-existing"

set "COMP_FLAG=--no-comp"
if /I "%GENERATE_COMP%"=="true" set "COMP_FLAG=--comp"

set "GPU_POST_FLAG=--cpu-post"
if /I "%GPU_POST%"=="true" set "GPU_POST_FLAG=--gpu-post"

set "MAX_FRAMES_FLAG="
if not "%MAX_FRAMES%"=="" set "MAX_FRAMES_FLAG=--max-frames %MAX_FRAMES%"

echo [CorridorKey Deadline AutoRun]
echo Target: "%TARGET_PATH%"
echo Config: "%CONFIG_FILE%"

echo Running wizard organization pass...
cd /d "%SCRIPT_DIR%"
uv run --extra cuda corridorkey --device %DEVICE% wizard "%TARGET_PATH%"
if errorlevel 1 (
    echo [ERROR] Wizard stage failed.
    exit /b 1
)

echo Running non-interactive inference...
uv run --extra cuda corridorkey --device %DEVICE% run-inference --backend %BACKEND% %MAX_FRAMES_FLAG% %SKIP_EXISTING_FLAG% %LINEAR_FLAG% --despill %DESPILL% %DESPECKLE_FLAG% --despeckle-size %DESPECKLE_SIZE% --refiner %REFINER% %COMP_FLAG% %GPU_POST_FLAG%
if errorlevel 1 (
    echo [ERROR] Inference stage failed.
    exit /b 1
)

echo Done.
exit /b 0
