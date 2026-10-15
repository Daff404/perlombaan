# SHION — Platform Cerdas Pengelolaan Limbah Rumah Tangga

> **Technology in Harmony with Nature**

## Filosofi Brand

> “SHION adalah pilar kesadaran dan kompas menuju kehidupan yang selaras. Ia menghubungkan kecerdasan teknologi dengan komitmen abadi manusia untuk tidak melupakan dan merawat Buminya.”

SHION adalah aplikasi Android yang membantu pengguna mengelola sampah rumah tangga dengan **AI Image Scanner**, **Green Point & Reward**, dan **Eco-Tracker**. Aplikasi memberikan edukasi pemilahan dan daur ulang sampah, memfasilitasi penyetoran ke bank sampah mitra, dan memperkirakan jejak karbon harian berdasarkan kebiasaan konsumsi serta transportasi.

## Tujuan Pengembangan

Bangun aplikasi Android yang benar-benar dapat dijalankan, bukan hanya mockup atau prototipe statis. Semua antarmuka menggunakan **bahasa Indonesia**. Gunakan identitas visual SHION yang original, elegan, dan mudah digunakan.

## Batasan Ruang Lingkup

Tiga fitur inti **wajib**:

1. **AI Image Scanner** — Foto sampah plastik, kertas, atau organik; deteksi dengan TensorFlow Lite secara *on-device*; tampilkan kategori, keyakinan prediksi, dan panduan pemilahan/daur ulang.
2. **Green Point & Reward** — Poin diberikan **hanya setelah** penyetoran sampah ke bank sampah mitra diverifikasi. Poin dapat ditukar dengan diskon transportasi umum atau produk ramah lingkungan jika tersedia mitra yang benar-benar mendukungnya.
3. **Eco-Tracker** — Catat kebiasaan konsumsi dan transportasi; hitung estimasi emisi harian dalam kg CO₂e; tampilkan grafik dan riwayat.

Halaman autentikasi, dashboard, bank sampah, edukasi, riwayat, notifikasi, dan profil adalah **fitur pendukung** bagi tiga fitur inti.

**Tidak menggunakan gamifikasi tambahan:** tidak ada XP, level, badge, achievement, leaderboard, streak, misi, atau tantangan harian. Green Point tetap digunakan sebagai saldo transaksi untuk penukaran reward, **bukan** XP atau peringkat.

## Teknologi

| Lapisan | Teknologi |
|---|---|
| Frontend Android | Flutter + Dart |
| UI, state, navigasi | Material 3 (kustom), Riverpod, GoRouter |
| Animasi dan tipografi | Flutter Animate, Google Fonts |
| Backend | Firebase |
| Login | Firebase Authentication |
| Database | Cloud Firestore |
| Penyimpanan gambar | Firebase Cloud Storage |
| Logika transaksi | Firebase Cloud Functions |
| Notifikasi | Firebase Cloud Messaging |
| AI lokal | TensorFlow Lite |
| Native Android | Kotlin, hanya jika diperlukan |

Jangan menambahkan Node.js/NestJS/PostgreSQL sebagai backend aplikasi terpisah. Cloud Functions dapat menggunakan runtime yang didukung Firebase untuk logika server yang diperlukan.

## Referensi Desain

- Referensi visual: https://i.top4top.io/p_3940kdle21.jpg
- Referensi lokal yang disarankan: `design/reference.jpg`

Pelajari referensi sebelum implementasi. Jika URL tidak dapat dibuka, gunakan file lokal; jika keduanya tidak tersedia, minta referensinya. **Jangan menyalin** logo, ilustrasi, ikon, atau layout secara identik. Kembangkan identitas SHION sendiri.

### Arah UI/UX

