# SHION

Implementasi awal Android Flutter + Firebase. Ini kode proyek nyata, tanpa data mitra, prediksi AI, poin, atau voucher buatan. Belum merupakan aplikasi lengkap atau siap produksi.

## Menjalankan di VS Code

Prasyarat: Flutter stable yang mendukung Dart >=3.4, Android SDK, JDK sesuai Flutter, Node.js 22, Firebase CLI dan FlutterFire CLI.

```bash
cd shion
flutter create --platforms=android --org=id.shion.app .
flutter pub get
flutterfire configure
```

Perintah `flutter create` menghasilkan folder native Android yang belum tersedia dalam paket ini. Pertahankan kode `lib/` yang sudah ada. Ikuti keluaran FlutterFire untuk menghubungkan Firebase; `main.dart` menggunakan konfigurasi native default Android. Pastikan `android/app/google-services.json` dan plugin Google Services terpasang. Aktifkan Email/Password pada Firebase Authentication, lalu buat Firestore dan Storage.

Tambahkan izin `android.permission.INTERNET` pada AndroidManifest utama untuk build release. Sesuaikan minSdk dengan kebutuhan plugin. ImagePicker menggunakan aplikasi kamera Android dan pemilih foto sistem.

```bash
cd firebase/functions
npm install
npm test
npm run check
cd ../..
firebase use --add
firebase deploy --only firestore,storage,functions
flutter analyze
flutter test
flutter run
flutter build apk --release
```

## Konfigurasi data administrator

Semua transaksi saldo hanya ditulis Cloud Functions menggunakan Admin SDK. Aturan Firestore menolak penulisan transaksi dari klien. Kelola data katalog dengan skrip Admin SDK atau Firebase Console, bukan aplikasi klien.

- `recycling_banks/{id}`: `name`, `address`, `hours`, `active: true`, `categories: ['plastik','kertas']`, `staffUids: [uid]`.
- `point_rates/{category}`: `pointsPerKg` berupa angka positif. Kategori: plastik, kertas, organik.
- `rewards/{id}`: `title`, `category` (`transport`/`eco_product`), `cost` bilangan bulat positif, `stock` bilangan bulat, `active`, `partnerIntegrated`. Aktifkan integrasi hanya setelah pemenuhan reward mitra benar-benar tersedia.
- `emission_factors/{mode}`: `active`, `source` URL dokumen, `unit` (`km`/`kWh`), `kgCO2ePerUnit` angka >=0, `boundary` penjelasan cakupan. Mode: walk, bicycle, motorcycle, car, public, electricity. Isi dari sumber yang terverifikasi; tidak ada faktor bawaan yang dikarang. Faktor disalin ke catatan agar histori tetap konsisten.
- `articles/{id}`: `active`, `title`, `body`.
- Peran petugas/admin berasal dari custom claims Firebase Authentication yang hanya diberikan melalui Admin SDK. Jangan menaruh pengaturan peran pada dokumen pengguna.

`submitDeposit` menerima bankId/category/estimatedKg. `verifyDeposit` menerima depositId/actualKg dan hanya mengizinkan admin atau staff bank terkait. Poin dicatat sekali per ID setoran dalam transaksi Firestore. `redeemReward` menerima rewardId/requestId; pemanggil harus memakai ulang requestId yang sama saat mengulang permintaan akibat kegagalan jaringan. UI saat ini belum menyimpan kunci retry lintas restart, sehingga retry manual bisa membuat permintaan penukaran kedua yang sah. Reward berstatus Menunggu, tanpa voucher: pemenuhan/refund mitra belum diimplementasikan.

## Status jujur

Ditulis: tema dasar, masuk/daftar/lupa sandi/verifikasi email, lima tab, ringkasan saldo, daftar bank aktif, pengajuan setoran, riwayat, penukaran dengan konfirmasi, input dan riwayat estimasi karbon, artikel, profil/logout, kamera/galeri, backend transaksi dan aturan akses.

Belum selesai: desain final berdasarkan gambar referensi, proyek native Android, onboarding, Google Sign-In, state Riverpod/GoRouter, model & preprocessing TFLite, preview/simpan hasil scan, unggah foto, grafik/filter/tanggal Eco-Tracker, pengeditan profil, antarmuka petugas/admin, penolakan setoran, FCM/notifikasi, pemenuhan/refund reward mitra, App Check, emulator security tests, integrasi end-to-end dan APK. Dependensi Riverpod/GoRouter/TFLite disediakan untuk tahap lanjutan; belum semua dipakai.

Tanpa konfigurasi Firebase, aplikasi menampilkan pesan konfigurasi dan tidak mengaktifkan data palsu. AI belum menghasilkan prediksi. Tanpa mitra, daftar kosong. Tidak ada gamifikasi.

## Validasi saat paket dibuat

- `node --check firebase/functions/index.js`: lulus.
- `node --test firebase/functions/test/domain.test.js`: 4 tes lulus (kalkulasi poin, validasi jumlah, saldo/stok).
- Flutter/Dart/Android SDK tidak tersedia; analisis Dart, pengujian widget, emulator, build dan pengujian perangkat belum dijalankan.
- Tes unit domain belum membuktikan keamanan Rules maupun konkurensi Firestore; uji Emulator Suite wajib sebelum deploy nyata.
- URL referensi desain mengembalikan HTML, bukan gambar. Kirim `design/reference.jpg` sebelum finalisasi desain.

Lihat SPECIFICATION.md untuk kebutuhan lengkap yang masih menjadi acuan pengerjaan.
