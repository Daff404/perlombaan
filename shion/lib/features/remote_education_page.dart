// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../ui/forest.dart';
import '../ui/rich_answer.dart';

class RemoteEducationPage extends StatefulWidget {
  const RemoteEducationPage({super.key, required this.store, this.initialQuery = ''});
  final ApiStore store;
  final String initialQuery;
  @override
  State<RemoteEducationPage> createState() => _remoteEdukasiHalamanKeadaan();
}
class _remoteEdukasiHalamanKeadaan extends State<RemoteEducationPage> {
  List<Map<String, dynamic>> _daftarArtikel = [];
  String _kueri = '', _kategori = 'Semua';
  String? _galat;
  bool _memuat = true;
  @override
  void initState() { super.initState(); _kueri = widget.initialQuery; _muat(); }
  Future<void> _muat() async {
    try {
      final data = await widget.store.edukasi();
      if (mounted) setState(() { _daftarArtikel = (data['articles'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(); _galat = null; });
    } catch (e) { if (mounted) setState(() => _galat = e.toString()); }
    finally { if (mounted) setState(() => _memuat = false); }
  }
  void _buka(Map<String, dynamic> artikel) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => ForestPage(child: Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)), Expanded(child: serif('Edukasi', size: 27))])),
    Expanded(child: ListView(padding: const EdgeInsets.all(22), children: [
      _ilustrasi(artikel, height: 220), const SizedBox(height: 22),
      serif('${artikel['judul']}', size: 32), const SizedBox(height: 10),
      Text('${artikel['kategori']} • ${artikel['sumber'] ?? 'Tim SHION'}', style: const TextStyle(color: sage, fontSize: 11)), const SizedBox(height: 20),
      Glass(child: RichAnswer('${artikel['konten'] ?? artikel['desk']}')),
    ])),
  ]))));
  Widget _ilustrasi(Map<String, dynamic> artikel, {double height = 170}) => ClipRRect(borderRadius: BorderRadius.circular(22), child: artikel['gambar'] is String && (artikel['gambar'] as String).isNotEmpty
    ? SizedBox(height: height, width: double.infinity, child: RemotePhoto(artikel['gambar'] as String))
    : LayoutBuilder(builder: (context, box) => VectorArtwork(asset: 'assets/vector/eco_education.png', width: box.maxWidth, height: height, background: surfaceLow)));
  @override
  Widget build(BuildContext context) {
    final daftarKategori = ['Semua', ..._daftarArtikel.map((e) => '${e['kategori']}').toSet()];
    final cocok = _daftarArtikel.where((e) => (_kategori == 'Semua' || e['kategori'] == _kategori) && '${e['judul']} ${e['desk']}'.toLowerCase().contains(_kueri.toLowerCase())).toList();
    return RefreshIndicator(onRefresh: _muat, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(22), children: [
      serif('Kenali. Pilah. Rawat.', size: 32), const SizedBox(height: 9), const Text('Pengetahuan pilihan dari tim SHION.', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 20), TextField(decoration: const InputDecoration(hintText: 'Cari edukasi…', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => _kueri = v)),
      const SizedBox(height: 13), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: daftarKategori.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c), selected: c == _kategori, onSelected: (_) => setState(() => _kategori = c)))).toList())),
      const SizedBox(height: 16),
      if (_memuat) const LinearProgressIndicator(color: sage),
      if (_galat != null) Column(children: [Text(_galat!, style: const TextStyle(color: terracotta)), TextButton(onPressed: _muat, child: const Text('Coba lagi'))]),
      if (!_memuat && cocok.isEmpty && _galat == null) const Glass(child: Text('Belum ada artikel yang cocok.')),
      for (final artikel in cocok) Padding(padding: const EdgeInsets.only(bottom: 17), child: Glass(onTap: () => _buka(artikel), padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ilustrasi(artikel), Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${artikel['sumber'] ?? 'Tim SHION'} • ${artikel['kategori']}', style: const TextStyle(color: sage, fontSize: 10)), const SizedBox(height: 9),
          serif('${artikel['judul']}', size: 25), const SizedBox(height: 10), Text('${artikel['desk']}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, height: 1.6, fontSize: 12)),
          const SizedBox(height: 12), const Row(children: [Text('Baca selengkapnya', style: TextStyle(color: sage, fontSize: 11)), Spacer(), Icon(Icons.arrow_forward, color: sage, size: 18)]),
        ])),
      ]))),
    ]));
  }
}