- **Gaya:** Eco-Futurism, Organic Minimalism, glassmorphism terbatas, editorial premium.
- **Palet:** Midnight Forest `#071B16`, Deep Evergreen `#102D25`, Botanical Green `#205342`, Sage `#A9C8A1`, Soft Lime `#DDF4B5`, Warm Ivory `#F7F5EB`.
- **Font:** Plus Jakarta Sans, DM Sans, Cormorant Garamond untuk judul dekoratif.
- **Prinsip:** navigasi jelas, kontras terbaca, komponen konsisten, responsif, animasi halus, gambar teroptimasi, dan scroll ringan.
- **Logo:** wordmark SHION dengan simbol original yang menyatukan alam, teknologi, kesadaran, dan kompas; cocok untuk ikon Android.

## Halaman dan Alur

### 1. Splash Screen

Tampilkan logo SHION, latar hijau hutan, animasi lembut, dan tagline **Technology in Harmony with Nature**. Lanjutkan berdasarkan status onboarding dan autentikasi.

### 2. Onboarding (3 halaman)

1. **Kenali Sampahmu dengan AI** — Foto sampah dan dapatkan panduan pemilahan.
2. **Ubah Sampah Menjadi Manfaat** — Setor sampah, dapatkan Green Point, dan tukarkan reward.
3. **Kenali Dampak Aktivitasmu** — Pantau estimasi jejak karbon konsumsi dan transportasi.

Sediakan swipe, indikator progres, Lewati, Lanjut, dan Mulai Sekarang.

### 3. Autentikasi

Registrasi, login email/password, Google Sign-In, lupa password, verifikasi email, sesi tersimpan, dan logout melalui Firebase Authentication. Validasi input dan tampilkan pesan kesalahan yang jelas. Jangan simpan password di Firestore.

### 4. Dashboard

- Sapaan berdasarkan waktu, nama pengguna, avatar, dan notifikasi.
- Hero **“Langkah Kecil, Dampak Besar.”** dengan tombol **Mulai Scan**.
- Saldo Green Point, poin masuk, dan poin terpakai.
- Akses cepat: Scan Sampah, Setor Sampah, Tukar Poin, Eco-Tracker.
- Ringkasan jumlah scan, berat sampah terverifikasi, dan estimasi jejak karbon hari ini.
- Tips edukasi daur ulang singkat.

### 5. AI Image Scanner

- Kamera langsung, tombol foto, galeri, bingkai scan, flash bila tersedia, izin kamera, dan loading.
- Klasifikasi **plastik, kertas, organik** dengan TensorFlow Lite di perangkat.
- Proses gambar sesuai spesifikasi model (orientasi, ukuran, normalisasi, label), lalu tampilkan kategori dan skor keyakinan.
- Jika skor rendah, beri pilihan koreksi manual.
- **Dilarang membuat prediksi AI acak atau palsu.** Jika model terlatih belum tersedia, siapkan integrasi dan tampilkan status belum dikonfigurasi.

### 6. Hasil Scan dan Panduan Daur Ulang

Tampilkan foto, kategori, skor keyakinan, deskripsi material, langkah pemilahan, dan panduan daur ulang. Sediakan **Simpan Riwayat**, **Cari Bank Sampah**, dan **Scan Lagi**. Panduan khusus plastik, kertas, dan organik harus akurat dan mudah diterapkan.

### 7. Bank Sampah dan Penyetoran

- Daftar dan pencarian bank sampah mitra, alamat, jam operasional, jenis sampah diterima, dan detail layanan.
- Peta boleh menggunakan Google Maps bila sudah dikonfigurasi; daftar harus tetap berguna tanpa peta.
- Alur: pilih bank sampah → pilih kategori → isi estimasi berat → ajukan setoran → terima kode transaksi → petugas memverifikasi berat aktual → backend menghitung poin → pengguna menerima notifikasi.
- Status: **Menunggu, Diproses, Diverifikasi, Selesai, Ditolak**.
- Jangan mengarang bank sampah atau mengklaim kemitraan yang belum ada.

### 8. Green Point

Tampilkan saldo, total poin masuk, total poin keluar, dan riwayat transaksi. Nilai poin dihitung dari kategori dan **berat aktual terverifikasi**, sesuai aturan administrator. Gunakan Cloud Functions dan transaksi Firestore agar pengguna tidak dapat mengubah saldo, mengklaim poin dua kali, atau menghasilkan saldo negatif.

