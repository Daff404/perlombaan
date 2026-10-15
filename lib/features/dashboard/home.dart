import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/repository.dart';
import '../../shared/catalog_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final repo = ShionRepository();
  int tab = 0;
  final amount = TextEditingController();
  String mode = 'walk';
  String category = 'plastik';
  @override
  void dispose() { amount.dispose(); super.dispose(); }
  void open(String title, Widget child) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child))));
  Widget tile(String title, String subtitle, IconData icon, VoidCallback action) => Card(child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.arrow_forward), onTap: action));
  Widget get dashboard => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('HIDUP SELARAS', style: TextStyle(letterSpacing: 4, color: Color(0xffa9c8a1))),
    const SizedBox(height: 18),
    const Text('Langkah Kecil,\nDampak Besar.', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600, height: 1.15)),
    const SizedBox(height: 16),
    const Text('Kenali sampahmu. Rawat Bumi dari rumah.'),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: () => setState(() => tab = 1), icon: const Icon(Icons.document_scanner_outlined), label: const Text('Mulai Scan')),
    StreamBuilder(stream: repo.db.collection('users').doc(repo.uid).snapshots(), builder: (context, state) {
      final data = state.data?.data();
      return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('GREEN POINT'), Text('${data?['balance'] ?? 0}', style: const TextStyle(fontSize: 36)), Text('Masuk: ${data?['earned'] ?? 0} • Terpakai: ${data?['spent'] ?? 0}'), TextButton(onPressed: () => open('Tukar Poin', rewards), child: const Text('Lihat reward'))])));
    }),
    tile('Setor Sampah', 'Temukan layanan mitra yang tersedia', Icons.recycling, () => setState(() => tab = 2)),
    tile('Eco-Tracker', 'Catat estimasi emisi aktivitasmu', Icons.public, () => setState(() => tab = 3)),
    tile('Riwayat Setoran', 'Pantau status penyetoran', Icons.history, () => open('Riwayat Setoran', history('waste_deposits'))),
    tile('Edukasi', 'Panduan pemilahan dari SHION', Icons.menu_book, () => open('Edukasi', DataList(stream: repo.catalog('articles'), empty: 'Artikel belum diterbitkan.', builder: (data, id) => ExpansionTile(title: Text(data['title'] ?? ''), children: [Padding(padding: const EdgeInsets.all(16), child: Text(data['body'] ?? ''))])))),
  ]);
  Widget history(String collection) => DataList(stream: repo.watch(collection), empty: 'Belum ada aktivitas.', builder: (data, id) => Card(child: ListTile(title: Text(data['status']?.toString() ?? data['mode']?.toString() ?? 'Transaksi'), subtitle: Text('Kode: $id\n${data['points'] ?? data['kgCO2e'] ?? ''}'))));
  Widget get scanner => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.document_scanner_outlined, size: 110),
    const SizedBox(height: 24), const Text('Kenali Sampahmu', style: TextStyle(fontSize: 30)),
    const Text('Model TensorFlow Lite terlatih belum tersedia. Klasifikasi AI belum dapat dijalankan.'),
    const SizedBox(height: 20),
    FilledButton(onPressed: () => capture(ImageSource.camera), child: const Text('Buka Kamera')),
    OutlinedButton(onPressed: () => capture(ImageSource.gallery), child: const Text('Pilih dari Galeri')),
    const SizedBox(height: 24),
    const Text('Panduan pemilahan', style: TextStyle(fontSize: 22)),
    const ListTile(title: Text('Plastik'), subtitle: Text('Kosongkan isi, bersihkan seperlunya, lalu keringkan. Periksa jenis plastik yang diterima bank sampah.')),
    const ListTile(title: Text('Kertas'), subtitle: Text('Pisahkan kertas bersih dan kering. Kertas berminyak atau berlapis tidak selalu diterima untuk daur ulang.')),
    const ListTile(title: Text('Organik'), subtitle: Text('Pisahkan sisa makanan dan bahan organik dari kemasan. Gunakan metode kompos yang sesuai; hindari minyak dan daging pada kompos rumahan sederhana.')),
  ]);
  Future<void> capture(ImageSource source) async {
    await perform(context, () async {
      final image = await ImagePicker().pickImage(source: source, maxWidth: 1600);
      if (image != null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto dipilih. Analisis menunggu model AI terlatih; belum ada prediksi.')));
    });
  }
  Widget get banks => DataList(stream: repo.catalog('recycling_banks'), empty: 'Belum ada bank sampah mitra terdaftar.', builder: (data, id) => Card(child: ListTile(title: Text(data['name'] ?? ''), subtitle: Text('${data['address'] ?? ''}\n${data['hours'] ?? ''}'), onTap: () => deposit(id, data))));
  void deposit(String id, Map<String, dynamic> bank) {
    final weight = TextEditingController();
    String selected = 'plastik';
    showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, update) => AlertDialog(title: Text('Setor ke ${bank['name']}'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButton<String>(value: selected, items: ['plastik', 'kertas', 'organik'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (x) => update(() => selected = x!)), TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Estimasi berat (kg)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () async { final value = double.tryParse(weight.text.replaceAll(',', '.')); if (value == null || value <= 0) return; await perform(context, () => repo.call('submitDeposit', {'bankId': id, 'category': selected, 'estimatedKg': value})); if (context.mounted) Navigator.pop(context); }, child: const Text('Ajukan'))]))).whenComplete(weight.dispose);
  }
  Widget get rewards => DataList(stream: repo.catalog('rewards'), empty: 'Belum ada reward dari mitra aktif.', builder: (data, id) => Card(child: ListTile(title: Text(data['title'] ?? ''), subtitle: Text('${data['cost']} poin • stok ${data['stock']}'), trailing: FilledButton(onPressed: () async {
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Konfirmasi penukaran'), content: Text('Tukar ${data['cost']} poin untuk ${data['title']}?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Tukarkan'))]));
    if (confirmed == true && mounted) await perform(context, () => repo.call('redeemReward', {'rewardId': id, 'requestId': repo.db.collection('redemptions').doc().id}));
  }, child: const Text('Tukar')))));
  Widget get carbon => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Eco-Tracker', style: TextStyle(fontSize: 30)),
    const Text('Angka merupakan estimasi kg CO₂e, bukan pengukuran langsung. Faktor bermotor harus dikonfigurasi administrator dengan sumbernya.'),
    const SizedBox(height: 24),
    DropdownButtonFormField<String>(value: mode, items: const [DropdownMenuItem(value: 'walk', child: Text('Jalan kaki (km)')), DropdownMenuItem(value: 'bicycle', child: Text('Sepeda (km)')), DropdownMenuItem(value: 'motorcycle', child: Text('Sepeda motor (km)')), DropdownMenuItem(value: 'car', child: Text('Mobil (km)')), DropdownMenuItem(value: 'public', child: Text('Transportasi umum (km)')), DropdownMenuItem(value: 'electricity', child: Text('Listrik (kWh)'))], onChanged: (x) => setState(() => mode = x!)),
    const SizedBox(height: 12), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Jumlah sesuai satuan aktivitas')),
    const SizedBox(height: 12), FilledButton(onPressed: () => perform(context, () async { final value = double.tryParse(amount.text.replaceAll(',', '.')); if (value == null || value <= 0) throw Exception('Masukkan angka positif.'); await repo.saveCarbon(mode, value, DateTime.now()); amount.clear(); }), child: const Text('Simpan Aktivitas Hari Ini')),
    const SizedBox(height: 20), history('carbon_records'),
  ]);
  Widget get profile => Column(children: [
    const CircleAvatar(radius: 40, child: Icon(Icons.person_outline, size: 40)),
    Text(repo.auth.currentUser?.email ?? ''),
    if (!(repo.auth.currentUser?.emailVerified ?? false)) TextButton(onPressed: () => perform(context, () => repo.auth.currentUser!.sendEmailVerification()), child: const Text('Kirim email verifikasi')),
    tile('Transaksi Green Point', 'Riwayat perubahan saldo', Icons.receipt_long, () => open('Transaksi Green Point', history('point_transactions'))),
    tile('Penukaran Reward', 'Pantau permintaan reward', Icons.card_giftcard, () => open('Penukaran Reward', history('redemptions'))),
    const Padding(padding: EdgeInsets.all(20), child: Text('SHION adalah pilar kesadaran dan kompas menuju kehidupan yang selaras. Ia menghubungkan kecerdasan teknologi dengan komitmen abadi manusia untuk tidak melupakan dan merawat Buminya.')),
    OutlinedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Keluar')),
  ]);
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('SHION', style: TextStyle(letterSpacing: 5))), body: SingleChildScrollView(key: ValueKey(tab), padding: const EdgeInsets.all(22), child: [dashboard, scanner, banks, carbon, profile][tab]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (value) => setState(() => tab = value), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'), NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Scan'), NavigationDestination(icon: Icon(Icons.recycling), label: 'Bank Sampah'), NavigationDestination(icon: Icon(Icons.public), label: 'Eco-Tracker'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil')]));
}
