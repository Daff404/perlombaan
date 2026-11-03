// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../core/system_log.dart';
import '../ui/forest.dart';

class CarbonPage extends StatefulWidget {
  const CarbonPage({super.key, required this.store, required this.onSaved});
  final ApiStore store;
  final VoidCallback onSaved;
  @override
  State<CarbonPage> createState() => _karbonHalamanKeadaan();
}

class _karbonHalamanKeadaan extends State<CarbonPage> {
  static const faktorEmisi = {
    'Jalan kaki': 0.0,
    'Sepeda': 0.0,
    'Sepeda motor': .10,
    'Mobil': .17,
    'Transportasi umum': .08,
    'Listrik': .85,
  };
  final nilaiJumlah = TextEditingController(),
      masukanFaktor = TextEditingController(text: '0');
  String aktivitas = 'Jalan kaki';
  bool sibuk = false;
  @override
  void dispose() {
    nilaiJumlah.dispose();
    masukanFaktor.dispose();
    super.dispose();
  }

  double angka(String s) =>
      double.tryParse(s.replaceAll(',', '.')) ?? double.nan;
  Future<void> simpan() async {
    if (sibuk) return;
    final jumlah = angka(nilaiJumlah.text), emisi = angka(masukanFaktor.text);
    if (!jumlah.isFinite ||
        jumlah <= 0 ||
        jumlah > 100000 ||
        !emisi.isFinite ||
        emisi < 0 ||
        emisi > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi jumlah dan faktor emisi yang valid.'),
        ),
      );
      return;
    }
    setState(() => sibuk = true);
    try {
      await widget.store.tambahCatatan('activities', {
        'activity': aktivitas,
        'amount': jumlah,
        'unit': aktivitas == 'Listrik' ? 'kWh' : 'km',
        'factor': emisi,
        'co2Kg': jumlah * emisi,
        'factorSource': 'Asumsi pengguna',
      });
      if (!mounted) return;
      nilaiJumlah.clear();
      widget.onSaved();
      if (mounted) setState(() {});
    } catch (e) {
      SystemLog.add('carbon', e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan belum tersimpan.')),
        );
    } finally {
      if (mounted) setState(() => sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riwayatAktivitas = widget.store.ambilDaftar('activities');
    final hariIni = DateTime.now().toIso8601String().split('T').first;
    final total = riwayatAktivitas
        .where((r) => '${r['createdAt']}'.startsWith(hariIni))
        .fold<double>(0, (a, r) => a + (r['co2Kg'] as num? ?? 0).toDouble());
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xff173b2c),
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
                initialValue: aktivitas,
                decoration: const InputDecoration(labelText: 'Aktivitas'),
                items: faktorEmisi.keys
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() {
                  aktivitas = v!;
                  masukanFaktor.text = '${faktorEmisi[v]}';
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nilaiJumlah,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: aktivitas == 'Listrik'
                      ? 'Pemakaian (kWh)'
                      : 'Jarak (km)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: masukanFaktor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'Faktor kg CO₂e/${aktivitas == 'Listrik' ? 'kWh' : 'km'}',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Faktor awal merupakan asumsi yang bisa kamu ubah. Estimasi = jumlah × faktor; bukan pengukuran emisi. Jalan kaki/sepeda dihitung tanpa emisi operasional langsung.',
                style: TextStyle(fontSize: 10, height: 1.6, color: muted),
              ),
              const SizedBox(height: 18),
              LeafButton('Simpan Catatan', onTap: sibuk ? null : simpan),
            ],
          ),
        ),
        const SizedBox(height: 24),
        serif('Catatan Perjalanan', size: 27),
        const SizedBox(height: 12),
        ...riwayatAktivitas.map(
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