### 9. Reward Marketplace

- Hanya dua kategori inti: **potongan harga transportasi umum** dan **produk ramah lingkungan**.
- Kartu reward: gambar, judul, deskripsi, kebutuhan poin, stok/ketersediaan, tombol Tukarkan.
- Alur: pilih reward → periksa saldo dan ketersediaan → konfirmasi → transaksi atomik di backend → simpan riwayat → tampilkan status.
- Jika mitra belum terintegrasi, tampilkan katalog dan penukaran sebagai **simulasi yang diberi label jelas**; jangan membuat voucher palsu seolah berlaku nyata.

### 10. Eco-Tracker

- Catat transportasi: jalan kaki, sepeda, sepeda motor, mobil, transportasi umum; input jarak dan tanggal.
- Catat konsumsi: misalnya penggunaan listrik dan kategori konsumsi yang memiliki faktor emisi terdokumentasi.
- Hitung estimasi **kg CO₂e** dengan faktor emisi bersumber dan satuan yang jelas.
- Tampilkan statistik harian, mingguan, bulanan, grafik, riwayat, dan saran pengurangan emisi.
- Tegaskan bahwa angka merupakan **estimasi**, bukan pengukuran langsung. Hindari klaim dampak yang tidak dapat dihitung.

### 11. Edukasi Daur Ulang

Artikel dan panduan terkait plastik, kertas, organik, pemilahan, dan daur ulang. Sediakan pencarian, detail artikel, dan konten dari Firestore. Hindari fitur edukasi yang tidak berkaitan dengan ruang lingkup SHION.

### 12. Riwayat, Notifikasi, dan Profil

- **Riwayat:** scan, penyetoran, transaksi Green Point, penukaran reward, dan catatan Eco-Tracker; dengan filter dan detail.
- **Notifikasi:** perubahan status setoran, poin diterima, penukaran reward, dan informasi layanan melalui FCM bila dikonfigurasi.
- **Profil:** foto, nama, email, saldo poin, ringkasan aktivitas, edit profil, privasi, pengaturan notifikasi, Tentang SHION, logout.
- **Tentang SHION:** tampilkan filosofi brand secara utuh.

### Navigasi Utama

1. Beranda
2. Scan
3. Bank Sampah
4. Eco-Tracker
5. Profil

Reward diakses melalui kartu Green Point/dashboard dan profil. Dukung tombol kembali Android dan pertahankan state tab yang relevan.

## Peran dan Hak Akses

- **Pengguna:** scan, lihat panduan, ajukan setoran, lihat saldo, tukar reward, catat Eco-Tracker.
- **Petugas Bank Sampah:** lihat permintaan untuk bank sampah yang ditugaskan, periksa berat aktual, setujui/tolak, lihat riwayat.
- **Administrator:** kelola mitra bank sampah, nilai poin, reward, konten edukasi, dan audit transaksi.

Otorisasi harus diperiksa **di backend**, bukan hanya menyembunyikan tombol.

## Rancangan Firestore

Collections awal:

```text
users
waste_scans
waste_guides
recycling_banks
waste_deposits
point_transactions
rewards
redemptions
carbon_records
articles
notifications
```

Gunakan model data bertipe, ID pengguna, timestamp server, status transaksi, dan aturan akses yang sesuai. Rancang indeks Firestore untuk kueri yang digunakan.

## Keamanan

- Firebase Authentication, Firestore Security Rules, Storage Security Rules.
- Role-based access control dan validasi input.
- Operasi poin, verifikasi setoran, dan penukaran reward hanya melalui backend tepercaya.
- Transaksi atomik, idempotensi, pemeriksaan stok dan saldo.
- Validasi tipe/ukuran foto dan izin akses data pengguna.
- App Check jika sesuai.
- Jangan menanam kredensial rahasia di kode aplikasi.

## Performa dan Aksesibilitas

