import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/local_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShionApp());
}

class ShionApp extends StatelessWidget {
  const ShionApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SHION',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffa9c8a1),
            brightness: Brightness.dark,
            surface: const Color(0xff102d25),
          ),
          scaffoldBackgroundColor: const Color(0xff071b16),
          cardTheme: const CardThemeData(color: Color(0xff102d25)),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const ShionHome(),
      );
}

class ShionHome extends StatefulWidget {
  const ShionHome({super.key});

  @override
  State<ShionHome> createState() => _ShionHomeState();
}

class _ShionHomeState extends State<ShionHome> {
  LocalStore? _store;
  int _tab = 0;
  String _category = 'Plastik';
  String _activity = 'Jalan kaki';
  String? _photoPath;
  final _weight = TextEditingController();
  final _distance = TextEditingController();
  final _destination = TextEditingController();
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (!mounted) return;
      setState(() {
        _store = LocalStore(preferences);
        _name.text = _store!.name;
      });
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _distance.dispose();
    _destination.dispose();
    _name.dispose();
    super.dispose();
  }

  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() {});
      _notify('Tersimpan di perangkat.');
    } catch (error) {
      _notify('Gagal menyimpan: $error');
    }
  }

  double? _validNumber(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0 || value > 100000) {
      _notify('Masukkan angka positif yang valid.');
      return null;
    }
    return value;
  }

  Widget _tile(String title, String subtitle, IconData icon, VoidCallback onTap) =>
      Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Widget _history(String key, String empty, String Function(Map<String, dynamic>) label) {
    final rows = _store!.getList(key);
    if (rows.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text(empty));
    return Column(
      children: rows.map((row) => Card(
        child: ListTile(
          title: Text(label(row)),
          subtitle: Text(row['createdAt']?.toString() ?? ''),
        ),
      )).toList(),
    );
  }

  Widget get _home => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('TECHNOLOGY IN HARMONY WITH NATURE',
              style: TextStyle(letterSpacing: 2, color: Color(0xffa9c8a1))),
          const SizedBox(height: 22),
          Text('Halo${_store!.name.isEmpty ? '' : ', ${_store!.name}'}',
              style: Theme.of(context).textTheme.titleLarge),
          const Text('Langkah Kecil,\nDampak Besar.',
              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w600, height: 1.1)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => setState(() => _tab = 1),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Kenali Sampah'),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GREEN POINT'),
                Text('0', style: TextStyle(fontSize: 36)),
                Text('Poin nyata menunggu verifikasi bank sampah mitra.'),
              ]),
            ),
          ),
          _tile('Rencana Setoran', 'Catat sampah yang ingin disetor', Icons.recycling,
              () => setState(() => _tab = 2)),
          _tile('Eco-Tracker', 'Simpan catatan aktivitas', Icons.public,
              () => setState(() => _tab = 3)),
          _tile('Panduan Daur Ulang', 'Pelajari pemilahan sampah', Icons.menu_book,
              () => _openPage('Panduan', _guides)),
        ],
      );

  Widget get _guides => const Column(children: [
        ListTile(title: Text('Plastik'), subtitle: Text('Kosongkan, bersihkan seperlunya, dan pisahkan berdasarkan jenis yang diterima layanan setempat.')),
        ListTile(title: Text('Kertas'), subtitle: Text('Pisahkan kertas bersih dan kering. Kertas berminyak atau berlapis bisa tidak diterima.' )),
        ListTile(title: Text('Organik'), subtitle: Text('Pisahkan sisa makanan dari kemasan. Gunakan metode kompos yang sesuai.' )),
      ]);

  void _openPage(String title, Widget child) => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: SingleChildScrollView(padding: const EdgeInsets.all(18), child: child),
          ),
        ),
      );

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 82,
      );
      if (image == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'shion_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final saved = await File(image.path).copy('${directory.path}${Platform.pathSeparator}$filename');
      if (mounted) setState(() => _photoPath = saved.path);
    } catch (error) {
      _notify('Tidak dapat membuka foto: $error');
    }
  }

  Widget get _scanner => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.document_scanner_outlined, size: 88),
          const Text('Kenali Sampahmu', style: TextStyle(fontSize: 29)),
          const Text('Model AI terlatih belum dipasang. Pilih kategori manual; aplikasi tidak membuat prediksi.'),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Ambil Foto')),
          OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Pilih dari Galeri')),
          if (_photoPath != null && File(_photoPath!).existsSync())
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Image.file(File(_photoPath!), height: 190, fit: BoxFit.contain)),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Pilih kategori'),
            items: ['Plastik', 'Kertas', 'Organik'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _save(() => _store!.addRecord('scans', {
              'category': _category,
              'photoPath': _photoPath,
              'classification': 'manual',
            })),
            child: const Text('Simpan Riwayat Scan'),
          ),
          const SizedBox(height: 18),
          _guides,
          const Text('Riwayat Scan', style: TextStyle(fontSize: 21)),
          _history('scans', 'Belum ada catatan scan.', (row) => '${row['category']} • manual'),
        ],
      );

  Widget get _deposits => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Rencana Setoran', style: TextStyle(fontSize: 29)),
          const Text('Catatan ini hanya tersimpan di perangkat dan belum dikirim atau diverifikasi bank sampah.'),
          const SizedBox(height: 14),
          TextField(controller: _destination, decoration: const InputDecoration(labelText: 'Nama tempat (opsional)')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Jenis sampah'),
            items: ['Plastik', 'Kertas', 'Organik'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 10),
          TextField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Perkiraan berat (kg)')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final amount = _validNumber(_weight);
              if (amount == null) return;
              _save(() => _store!.addRecord('deposits', {
                'destination': _destination.text.trim(),
                'category': _category,
                'estimatedKg': amount,
                'status': 'Rencana pribadi',
              }));
              _weight.clear();
            },
            child: const Text('Simpan Rencana'),
          ),
          _history('deposits', 'Belum ada rencana setoran.', (row) => '${row['category']} • ${row['estimatedKg']} kg'),
        ],
      );

  Widget get _tracker => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Eco-Tracker', style: TextStyle(fontSize: 29)),
          const Text('Catatan disimpan lokal. Estimasi kg CO₂e perlu faktor emisi bersumber; aplikasi tidak mengarang angkanya.'),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _activity,
            decoration: const InputDecoration(labelText: 'Aktivitas'),
            items: ['Jalan kaki', 'Sepeda', 'Sepeda motor', 'Mobil', 'Transportasi umum', 'Listrik'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => _activity = value!),
          ),
          const SizedBox(height: 10),
          TextField(controller: _distance, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _activity == 'Listrik' ? 'Pemakaian (kWh)' : 'Jarak (km)')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final amount = _validNumber(_distance);
              if (amount == null) return;
              _save(() => _store!.addRecord('activities', {
                'activity': _activity,
                'amount': amount,
                'unit': _activity == 'Listrik' ? 'kWh' : 'km',
              }));
              _distance.clear();
            },
            child: const Text('Simpan Aktivitas'),
          ),
          _history('activities', 'Belum ada catatan aktivitas.', (row) => '${row['activity']} • ${row['amount']} ${row['unit']}'),
        ],
      );

  Widget get _profile => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircleAvatar(radius: 34, child: Icon(Icons.eco_outlined, size: 34)),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama panggilan')),
          const SizedBox(height: 10),
          FilledButton(onPressed: () => _save(() => _store!.setName(_name.text)), child: const Text('Simpan Profil')),
          const SizedBox(height: 22),
          const Text('Green Point & Reward', style: TextStyle(fontSize: 22)),
          const Text('Saldo 0. Setoran harus diverifikasi mitra agar poin atau voucher nyata dapat diterbitkan. Fitur transaksi belum tersedia dalam penyimpanan lokal saja.'),
          const SizedBox(height: 22),
          const Text('Tentang SHION', style: TextStyle(fontSize: 22)),
          const Text('SHION adalah pilar kesadaran dan kompas menuju kehidupan yang selaras. Ia menghubungkan kecerdasan teknologi dengan komitmen abadi manusia untuk tidak melupakan dan merawat Buminya.'),
          const SizedBox(height: 20),
          const Text('Data tersimpan di perangkat ini. Menghapus data aplikasi dapat menghapus catatan.'),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Scaffold(
      appBar: AppBar(title: const Text('SHION', style: TextStyle(letterSpacing: 5))),
      body: store == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              key: ValueKey<int>(_tab),
              padding: const EdgeInsets.all(20),
              child: <Widget>[_home, _scanner, _deposits, _tracker, _profile][_tab],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.recycling), label: 'Setor'),
          NavigationDestination(icon: Icon(Icons.public), label: 'Eco-Tracker'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
