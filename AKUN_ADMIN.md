# Akun Admin SHION

Akun admin disimpan langsung di `server/database/account.json` dan dimuat saat server mulai. Tidak ada bootstrap maupun `create-admin.js`. Pendaftaran dari aplikasi hanya membuat akun `user`.

Akun yang tersedia: `admin-shion`, `admin-idrus`, dan `admin-muis` (email: `admin@shion.app`, `idrus@shion.app`, `muis@shion.app`). Kata sandi awal: `ShionBumi#2026`, `SHION-Idrus!mN358SkcG8AtzB9X`, dan `SHION-Muis!113fQt_7gJraraeW` sesuai urutan akun. Ganti setelah login.

Untuk menambah admin, hentikan server, tambahkan akun dengan `role: "admin"` dan hash scrypt ke array `server/database/account.json`, lalu jalankan ulang server. Panduan pembentukan hash ada di `server/README.md`.
