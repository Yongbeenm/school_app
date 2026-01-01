@echo off
setlocal enabledelayedexpansion

REM ===== CONFIG =====
set BACKEND_DIR=backend_flask
set OUT_DIR=dist\backend
set EXE_NAME=school_backend

if not exist "%BACKEND_DIR%\run.py" (
  echo [ERROR] Cannot find %BACKEND_DIR%\run.py. Make sure you placed this kit in project root.
  exit /b 1
)

REM Use python launcher if available
where py >nul 2>nul
if %errorlevel%==0 (
  set PY=py -3
) else (
  set PY=python
)

echo [1/4] Install backend dependencies...
cd /d "%BACKEND_DIR%"
%PY% -m pip install -r requirements.txt
%PY% -m pip install waitress pyinstaller

echo [2/4] Prepare production entrypoint...
copy /Y "..\windows_packaging\backend_templates\run_prod.py" run_prod.py >nul

echo [3/4] Build backend EXE with PyInstaller...
%PY% -m PyInstaller --noconfirm --clean --onefile --name %EXE_NAME% ^
  --add-data "app;app" ^
  run_prod.py

cd /d ".."
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
copy /Y "%BACKEND_DIR%\dist\%EXE_NAME%.exe" "%OUT_DIR%\%EXE_NAME%.exe" >nul

echo [4/4] Done. Backend EXE: %OUT_DIR%\%EXE_NAME%.exe
endlocal
