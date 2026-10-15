import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/local_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocalStore? store;
  int page = 0;
  String material = 'Plastik';
  String activity = 'Jalan kaki';
  File? photo;
  final amount = TextEditingController();
  final place = TextEditingController();
  final name = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        store = LocalStore(prefs);
        name.text = store!.name;
      });
    }).catchError((Object error) {
      if (mounted) _message('Penyimpanan lokal tidak tersedia: $error');
    });
  }

  @override
  void dispose() {
    amount.dispose();
    place.dispose();
    name.dispose();
    super.dispose();
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _perform(Future<void> Function() work) async {
    try {
      await work();
      if (mounted) setState(() {});
      _message('Catatan tersimpan di perangkat.');
    } catch (error) {
      _message('Gagal: $error');
    }
  }

  double? _number() {
    final value = double.tryParse(amount.text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0 || value > 100000) {
      _message('Masukkan jumlah positif yang valid.');
      return null;
    }
    return value;
  }

  Widget _card(String title, String description, IconData icon, VoidCallback onTap) =>
      Card(child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right), onTap: onTap));

  Widget _records(String key, String empty, String Function(Map<String, dynamic>) title) {
    final items = store!.records(key);
    if (items.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text(empty));
    return Column(children: items.map((item) => Card(child: ListTile(
      title: Text(title(item)),
      subtitle: Text('${item['createdAt'] ?? ''}'),
    ))).toList());
  }

  Widget get _dashboard => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('TECHNOLOGY IN HARMONY WITH NATURE', style: TextStyle(letterSpacing: 2, color: Color(0xffa9c8a1))),
    const SizedBox(height: 22),
    Text('Halo${store!.name.isEmpty ? '' : ', ${store!.name}'}', style: Theme.of(context).textTheme.titleLarge),
    const Text('Langkah Kecil,\nDampak Besar.', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w600, height: 1.1)),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: () => setState(() => page = 1), icon: const Icon(Icons.document_scanner), label: const Text('Kenali Sampah')),
    const SizedBox(height: 16),
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('GREEN POINT'), Text('${store!.points}', style: const TextStyle(fontSize: 36)),
      const Text('Poin memerlukan verifikasi mitra. Tidak ada poin yang diterbitkan secara offline.'),
    ]))),
    _card('Bank Sampah', 'Catat rencana setoran pribadi', Icons.recycling, () => setState(() => page = 2)),
    _card('Eco-Tracker', 'Catat aktivitas dan estimasi emisi', Icons.public, () => setState(() => page = 3)),
    _card('Edukasi', 'Panduan pemilahan sampah', Icons.menu_book, () => _open('Panduan Daur Ulang', _guides)),
  ]);

  Widget get _guides => const Column(children: [
    ListTile(title: Text('Plastik'), subtitle: Text('Kosongkan dan bersihkan kemasan; periksa jenis plastik yang diterima bank sampah setempat.')),
    ListTile(title: Text('Kertas'), subtitle: Text('Pisahkan kertas bersih dan kering dari yang berminyak atau berlapis.')),
    ListTile(title: Text('Organik'), subtitle: Text('Pisahkan sisa makanan dari kemasan. Komposkan bahan yang sesuai dengan metode yang digunakan.')),
  ]);

  void _open(String title, Widget child) => Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: SingleChildScrollView(
      padding: const EdgeInsets.all(18), child: child))));

  Future<void> _pick(ImageSource source) async {
    try {
      final chosen = await ImagePicker().pickImage(source: source, maxWidth: 1400, imageQuality: 80);
      if (chosen == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'scan_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final saved = await File(chosen.path).copy('${directory.path}${Platform.pathSeparator}$filename');
      if (mounted) setState(() => photo = saved);
    } catch (error) { _message('Foto tidak dapat dibuka: $error'); }
  }

  Widget get _scanner => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.document_scanner_outlined, size: 92),
    const Text('Kenali Sampahmu', style: TextStyle(fontSize: 29)),
    const SizedBox(height: 8),
    const Text('Model AI terlatih belum tersedia. Pilih kategori sendiri; aplikasi tidak membuat prediksi palsu.'),
    const SizedBox(height: 16),
    OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Ambil Foto')),
    OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Pilih Galeri')),
    if (photo != null) Image.file(photo!, height: 180, fit: BoxFit.contain),
    DropdownButtonFormField<String>(initialValue: material, decoration: const InputDecoration(labelText: 'Kategori manual'),
      items: ['Plastik', 'Kertas', 'Organik'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: (value) => setState(() => material = value!)),
    const SizedBox(height: 12),
    FilledButton(onPressed: () => _perform(() => store!.add('scans', {
      'category': material, 'method': 'manual', 'photoPath': photo?.path,
    })), child: const Text('Simpan Catatan Scan')),
    const SizedBox(height: 18), _guides,
    const Text('Riwayat Scan', style: TextStyle(fontSize: 21)),
    _records('scans', 'Belum ada catatan.', (item) => '${item['category']} • kategorisasi manual'),
  ]);

  Widget get _banks => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Rencana Setoran', style: TextStyle(fontSize: 29)),
    const Text('Daftar mitra belum tersedia. Catatan di sini hanya untuk kebutuhan pribadi; belum dikirim ke petugas.'),
    const SizedBox(height: 18),
    TextField(controller: place, decoration: const InputDecoration(labelText: 'Nama tempat tujuan (opsional)')),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(initialValue: material, decoration: const InputDecoration(labelText: 'Jenis sampah'),
      items: ['Plastik', 'Kertas', 'Organik'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: (value) => setState(() => material = value!)),
    const SizedBox(height: 12),
    TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Perkiraan berat (kg)')),
    const SizedBox(height: 12),
    FilledButton(onPressed: () {
      final value = _number(); if (value == null) return;
      _perform(() => store!.add('deposits', {'category': material, 'estimatedKg': value,
        'destination': place.text.trim(), 'status': 'Rencana pribadi'}));
      amount.clear();
    }, child: const Text('Simpan Rencana')),
    _records('deposits', 'Belum ada rencana setoran.',
      (item) => '${item['category']} • ${item['estimatedKg']} kg • ${item['status']}'),
  ]);

  // No unsupported emissions factors are invented for motorized modes.
  Widget get _tracker => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Eco-Tracker', style: TextStyle(fontSize: 29)),
    const Text('Aktivitas disimpan lokal. Estimasi 0 kg CO₂e hanya berlaku bagi emisi langsung berjalan kaki dan bersepeda. Aktivitas lain memerlukan faktor emisi bersumber.'),
    const SizedBox(height: 18),
    DropdownButtonFormField<String>(initialValue: activity, decoration: const InputDecoration(labelText: 'Aktivitas'),
      items: ['Jalan kaki', 'Sepeda', 'Sepeda motor', 'Mobil', 'Transportasi umum', 'Listrik'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: (value) => setState(() => activity = value!)),
    const SizedBox(height: 12),
    TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: activity == 'Listrik' ? 'Konsumsi (kWh)' : 'Jarak (km)')),
    const SizedBox(height: 12),
    FilledButton(onPressed: () {
      final value = _number(); if (value == null) return;
      _perform(() => store!.add('carbon', {'activity': activity, 'amount': value,
        'unit': activity == 'Listrik' ? 'kWh' : 'km',
        'directKgCO2e': ['Jalan kaki', 'Sepeda'].contains(activity) ? 0 : null}));
      amount.clear();
    }, child: const Text('Simpan Aktivitas')),
    _records('carbon', 'Belum ada aktivitas.', (item) =>
      '${item['activity']} • ${item['amount']} ${item['unit']} • ${item['directKgCO2e'] == null ? 'estimasi belum tersedia' : '0 kg CO₂e langsung'}'),
  ]);

  Widget get _profile => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const CircleAvatar(radius: 36, child: Icon(Icons.eco, size: 36)),
    const SizedBox(height: 20),
    TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama panggilan')),
    const SizedBox(height: 12),
    FilledButton(onPressed: () => _perform(() => store!.setName(name.text)), child: const Text('Simpan Profil')),
    const SizedBox(height: 24),
    const Text('Reward & Green Point', style: TextStyle(fontSize: 22)),
    const Text('Saldo 0. Verifikasi setoran, transaksi poin, dan voucher mitra memerlukan layanan dan mitra nyata. Fitur ini belum bisa dijalankan secara offline.'),
    const SizedBox(height: 24),
    const Text('Tentang SHION', style: TextStyle(fontSize: 22)),
    const Text('SHION adalah pilar kesadaran dan kompas menuju kehidupan yang selaras. Ia menghubungkan kecerdasan teknologi dengan komitmen abadi manusia untuk tidak melupakan dan merawat Buminya.'),
    const SizedBox(height: 20),
    const Text('Data disimpan di perangkat ini. Menghapus data aplikasi dapat menghapus catatan.'),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SHION', style: TextStyle(letterSpacing: 5))),
      body: store == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(key: ValueKey(page), padding: const EdgeInsets.all(20),
            child: [_dashboard, _scanner, _banks, _tracker, _profile][page]),
      bottomNavigationBar: NavigationBar(selectedIndex: page, onDestinationSelected: (value) => setState(() => page = value), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Scan'),
        NavigationDestination(icon: Icon(Icons.recycling), label: 'Setor'),
        NavigationDestination(icon: Icon(Icons.public), label: 'Eco-Tracker'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
      ]),
    );
  }
}
