@echo off
setlocal

set PORTABLE_DIR=dist\SchoolApp_Portable

if not exist "dist\backend\school_backend.exe" (
  echo [ERROR] Backend EXE not found. Run windows_packaging\build_backend.bat first.
  exit /b 1
)

if not exist "dist\frontend" (
  echo [ERROR] Frontend not found. Run windows_packaging\build_frontend.bat first.
  exit /b 1
)

REM Optional seed database from backend_flask\instance\student_system.db
set SEED_DB=backend_flask\instance\student_system.db

REM Recreate portable folder
if exist "%PORTABLE_DIR%" rmdir /S /Q "%PORTABLE_DIR%"
mkdir "%PORTABLE_DIR%\backend"
mkdir "%PORTABLE_DIR%\frontend"
mkdir "%PORTABLE_DIR%\data"

copy /Y "dist\backend\school_backend.exe" "%PORTABLE_DIR%\backend\school_backend.exe" >nul
xcopy /E /I /Y "dist\frontend\*" "%PORTABLE_DIR%\frontend\"

REM Copy seeded DB if available
if exist "%SEED_DB%" (
  copy /Y "%SEED_DB%" "%PORTABLE_DIR%\data\student_system.db" >nul
) else (
  REM Create an empty placeholder folder; DB will be created on first run
)

REM Create launcher (assumes flutter exe name is flutter_app.exe)
(
echo @echo off
echo setlocal
echo cd /d "%%~dp0"
echo REM Point backend to writable DB file
echo set DB_PATH=%%CD%%\data\student_system.db
echo set DB_URL=sqlite:///%%DB_PATH:\=/%
echo set DATABASE_URL=%%DB_URL%%
echo start "" /min "%%~dp0backend\school_backend.exe"
echo timeout /t 2 ^>nul
echo start "" "%%~dp0frontend\flutter_app.exe"
echo endlocal
) > "%PORTABLE_DIR%\start.bat"

echo Done. Portable folder created at:
echo   %PORTABLE_DIR%
echo Run:
echo   %PORTABLE_DIR%\start.bat
endlocal
