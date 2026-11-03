# Patch Java 25.0.3 untuk Flutter 3.47.7

Konfigurasi Java 25 sudah diterapkan langsung pada folder android project SHION ini. Untuk membangun project ini, jalankan Build-Java25.ps1 dari folder yang sama dengan pubspec.yaml. Apply-Java25.ps1 hanya diperlukan jika ingin menerapkan perbaikan ke checkout lama di lokasi lain; skrip tersebut membuat backup.

Versi: Gradle 9.3.1, AGP 9.1.0, Kotlin Gradle Plugin 2.4.0. Ketiganya sama dengan konstanta template SDK Flutter 3.47.7 yang diperiksa. Gradle mendukung Java 25 sejak 9.1.0; AGP 9.1 memerlukan Gradle 9.3.1. Java runtime tetap 25.0.3, sementara target bytecode aplikasi tetap Java 11. Legacy Kotlin/Android DSL dipertahankan memakai android.builtInKotlin=false dan android.newDsl=false.

File konfigurasi aktif ada di folder android/. android/build.gradle.kts tidak memerlukan perubahan. Tidak ada perubahan package name, UI, dependency pubspec, signing, versi SDK, atau NDK dalam patch build ini. Apply-Java25.ps1 mempertahankan pengaturan asli tersebut di PC Anda.

Ekstrak ZIP, kemudian buka PowerShell di folder shion yang berisi pubspec.yaml. Untuk project ini cukup jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Java25.ps1
```

Opsional, hanya untuk memperbaiki checkout lama di lokasi lain:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Apply-Java25.ps1 -ProjectPath 'C:\Users\daffa\StudioProjects\perlombaan'
```

ExecutionPolicy Bypass berlaku untuk proses ini saja. Skrip build memakai instalasi Java 25.0.3 yang sudah aktif, mengarahkan Flutter ke JDK itu, memeriksa SDK/cmdline-tools dan meminta persetujuan lisensi lewat prompt resmi. Skrip lalu menjalankan flutter clean, flutter pub get, dan flutter build apk --release. Bila settings/api.json tersedia, alamat API publik dibaca lewat dart-define-from-file. Kunci Gemini hanya ditempatkan pada server. Skrip berhenti saat suatu perintah gagal dan baru melaporkan sukses bila APK tersedia.

## Android SDK dan jaringan

SDK yang diharapkan: C:\Users\daffa\AppData\Local\Android\sdk. cmdline-tools yang diperlukan: cmdline-tools/latest/bin/sdkmanager.bat. Bila belum ada, pasang Android SDK Command-line Tools (latest) melalui Android Studio > SDK Manager > SDK Tools. Android Studio dipakai mengelola SDK; Anda tetap bisa mengedit/build di VS Code.

Flutter 3.47.7 menggunakan compile SDK 36. AGP 9.1 memerlukan Build Tools 36.0.0. Base ini menetapkan NDK 29.0.14206865 dan patch mempertahankannya. Pasang paket yang belum tersedia melalui SDK Manager, atau jalankan setelah cmdline-tools tersedia:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;29.0.14206865"
flutter doctor --android-licenses
```

Jika muncul Temporary failure in name resolution, Could not GET, atau timeout untuk plugins.gradle.org, repo.maven.apache.org, dl.google.com, atau services.gradle.org, unduhan build sedang gagal karena jaringan/DNS. Mengganti dependency aplikasi tidak menyelesaikan masalah jaringan itu. Pastikan akses domain berhasil lalu ulangi build; jangan menghapus cache yang sudah berhasil diunduh.

## Status verifikasi

Build APK pada revisi ini belum diverifikasi. Proses penyiapan Flutter di lingkungan pembuat paket ditolak pemeriksaan otomatis karena mencoba mengakses metadata cloud. Jalankan build pada PC Anda mengikuti README.md. Backend telah diuji terpisah; rincian pemeriksaan ada pada VALIDATION.md di akar paket.

Sumber:
- https://docs.gradle.org/9.1.0/release-notes.html
- https://developer.android.com/build/releases/agp-9-1-0-release-notes
- https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin
- Flutter 3.47.7: packages/flutter_tools/lib/src/android/gradle_utils.dart
