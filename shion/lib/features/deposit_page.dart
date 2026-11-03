// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../core/system_log.dart';
import '../ui/forest.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key, required this.store, required this.onSaved, required this.onScan});
  final ApiStore store;
  final VoidCallback onSaved, onScan;
  @override
  State<DepositPage> createState() => _setoranHalamanKeadaan();
}

class _setoranHalamanKeadaan extends State<DepositPage> {
  final nilaiJumlah = TextEditingController(), tujuan = TextEditingController();
  String satuan = 'kg';
  String? kategoriTerpilih;
  bool sibuk = false;
  String? _setoranPermintaanId;
  String? _setoranTandatangan;
  static const kategoriDidukung = {'Plastik', 'Kertas', 'Organik'};

  @override
  void initState() {
    super.initState();
    final tersedia = kategoriTersedia;
    if (tersedia.isNotEmpty) kategoriTerpilih = tersedia.first;
  }

  @override
  void dispose() {
    nilaiJumlah.dispose();
    tujuan.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get kandidatPindai {
    final daftarKandidat = <Map<String, dynamic>>[];
    for (final pindai in widget.store.ambilDaftar('scans')) {
      if (pindai['isWaste'] == true && (pindai['confidence'] as num? ?? 0) >= .65 && pindai['depositedAt'] == null && pindai['duplicate'] != true && kategoriDidukung.contains(pindai['category'])) {
        daftarKandidat.add(pindai);
      }
    }
    return daftarKandidat;
  }

  List<String> get kategoriTersedia => kandidatPindai
      .map((pindai) => pindai['category'] as String)
      .toSet()
      .toList();

  Map<String, dynamic>? get pindaiTerpilih {
    for (final pindai in kandidatPindai) {
      if (pindai['category'] == kategoriTerpilih) return pindai;
    }
    return null;
  }

  Future<void> simpan() async {
    if (sibuk) return;
    final kuantitas = double.tryParse(nilaiJumlah.text.trim().replaceAll(',', '.'));
    final kategori = kategoriTerpilih;
    if (kategori == null || !kategoriTersedia.contains(kategori)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pindai sampah terlebih dahulu agar kategorinya terisi otomatis.'),
      ));
      return;
    }
    if (kuantitas == null || !kuantitas.isFinite || kuantitas <= 0 || kuantitas > 1000 || (satuan == 'satuan' && kuantitas % 1 != 0) || tujuan.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Isi ${satuan == 'kg' ? 'berat 0–1.000 kg' : 'jumlah 1–1.000 satuan'} dan nama tempat setor.'),
      ));
      return;
    }
    final labelSatuan = satuan == 'kg' ? 'kg' : 'satuan';
    final disetujui = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Setoran'),
        content: Text('$kategori • $kuantitas $labelSatuan\n${tujuan.text.trim()}\n\nSatu hasil scan hanya dapat dipakai untuk satu setoran. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Konfirmasi')),
        ],
      ),
    );
    if (disetujui != true || !mounted) return;
    setState(() => sibuk = true);
    try {
      final idPindai = pindaiTerpilih!['id'] as String;
      final tandaTangan = '$idPindai|$kuantitas|$satuan|${tujuan.text.trim()}';
      if (_setoranTandatangan != tandaTangan) { _setoranTandatangan = tandaTangan; _setoranPermintaanId = ApiClient.buatIdPermintaan(); }
      await widget.store.konfirmasiSetoran(category: kategori, scanId: idPindai, kg: kuantitas, unit: satuan, destination: tujuan.text, requestId: _setoranPermintaanId!);
      if (!mounted) return;
      _setoranPermintaanId = null;
      _setoranTandatangan = null;
      final tersedia = kategoriTersedia;
      kategoriTerpilih = tersedia.isEmpty ? null : tersedia.first;
      widget.onSaved();
      nilaiJumlah.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setoran tercatat. Green Point bertambah.')));
      }
    } catch (e) {
      SystemLog.add('deposit', e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setoran belum tersimpan. Coba lagi.')));
    } finally {
      if (mounted) setState(() => sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daftarPindai = kandidatPindai;
    final daftarKategori = kategoriTersedia;
    final pindai = pindaiTerpilih;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        PhotoPanel(
          photo: Photos.recycle,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.recycling, size: 42, color: sage),
            const SizedBox(height: 15),
            serif('Kembalikan nilainya.', size: 34),
            const SizedBox(height: 12),
            const Text('Pilah, timbang, lalu catat setoranmu.', style: TextStyle(color: muted)),
          ]),
        ),
        const SizedBox(height: 18),
        Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: sage),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kategori dari scan AI', style: TextStyle(color: muted, fontSize: 11)),
              const SizedBox(height: 3),
              Text(daftarPindai.isEmpty ? 'Pindai sampah sebelum mencatat setoran' : '${daftarKategori.length} kategori tersedia dari hasil scan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ])),
            IconButton(onPressed: widget.onScan, tooltip: 'Pindai sampah', icon: const Icon(Icons.document_scanner_outlined, color: sage)),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('category-$kategoriTerpilih-${daftarKategori.join(',')}'),
            initialValue: daftarKategori.contains(kategoriTerpilih) ? kategoriTerpilih : null,
            decoration: const InputDecoration(labelText: 'Pilih kategori hasil scan'),
            items: daftarKategori.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: daftarKategori.isEmpty ? null : (value) => setState(() => kategoriTerpilih = value),
          ),
          if (daftarKategori.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: const Color(0xffedf3e6), borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xff16452e)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Kategori berasal dari scan AI akunmu yang belum digunakan untuk setoran. Pindai satu benda sebelum mencatat setoran baru.', style: TextStyle(color: Color(0xff16452e), fontSize: 11, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 10),
            LeafButton('Pindai sampah sekarang', icon: Icons.document_scanner_outlined, onTap: widget.onScan),
          ] else if (pindai?['name'] is String) ...[
            const SizedBox(height: 8),
            Text('Objek terdeteksi: ${pindai!['name']}', style: const TextStyle(color: muted, fontSize: 11)),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: satuan,
            decoration: const InputDecoration(labelText: 'Satuan setoran'),
            items: const [DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')), DropdownMenuItem(value: 'satuan', child: Text('Satuan (pcs)'))],
            onChanged: daftarKategori.isEmpty ? null : (value) { if (value != null) setState(() => satuan = value); },
          ),
          const SizedBox(height: 14),
          TextField(enabled: daftarKategori.isNotEmpty, controller: nilaiJumlah, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: satuan == 'kg' ? 'Berat bersih (kg)' : 'Jumlah satuan (pcs)')),
          const SizedBox(height: 14),
          TextField(enabled: daftarKategori.isNotEmpty, controller: tujuan, decoration: const InputDecoration(labelText: 'Nama bank sampah / tempat setor')),
          const SizedBox(height: 18),
          LeafButton(sibuk ? 'Menyimpan…' : 'Konfirmasi Setoran', icon: Icons.check_circle_outline, onTap: sibuk || kategoriTerpilih == null || daftarKategori.isEmpty ? null : simpan),
        ])),
        const SizedBox(height: 22),
        serif('Setoran Terakhir', size: 27),
        const SizedBox(height: 12),
        if (widget.store.ambilDaftar('deposits').isEmpty)
          Glass(
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Row(
              children: [
                const VectorArtwork(
                  asset: 'assets/vector/community_waste_bank.png',
                  width: 112,
                  height: 94,
                  background: Color(0xff244a35),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Belum ada setoran. Mulai dengan memilah sampah bersih dan temukan bank sampah terdekat.',
                    style: TextStyle(fontSize: 11, height: 1.5, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ...widget.store.ambilDaftar('deposits').map((r) {
          final kuantitas = r['quantity'] ?? r['estimatedKg'] ?? 0;
          final unitTersimpan = r['unit'] ?? 'kg';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Glass(child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.recycling, color: sage),
              title: Text('${r['kategori']} • $kuantitas $unitTersimpan'),
              subtitle: Text('${r['tujuan']}'),
              trailing: Text('+${r['poin'] ?? 0}', style: const TextStyle(color: sage)),
            )),
          );
        }),
      ],
    );
  }
}
