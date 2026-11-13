// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/places_service.dart';
import 'deposit_qr_page.dart';
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
  final nilaiJumlah = TextEditingController(), kotaPencarian = TextEditingController();
  late final PlacesService _places = PlacesService(widget.store.api);
  List<Map<String, dynamic>> kelurahan = [];
  String? kelurahanId, kota, lokasiGalat;
  bool memuatLokasi = false;
  String satuan = 'kg';
  String? kategoriTerpilih;
  bool sibuk = false;
  String? _setoranPermintaanId;
  String? _setoranTandatangan;
  static const kategoriDidukung = {'Plastik', 'Kertas', 'Organik', 'Logam', 'Kaca', 'Elektronik', 'B3', 'Residu'};

  @override
  void initState() {
    super.initState();
    final tersedia = kategoriTersedia;
    if (tersedia.isNotEmpty) kategoriTerpilih = tersedia.first;
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) muatKelurahan(gps: true); });
  }

  @override
  void dispose() {
    nilaiJumlah.dispose();
    kotaPencarian.dispose();
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
    final terpilih = kategoriTersedia.contains(kategoriTerpilih) ? kategoriTerpilih : (kategoriTersedia.isEmpty ? null : kategoriTersedia.first);
    for (final pindai in kandidatPindai) {
      if (pindai['category'] == terpilih) return pindai;
    }
    return null;
  }

  String get namaKelurahan {
    for (final v in kelurahan) { if (v['id'] == kelurahanId) return 'Kelurahan ${v['name']}'; }
    return 'Pilih kelurahan';
  }

  Future<void> muatKelurahan({bool gps = false}) async {
    if (memuatLokasi) return;
    setState(() { memuatLokasi = true; lokasiGalat = null; });
    try {
      HasilPencarianTempat hasil;
      if (gps) {
        if (!await Geolocator.isLocationServiceEnabled()) throw const PlacesException('GPS belum aktif. Cari berdasarkan kota di bawah.');
        var izin = await Geolocator.checkPermission();
        if (izin == LocationPermission.denied) izin = await Geolocator.requestPermission();
        if (izin == LocationPermission.denied || izin == LocationPermission.deniedForever) throw const PlacesException('Izin lokasi belum diberikan. Cari berdasarkan kota di bawah.');
        final posisi = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)));
        hasil = await _places.terdekat(LatLng(posisi.latitude, posisi.longitude));
      } else {
        hasil = await _places.cariWilayah(kotaPencarian.text);
      }
      if (!mounted) return;
      setState(() { kelurahan = hasil.kelurahan; kota = hasil.kota; kelurahanId = null; lokasiGalat = null; });
    } catch (e) { if (mounted) setState(() => lokasiGalat = e.toString()); }
    finally { if (mounted) setState(() => memuatLokasi = false); }
  }

  Future<void> simpan() async {
    if (sibuk) return;
    final kuantitas = double.tryParse(nilaiJumlah.text.trim().replaceAll(',', '.'));
    final kategori = kategoriTersedia.contains(kategoriTerpilih) ? kategoriTerpilih : (kategoriTersedia.isEmpty ? null : kategoriTersedia.first);
    if (kategori == null || !kategoriTersedia.contains(kategori)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pindai sampah terlebih dahulu agar kategorinya terisi otomatis.'),
      ));
      return;
    }
    if (kuantitas == null || !kuantitas.isFinite || kuantitas <= 0 || kuantitas > 1000 || (satuan == 'satuan' && kuantitas % 1 != 0) || kelurahanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Isi ${satuan == 'kg' ? 'berat 0–1.000 kg' : 'jumlah 1–1.000 satuan'} dan pilih kelurahan tujuan.'),
      ));
      return;
    }
    final labelSatuan = satuan == 'kg' ? 'kg' : 'satuan';
    final disetujui = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Setoran'),
        content: Text('$kategori • $kuantitas $labelSatuan\n$namaKelurahan, ${kota ?? ''}\n\nSetoran akan disimpan sampai admin memindai QR dan memverifikasi jumlah poin.'),
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
      final tandaTangan = '$idPindai|$kuantitas|$satuan|$kelurahanId';
      if (_setoranTandatangan != tandaTangan) { _setoranTandatangan = tandaTangan; _setoranPermintaanId = ApiClient.buatIdPermintaan(); }
      await widget.store.konfirmasiSetoran(category: kategori, scanId: idPindai, kg: kuantitas, unit: satuan, kelurahanId: kelurahanId!, requestId: _setoranPermintaanId!);
      if (!mounted) return;
      _setoranPermintaanId = null;
      _setoranTandatangan = null;
      final tersedia = kategoriTersedia;
      kategoriTerpilih = tersedia.isEmpty ? null : tersedia.first;
      widget.onSaved();
      nilaiJumlah.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setoran disimpan. Tunjukkan QR saat sampah dikumpulkan.')));
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
            initialValue: daftarKategori.contains(kategoriTerpilih) ? kategoriTerpilih : (daftarKategori.isEmpty ? null : daftarKategori.first),
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
          Text('Kelurahan tujuan${kota == null ? '' : ' • $kota'}', style: const TextStyle(color: sage, fontSize: 12)),
          const SizedBox(height: 8),
          if (memuatLokasi) const LinearProgressIndicator(color: sage),
          Row(children: [
            Expanded(child: TextField(controller: kotaPencarian, textInputAction: TextInputAction.search, onSubmitted: (_) => muatKelurahan(), decoration: const InputDecoration(labelText: 'Cari kota jika GPS belum tersedia'))),
            IconButton(onPressed: memuatLokasi ? null : () => muatKelurahan(), icon: const Icon(Icons.search_rounded, color: sage)),
            IconButton(onPressed: memuatLokasi ? null : () => muatKelurahan(gps: true), icon: const Icon(Icons.my_location_rounded, color: sage)),
          ]),
          if (lokasiGalat != null) Text(lokasiGalat!, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('kelurahan-$kota-$kelurahanId'),
            initialValue: kelurahanId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pilih kelurahan tujuan *'),
            items: kelurahan.map((v) => DropdownMenuItem<String>(value: v['id'] as String, child: Text('${v['name']} • ${v['district']}', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: kelurahan.isEmpty ? null : (value) => setState(() => kelurahanId = value),
          ),
          const SizedBox(height: 18),
          LeafButton(sibuk ? 'Menyimpan…' : 'Konfirmasi Setoran', icon: Icons.check_circle_outline, onTap: sibuk || daftarKategori.isEmpty ? null : simpan),
        ])),
        const SizedBox(height: 22),
        const Text('List Setoran yang Disimpan', style: TextStyle(fontFamily: 'Manrope', fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 5),
        const Text('Belum dikirimkan. Tunjukkan QR setoran saat sampah diserahkan.', style: TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 12),
        if (widget.store.ambilDaftar('deposits').where((r) => r['status'] == 'Disimpan').isEmpty)
          const Glass(child: Text('Belum ada setoran yang menunggu pengumpulan.')),
        ...widget.store.ambilDaftar('deposits').where((r) => r['status'] == 'Disimpan').map((r) => _kartuSetoran(r, pending: true)),
        const SizedBox(height: 23),
        const Text('List Setoran yang Sudah Dikumpulkan', style: TextStyle(fontFamily: 'Manrope', fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 5),
        const Text('Sampah telah diserahkan dan poin sudah diterima.', style: TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 12),
        if (widget.store.ambilDaftar('deposits').where((r) => r['status'] == 'Selesai').isEmpty)
          const Glass(child: Text('Belum ada setoran yang dikumpulkan.')),
        ...widget.store.ambilDaftar('deposits').where((r) => r['status'] == 'Selesai').map((r) => _kartuSetoran(r, pending: false)),
      ],
    );
  }
  Widget _kartuSetoran(Map<String, dynamic> r, {required bool pending}) {
    final destination = r['destination']?.toString().trim() ?? '';
    final tujuanTampil = destination.isEmpty || destination.toLowerCase() == 'null' || destination.toLowerCase() == 'kelurahan' ? 'Kelurahan belum dicatat' : destination;
    final quantity = r['quantity'] ?? r['estimatedKg'] ?? 0;
    final unit = r['unit'] == 'satuan' ? 'satuan' : 'kg';
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.recycling, color: sage), const SizedBox(width: 10), Expanded(child: Text('${r['category'] ?? 'Kategori sampah'} • $quantity $unit', style: const TextStyle(fontWeight: FontWeight.w600))), if (!pending) Text('+${((r['points'] ?? r['poin']) as num? ?? 0).toInt()} poin', style: const TextStyle(color: sage))]),
      const SizedBox(height: 8),
      Text('$tujuanTampil${r['city'] is String ? ', ${r['city']}' : ''}', style: const TextStyle(color: muted, fontSize: 12)),
      if (pending) ...[const SizedBox(height: 12), LeafButton('Tampilkan QR setoran', icon: Icons.qr_code_rounded, onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => Scaffold(backgroundColor: forestDeep, appBar: AppBar(title: const Text('QR Setoran')), body: DepositQrPage(store: widget.store, depositId: r['id'] as String)))).then((_) { if (mounted) widget.store.segarkan(); }))],
    ])));
  }

}
