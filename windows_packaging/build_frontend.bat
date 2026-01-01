@echo off
setlocal

REM ===== CONFIG =====
set FRONTEND_DIR=flutter_app

if not exist "%FRONTEND_DIR%\pubspec.yaml" (
  echo [ERROR] Cannot find %FRONTEND_DIR%\pubspec.yaml. Make sure you placed this kit in project root.
  exit /b 1
)

echo [1/3] Flutter pub get...
cd /d "%FRONTEND_DIR%"
call flutter pub get

echo [2/3] Build Windows release...
call flutter config --enable-windows-desktop
call flutter build windows --release

echo [3/3] Copy output to dist...
cd /d ".."
if not exist "dist\frontend" mkdir "dist\frontend"
xcopy /E /I /Y "%FRONTEND_DIR%\build\windows\x64\runner\Release\*" "dist\frontend\"

echo Done. Frontend in dist\frontend\
endlocal
