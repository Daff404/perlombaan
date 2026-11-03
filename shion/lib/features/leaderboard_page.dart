// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../ui/forest.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<LeaderboardPage> createState() => _papanPeringkatHalamanKeadaan();
}

class _papanPeringkatHalamanKeadaan extends State<LeaderboardPage> {
  static const buttonGreen = Color(0xff009d20);
  String _metrik = 'points';
  Map<String, dynamic>? _data;
  String? _galat;
  bool _memuat = true;
  int _generasi = 0;
  @override
  void initState() { super.initState(); _muat(); }
  Future<void> _muat() async {
    final generasi = ++_generasi;
    setState(() { _memuat = true; _galat = null; });
    try {
      final hasil = await widget.store.papanPeringkat(_metrik);
      if (mounted && generasi == _generasi) setState(() => _data = hasil);
    } catch (error) {
      if (mounted && generasi == _generasi) setState(() => _galat = error.toString());
    } finally {
      if (mounted && generasi == _generasi) setState(() => _memuat = false);
    }
  }
  String _skor(Map baris) => '${baris[_metric] ?? 0} ${_metrik == 'poin' ? 'poin' : 'setoran'}';
  @override
  Widget build(BuildContext context) {
    final daftarBaris = (_data?['rows'] as List? ?? []).whereType<Map>().toList();
    final podium = daftarBaris.where((r) => (r[_metrik] as num? ?? 0) > 0).take(3).toList();
    final saya = _data?['me'] as Map?;
    return RefreshIndicator(
      color: sage, onRefresh: _muat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 5, 22, 26),
        children: [
          const Text('JEJAK BAIK BERSAMA', style: TextStyle(color: sage, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          serif('Langkah kecil,\ndampak bersama.', size: 31),
          const SizedBox(height: 10),
          const Text('Lihat kontribusi komunitas SHION. Peringkat dihitung dari seluruh riwayat akun.', style: TextStyle(color: muted, height: 1.6, fontSize: 12)),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'points', label: Text('Poin tertinggi'), icon: Icon(Icons.eco_outlined, size: 17)),
              ButtonSegment(value: 'deposits', label: Text('Setoran terbanyak'), icon: Icon(Icons.recycling, size: 17)),
            ],
            selected: {_metrik},
            style: SegmentedButton.styleFrom(selectedBackgroundColor: buttonGreen, selectedForegroundColor: Colors.white, textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13)),
            onSelectionChanged: (selected) { setState(() { _metrik = selected.first; _data = null; }); _muat(); },
          ),
          const SizedBox(height: 18),
          if (_memuat) const Padding(padding: EdgeInsets.all(35), child: Center(child: CircularProgressIndicator(color: buttonGreen)))
          else if (_galat != null) Glass(child: Column(children: [
            Text(_galat!, textAlign: TextAlign.center),
            const SizedBox(height: 15),
            LeafButton('Coba lagi', onTap: _muat, icon: Icons.refresh),
          ]))
          else ...[
            if (podium.isNotEmpty) _podium(podium)
            else Glass(child: Column(children: [
              const VectorArtwork(asset: 'assets/vector/plant_a_seedling.png', width: 180, height: 140),
              const SizedBox(height: 12),
              serif('Mulai dari langkahmu.', size: 24, align: TextAlign.center),
              const SizedBox(height: 8),
              Text(_metrik == 'points' ? 'Poin komunitas akan muncul setelah scan dan setoran tercatat.' : 'Setoran komunitas akan muncul setelah pencatatan pertama.', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
            ])),
            const SizedBox(height: 22),
            Row(children: [Expanded(child: serif('Papan komunitas', size: 23)), Text('${_data?['totalUsers'] ?? 0} pengguna', style: const TextStyle(color: muted, fontSize: 10))]),
            const SizedBox(height: 7),
            Text(_metrik == 'points' ? 'Total poin diperoleh; penukaran tidak mengurangi peringkat.' : 'Jumlah setoran tercatat. Berat kg dan jumlah satuan ditampilkan terpisah.', style: const TextStyle(color: muted, fontSize: 10, height: 1.5)),
            const SizedBox(height: 14),
            for (final baris in daftarBaris) Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: baris['isMe'] == true ? const Color(0xff174a27) : surfaceLow, borderRadius: BorderRadius.circular(17), border: Border.all(color: baris['isMe'] == true ? buttonGreen : const Color(0xff345340))),
                child: Row(children: [
                  SizedBox(width: 27, child: Text('${baris['rank']}', style: const TextStyle(color: sage, fontWeight: FontWeight.w800))),
                  _avatar(baris, 35),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${baris['nama']}${baris['isMe'] == true ? ' (Kamu)' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(_metrik == 'points' ? '${baris['deposits']} setoran tercatat' : '${(row['totalKg'] as num? ?? 0).toStringAsFixed(1)} kg • ${baris['totalUnits']} satuan', style: const TextStyle(color: muted, fontSize: 10)),
                  ])),
                  const SizedBox(width: 6),
                  Text(_skor(baris), style: const TextStyle(fontSize: 11, color: sage, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            if (daftarBaris.isEmpty) const Glass(child: Text('Belum ada pengguna di papan komunitas.')),
            if (saya != null) ...[
              const SizedBox(height: 14),
              Glass(child: Row(children: [
                const Icon(Icons.person_pin_circle_outlined, color: sage, size: 29),
                const SizedBox(width: 12),
                Expanded(child: Text('Posisimu #${saya['rank']}\n${_skor(me)}', style: const TextStyle(fontSize: 12, height: 1.5))),
                const Icon(Icons.eco_outlined, color: sage),
              ])),
            ],
            const SizedBox(height: 12),
            const Text('Nilai yang sama mendapat peringkat sama. Menampilkan hingga 100 pengguna. Setoran merupakan catatan pengguna, belum merupakan verifikasi bank sampah.', style: TextStyle(color: muted, fontSize: 10, height: 1.5)),
          ],
        ],
      ),
    );
  }
  Widget _avatar(Map baris, double size) {
    final nama = (baris['name'] as String? ?? '').trim();
    return Container(width: size, height: size, alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xff009d20)),
      child: Text(nama.isEmpty ? 'S' : nama.characters.first.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: size * .38, fontWeight: FontWeight.w800)));
  }
  Widget _podium(List<Map> winners) => Container(
    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
    decoration: BoxDecoration(
      color: const Color(0xff102f24),
      border: Border.all(color: const Color(0xff4a714b)), borderRadius: BorderRadius.circular(25),
    ),
    child: SizedBox(height: 350, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: winners.length > 1 ? _langkah(winners[1], 85, false) : const SizedBox()),
      Expanded(child: _langkah(winners[0], 115, true)),
      Expanded(child: winners.length > 2 ? _langkah(winners[2], 70, false) : const SizedBox()),
    ])),
  );
  Widget _langkah(Map baris, double height, bool first) => Column(mainAxisAlignment: MainAxisAlignment.end, children: [
    if (first) const Icon(Icons.workspace_premium_outlined, color: Color(0xffe5c878), size: 22),
    _avatar(baris, first ? 44 : 37),
    const SizedBox(height: 7),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text('${baris['nama']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
    const SizedBox(height: 7),
    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), decoration: BoxDecoration(color: first ? const Color(0xffedcd87) : const Color(0xffbddda1), borderRadius: BorderRadius.circular(20)), child: Text(_skor(baris), style: const TextStyle(color: forestDeep, fontSize: 9, fontWeight: FontWeight.w800))),
    const SizedBox(height: 6),
    Container(height: height, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: first ? const Color(0xff009d20) : const Color(0xff087d1a), borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
      child: Padding(padding: const EdgeInsets.only(top: 15), child: Text('${baris['rank']}', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xffe2f4cd), fontFamily: 'Fraunces', fontSize: first ? 52 : 43))),
    ),
  ]);
}
