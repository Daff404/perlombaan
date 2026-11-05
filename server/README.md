# SHION REST API 1.0.0

<!-- ==== [ DAFFA - BACKEND ] ==== -->
<!-- ==== [ IDRUS - FRONTEND ] ==== -->
<!-- ==== [ MUIS - UI UX ] ==== -->

Catatan pembagian kode: ZIP ini hanya berisi REST API/backend, sehingga sumber Flutter frontend (Idrus) dan UI/UX (Muis) tidak disertakan. Semua kode JavaScript backend diberi penanda Daffa. Nama fungsi dan variabel internal menggunakan bahasa Indonesia; nama field API/JSON tetap mengikuti kontrak agar aplikasi Flutter yang sudah terhubung tidak rusak.

Node.js 22.9+, satu proses API. Dari folder server: npm ci, npm test, npm start.
.env tersedia; isi GEMINI_API_KEY. Domain https://app.daffaputra.id diarahkan ke port 3000 melalui reverse proxy HTTPS. Folder source/data/session/secrets tidak boleh dilayani sebagai folder publik. Batas body proxy minimal 24 MB.

## Akun admin

Akun awal berada langsung di `database/account.json` sebagai array. Tidak ada folder bootstrap atau skrip `create-admin.js`; server membaca akun dari berkas ini ketika mulai. Paket ini menyertakan akun administrator SHION, Idrus, dan Muis. Pendaftaran aplikasi hanya membuat akun dengan `role: "user"`.

Untuk menambahkan admin baru, buat hash kata sandi dari folder `server`:

```bash
node -e "require('./src/security').hashKataSandi('PasswordBaruPanjang!').then(console.log)"
```

Tambahkan objek akun berisi `id`, `username`, `name`, `email`, `phone`, `role: "admin"`, `passwordHash` hasil perintah tersebut, dan `createdAt` ke array `database/account.json`. Hentikan server sebelum mengedit berkas. Jangan menimpa `account.json` pada server yang sudah berisi akun; gabungkan akun admin baru dengan data akun yang ada.

Admin aplikasi mengelola fitur SHION; admin grup hanya mengelola grup tempat ia menjadi anggota.

## Penyimpanan

- database/account.json: array akun user/admin dengan hash password, username stabil, identitas dan role.
- session/<username>/<hash-token>.json: sesi login dengan tokenHash dan expiry; token asli tidak disimpan di server.
- session/<username>/messages.json: percakapan AI.
- session/<username>/scans.json, deposits.json, ledger.json, vouchers.json, guides.json, activities.json, places.json: data pribadi.
- session/<username>/notificationReads.json, pointQrs.json: status baca dan QR penerima.
- session/<username>/groupMessages.json: pesan komunitas yang dikirim pengguna; groupInvites.json/groupRequests.json: undangan dan permintaan milik pengguna.
- session/<username>/media/: media komunitas; scan-media/: foto scan. Akses melalui API memeriksa kepemilikan/keanggotaan.
- content/notifikasi.json: pengumuman dan pemberitahuan dengan judul, desk, gambar HTTPS opsional, ID/waktu/penerima.
- content/edukasi/<id>.json: artikel admin. content/community.json: metadata grup, anggota/role, aturan join dan referensi pesan sematan.
- storage/activity.json: metadata operasional dan revisi. storage/transaction.json: jurnal commit lintas file, dihapus setelah berhasil.
- uploads/: kompatibilitas foto versi lama, dipindahkan otomatis ketika startup.

Folder session menyimpan data tahan lama, bukan cache untuk dihapus. Logout mencabut token login, bukan riwayat.
JSON memakai snapshot memori, transaksi terserialisasi, lock satu proses, jurnal pemulihan dan penulisan atomik. Jangan mengedit JSON ketika server hidup. Backup database/, session/, content/, storage/ dan uploads/ bersama saat server dihentikan.

## Upgrade

Backup dan hentikan versi lama, pertahankan .env serta seluruh folder data, terutama `database/account.json` yang sudah ada. Ganti source dan jalankan npm ci lalu npm start. DATABASE_FILE=./database/account.json.
Versi gabungan database/shion.json atau struktur v3 dikenali otomatis. Riwayat/saldo tidak direset; notifikasi dan edukasi pindah ke content/. Foto scan lama disalin ke session pengguna, metadata disimpan, lalu salinan lama dibersihkan. Jika migrasi gagal, perbaiki penyebabnya dan restart agar jurnal dilanjutkan. Salinan database gabungan lama berada di storage/legacy-backup.json.

