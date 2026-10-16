# SHION

SHION memakai struktur proyek Flutter dari arsip yang diberikan. Kerangka Android dan susunan foldernya dipertahankan; aplikasi demo bawaan diganti menjadi aplikasi SHION. Aplikasi ini tidak memakai Firebase.

## Build APK di Windows

1. Ekstrak ZIP lalu buka folder `shion` melalui **File → Open Folder** di VS Code.
2. Pastikan Flutter dan Android SDK sudah terpasang. Di terminal, `flutter doctor` harus menampilkan Android toolchain tanpa tanda silang.
3. Jalankan:

```powershell
.\build-apk.ps1
```

Jika PowerShell menolak menjalankan skrip:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-apk.ps1
```

APK release dibuat di `build\app\outputs\flutter-apk\app-release.apk`.

## Data dan fitur

Profil, riwayat scan, foto, rencana setoran, dan catatan aktivitas disimpan di perangkat. Scan menggunakan foto dan kategori yang dipilih manual; model AI belum dipasang. Rencana setoran bersifat pribadi dan tidak dikirim atau diverifikasi mitra. Green Point tetap nol karena transaksi dan verifikasi mitra tidak tersedia secara lokal. Eco-Tracker menyimpan jarak atau pemakaian listrik tanpa mengarang estimasi emisi.

Data lokal dapat hilang jika data aplikasi dihapus. `android/local.properties` sengaja tidak disertakan karena Flutter membuatnya untuk lokasi SDK pada komputer yang menjalankan build.
