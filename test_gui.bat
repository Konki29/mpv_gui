@echo off
setlocal

REM ============================================================================
REM  MPV Custom OSC - GUI Test Script
REM ============================================================================

set "SCRIPT_DIR=%~dp0"
set "MPV_EXE=%SCRIPT_DIR%..\mpv.exe"
set "TEST_VIDEO=%SCRIPT_DIR%..\chainsaw.mkv"

REM Find mpv.exe
if not exist "%MPV_EXE%" (
    where mpv >nul 2>&1
    if %errorlevel% equ 0 (
        set "MPV_EXE=mpv"
    ) else (
        echo [ERROR] mpv.exe not found.
        pause
        exit /b 1
    )
)

REM Check test video
if not exist "%TEST_VIDEO%" (
    echo [ERROR] chainsaw.mkv not found at %TEST_VIDEO%
    echo   Place a video file named chainsaw.mkv next to mpv.exe
    pause
    exit /b 1
)

echo.
echo ============================================
echo  MPV Custom OSC - Test
echo ============================================
echo  Config: %SCRIPT_DIR%
echo  Video:  %TEST_VIDEO%
echo.
echo  TEST CHECKLIST:
echo    1. Progress bar: hover and drag left/right
echo    2. Play/Pause: click center button
echo    3. Skip: click 5s forward/backward buttons
echo    4. CC button: click subtitle selector
echo    5. Auto-hide: wait 2s without moving mouse
echo    6. Time display: verify it updates during drag
echo.
echo  Press any key to launch mpv...
pause >nul

REM Use MPV_HOME to force config directory
set "MPV_HOME=%SCRIPT_DIR%"
"%MPV_EXE%" --force-window=yes "%TEST_VIDEO%"

echo.
echo  Test complete.
pause >nul
