@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM CorridorKey Deadline automation launcher
REM - Accepts an input path and optional config, OR config-only (with input_path/target_path inside config)
REM - Supports .json and key=value text config
REM - Runs wizard first, then non-interactive inference

set "SCRIPT_DIR=%~dp0"
set "ARG1=%~1"
set "ARG2=%~2"

set "TARGET_PATH="
set "CONFIG_FILE="

REM Detect invocation style
if "%ARG1%"=="" goto :no_args
for %%I in ("%ARG1%") do set "ARG1_EXT=%%~xI"
if /I "%ARG1_EXT%"==".json" (
    set "CONFIG_FILE=%ARG1%"
    set "TARGET_PATH=%ARG2%"
) else if /I "%ARG1_EXT%"==".txt" (
    set "CONFIG_FILE=%ARG1%"
    set "TARGET_PATH=%ARG2%"
) else (
    set "TARGET_PATH=%ARG1%"
    set "CONFIG_FILE=%ARG2%"
)

if "%CONFIG_FILE%"=="" set "CONFIG_FILE=%SCRIPT_DIR%CorridorKey_Deadline_Config.json"
if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found: "%CONFIG_FILE%"
    pause
    exit /b 1
)

REM Defaults (can be overridden by config)
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

for %%I in ("%CONFIG_FILE%") do set "CONFIG_EXT=%%~xI"
if /I "%CONFIG_EXT%"==".json" (
    for /f "usebackq delims=" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $c = Get-Content -Raw -Path '%CONFIG_FILE%' ^| ConvertFrom-Json; if($c.input_path){'TARGET_PATH=' + $c.input_path}; if($c.target_path){'TARGET_PATH=' + $c.target_path}; if($c.device){'DEVICE=' + $c.device}; if($c.backend){'BACKEND=' + $c.backend}; if($null -ne $c.linear){'LINEAR=' + $c.linear.ToString().ToLower()}; if($null -ne $c.despill){'DESPILL=' + $c.despill}; if($null -ne $c.despeckle){'DESPECKLE=' + $c.despeckle.ToString().ToLower()}; if($null -ne $c.despeckle_size){'DESPECKLE_SIZE=' + $c.despeckle_size}; if($null -ne $c.refiner){'REFINER=' + $c.refiner}; if($null -ne $c.skip_existing){'SKIP_EXISTING=' + $c.skip_existing.ToString().ToLower()}; if($null -ne $c.max_frames){'MAX_FRAMES=' + $c.max_frames}; if($null -ne $c.generate_comp){'GENERATE_COMP=' + $c.generate_comp.ToString().ToLower()}; if($null -ne $c.gpu_post){'GPU_POST=' + $c.gpu_post.ToString().ToLower()} } catch { Write-Error $_; exit 1 }"`) do (
        set "%%A"
    )
) else (
    for /f "usebackq tokens=1,* delims==" %%K in ("%CONFIG_FILE%") do (
        if /I "%%K"=="input_path" set "TARGET_PATH=%%L"
        if /I "%%K"=="target_path" set "TARGET_PATH=%%L"
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

if "%TARGET_PATH%"=="" goto :no_args

if exist "%TARGET_PATH%\" (
    set "FINAL_TARGET=%TARGET_PATH%"
) else if exist "%TARGET_PATH%" (
    for %%I in ("%TARGET_PATH%") do set "FINAL_TARGET=%%~dpI"
    if "!FINAL_TARGET:~-1!"=="\" set "FINAL_TARGET=!FINAL_TARGET:~0,-1!"
) else (
    echo [ERROR] Input path does not exist: "%TARGET_PATH%"
    exit /b 1
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
echo Input: "%FINAL_TARGET%"
echo Config: "%CONFIG_FILE%"

cd /d "%SCRIPT_DIR%"
uv run --extra cuda corridorkey --device %DEVICE% wizard "%FINAL_TARGET%"
if errorlevel 1 (
    echo [ERROR] Wizard stage failed.
    exit /b 1
)

uv run --extra cuda corridorkey --device %DEVICE% run-inference --backend %BACKEND% %MAX_FRAMES_FLAG% %SKIP_EXISTING_FLAG% %LINEAR_FLAG% --despill %DESPILL% %DESPECKLE_FLAG% --despeckle-size %DESPECKLE_SIZE% --refiner %REFINER% %COMP_FLAG% %GPU_POST_FLAG%
if errorlevel 1 (
    echo [ERROR] Inference stage failed.
    exit /b 1
)

echo Done.
exit /b 0

:no_args
echo [ERROR] Missing required input.
echo Usage:
echo   CorridorKey_Deadline_AutoRun.bat "D:\Shots\Shot010" "D:\cfg\corridorkey_deadline.json"
echo   CorridorKey_Deadline_AutoRun.bat "D:\cfg\corridorkey_deadline.json"
echo.
echo In config-only mode, set input_path or target_path in the config file.
pause
exit /b 1