## QR dan poin

POST /api/points/qr membuat QR 120 detik untuk akun user dan menggantikan QR lama yang belum dipakai.
GET /api/points/qr/:id memberi status QR pemilik.
POST /api/admin/points/resolve menerima payload QR dan mengembalikan identitas penerima.
POST /api/admin/points/credit menerima payload, amount bilangan bulat 1–100000, requestId unik. Hanya admin aplikasi. Validasi expiry, sesi pemilik, status sekali pakai dan saldo dilakukan dalam transaksi yang sama dengan pencatatan ledger/notifikasi. Retry requestId yang sama tidak mengkredit ulang.

Poin scan baru yang memenuhi syarat = 1; setoran valid = 1. Batas 5 scan berpoin/hari dan penolakan duplikat tetap. Kredit QR mengikuti jumlah admin. Saldo historis dan biaya penukaran tidak diubah.

## Komunitas

GET/POST /api/groups: pencarian (q), undangan sendiri, membuat grup.
GET /api/groups/:id: info anggota, pesan terbaru, sematan dan antrean persetujuan untuk admin grup; query before ISO untuk riwayat.
POST /api/groups/:id/join, /invite (username), /leave, /promote (userId), /messages (body,requestId), /pin (messageId,pinned).
POST /api/group-invites/:id/respond (accept boolean).
POST /api/groups/:id/requests/:requestId (accept boolean), PUT /api/groups/:id/settings (approvalRequired boolean).
POST /api/groups/:id/media?kind=image|video&requestId=... dengan application/octet-stream, batas 20 MB.
GET /api/groups/:id/media/:messageId memeriksa anggota aktif, mendukung range untuk video.

Pembuat grup menjadi admin. Anggota boleh mengundang, penerima harus menyetujui sendiri; mode persetujuan menambahkan langkah admin. Admin terakhir wajib mempromosikan pengganti jika anggota lain masih ada. Keluar mencabut akses pesan/media; pesan historis tetap tersimpan. Grup kosong diarsipkan. Maksimal 200 anggota, 10 grup aktif per pembuat, tiga sematan. Pencarian menampilkan maksimal 100 hasil; persempit nama untuk hasil lain. Riwayat chat dipoll setiap tiga detik dari Flutter, bukan koneksi WebSocket. Tidak ada enkripsi end-to-end; HTTPS dan pembatasan keanggotaan melindungi akses.

## Notifikasi dari server

Admin broadcast ke semua user aktif saat pengiriman. Notifikasi QR ditargetkan penerima; notifikasi komunitas ke anggota/penerima undangan yang relevan. GET /api/admin/notifications hanya menampilkan broadcast, bukan notifikasi privat komunitas.

GET /api/notifications mengembalikan notifikasi akun dari server; POST /api/notifications/read menyimpan status baca dalam session pengguna. Flutter memeriksa endpoint ini ketika aplikasi aktif dan menampilkan notifikasi Android lokal untuk pesan baru. Tidak ada Firebase, token push atau konfigurasi layanan eksternal. Notifikasi sistem saat aplikasi ditutup tidak bisa dikirim oleh polling biasa; lihat NOTIFIKASI_SERVER.md.

## Endpoint lama

Semua selain login/register/health memerlukan Authorization: Bearer <token>. Respons JSON {status:true,data:{...}}.
- Auth register/login/logout/me/password, state/profile.
- scans, scans/:id/photo, deposits, activities, places, chat, guides, rewards/:id/redeem.
- leaderboard?metric=points|deposits.
- notifications dan notifications/read.
- education: artikel edukasi internal SHION yang dikelola admin.
- admin/users, admin/notifications, admin/education; publish/hapus edukasi.

Tidak ada Telegram. .env.example berisi seluruh variabel. Kode backend menggunakan penanda `// ==== [ DAFFA - BACKEND ] ==== //`. Source UI/UX Muis dan frontend Idrus tidak termasuk dalam paket backend ini. Uji menggunakan npm test dengan data sementara; tidak mengirim notifikasi ke hosting sungguhan.


### Peta dan pencarian lokasi

Lokasi menggunakan OpenStreetMap, Nominatim untuk mencari wilayah dan Overpass untuk mencari titik di sekitarnya. Tidak memerlukan API key. Pencarian geokode diantrikan minimal satu detik sesuai kebijakan Nominatim; hasil dan cakupan lokasi mengikuti data komunitas OpenStreetMap. Aplikasi menampilkan atribusi peta.
