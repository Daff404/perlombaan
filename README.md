# SHION — Flutter dan REST API

Paket lengkap ini berisi dua folder terpisah:

- `shion/` — aplikasi Flutter Android, assets/vector, konfigurasi, dan tes.
- `server/` — REST API Node.js, database akun admin, edukasi, dan tes backend.

## Menjalankan

1. Server: di `server/`, salin `.env.example` menjadi `.env`, isi konfigurasi, lalu jalankan `npm ci`, `npm test`, dan `npm start` (Node.js 22.9+).
2. Aplikasi: di `shion/`, jalankan `flutter pub get`, `flutter analyze`, `flutter test`, dan `flutter build apk --release`.
3. URL REST API ada di `shion/settings/api.json`.

Akun admin dimuat langsung dari `server/database/account.json`; bootstrap dan `create-admin.js` sudah dihapus. Server membuat `server/session/<username>/` otomatis untuk data sesi dan data pribadi. Jangan menimpa file akun pada server yang sudah dipakai.

## Penanda kode

`// ==== [ MUIS - UI UX ] ==== //` menandai UI/UX, `// ==== [ IDRUS - FRONTEND ] ==== //` menandai Flutter, dan `// ==== [ DAFFA - BACKEND ] ==== //` menandai REST API. Nama variabel dan fungsi internal Flutter sudah dialihkan ke bahasa Indonesia. Field API/JSON dan method override Flutter tetap mengikuti kontraknya.
