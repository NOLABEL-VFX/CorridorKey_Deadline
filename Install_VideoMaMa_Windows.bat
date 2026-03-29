@echo off
TITLE VideoMaMa Setup Wizard
echo ===================================================
echo   VideoMaMa (AlphaHint Generator) - Auto-Installer
echo ===================================================
echo.

:: Make sure uv is available in this shell session.
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
where uv >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] uv is required but was not found on PATH.
    echo Please run Install_CorridorKey_Windows.bat, then reopen Command Prompt and retry.
    pause
    exit /b 1
)

:: Check that uv sync has been run (the .venv directory should exist)
if not exist ".venv" (
    echo [ERROR] Project environment not found.
    echo Please run Install_CorridorKey_Windows.bat first!
    pause
    exit /b
)

:: 1. Download Weights (all Python deps are already installed by uv sync)
echo [1/1] Downloading VideoMaMa Model Weights...
if not exist "VideoMaMaInferenceModule\checkpoints" mkdir "VideoMaMaInferenceModule\checkpoints"

echo Downloading VideoMaMa weights from HuggingFace...
uv run hf download SammyLim/VideoMaMa --local-dir VideoMaMaInferenceModule\checkpoints

echo.
echo ===================================================
echo   VideoMaMa Setup Complete!
echo ===================================================
pause