- Targetkan pengalaman mulus pada Android kelas menengah; evaluasi performa pada perangkat nyata.
- Gunakan lazy loading, caching gambar, ukuran gambar sesuai kebutuhan, dan widget rebuild yang efisien.
- Hindari blur berlapis dan animasi berat saat scroll.
- Sediakan loading, empty, error, success, dan offline state yang relevan.
- Perhatikan ukuran area sentuh, kontras, dan teks yang dapat diperbesar.

## Struktur Proyek yang Disarankan

```text
shion/
├── android/
├── lib/
│   ├── app/
│   ├── core/
│   ├── features/
│   │   ├── authentication/
│   │   ├── onboarding/
│   │   ├── dashboard/
│   │   ├── ai_scanner/
│   │   ├── waste_guides/
│   │   ├── recycling_banks/
│   │   ├── waste_deposits/
│   │   ├── green_points/
│   │   ├── rewards/
│   │   ├── eco_tracker/
│   │   ├── education/
│   │   ├── activity_history/
│   │   ├── notifications/
│   │   └── profile/
│   └── shared/
├── assets/
│   ├── images/
│   ├── icons/
│   ├── illustrations/
│   └── models/
├── design/
│   └── reference.jpg
├── firebase/
│   ├── functions/
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   └── storage.rules
├── test/
├── integration_test/
└── README.md
```

Pisahkan UI, state management, domain, dan akses data. Jangan menumpuk semua logika dalam satu file.

## Tahapan Pengerjaan

1. **Fondasi:** periksa workspace, siapkan Flutter, dependencies, tema, komponen reusable, dan navigasi.
2. **UI/UX:** bangun seluruh layar dengan data demo yang diberi label; pastikan tombol dan navigasi berfungsi.
3. **Firebase:** integrasikan Authentication, Firestore, Storage, Cloud Functions, aturan keamanan, dan notifikasi.
4. **AI Scanner:** kamera, preprocessing, model TFLite terlatih, hasil scan, dan panduan daur ulang.
5. **Green Point & Reward:** bank sampah, penyetoran, verifikasi petugas, perhitungan poin, penukaran reward.
6. **Eco-Tracker:** input transportasi/konsumsi, estimasi emisi, grafik, dan riwayat.
7. **Finalisasi:** optimasi, pengujian, dokumentasi, dan build APK jika lingkungan mendukung.

## Pengujian dan Kriteria Selesai

Jalankan perintah yang sesuai dengan proyek:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

Uji setidaknya:

- Login, registrasi, dan navigasi.
- Kamera, izin akses, dan klasifikasi dengan model yang benar-benar tersedia.
- Penyetoran, verifikasi berat, dan pemberian poin satu kali saja.
- Penukaran reward tanpa saldo negatif atau pengurangan ganda.
- Perhitungan Eco-Tracker dengan contoh data dan faktor emisi yang diketahui.
- Pembatasan akses pengguna/petugas/admin melalui Firebase Emulator Suite jika tersedia.

Jangan mengklaim suatu fitur sudah siap produksi jika belum dikonfigurasi atau diuji.

## Instruksi untuk AI Coding Agent di VS Code

Bertindak sebagai pengembang yang dapat membuat dan mengedit file langsung di workspace.

1. Periksa proyek yang sudah ada; jangan merusak kode yang berfungsi.
2. Baca referensi desain sebelum mengimplementasikan UI.
3. Buat rencana singkat, kemudian **langsung tulis kode nyata** secara bertahap.
4. Pertahankan tiga fitur inti dan jangan menambah gamifikasi di luar Green Point & Reward.
5. Pastikan setiap tombol memiliki fungsi, navigasi, atau umpan balik yang jelas.
6. Jangan membuat hasil AI, lokasi mitra, transaksi, atau voucher palsu yang ditampilkan sebagai data nyata.
7. Jika kredensial Firebase, model TFLite, Maps, atau mitra reward belum tersedia, siapkan integrasi, dokumentasi, dan mode demo transparan.
8. Setelah tiap fase, jalankan analisis/pengujian yang relevan dan perbaiki kesalahan.
9. Jelaskan fitur yang selesai, fitur yang masih memerlukan konfigurasi, dan hasil pengujian yang benar-benar dijalankan.
10. Siapkan instruksi menjalankan aplikasi di Android dan membuat APK.

