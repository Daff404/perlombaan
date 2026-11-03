// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/api_client.dart';
import '../core/api_store.dart';
import '../ui/forest.dart';

class PointsQrPage extends StatefulWidget {
  const PointsQrPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<PointsQrPage> createState() => _poinQrHalamanKeadaan();
}
class _poinQrHalamanKeadaan extends State<PointsQrPage> with WidgetsBindingObserver {
  Map<String, dynamic>? kodeQr;
  Timer? pengaturWaktu;
  String? galat;
  bool sibuk = false, memeriksa = false, aktif = true, diterima = false;
  int nilaiJumlah = 0;
  int get detikTersisa => kodeQr == null ? 0 : math.max(0, DateTime.parse(kodeQr!['expiresAt'] as String).difference(DateTime.now()).inSeconds);
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); unawaited(muat()); pengaturWaktu = Timer.periodic(const Duration(seconds: 1), (_) => perbaruiDetik()); }
  Future<void> muat() async {
    if (sibuk) return;
    setState(() { sibuk = true; galat = null; diterima = false; kodeQr = null; });
    try { final data = await widget.store.api.permintaan('POST', '/points/qr', body: {}); if (mounted) setState(() => kodeQr = data); }
    catch (e) { if (mounted) setState(() => galat = '$e'); }
    finally { if (mounted) setState(() => sibuk = false); }
  }
  Future<void> perbaruiDetik() async {
    if (!mounted || !aktif || kodeQr == null || diterima || sibuk || memeriksa) return;
    setState(() {});
    memeriksa = true;
    try {
      final data = await widget.store.api.permintaan('GET', '/points/qr/${kodeQr!['id']}');
      if (!mounted) return;
      if (data['used'] == true) { setState(() { diterima = true; nilaiJumlah = (data['amount'] as num).toInt(); }); await widget.store.segarkan(); }
      else if (data['expired'] == true || detikTersisa == 0) { await muat(); }
    } catch (e) { if (mounted) setState(() => galat = '$e'); }
    finally { memeriksa = false; }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { aktif = state == AppLifecycleState.resumed; if (aktif) unawaited(perbaruiDetik()); }
  @override
  void dispose() { pengaturWaktu?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    Text(diterima ? 'Poin sudah masuk!' : 'QR pribadimu', style: const TextStyle(fontSize: 30, fontFamily: 'Cormorant')),
    const SizedBox(height: 8),
    Text(widget.store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
    SelectableText('@${widget.store.user['username'] ?? ''}', style: const TextStyle(color: sage)),
    const SizedBox(height: 24),
    if (diterima) Glass(child: Column(children: [const Icon(Icons.check_circle, color: sage, size: 64), Text('+$nilaiJumlah poin', style: const TextStyle(fontSize: 36)), Text('Saldo: ${widget.store.poin} poin')]))
    else if (sibuk) const Center(child: CircularProgressIndicator())
    else if (kodeQr != null && detikTersisa > 0) Center(child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: QrImageView(data: kodeQr!['payload'] as String, size: math.min(MediaQuery.sizeOf(context).width - 116, 280.0)))),
    const SizedBox(height: 18),
    if (!diterima) Text('Berlaku $detikTersisa detik • diperbarui otomatis\nTunjukkan kepada admin untuk menerima poin.', textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.6)),
    if (galat != null) Padding(padding: const EdgeInsets.all(12), child: Text(galat!, style: const TextStyle(color: Colors.orangeAccent))),
    const SizedBox(height: 18),
    LeafButton(diterima ? 'Terima poin lagi' : 'Perbarui QR', onTap: sibuk ? null : muat, icon: Icons.qr_code_rounded),
  ]);
}

