// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../ui/forest.dart';
import 'notifications_page.dart';
import 'points_qr_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<AdminPage> createState() => _adminHalamanKeadaan();
}
class _adminHalamanKeadaan extends State<AdminPage> {
  final _formulir = GlobalKey<FormState>();
  final _judul = TextEditingController(), _isi = TextEditingController(), _gambar = TextEditingController();
  final _konten = TextEditingController(), _kategori = TextEditingController(text: 'Daur Ulang');
  List<Map<String, dynamic>> _riwayat = [], _daftarArtikel = [];
  String? _galat, _tandaTangan, _permintaanId;
  int _daftarPengguna = 0;
  bool _edukasi = false, _memuat = true, _mengirim = false;
  @override
  void initState() { super.initState(); _muat(); }
  @override
  void dispose() { for (final c in [_judul, _isi, _gambar, _konten, _kategori]) { c.dispose(); } super.dispose(); }
  Future<void> _muat() async {
    if (!widget.store.adalahAdmin) return;
    try {
      final hasil = await Future.wait([widget.store.daftarPenggunaAdmin(), widget.store.notifikasiAdmin(), widget.store.edukasiAdmin()]);
      if (mounted) setState(() {
        _daftarPengguna = (hasil[0]['users'] as List).length;
        _riwayat = (hasil[1]['notifications'] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
        _daftarArtikel = (hasil[2]['articles'] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
        _galat = null;
      });
    } catch (e) { if (mounted) setState(() => _galat = e.toString()); }
    finally { if (mounted) setState(() => _memuat = false); }
  }
  String? _wajib(String? value, int min) => (value ?? '').trim().length < min ? 'Isi minimal $min karakter.' : null;
  String? _gambarValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final alamat = Uri.tryParse(value!.trim());
    return alamat?.scheme == 'https' && (alamat?.host.isNotEmpty ?? false) ? null : 'Gunakan URL gambar HTTPS.';
  }
  Future<void> _kirim() async {
    if (_mengirim || !(_formulir.currentState?.validate() ?? false)) return;
    final konfirmasi = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(_edukasi ? 'Terbitkan edukasi?' : 'Kirim ke semua pengguna?'),
      content: Text(_edukasi ? 'Artikel akan dapat dibaca seluruh pengguna SHION.' : 'Notifikasi akan masuk ke kotak pesan $_daftarPengguna pengguna.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan'))],
    ));
    if (konfirmasi != true || !mounted) return;
    setState(() { _mengirim = true; _galat = null; });
    try {
      final tandaTangan = '$_edukasi|${_judul.text}|${_isi.text}|${_gambar.text}|${_konten.text}|${_kategori.text}';
      if (_tandaTangan != tandaTangan) { _tandaTangan = tandaTangan; _permintaanId = ApiClient.buatIdPermintaan(); }
      if (_edukasi) {
        await widget.store.terbitkanEdukasi({'requestId': _permintaanId, 'judul': _judul.text.trim(), 'desk': _isi.text.trim(), 'konten': _konten.text.trim(), 'kategori': _kategori.text.trim(), 'gambar': _gambar.text.trim()});
      } else {
        await widget.store.kirimNotifikasi(title: _judul.text.trim(), body: _isi.text.trim(), gambar: _gambar.text.trim(), requestId: _permintaanId!);
      }
      _tandaTangan = null; _permintaanId = null;
      for (final c in [_judul, _isi, _gambar, _konten]) { c.clear(); }
      await _muat();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_edukasi ? 'Edukasi berhasil diterbitkan.' : 'Notifikasi terkirim ke semua pengguna.')));
    } catch (e) { if (mounted) setState(() => _galat = e.toString()); }
    finally { if (mounted) setState(() => _mengirim = false); }
  }
  Future<void> _hapus(Map<String, dynamic> article) async {
    final ya = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Hapus edukasi?'), content: Text('${article['judul']}'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus'))]));
    if (ya != true || !mounted) return;
    setState(() => _mengirim = true);
    try { await widget.store.hapusEdukasi(article['id'] as String); await _muat(); }
    catch (e) { if (mounted) setState(() => _galat = e.toString()); }
    finally { if (mounted) setState(() => _mengirim = false); }
  }
  @override
  Widget build(BuildContext context) {
    if (!widget.store.adalahAdmin) return const Center(child: Text('Akses khusus admin.'));
    return RefreshIndicator(onRefresh: _muat, color: sage, child: ListView(padding: const EdgeInsets.all(20), physics: const AlwaysScrollableScrollPhysics(), children: [
      Glass(child: Row(children: [const Icon(Icons.admin_panel_settings_outlined, color: sage, size: 35), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [serif('Ruang pengelola', size: 27), Text('$_daftarPengguna pengguna • kabar dan pengetahuan', style: const TextStyle(color: muted, fontSize: 11))]))])),
      const SizedBox(height: 20),
      LeafButton('Scan QR pengguna • tambah poin', icon: Icons.qr_code_scanner, onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => Scaffold(backgroundColor: forestDeep, appBar: AppBar(title: const Text('Tambah poin pengguna')), body: AdminQrPage(store: widget.store))))),
      const SizedBox(height: 20),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, icon: Icon(Icons.campaign_outlined), label: Text('Notifikasi')), ButtonSegment(value: true, icon: Icon(Icons.menu_book_outlined), label: Text('Edukasi'))], selected: {_edukasi}, onSelectionChanged: _mengirim ? null : (v) => setState(() { _edukasi = v.first; _formulir.currentState?.reset(); _galat = null; })),
      const SizedBox(height: 20),
      if (_memuat) const LinearProgressIndicator(color: sage) else Form(key: _formulir, child: Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        serif(_edukasi ? 'Bagikan pengetahuan.' : 'Sampaikan kabar baik.', size: 27),
        const SizedBox(height: 10),
        if (!_edukasi) const Text('Penerima: semua pengguna', style: TextStyle(color: sage, fontSize: 12)),
        const SizedBox(height: 14),
        TextFormField(controller: _judul, maxLength: _edukasi ? 180 : 100, decoration: const InputDecoration(labelText: 'Judul'), validator: (v) => _wajib(v, 3)),
        TextFormField(controller: _isi, minLines: 3, maxLines: 5, maxLength: _edukasi ? 500 : 2000, decoration: InputDecoration(labelText: _edukasi ? 'Ringkasan' : 'Isi notifikasi', alignLabelWithHint: true), validator: (v) => _wajib(v, 3)),
        if (_edukasi) ...[
          TextFormField(controller: _kategori, maxLength: 60, decoration: const InputDecoration(labelText: 'Kategori'), validator: (v) => _wajib(v, 2)),
          TextFormField(controller: _konten, minLines: 8, maxLines: 18, maxLength: 30000, decoration: const InputDecoration(labelText: 'Isi artikel', helperText: 'Bisa memakai judul, daftar, dan teks tebal Markdown.', alignLabelWithHint: true), validator: (v) => _wajib(v, 20)),
        ],
        const SizedBox(height: 10),
        TextFormField(controller: _gambar, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'URL gambar HTTPS (opsional)', prefixIcon: Icon(Icons.image_outlined)), validator: _gambarValidator),
        const SizedBox(height: 20),
        LeafButton(_mengirim ? 'Menyimpan…' : _edukasi ? 'Terbitkan edukasi' : 'Kirim ke semua pengguna', onTap: _mengirim ? null : _kirim, icon: _edukasi ? Icons.publish_outlined : Icons.send_rounded),
      ]))),
      if (_galat != null) Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(_galat!, style: const TextStyle(color: terracotta))),
      const SizedBox(height: 25),
      serif(_edukasi ? 'Edukasi terbit' : 'Notifikasi terkirim', size: 25),
      const SizedBox(height: 12),
      if ((_edukasi ? _daftarArtikel : _riwayat).isEmpty) const Glass(child: Text('Belum ada konten.')),
      for (final catatan in (_edukasi ? _daftarArtikel : _riwayat)) Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${catatan['judul'] ?? catatan['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text('${catatan['desk'] ?? catatan['body'] ?? ''}', style: const TextStyle(color: muted, height: 1.5, fontSize: 12)),
        const SizedBox(height: 8), Text(notificationTime(catatan['createdAt']), style: const TextStyle(color: sage, fontSize: 10)),
        if (_edukasi) TextButton.icon(onPressed: _mengirim ? null : () => _hapus(catatan), icon: const Icon(Icons.delete_outline, size: 17), label: const Text('Hapus edukasi')),
      ]))),
    ]));
  }
}
