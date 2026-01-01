# Flutter App (Source) — Khmer UI

⚠️ អ្នកមានតែ APK មិនអាចយក Source Code ពេញលេញចេញពី APK បានងាយៗទេ។ ដូច្នេះខ្ញុំបានធ្វើ **Flutter Source ថ្មី** ឲ្យអ្នក ដែលភ្ជាប់ទៅ Flask Backend តាម API token (`Authorization: Bearer <token>`).

## របៀបប្រើ (Android Phone)

### 1) បង្កើត Flutter Project ថ្មី
នៅលើ Mac/Windows:
```bash
flutter create school_app
```

### 2) Copy Source ពី Zip នេះទៅ project `school_app`
Copy/Replace:
- `lib/`
- `assets/`
- `pubspec.yaml`

(អាច copy ដូច command)
```bash
SRC=path/to/this/flutter_app
DST=path/to/school_app
rm -rf "$DST/lib" "$DST/assets"
cp -R "$SRC/lib" "$DST/lib"
cp -R "$SRC/assets" "$DST/assets"
cp "$SRC/pubspec.yaml" "$DST/pubspec.yaml"
```

### 3) ដំឡើង packages
```bash
cd school_app
flutter pub get
```

### 4) កំណត់ Backend URL
កែ `lib/config.dart`

- Backend នៅលើ **ទូរស័ព្ទដូចគ្នា (Termux)**:
  - `http://127.0.0.1:5001`
- Backend នៅលើ Laptop (Wi‑Fi IP):
  - `http://<IP-LAPTOP>:5001`

### 5) Run លើទូរស័ព្ទ (USB ដំបូង)
```bash
flutter devices
flutter run -d <deviceId>
```

### 6) Build APK Release ដើម្បីដំឡើង
```bash
flutter build apk --release
```
APK នៅ:
`build/app/outputs/flutter-apk/app-release.apk`

## Backend API (Flask)
App នេះប្រើ endpoints (សង្ខេប):
- POST `/api/login` -> {token, role}
- GET `/api/me`
- GET `/api/health`
- Admin:
  - `/api/admin/classes`
  - `/api/admin/teachers`
  - `/api/admin/students`
  - `/api/admin/terms`
  - `/api/admin/ranking`
- Teacher:
  - `/api/teacher/terms`
  - `/api/teacher/subjects`
  - `/api/teacher/students`
  - `/api/teacher/marks`
  - `/api/teacher/attendance`
  - `/api/teacher/ranking`
- Student:
  - `/api/student/terms`
  - `/api/student/overview`

✅ បើ UI “Loading” ជានិច្ច សូមពិនិត្យ:
- Backend URL ត្រឹមត្រូវ
- Backend រត់ (`python run.py --host 127.0.0.1 --port 5001`)
- Login បានទទួល token (App រក្សាទុក token ក្នុង SharedPreferences)

