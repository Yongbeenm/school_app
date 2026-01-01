# School App — Windows one-set build kit (Backend + Frontend)

This kit helps you package:
- Flask backend -> Windows EXE (PyInstaller)
- Flutter desktop app -> Windows EXE (flutter build windows)
- One portable folder (start.bat runs both)
- Optional installer (Inno Setup)

## Prerequisites (on Windows)
1) Install Python 3.12.x (check "Add python to PATH")
2) Install Flutter SDK for Windows + enable windows desktop:
   - `flutter doctor`
   - `flutter config --enable-windows-desktop`
3) Install Visual Studio 2022 (Workloads):
   - **Desktop development with C++**
4) (Optional) Install Inno Setup 6 for building installer.

## Where to put this kit
Copy the whole `windows_packaging/` folder into the **root** of your project that contains:
- `backend_flask/`  (Flask backend)
- `flutter_app/`    (Flutter app)

Expected structure:
project_root/
  backend_flask/
  flutter_app/
  windows_packaging/

## 1) Build backend EXE
Open **PowerShell** in project_root and run:
  `windows_packaging\build_backend.bat`

Output:
  `dist\backend\school_backend.exe`

## 2) Build Flutter Windows app
Run:
  `windows_packaging\build_frontend.bat`

Output:
  `dist\frontend\<your_flutter_exe_and_dlls>`

## 3) Create portable one-set folder
Run:
  `windows_packaging\make_portable.bat`

Output:
  `dist\SchoolApp_Portable\`
  - start.bat (runs backend then opens app)

## 4) Optional: Build installer setup.exe
### One click (recommended)
Run:
  `windows_packaging\build_all_and_make_setup.bat`

This will build backend + frontend + portable folder + (if Inno Setup is installed) `dist\SchoolApp_Setup.exe`.

### Manual
If you prefer manual, install Inno Setup, then open:
  `windows_packaging\installer\SchoolApp.iss`
and click **Build**.

## Notes
- Backend is served on: http://127.0.0.1:5001
- Your Flutter app must use base URL: http://127.0.0.1:5001
- Portable DB file is stored inside:
    dist\SchoolApp_Portable\data\student_system.db
  (copied from `backend_flask\instance\student_system.db` when available).
- Installer default directory is `{localappdata}\School App` to avoid write permission issues.