class AdminQrPage extends StatefulWidget {
  const AdminQrPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<AdminQrPage> createState() => _adminQrHalamanKeadaan();
}
class _adminQrHalamanKeadaan extends State<AdminQrPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
  final pemindai = MobileScannerController(formats: const [BarcodeFormat.qrCode], autoStart: false);
  final nilaiJumlah = TextEditingController(text: '1');
  Map<String, dynamic>? penerima;
  String? muatan, galat, bukti;
  String? idPermintaan;
  int? jumlahTertunda;
  bool sibuk = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); WidgetsBinding.instance.addPostFrameCallback((_) => mulai()); }
  Future<void> mulai() async { try { await pemindai.start(); } catch (e) { if (mounted) setState(() => galat = 'Kamera belum tersedia. Periksa izin kamera.'); } }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.resumed && penerima == null && bukti == null) { unawaited(mulai()); } else { unawaited(pemindai.stop()); } }
  Future<void> deteksi(BarcodeCapture capture) async {
    if (sibuk || penerima != null || bukti != null) return;
    final daftarKode = capture.barcodes.map((b) => b.rawValue).whereType<String>();
    if (daftarKode.isEmpty) return;
    setState(() { sibuk = true; galat = null; });
    try {
      final mentah = daftarKode.first;
      final data = await widget.store.api.permintaan('POST', '/admin/points/resolve', body: {'payload': mentah});
      await pemindai.stop();
      if (mounted) setState(() { penerima = data; muatan = mentah; idPermintaan = null; jumlahTertunda = null; });
    } catch (e) { await pemindai.stop(); if (mounted) setState(() => galat = '$e'); }
    finally { if (mounted) setState(() => sibuk = false); }
  }
  Future<void> kirim() async {
    final jumlah = jumlahTertunda ?? int.tryParse(nilaiJumlah.text);
    if (sibuk || jumlah == null || jumlah < 1 || jumlah > 100000) { if (mounted) setState(() => galat = 'Masukkan 1–100.000 poin.'); return; }
    if (idPermintaan == null) {
      final disetujui = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Konfirmasi poin'), content: Text('Tambahkan $jumlah poin ke ${penerima!['user']['name']}?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tambahkan'))]));
      if (disetujui != true || !mounted) return;
      idPermintaan = ApiClient.buatIdPermintaan(); jumlahTertunda = jumlah;
    }
    setState(() { sibuk = true; galat = null; });
    try {
      final hasil = await widget.store.api.permintaan('POST', '/admin/points/credit', body: {'payload': muatan, 'amount': jumlah, 'requestId': idPermintaan});
      if (mounted) setState(() { bukti = '${hasil['amount']} poin berhasil ditambahkan.\nBukti: ${hasil['receiptId']}'; penerima = null; });
    } catch (e) { if (mounted) setState(() => galat = '$e'); }
    finally { if (mounted) setState(() => sibuk = false); }
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); sweep.dispose(); unawaited(pemindai.dispose()); nilaiJumlah.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(22), children: [
    const Text('Pindai QR pengguna', style: TextStyle(fontSize: 28, fontFamily: 'Cormorant')),
    const Text('Pastikan nama penerima sebelum menambahkan poin.', style: TextStyle(color: muted)),
    const SizedBox(height: 20),
    if (penerima == null && bukti == null) ClipRRect(borderRadius: BorderRadius.circular(26), child: SizedBox(height: 340, child: Stack(fit: StackFit.expand, children: [
      MobileScanner(controller: pemindai, onDetect: deteksi, useAppLifecycleState: false, errorBuilder: (_, galat) => const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Kamera belum tersedia. Izinkan kamera melalui Profil → Izin aplikasi, lalu coba lagi.', textAlign: TextAlign.center)))),
      IgnorePointer(child: AnimatedBuilder(animation: sweep, builder: (_, child) => CustomPaint(painter: _qrPindai(sweep.value)))),
      Positioned(right: 12, top: 12, child: IconButton.filled(onPressed: () async { try { await pemindai.toggleTorch(); } catch (_) {} }, icon: const Icon(Icons.flash_on))),
      if (sibuk) const Center(child: CircularProgressIndicator()),
    ]))),
    if (penerima != null) Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.verified_user_outlined, color: sage, size: 42),
      Text('${penerima!['user']['name']}', style: const TextStyle(fontSize: 25)),
      Text('@${penerima!['user']['username']}'), const SizedBox(height: 18),
      TextField(controller: nilaiJumlah, enabled: idPermintaan == null && !sibuk, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah poin')),
      const SizedBox(height: 16), LeafButton(sibuk ? 'Memproses…' : idPermintaan == null ? 'Tambahkan poin' : 'Periksa / ulangi transaksi', onTap: sibuk ? null : kirim, icon: Icons.add),
    ])),
    if (bukti != null) Glass(child: Column(children: [const Icon(Icons.check_circle, size: 60, color: sage), SelectableText(bukti!)])),
    if (galat != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(galat!, style: const TextStyle(color: Colors.orangeAccent))),
    const SizedBox(height: 16),
    if (!sibuk) TextButton.icon(onPressed: () { setState(() { penerima = null; bukti = null; muatan = null; idPermintaan = null; jumlahTertunda = null; galat = null; }); unawaited(mulai()); }, icon: const Icon(Icons.qr_code_scanner), label: const Text('Pindai lagi')),
  ]);
}
class _qrPindai extends CustomPainter {
  _qrPindai(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final sisi = math.min(size.width, size.height) * .70;
    final kotak = Rect.fromCenter(center: size.center(Offset.zero), width: sisi, height: sisi);
    final masker = Path()..addRect(Offset.zero & size)..addRRect(RRect.fromRectAndRadius(kotak, const Radius.circular(18)))..fillType = PathFillType.evenOdd;
    canvas.drawPath(masker, Paint()..color = const Color(0x88000000));
    canvas.drawRRect(RRect.fromRectAndRadius(kotak, const Radius.circular(18)), Paint()..color = sage..style = PaintingStyle.stroke..strokeWidth = 3);
    final y = kotak.top + 8 + (sisi - 16) * progress;
    canvas.drawLine(Offset(kotak.left + 10, y), Offset(kotak.right - 10, y), Paint()..color = sage..strokeWidth = 3);
  }
  @override
  bool shouldRepaint(_qrPindai old) => old.progress != progress;
}
