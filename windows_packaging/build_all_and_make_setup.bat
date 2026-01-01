@echo off
setlocal

REM Build everything (backend EXE + frontend Windows + portable folder + installer)
REM Run this from PROJECT ROOT (the folder that contains backend_flask/ and flutter_app/)

echo ==============================================
echo  School App - One Click Windows Build (x64)
echo ==============================================
echo.

REM 1) Backend
call "%~dp0build_backend.bat"
if errorlevel 1 exit /b 1

echo.
REM 2) Frontend
call "%~dp0build_frontend.bat"
if errorlevel 1 exit /b 1

echo.
REM 3) Portable folder
call "%~dp0make_portable.bat"
if errorlevel 1 exit /b 1

echo.
REM 4) Installer (requires Inno Setup)
set ISCC=

REM Try ISCC in PATH
where ISCC.exe >nul 2>nul
if %errorlevel%==0 (
  for /f "delims=" %%i in ('where ISCC.exe') do set ISCC=%%i
)

REM Common install locations
if "%ISCC%"=="" if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if "%ISCC%"=="" if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set ISCC=C:\Program Files\Inno Setup 6\ISCC.exe

if "%ISCC%"=="" (
  echo [WARN] Inno Setup not found. Installer was NOT created.
  echo        Install Inno Setup 6, then re-run this script.
  echo        You can still share: dist\SchoolApp_Portable\ (or zip it)
  echo.
  echo Done.
  exit /b 0
)

echo [4/4] Building installer with Inno Setup...
"%ISCC%" "%~dp0installer\SchoolApp.iss"
if errorlevel 1 exit /b 1

echo.
echo Done! Output files:
echo   - dist\SchoolApp_Portable\start.bat
if exist "dist\SchoolApp_Setup.exe" echo   - dist\SchoolApp_Setup.exe
endlocal
