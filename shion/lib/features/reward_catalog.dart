// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../core/system_log.dart';
import '../ui/forest.dart';

class RewardCatalog extends StatefulWidget {
  const RewardCatalog({
    super.key,
    required this.store,
    required this.onChanged,
  });
  final ApiStore store;
  final VoidCallback onChanged;
  @override
  State<RewardCatalog> createState() => _hadiahCatalogKeadaan();
}

class _hadiahCatalogKeadaan extends State<RewardCatalog> {
  bool sibuk = false;
  final Map<String, String> _permintaanIds = {};
  Future<void> tukar(Map<String, dynamic> reward) async {
    if (sibuk) return;
    final disetujui = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tukar Green Point'),
        content: Text(
          '${reward['title']}\n${reward['cost']} poin akan digunakan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
    if (disetujui != true || !mounted) return;
    setState(() => sibuk = true);
    try {
      final idHadiah = reward['id'] as String;
      final idPermintaan = _permintaanIds.putIfAbsent(idHadiah, ApiClient.buatIdPermintaan);
      final kode = await widget.store.tukarHadiah(idHadiah, idPermintaan);
      _permintaanIds.remove(idHadiah);
      if (!mounted) return;
      widget.onChanged();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Voucher Tersimpan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: sage,
                size: 55,
              ),
              const SizedBox(height: 18),
              Text('${reward['title']}'),
              const SizedBox(height: 16),
              SelectableText(
                kode,
                style: const TextStyle(fontSize: 22, letterSpacing: 2),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (e) {
      SystemLog.add('reward', e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penukaran belum berhasil. Periksa saldo poinmu.'),
          ),
        );
    } finally {
      if (mounted) setState(() => sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      serif('Pilihan Reward', size: 28),
      const SizedBox(height: 14),
      ...widget.store.katalogHadiah.map(
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: PhotoPanel(
            photo: r['photo'] as String,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                serif(r['title'] as String, size: 24),
                const SizedBox(height: 28),
                LeafButton(
                  '${r['cost']} poin • Tukar',
                  icon: Icons.arrow_forward,
                  onTap: sibuk || widget.store.poin < (r['cost'] as int)
                      ? null
                      : () => tukar(r),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      serif('Voucher Saya', size: 26),
      const SizedBox(height: 12),
      if (widget.store.ambilDaftar('vouchers').isEmpty)
        const Glass(
          child: Text(
            'Voucher yang kamu tukar akan tersimpan di sini.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
      ...widget.store
          .ambilDaftar('vouchers')
          .map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${v['title']}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            '${v['kode']}',
                            style: const TextStyle(
                              color: sage,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Salin kode',
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: '${v['kode']}'),
                          ),
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    ],
  );
}
