// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
part of '../main.dart';

class Article {
  const Article(this.title, this.category, this.photo, this.body);
  final String title, category, photo, body;
}

const articles = [
  Article(
    '5 Cara Mudah Mengurangi Sampah Plastik di Rumah',
    'Tips',
    Photos.reuse,
    'Perubahan kecil bisa dimulai dari kebiasaan sehari-hari.\n\n1. Bawa tas belanja yang dapat dipakai berulang. Simpan di dekat pintu agar tidak tertinggal.\n\n2. Gunakan botol minum sendiri ketika akses isi ulang tersedia.\n\n3. Buat daftar belanja untuk menghindari barang yang tidak diperlukan.\n\n4. Pilih kemasan yang dapat digunakan kembali dan layanan isi ulang bila tersedia.\n\n5. Pisahkan sampah sesuai ketentuan pengelola di daerahmu. Kemasan yang diterima dapat berbeda di setiap tempat.',
  ),
  Article(
    'Apa itu Jejak Karbon dan Cara Menguranginya',
    'Gaya Hidup',
    Photos.bus,
    'Jejak karbon menggambarkan emisi gas rumah kaca yang terkait dengan aktivitas. Perjalanan dan penggunaan energi adalah beberapa sumbernya.\n\nCatat jarak perjalanan dan pemakaian listrik agar kamu memahami kebiasaan sendiri. Berjalan kaki, bersepeda pada rute aman, serta transportasi bersama dapat menjadi pilihan sesuai kebutuhan.\n\nMenghitung kg CO₂e memerlukan faktor emisi yang sesuai lokasi, kendaraan, sumber energi, dan periode. SHION saat ini menyimpan data aktivitas tanpa menampilkan estimasi yang belum terverifikasi.',
  ),
  Article(
    'Manfaat Daur Ulang untuk Lingkungan',
    'Daur Ulang',
    Photos.plant,
    'Pemilahan membantu material yang masih bernilai masuk ke aliran pengolahan yang sesuai.\n\nKosongkan kemasan, pisahkan material yang basah dari kertas kering, lalu tanyakan syarat penerimaan pada tempat setor. Hindari mencampurkan limbah berbahaya dengan sampah daur ulang rumah tangga.\n\nMengurangi konsumsi dan memakai ulang barang tetap penting. Tidak semua material dapat didaur ulang di semua daerah.',
  ),
  Article(
    'Jenis-Jenis Sampah dan Cara Menanganinya',
    'Daur Ulang',
    Photos.organic,
    'Organik: pisahkan dari kemasan dan gunakan pengolahan organik yang sesuai.\n\nKertas: simpan bersih dan kering. Kertas berminyak atau berlapis mungkin tidak diterima.\n\nPlastik: kelompokkan sesuai petunjuk tempat setor. Simbol pada kemasan tidak menjamin tersedianya fasilitas pengolahan lokal.\n\nBaterai, elektronik, dan limbah berbahaya perlu jalur pengumpulan khusus. Hubungi pengelola sampah setempat untuk petunjuk penanganan.',
  ),
];
