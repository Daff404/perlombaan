# SHION — Android lokal

Aplikasi Flutter yang menyimpan catatan pribadi di perangkat dengan `shared_preferences`. Tidak menggunakan layanan cloud, akun, server, atau konfigurasi eksternal.

## Build di Windows

Pastikan `flutter doctor` mengenali Android SDK dan lisensinya sudah diterima. Buka folder `shion` yang berisi `pubspec.yaml` di VS Code, lalu jalankan:

```powershell
.\build-apk.ps1
```

Skrip menyiapkan folder Android native jika belum ada, memasang dependency, menjalankan analisis dan tes, kemudian membuat APK. Hasilnya di `build\app\outputs\flutter-apk\app-release.apk`. Jika kebijakan eksekusi PowerShell memblokir skrip, jalankan `powershell -ExecutionPolicy Bypass -File .\build-apk.ps1` dari folder proyek.

## Status fitur

Beranda, foto kamera/galeri, kategorisasi sampah manual, panduan pemilahan, catatan rencana setoran, catatan aktivitas Eco-Tracker, dan profil tersedia secara lokal. Foto terpilih disalin ke direktori dokumen aplikasi, sementara metadata scan disimpan di preferensi perangkat. Data tidak disinkronkan atau dicadangkan. Penyimpanan lokal cocok untuk catatan pribadi, bukan untuk saldo keuangan atau otorisasi petugas.

Model TensorFlow Lite terlatih belum tersedia, sehingga tidak ada prediksi AI atau angka keyakinan palsu. Estimasi emisi bermotor/listrik belum disediakan tanpa faktor emisi bersumber. Green Point dan voucher mitra tidak dapat diterbitkan atau diverifikasi hanya dengan penyimpanan lokal. Rencana setoran tidak dikirim ke bank sampah. APK ini bukan implementasi penuh dari spesifikasi lama yang mensyaratkan integrasi pihak luar.

Jika `flutter analyze` atau `flutter test` gagal pada mesinmu, skrip berhenti tanpa membuat klaim build berhasil; kirim teks error lengkap agar dapat diperbaiki. APK belum dapat diuji di lingkungan pembuatan paket ini karena Flutter dan Android SDK tidak tersedia di sana.
