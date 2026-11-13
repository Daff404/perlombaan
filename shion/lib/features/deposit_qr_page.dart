import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../ui/forest.dart';

class DepositQrPage extends StatefulWidget {
  const DepositQrPage({super.key, required this.store, required this.depositId});
  final ApiStore store;
  final String depositId;
  @override
  State<DepositQrPage> createState() => _DepositQrState();
}
class _DepositQrState extends State<DepositQrPage> {
  Map<String, dynamic>? qr;
  Timer? timer;
  bool busy = false, collected = false;
  String? error;
  @override
  void initState() { super.initState(); unawaited(load()); timer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(check())); }
  Future<void> load() async {
    if (busy || collected) return;
    setState(() { busy = true; error = null; });
    try { final data = await widget.store.api.permintaan('POST', '/deposits/${Uri.encodeComponent(widget.depositId)}/qr', body: {}); if (mounted) setState(() => qr = data); }
    catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> check() async {
    if (!mounted || busy || collected) return;
    try {
      await widget.store.segarkan();
      if (!mounted) return;
      final rows = widget.store.ambilDaftar('deposits').where((d) => d['id'] == widget.depositId);
      if (rows.isNotEmpty && rows.first['status'] == 'Selesai') { setState(() => collected = true); return; }
      if (qr != null && DateTime.tryParse(qr!['expiresAt']?.toString() ?? '')?.isBefore(DateTime.now()) == true) await load();
    } catch (e) { if (mounted) setState(() => error = 'Koneksi terputus. Coba perbarui QR.'); }
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    serif(collected ? 'Setoran sudah dikumpulkan' : 'QR setoranmu', size: 31),
    const SizedBox(height: 9),
    const Text('Tunjukkan kode ini kepada admin saat sampah diserahkan. Poin diberikan setelah admin mengonfirmasi.', style: TextStyle(color: muted)),
    const SizedBox(height: 24),
    if (collected) const Glass(child: Text('Setoran selesai. Poin sudah masuk ke akunmu.'))
    else if (qr != null) Center(child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: QrImageView(data: qr!['payload'] as String, size: 260)))
    else if (busy) const Center(child: CircularProgressIndicator(color: sage)),
    const SizedBox(height: 16),
    if (busy && qr != null) const LinearProgressIndicator(color: sage),
    if (error != null) Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
    if (!collected) LeafButton('Perbarui QR', icon: Icons.refresh_rounded, onTap: busy ? null : load),
  ]);
}

class AdminDepositQrPage extends StatefulWidget {
  const AdminDepositQrPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<AdminDepositQrPage> createState() => _AdminDepositQrState();
}
class _AdminDepositQrState extends State<AdminDepositQrPage> with WidgetsBindingObserver {
  final camera = MobileScannerController(formats: const [BarcodeFormat.qrCode], autoStart: false);
  final amount = TextEditingController();
  Map<String, dynamic>? deposit;
  String? payload, error, receipt, requestId;
  int? confirmedAmount;
  bool busy = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); WidgetsBinding.instance.addPostFrameCallback((_) => start()); }
  Future<void> start() async { try { await camera.start(); } catch (e) { if (mounted) setState(() => error = 'Kamera belum tersedia. Periksa izin kamera.'); } }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed && deposit == null && receipt == null) { unawaited(start()); } else { unawaited(camera.stop()); } }
  Future<void> detected(BarcodeCapture capture) async {
    if (busy || deposit != null || receipt != null) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().where((s) => s.startsWith('shion:deposit:'));
    if (raw.isEmpty) return;
    setState(() { busy = true; error = null; });
    try {
      final result = await widget.store.api.permintaan('POST', '/admin/deposits/resolve', body: {'payload': raw.first});
      await camera.stop();
      if (mounted) setState(() { deposit = result; payload = raw.first; });
    } catch (e) { await camera.stop(); if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> collect() async {
    final points = confirmedAmount ?? int.tryParse(amount.text.trim());
    if (busy || points == null || points < 1 || points > 100000) { setState(() => error = 'Masukkan 1–100.000 poin.'); return; }
    if (requestId == null) {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Konfirmasi pengumpulan'), content: Text('Setoran ${deposit!['category']} ke ${deposit!['destination']} milik ${deposit!['user']['name']}. Berikan $points poin?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Konfirmasi'))]));
      if (ok != true || !mounted) return;
      requestId = ApiClient.buatIdPermintaan(); confirmedAmount = points;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = await widget.store.api.permintaan('POST', '/admin/deposits/collect', body: {'payload': payload, 'amount': points, 'requestId': requestId});
      if (mounted) setState(() { receipt = '${result['amount']} poin berhasil dikirim.\nSetoran ${result['depositId']} sudah dikumpulkan.'; deposit = null; });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); unawaited(camera.dispose()); amount.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(22), children: [
    serif('Pindai QR setoran', size: 29),
    const Text('Periksa sampah dan kelurahan tujuan sebelum memberi poin.', style: TextStyle(color: muted)),
    const SizedBox(height: 18),
    if (deposit == null && receipt == null) ClipRRect(borderRadius: BorderRadius.circular(24), child: SizedBox(height: 350, child: Stack(children: [
      MobileScanner(controller: camera, onDetect: detected, useAppLifecycleState: false, errorBuilder: (_, __) => const Center(child: Text('Kamera tidak tersedia. Periksa izin aplikasi.'))),
      const Positioned(top: 12, left: 12, child: Icon(Icons.qr_code_scanner_rounded, color: sage, size: 34)),
      if (busy) const Center(child: CircularProgressIndicator(color: sage)),
    ]))),
    if (deposit != null) Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${deposit!['user']['name']}', style: const TextStyle(fontSize: 23)),
      Text('${deposit!['category']} • ${deposit!['quantity']} ${deposit!['unit']}'),
      Text('${deposit!['destination']}, ${deposit!['city'] ?? ''}', style: const TextStyle(color: muted)),
      const SizedBox(height: 15),
      TextField(controller: amount, enabled: requestId == null && !busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah poin yang dikirim')),
      const SizedBox(height: 16),
      LeafButton(busy ? 'Mengirim…' : 'Konfirmasi dan kirim poin', icon: Icons.check_circle_outline, onTap: busy ? null : collect),
    ])),
    if (receipt != null) Glass(child: Text(receipt!)),
    if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: const TextStyle(color: Colors.orangeAccent))),
    TextButton.icon(onPressed: busy ? null : () { setState(() { deposit = null; payload = null; receipt = null; error = null; requestId = null; confirmedAmount = null; amount.clear(); }); unawaited(start()); }, icon: const Icon(Icons.qr_code_scanner), label: const Text('Pindai lagi')),
  ]);
}
