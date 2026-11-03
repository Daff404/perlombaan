# SHION Flutter 1.0.0+5

Gunakan bersama REST API 1.0.0 dari folder server pada ZIP ini. Panduan di MULAI_DI_SINI.md dan NOTIFIKASI_SERVER.md pada root ZIP.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

API default https://app.daffaputra.id/api. Kunci Gemini hanya di server/.env, tidak perlu private.json. Data akun/riwayat/chat di server; perangkat menyimpan token sesi Android melalui secure storage.

Notifikasi bersumber langsung dari REST API dan diperiksa berkala ketika aplikasi terbuka. Android menampilkan notifikasi lokal untuk kabar baru saat SHION aktif. Tidak menggunakan Firebase atau layanan push eksternal.

Paket belum melalui analyzer/build APK di lingkungan penyusunan. Jalankan validasi di atas pada Flutter Windows milikmu. Uji kamera dan notifikasi lokal di HP fisik.