**Mulai dari memeriksa workspace, membuat proyek Flutter `shion` jika belum ada, menerapkan identitas visual SHION, dan membangun UI serta navigasi. Setelah itu lanjutkan integrasi Firebase, AI Scanner, Green Point & Reward, dan Eco-Tracker. Jangan berhenti pada perencanaan.**

---

## Penggunaan Gambar dan Aset Visual Open-Source/Gratis

Untuk tahap awal pengembangan SHION, gunakan gambar dan ilustrasi gratis yang **lisensinya mengizinkan penggunaan di aplikasi**, termasuk penggunaan komersial jika relevan. Google Images dan Pinterest hanya digunakan untuk mencari inspirasi atau menemukan sumber asli; gambar di sana tidak otomatis bebas hak cipta.

### Sumber yang Direkomendasikan

- **Unsplash** — https://unsplash.com — foto alam, hutan, daur ulang, sampah, dan transportasi. Lisensi: https://unsplash.com/license
- **Pexels** — https://www.pexels.com — foto sampah, produk ramah lingkungan, dan aktivitas sehari-hari. Lisensi: https://www.pexels.com/legal-pages/license/
- **unDraw** — https://undraw.co — ilustrasi untuk onboarding, empty state, dan edukasi. Lisensi: https://undraw.co/license

### Kebutuhan Visual per Fitur

1. **Splash & onboarding:** ilustrasi bumi, lingkungan, tumbuhan, dan teknologi yang relevan.
2. **Dashboard:** foto alam dan lingkungan hijau yang sesuai identitas SHION.
3. **AI Image Scanner:** foto contoh sampah plastik, kertas, dan organik untuk panduan antarmuka (bukan untuk melatih model AI tanpa izin dataset).
4. **Green Point & Reward:** foto produk ramah lingkungan dan transportasi umum; jangan menampilkan kerja sama merek/mitra yang belum terkonfirmasi.
5. **Eco-Tracker:** foto sepeda, perjalanan, transportasi umum, dan konsumsi rumah tangga.
6. **Edukasi:** foto pemilahan sampah, proses daur ulang, dan pengolahan sampah organik.

### Aturan Penggunaan dan Implementasi

- Pilih aset berdasarkan kecocokan visual, bukan sekadar hasil teratas Google/Pinterest.
- Periksa ketentuan lisensi pada halaman sumber asli sebelum mengunduh dan menggunakan aset.
- Simpan aset yang digunakan secara lokal dalam `assets/images/` atau `assets/illustrations/`.
- Optimalkan ukuran gambar; gunakan WebP untuk foto jika sesuai, dan SVG untuk ilustrasi jika didukung.
- Buat daftar `ASSET_CREDITS.md` berisi nama file, URL sumber, nama kreator jika tersedia, tanggal akses, dan jenis lisensi.
- Jangan gunakan gambar ber-watermark, gambar dengan hak cipta tidak jelas, atau logo pihak ketiga tanpa izin.
- Hindari penggunaan foto orang yang dapat dikenali untuk menyiratkan bahwa mereka mendukung SHION.
- Jangan gunakan gambar-gambar UI sebagai dataset pelatihan, validasi, atau pengujian TensorFlow Lite kecuali lisensinya secara eksplisit mengizinkan penggunaan AI/ML tersebut.
- Gunakan placeholder bertema SHION bila aset yang aman secara lisensi belum ditemukan.
- Utamakan aset lokal supaya antarmuka tidak bergantung pada koneksi internet saat runtime.

**Instruksi untuk AI Coding Agent:** cari, pilih, unduh, optimalkan, dan integrasikan gambar yang sesuai dari sumber berlisensi tersebut apabila lingkungan kerja menyediakan akses internet. Jika tidak, buat daftar URL aset yang disarankan dan placeholder, lalu jelaskan aset mana yang masih perlu diunduh. Jangan mengklaim telah mengunduh gambar apabila belum dilakukan.
