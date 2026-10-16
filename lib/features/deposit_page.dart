import 'package:flutter/material.dart';
import '../core/local_store.dart';
import '../core/system_log.dart';
import '../ui/forest.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key, required this.store, required this.onSaved});
  final LocalStore store;
  final VoidCallback onSaved;
  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final amount = TextEditingController(), destination = TextEditingController();
  String category = 'Plastik';
  bool busy = false;
  @override
  void dispose() {
    amount.dispose();
    destination.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    final kg = double.tryParse(amount.text.trim().replaceAll(',', '.'));
    if (kg == null ||
        !kg.isFinite ||
        kg <= 0 ||
        kg > 1000 ||
        destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi berat 0–1.000 kg dan nama tempat setor.'),
        ),
      );
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Setoran'),
        content: Text(
          '$category • $kg kg\n${destination.text.trim()}\n\nLanjutkan pencatatan setoran dan penambahan poin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.store.confirmDeposit(
        category: category,
        kg: kg,
        destination: destination.text,
      );
      widget.onSaved();
      amount.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setoran tercatat. Green Point bertambah.'),
          ),
        );
      }
    } catch (e) {
      SystemLog.add('deposit', e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran belum tersimpan. Coba lagi.')),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      PhotoPanel(
        photo: Photos.recycle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.recycling, size: 42, color: sage),
            const SizedBox(height: 15),
            serif('Kembalikan nilainya.', size: 34),
            const SizedBox(height: 12),
            const Text(
              'Pilah, timbang, lalu catat setoranmu.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Glass(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Jenis sampah'),
              items: [
                'Plastik',
                'Kertas',
                'Organik',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Berat bersih (kg)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: destination,
              decoration: const InputDecoration(
                labelText: 'Nama bank sampah / tempat setor',
              ),
            ),
            const SizedBox(height: 18),
            LeafButton(
              busy ? 'Menyimpan…' : 'Konfirmasi Setoran',
              icon: Icons.check_circle_outline,
              onTap: busy ? null : save,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      serif('Setoran Terakhir', size: 27),
      const SizedBox(height: 12),
      if (widget.store.getList('deposits').isEmpty)
        const Glass(child: Text('Belum ada setoran.')),
      ...widget.store
          .getList('deposits')
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Glass(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.recycling, color: sage),
                  title: Text('${r['category']} • ${r['estimatedKg']} kg'),
                  subtitle: Text('${r['destination']}'),
                  trailing: Text(
                    '+${r['points'] ?? 0}',
                    style: const TextStyle(color: sage),
                  ),
                ),
              ),
            ),
          ),
    ],
  );
}
