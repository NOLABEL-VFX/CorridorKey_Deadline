@echo off
setlocal
TITLE CorridorKey + GVM + VideoMaMa Full Installer

echo ===================================================
echo   CorridorKey Full Windows Installer
echo   (Git + CorridorKey + GVM + VideoMaMa)
echo ===================================================
echo.

where git >nul 2>&1
if %errorlevel% equ 0 (
    echo [1/5] Git is already available on PATH. Skipping install.
) else (
    where winget >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] winget is not available on this system.
        echo Install App Installer from Microsoft Store, then run this script again.
        exit /b 1
    )

    echo [1/5] Installing Git via winget...
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        echo [ERROR] Git installation failed.
        exit /b 1
    )

    where git >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Git install completed but git is still not launchable in this shell.
        echo Close and reopen Command Prompt, then run this script again.
        exit /b 1
    )
)

echo.
echo [2/5] Running Install_CorridorKey_Windows.bat...
call :run_without_pause "Install_CorridorKey_Windows.bat"
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo [3/5] Running Install_GVM_Windows.bat...
call :run_without_pause "Install_GVM_Windows.bat"
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo [4/5] Running Install_VideoMaMa_Windows.bat...
call :run_without_pause "Install_VideoMaMa_Windows.bat"
if %errorlevel% neq 0 exit /b %errorlevel%


echo.
echo [5/5] Re-applying CUDA Python environment (uv sync --extra cuda)...
uv sync --extra cuda
if %errorlevel% neq 0 (
    echo [ERROR] Failed to apply CUDA Python environment.
    exit /b 1
)

echo.
echo ===================================================
echo   Full setup complete.
echo ===================================================
exit /b 0

:run_without_pause
set "script=%~1"
if not exist "%script%" (
    echo [ERROR] Could not find %script%
    exit /b 1
)

:: Feed extra newline input so trailing "pause" prompts do not block automation.
(
    echo.
    echo.
    echo.
    echo.
    echo.
) | call "%script%"
set "rc=%errorlevel%"
if not "%rc%"=="0" (
    echo [ERROR] %script% failed with exit code %rc%.
    exit /b %rc%
)
exit /b 0
