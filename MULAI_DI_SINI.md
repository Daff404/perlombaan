# Mulai di sini — SHION

Paket berisi aplikasi Flutter `shion/` dan server Node.js `server/` sebagai folder terpisah.

## Server

1. Gunakan Node.js 22.9 atau lebih baru.
2. Dari folder `server/`, salin `.env.example` menjadi `.env` dan isi konfigurasi yang diperlukan.
3. Jalankan `npm ci`, `npm test`, lalu `npm start`. Jalankan satu instance server dan arahkan reverse proxy HTTPS ke port 3000.
4. Data akun berada di `database/account.json`. Data sesi, chat, media, dan aktivitas pengguna tersimpan terpisah dalam `session/<username>/`; folder `session/` dibuat otomatis saat server mulai.

Tidak ada bootstrap atau `create-admin.js`. Jangan menimpa `database/account.json` pada server yang sudah dipakai karena file itu berisi akun terdaftar. Backup `database/`, `session/`, dan `.env` sebelum memperbarui.

## Aplikasi Android

Dari folder `shion/`, jalankan di PowerShell:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

URL server bawaan dapat diubah di `shion/settings/api.json`. APK release berada di `shion/build/app/outputs/flutter-apk/app-release.apk`.
