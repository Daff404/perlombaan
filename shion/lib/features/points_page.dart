// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../core/system_log.dart';
import 'reward_catalog.dart';
import '../settings.dart';
import '../ui/forest.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key, required this.store, required this.onChanged});
  final ApiStore store;
  final VoidCallback onChanged;
  @override
  State<PointsPage> createState() => _poinHalamanKeadaan();
}

class _poinHalamanKeadaan extends State<PointsPage> {
  bool _sibuk = false;
  String? _panduanPermintaanId;

  Future<void> _tukar() async {
    if (_sibuk || widget.store.poin < Settings.guideCost) return;
    final berhasil = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Panduan Personal?'),
        content: Text(
          '${Settings.guideCost} poin akan digunakan setelah panduan berhasil dibuat. Ringkasan riwayat jenis sampah dipakai untuk menyusun panduan, tanpa foto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buat Panduan'),
          ),
        ],
      ),
    );
    if (berhasil != true || !mounted) return;
    setState(() => _sibuk = true);
    try {
      _panduanPermintaanId ??= ApiClient.buatIdPermintaan();
      final panduan = await widget.store.buatPanduan(_panduanPermintaanId!);
      _panduanPermintaanId = null;
      if (mounted) {
        setState(() {});
        widget.onChanged();
        _tampilkanPanduan(panduan);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(SystemLog.failure('guide', e))));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  void _tampilkanPanduan(String text) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surface,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      minChildSize: .4,
      maxChildSize: .94,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            serif('Panduan Pilah Personal', size: 29),
            const SizedBox(height: 20),
            SelectableText(
              text,
              style: const TextStyle(height: 1.8, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final bukuPoin = widget.store.ambilDaftar('ledger');
    final daftarPanduan = widget.store.ambilDaftar('guides');
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 5, 22, 25),
      children: [
        Glass(
          child: Row(
            children: [
              const BrandGlyph('leaf', size: 55),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Green Point',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  metric('${widget.store.poin}', size: 42),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Dapatkan ${Settings.pointsPerScan} poin untuk setiap foto sampah baru yang dikenali AI. Batas ${Settings.rewardedScansPerDay} scan berpoin per hari; foto duplikat tidak menambah saldo.',
          style: const TextStyle(color: muted, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 24),
        RewardCatalog(
          store: widget.store,
          onChanged: () {
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 24),
        serif('Panduan Personal', size: 25),
        const SizedBox(height: 13),
        PhotoPanel(
          photo: Photos.reuse,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              serif('Panduan Pilah Personal', size: 25),
              const SizedBox(height: 10),
              const Text(
                'SHION menyusun rencana 7 hari berdasarkan jenis sampah yang sudah kamu pindai. Panduan tersimpan dan bisa dibaca kembali.',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 18),
              LeafButton(
                _sibuk
                    ? 'Membuat Panduan…'
                    : '${Settings.guideCost} poin • Buat Panduan',
                icon: Icons.auto_awesome_outlined,
                onTap: _sibuk || widget.store.poin < Settings.guideCost
                    ? null
                    : _tukar,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Setorkan sampah terpilah, kumpulkan Green Point, lalu pilih reward favoritmu.',
          style: TextStyle(color: muted, fontSize: 10, height: 1.5),
        ),
        const SizedBox(height: 25),
        serif('Panduan Tersimpan', size: 24),
        const SizedBox(height: 12),
        if (daftarPanduan.isEmpty)
          const Glass(
            child: Text(
              'Panduan yang dibuat akan muncul di sini.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ...daftarPanduan.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Glass(
              onTap: () => _tampilkanPanduan(g['text'] as String),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: sage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Panduan ${'${g['createdAt']}'.split('T').first}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        serif('Riwayat Transaksi', size: 24),
        const SizedBox(height: 13),
        if (bukuPoin.isEmpty)
          const Glass(
            child: Text(
              'Belum ada transaksi poin.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ...bukuPoin.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Glass(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(
                    (r['delta'] as num) > 0
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    color: sage,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['description']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${r['createdAt']}'.split('T').first,
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(r['delta'] as num) > 0 ? '+' : ''}${r['delta']}',
                    style: const TextStyle(
                      color: sage,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
