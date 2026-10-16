import 'package:flutter/material.dart';
import '../core/local_store.dart';
import '../core/system_log.dart';
import '../ui/forest.dart';

class CarbonPage extends StatefulWidget {
  const CarbonPage({super.key, required this.store, required this.onSaved});
  final LocalStore store;
  final VoidCallback onSaved;
  @override
  State<CarbonPage> createState() => _CarbonPageState();
}

class _CarbonPageState extends State<CarbonPage> {
  static const factors = {
    'Jalan kaki': 0.0,
    'Sepeda': 0.0,
    'Sepeda motor': .10,
    'Mobil': .17,
    'Transportasi umum': .08,
    'Listrik': .85,
  };
  final amount = TextEditingController(),
      factor = TextEditingController(text: '0');
  String activity = 'Jalan kaki';
  bool busy = false;
  @override
  void dispose() {
    amount.dispose();
    factor.dispose();
    super.dispose();
  }

  double number(String s) =>
      double.tryParse(s.replaceAll(',', '.')) ?? double.nan;
  Future<void> save() async {
    if (busy) return;
    final value = number(amount.text), emission = number(factor.text);
    if (!value.isFinite ||
        value <= 0 ||
        value > 100000 ||
        !emission.isFinite ||
        emission < 0 ||
        emission > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi jumlah dan faktor emisi yang valid.'),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await widget.store.addRecord('activities', {
        'activity': activity,
        'amount': value,
        'unit': activity == 'Listrik' ? 'kWh' : 'km',
        'factor': emission,
        'co2Kg': value * emission,
        'factorSource': 'Asumsi pengguna',
      });
      amount.clear();
      widget.onSaved();
      if (mounted) setState(() {});
    } catch (e) {
      SystemLog.add('carbon', e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan belum tersimpan.')),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.store.getList('activities');
    final today = DateTime.now().toIso8601String().split('T').first;
    final total = rows
        .where((r) => '${r['createdAt']}'.startsWith(today))
        .fold<double>(0, (a, r) => a + (r['co2Kg'] as num? ?? 0).toDouble());
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xffe0e7ca),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              const Text(
                'JEJAK HARI INI',
                style: TextStyle(color: forest, letterSpacing: 3, fontSize: 11),
              ),
              const SizedBox(height: 20),
              Container(
                width: 185,
                height: 185,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 10, color: const Color(0xff6c874c)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.spa_outlined, color: forest),
                    Text(
                      total.toStringAsFixed(2),
                      style: const TextStyle(
                        color: forest,
                        fontFamily: 'Fraunces',
                        fontSize: 40,
                      ),
                    ),
                    const Text(
                      'kg CO₂e • estimasi',
                      style: TextStyle(color: forest, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pahami kebiasaanmu, kurangi dampaknya.',
                style: TextStyle(color: forest, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Glass(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: activity,
                decoration: const InputDecoration(labelText: 'Aktivitas'),
                items: factors.keys
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  activity = v!;
                  factor.text = '${factors[v]}';
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: activity == 'Listrik'
                      ? 'Pemakaian (kWh)'
                      : 'Jarak (km)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: factor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'Faktor kg CO₂e/${activity == 'Listrik' ? 'kWh' : 'km'}',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Faktor awal merupakan asumsi yang bisa kamu ubah. Estimasi = jumlah × faktor; bukan pengukuran emisi. Jalan kaki/sepeda dihitung tanpa emisi operasional langsung.',
                style: TextStyle(fontSize: 10, height: 1.6, color: muted),
              ),
              const SizedBox(height: 18),
              LeafButton('Simpan Catatan', onTap: busy ? null : save),
            ],
          ),
        ),
        const SizedBox(height: 24),
        serif('Catatan Perjalanan', size: 27),
        const SizedBox(height: 12),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Glass(
              child: Row(
                children: [
                  const Icon(Icons.eco_outlined, color: sage),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${r['activity']} • ${r['amount']} ${r['unit']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    r['co2Kg'] == null
                        ? '—'
                        : '${(r['co2Kg'] as num).toStringAsFixed(2)} kg',
                    style: const TextStyle(color: sage),
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
