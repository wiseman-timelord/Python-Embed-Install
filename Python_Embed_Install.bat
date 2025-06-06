:: Script: `.\Python_Embed_Install.bat`

:: Initialization
@echo off
setlocal enabledelayedexpansion

:: DP0 TO SCRIPT BLOCK
set "ScriptDirectory=%~dp0"
set "ScriptDirectory=%ScriptDirectory:~0,-1%"
cd /d "%ScriptDirectory%"
echo Dp0'd to Script.

:: Python 3.9 Embedded Enhancement Installer
:: Must be run from: C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python39
:: Requires: PowerShell 3+ and Admin privileges

echo.
echo Python 3.9 Embedded Enhancement Installer
echo ========================================
echo.

:: 1. Verify correct directory location
set "EXPECTED_DIR=%USERPROFILE%\AppData\Local\Programs\Python\Python39"
set "CURRENT_DIR=%CD%"

:: Normalize paths for case-insensitive comparison
if /i not "%CURRENT_DIR%" == "%EXPECTED_DIR%" (
    echo ERROR: Incorrect directory!
    echo.
    echo This must be run from:
    echo   %EXPECTED_DIR%
    echo.
    echo Current location:
    echo   %CURRENT_DIR%
    echo.
    echo Please move this batch file to the correct directory.
    echo.
    pause
    exit /b 1
)

:: 2. Verify admin privileges
NET SESSION >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Administrator privileges required
    echo.
    echo Please right-click this file and select:
    echo "Run as administrator"
    echo.
    echo If you already ran as admin, try:
    echo 1. Press Win+X
    echo 2. Select "Command Prompt (Admin)"
    echo 3. Navigate to: %EXPECTED_DIR%
    echo 4. Run: Python_Embed_Install.bat
    echo.
    pause
    exit /b 1
)

:: 3. Verify PowerShell version (Windows 8 should have v3+)
echo Checking PowerShell version...
powershell -Command "$ver = $PSVersionTable.PSVersion.Major; if ($ver -lt 3) { exit 1 } else { Write-Host 'Found PowerShell v'+$ver; exit 0 }"
if %errorlevel% equ 1 (
    echo.
    echo ERROR: Requires PowerShell version 3 or newer
    echo.
    echo Windows 8 should include PowerShell 3 by default.
    echo If you see this error, please:
    echo 1. Press Win+X, select "Command Prompt (Admin)"
    echo 2. Run: dism /online /enable-feature /featurename:MicrosoftWindowsPowerShellV3
    echo 3. Reboot and try again
    echo.
    pause
    exit /b 1
)

:: 4. Verify installer.ps1 exists
if not exist "installer.ps1" (
    echo ERROR: installer.ps1 not found in current directory
    echo Please ensure both files are in:
    echo %EXPECTED_DIR%
    echo.
    pause
    exit /b 1
)

:: 5. Verify python.exe exists
if not exist "python.exe" (
    echo ERROR: python.exe not found in current directory
    echo This indicates an incomplete Python installation
    echo.
    pause
    exit /b 1
)

:: All checks passed - run installer
echo.
echo System Check Complete - All Requirements Met
echo ===========================================
echo Running Python enhancement...
echo.

:: Capture PowerShell exit code properly
set "psExitCode=0"
powershell -ExecutionPolicy Bypass -NoProfile -File "installer.ps1"
set "psExitCode=!errorlevel!"

:: Check exit status
if !psExitCode! neq 0 (
    echo.
    echo INSTALLATION COMPLETED WITH ERRORS (Code: !psExitCode!)
    echo Check the log files in this directory:
    echo   pip-install.log
    echo   pip-install-errors.log
) else (
    echo.
    echo =============================
    echo ENHANCEMENT COMPLETED SUCCESSFULLY!
    echo.
    echo Test with:
    echo   python -m pip --version
    echo   python -c "import site; print(site.getsitepackages())"
)

echo.
echo Script execution finished. Press any key to exit...
pause >nul