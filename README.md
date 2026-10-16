# SHION

Aplikasi lingkungan berbasis Flutter untuk Android. Seluruh project berada dalam satu folder ini. Tanpa Firebase; profil, setoran, poin, voucher, riwayat scan dan aktivitas tersimpan lokal.

## Perubahan terbaru

- Navbar mengambang hijau, empat menu dan tombol scan besar di tengah mengikuti referensi.
- Skeleton loading saat membuka halaman; penanganan operasi jaringan tetap mengikuti status permintaan sebenarnya.
- Setiap halaman berada di file sendiri dalam lib/features/. Dashboard, onboarding, edukasi, profil dan riwayat menggunakan Dart parts untuk berbagi state shell; halaman scanner, poin, reward, setoran, karbon dan lokasi adalah widget terpisah. main.dart hanya berisi entry point, tema dan daftar parts; app_shell.dart mengelola navigasi.
- Warna/latar per halaman berbeda; tema hutan SHION tetap konsisten.
- Nama yang tampil ke pengguna adalah AI Detector. Pengaturan penyedia AI di UI dihapus. Konfigurasi teknis tetap di file settings.
- Frame kamera Android dikirim ke ML Kit melalui MethodChannel, maksimum sekitar 3 frame/detik dan satu proses aktif. Kotak digambar berdasarkan koordinat hasil deteksi sebenarnya; tidak ada kotak objek buatan. Format YUV420 dikonversi ke NV21 dengan memperhatikan stride setiap plane, orientasi sensor dan rotasi layar.
- ML Kit mendeteksi lokasi objek, bukan jenis sampah spesifik. Setelah foto diambil, AI Detector menganalisis jenis, material, kategori, dan panduan penanganan melalui Gemini API.
- Beranda memakai dua carousel foto bertema alam yang berpindah otomatis dan dapat digeser manual. Logo daun SHION pada splash awal dianimasikan saat aplikasi dibuka.
- Setor plastik 50 poin/kg, kertas 30 poin/kg, organik 20 poin/kg. Poin dan kuitansi setoran disimpan dalam satu transaksi lokal.
- Katalog reward transportasi, tumbler dan produk hijau. Penukaran memotong saldo dan menyimpan kode voucher; saldo tidak boleh negatif. Semua voucher adalah kode lokal, tanpa penyedia penukaran eksternal. Fitur setoran/reward merupakan simulasi untuk presentasi lomba, tanpa label simulasi di UI sesuai permintaan; bukan verifikasi bank sampah atau diskon yang dapat ditagihkan ke operator sungguhan.
- Jejak karbon harian menghitung jumlah aktivitas dikalikan faktor emisi yang dapat diubah pengguna. Faktor awal adalah asumsi, bukan faktor resmi terverifikasi; UI menyebut estimasi. Data lama tanpa faktor tidak dianggap memiliki emisi terukur.
- Profil > Console Sistem menampilkan log teknis, salin log dan bersihkan log. Pesan umum ditampilkan di UI; detail HTTP masuk console. Pola kunci API disamarkan. Log berada di memori, maksimum 200 baris; jangan tambahkan pencatatan foto atau header autentikasi.

## Jalankan di Windows

Buka folder ini di VS Code. Isi settings/private.json dengan API key pribadi dan model yang tersedia pada akun Anda:

```json
{
  "GEMINI_API_KEY": "ISI_KEY_ANDA",
  "GEMINI_MODEL": "gemini-3.5-flash-lite"
}
```

Key dalam paket sengaja kosong. Jangan unggah private.json ke GitHub atau mengirim key melalui chat. Key disertakan dalam build pribadi sehingga dapat diekstrak dari APK; distribusi publik dengan kunci bersama memerlukan proxy/backend dengan pembatasan akses.

Jalankan:

```powershell
flutter pub get
flutter run --dart-define-from-file=settings/private.json
```

Pilih perangkat Android di VS Code. Native object detection hanya tersedia di Android, tidak tersedia pada preview Chrome atau Windows desktop. Preview Chrome masih bisa digunakan untuk UI dan analisis foto lewat Gemini API, tetapi bukan untuk memvalidasi kotak deteksi ML Kit. Karena itu, layar scanner menampilkan keterangan platform saat berjalan di Chrome.

Build dengan Java 25.0.3 yang sudah Anda miliki:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Java25.ps1
```

Atau jika SDK/JDK sudah benar:

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=settings/private.json
```

APK target: build/app/outputs/flutter-apk/app-release.apk. Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0; Java tidak diturunkan. Panduan SDK/lisensi ada di JAVA25.md. ML Kit ditambahkan sebagai library Android com.google.mlkit:object-detection:17.0.2; tidak memerlukan akun/config Firebase. Model perangkat memerlukan unduhan awal dan layanan Google yang sesuai.

## Lokasi dan data

Peta memakai OpenStreetMap; pencarian kota Nominatim dan titik tempat setor Overpass. Titik tersebut merupakan catatan komunitas, tidak otomatis mitra resmi SHION. Ketersediaan data/jaringan menentukan hasil; hasil kosong tetap kosong. Rute dibuka di aplikasi peta eksternal.

Data aplikasi disimpan lokal. Menghapus data aplikasi menghapus riwayat, poin dan voucher. Poin lokal bukan saldo uang. Aset gambar/logo/ikon asli tersimpan di assets, bersama tiga keluarga font dan lisensi. Lihat ASSETS.md.

## Status verifikasi

Semua file Dart terbaru berhasil diparse oleh dart format. XML/JSON dan isi ZIP diperiksa. Harness Dart untuk LocalStore dengan adapter preferences dalam memori berhasil menjalankan tujuh pemeriksaan: kredit setoran, penukaran bersamaan, penyimpanan voucher, pembuatan ulang store, penolakan berat negatif, tidak ada perubahan data saat input salah, dan hitungan poin kertas. Ini tidak menguji plugin penyimpanan perangkat. Tes Flutter untuk transaksi dan redaksi log juga disertakan, tetapi belum dijalankan. Flutter analyze, flutter test, dan APK release belum berhasil dijalankan pada lingkungan pembuat paket: Flutter tool belum dapat mengambil dependensinya, tidak tersedia Android SDK, dan Java lokal bukan Java 25. Camera stream, rotasi kotak, unduhan model ML Kit dan analisis foto harus diuji pada perangkat Android. Jangan menyebut APK telah sukses dibangun sebelum perintah build nyata selesai.

Sumber implementasi object detection: https://developers.google.com/ml-kit/vision/object-detection/android
