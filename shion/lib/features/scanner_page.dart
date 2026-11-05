// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../core/system_log.dart';
import '../services/waste_result.dart';
import '../services/speech_service.dart';
import '../settings.dart';
import '../ui/forest.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    required this.store,
    required this.onSaved,
    required this.onFindPlace,
  });
  final ApiStore store;
  final VoidCallback onSaved, onFindPlace;
  @override
  State<ScannerPage> createState() => _pemindaiHalamanKeadaan();
}

class _pemindaiHalamanKeadaan extends State<ScannerPage> with WidgetsBindingObserver {
  CameraController? _kamera;
  final _suara = SpeechService();
  Uint8List? _foto;
  WasteResult? _hasil;
  String? _galat;
  bool _sibuk = false, _memulai = false, _persetujuan = false;
  String? _pindaiPermintaanId;
  bool _memotret = false;
  bool _depanKamera = false, _kilatAktif = false;
  bool _kameraLayarPenuh = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ==== [ IDRUS - FRONTEND ] ==== //
    // Tab kamera langsung membuka halaman kamera saat pertama kali dipilih.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_layarPenuhKamera());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kamera?.dispose();
    unawaited(_suara.stop().catchError((Object _) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _kamera != null) {
      final lama = _kamera;
      _kamera = null;
      lama?.dispose();
      if (mounted) setState(() {});
    }
  }

  void _pesan(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _izinKeKirim() async {
    if (_persetujuan) return true;
    final berhasil = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindai sampah'),
        content: const Text('Foto dikirim ke server SHION untuk mengenali jenis sampah. Hasil dan foto tersimpan ke akunmu. Hindari memotret wajah atau informasi pribadi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    _persetujuan = berhasil == true;
    return _persetujuan;
  }

  Future<void> _mulai() async {
    if (_memulai || _sibuk) return;
    setState(() {
      _memulai = true;
      _galat = null;
    });
    CameraController? controller;
    try {
      final daftarKamera = await availableCameras();
      if (daftarKamera.isEmpty)
        throw CameraException('noCamera', 'Kamera tidak ditemukan.');
      final lensa = daftarKamera.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => daftarKamera.first,
      );
      _depanKamera = lensa.lensDirection == CameraLensDirection.front;
      _kilatAktif = false;
      controller = CameraController(
        lensa,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _kamera?.dispose();
      setState(() {
        _kamera = controller;
        _foto = null;
        _hasil = null;
        });
    } on CameraException catch (e) {
      await controller?.dispose();
      if (mounted)
        setState(
          () => _galat = e.code.contains('AccessDenied')
              ? 'Izin kamera ditolak. Izinkan kamera dari pengaturan perangkat atau pilih foto galeri.'
              : 'Kamera tidak dapat dibuka. Coba lagi atau gunakan galeri.',
        );
    } catch (_) {
      await controller?.dispose();
      if (mounted)
        setState(
          () => _galat =
              'Kamera tidak tersedia pada perangkat ini. Gunakan galeri.',
        );
    } finally {
      if (mounted) setState(() => _memulai = false);
    }
  }

  Future<void> _alihKamera({VoidCallback? onUpdated}) async {
    if (_memulai || _memotret || _sibuk) return;
    final sebelumnya = _kamera;
    if (sebelumnya == null) return;
    setState(() => _memulai = true);
    try {
      final daftarKamera = await availableCameras();
      final diinginkan = _depanKamera
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      final sesuai = daftarKamera.where((c) => c.lensDirection == diinginkan);
      final berikutnya = sesuai.isEmpty ? null : sesuai.first;
      if (berikutnya == null) {
        _pesan('Kamera depan/belakang tidak tersedia.');
        return;
      }
      await sebelumnya.dispose();
      if (identical(_kamera, sebelumnya)) _kamera = null;
      final pengganti = CameraController(
        berikutnya,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await pengganti.initialize();
      if (_kilatAktif) {
        try { await pengganti.setFlashMode(FlashMode.torch); }
        catch (_) { _kilatAktif = false; }
      }
      if (!mounted) { await pengganti.dispose(); return; }
      setState(() {
        _kamera = pengganti;
        _depanKamera = berikutnya.lensDirection == CameraLensDirection.front;
      });
      onUpdated?.call();
    } catch (e) {
      SystemLog.add('camera-switch', e);
      _pesan('Kamera tidak dapat diganti. Coba lagi.');
    } finally {
      if (mounted) setState(() => _memulai = false);
      onUpdated?.call();
    }
  }

  Future<void> _ubahKilat({VoidCallback? onUpdated}) async {
    final kamera = _kamera;
    if (kamera == null) return;
    try {
      final aktifkan = !_kilatAktif;
      await kamera.setFlashMode(aktifkan ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _kilatAktif = aktifkan);
      onUpdated?.call();
    } catch (_) {
      _pesan('Flash tidak tersedia pada kamera ini.');
    }
  }

  Future<void> _tutupKamera() async {
    final lama = _kamera;
    _kamera = null;
    _kilatAktif = false;
    if (mounted) setState(() {});
    await lama?.dispose();
  }

  Future<void> _layarPenuhKamera() async {
    if (_kamera == null) await _mulai();
    if (!mounted || _kamera == null) return;
    setState(() => _kameraLayarPenuh = true);
    try {
      await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Kamera scan',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) => StatefulBuilder(
        builder: (dialogContext, updateDialog) {
          final kamera = _kamera;
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (kamera?.value.isInitialized == true)
                    Center(child: CameraPreview(kamera!))
                  else
                    const Center(child: CircularProgressIndicator(color: sage)),
                  Positioned(left: 24, right: 24, bottom: 130, child: const Text('Arahkan kamera ke satu benda dengan cahaya cukup', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, backgroundColor: Colors.black54))),
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _kameraKontrol(
                          Icons.close_rounded,
                          'Tutup kamera',
                          () async {
                            await _tutupKamera();
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          },
                        ),
                        _kameraKontrol(
                          _kilatAktif ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          _kilatAktif ? 'Flash mati' : 'Flash nyala',
                          () => _ubahKilat(onUpdated: () => updateDialog(() {})),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 25,
                    right: 25,
                    bottom: 25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _kameraKontrol(
                          Icons.cameraswitch_rounded,
                          'Putar kamera',
                          () => _alihKamera(onUpdated: () => updateDialog(() {})),
                        ),
                        GestureDetector(
                          onTap: _memotret ? null : () async {
                            await _ambil();
                            if (dialogContext.mounted && _kamera == null) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sage,
                              border: Border.all(color: Colors.white, width: 5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: forest, size: 32),
                          ),
                        ),
                        const SizedBox(width: 54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      transitionBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      );
    } finally {
      if (mounted) setState(() => _kameraLayarPenuh = false);
    }
  }

  Widget _kameraKontrol(IconData icon, String label, VoidCallback onTap) =>
      Tooltip(
        message: label,
        child: Material(
          color: const Color(0x88000000),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      );

  Future<void> _ambil() async {
    final kamera = _kamera;
    if (kamera == null || _sibuk || _memotret) return;
    if (!await _izinKeKirim() || !mounted) return;
    setState(() => _memotret = true);
    try {
      final foto = await kamera.takePicture();
      final byte = await foto.readAsBytes();
      if (!mounted) return;
      await _analisis(byte);
    } catch (_) {
      if (mounted) _pesan('Foto gagal diambil. Coba lagi.');
    } finally {
      if (mounted) setState(() => _memotret = false);
    }
  }

  Future<void> _galeri() async {
    if (_sibuk || !await _izinKeKirim() || !mounted) return;
    try {
      final berkas = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 75,
      );
      if (berkas == null) return;
      final byte = await berkas.readAsBytes();
      if (mounted) await _analisis(byte);
    } catch (_) {
      _pesan('Foto tidak dapat dibuka. Gunakan JPG, PNG, atau WebP.');
    }
  }

  Future<void> _analisis(Uint8List byte, {bool retry = false}) async {
    if (!retry) _pindaiPermintaanId = ApiClient.buatIdPermintaan();
    setState(() {
      _foto = byte;
      _sibuk = true;
      _hasil = null;
      _galat = null;
    });
    final lama = _kamera;
    _kamera = null;
    _kilatAktif = false;
    try {
      await lama?.dispose();
      final balasan = await widget.store.analisisPindai(byte, _pindaiPermintaanId!);
      final hasil = WasteResult.dariJson(Map<String, dynamic>.from(balasan['scan'] as Map));
      if (mounted) {
        setState(() => _hasil = hasil);
        widget.onSaved();
        final tersimpan = balasan['save'] as Map;
        _pesan('${tersimpan['poin']} poin • ${tersimpan['reason']}');
        unawaited(_ucapkanHasil(hasil));
      }
    } catch (e) {
      if (mounted) setState(() => _galat = SystemLog.failure('ai-detector', e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _ucapkanHasil(WasteResult hasil) async {
    final daftarLangkah = hasil.daftarLangkah.take(5).toList();
    final teksUcapan = StringBuffer()
      ..write('Hasil pemindaian. ${hasil.name}. Kategori ${hasil.category}. ')
      ..write('Bahan yang terlihat: ${hasil.material}. Cara penanganan. ');
    for (var indeks = 0; indeks < daftarLangkah.length; indeks++) {
      teksUcapan.write('${indeks + 1}. ${daftarLangkah[indeks]}. ');
    }
    if (hasil.warning.trim().isNotEmpty) {
      teksUcapan.write('Peringatan. ${hasil.warning}. ');
    }
    try {
      await _suara.speak(teksUcapan.toString());
    } catch (e) {
      SystemLog.add('scan-speech', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 5, 22, 25),
      children: [
        const Glass(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Text(
            'Bidik satu benda sampah dengan cahaya yang cukup. Foto akan diproses dan hasilnya disimpan ke akunmu.',
            style: TextStyle(color: muted, height: 1.5, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 12),
          const Glass(
            padding: EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: sage, size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Gunakan kamera atau galeri untuk memindai sampah.',
                    style: TextStyle(color: muted, height: 1.45, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: SizedBox(
            height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_foto != null)
                  Image.memory(_foto!, fit: BoxFit.cover)
                else if (!_kameraLayarPenuh && _kamera?.value.isInitialized == true)
                  Center(child: CameraPreview(_kamera!))
                else
                  DecoratedBox(
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff31563b), Color(0xff0a2b20), Color(0xff173d2d)])),
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned(left: 18, top: 20, child: Icon(Icons.auto_awesome, color: const Color(0xffe2b75e).withValues(alpha: .85), size: 17)),
                      Positioned(right: 15, top: 22, child: Container(width: 112, height: 112, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xffc8ed9c).withValues(alpha: .22), width: 1.5)))),
                      Positioned(left: 18, bottom: 20, child: Icon(Icons.eco_outlined, color: const Color(0xffb6df83).withValues(alpha: .72), size: 25)),
                      Image.asset('assets/vector/ai_waste_scanner.png', fit: BoxFit.contain, height: 310),
                    ]),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Material(
                    color: const Color(0x990b2118),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Perbesar dan buka kamera',
                      onPressed: _sibuk || _memulai ? null : _layarPenuhKamera,
                      icon: const Icon(Icons.crop_free, color: sage, size: 27),
                    ),
                  ),
                ),
                if (_sibuk)
                  const ColoredBox(
                    color: Color(0xa00b2118),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: sage),
                          SizedBox(height: 18),
                          Text('Sedang mengenali jenis sampah…'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LeafButton(
                _kamera == null ? 'Buka Kamera' : 'Ambil & Analisis',
                icon: Icons.camera_alt_outlined,
                onTap: _sibuk || _memulai || _memotret
                    ? null
                    : _kamera == null
                    ? _mulai
                    : _ambil,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LeafButton(
                'Galeri',
                icon: Icons.photo_outlined,
                onTap: _sibuk || _memulai || _memotret ? null : _galeri,
              ),
            ),
          ],
        ),
        if (_memulai)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(color: sage),
          ),
        if (_galat != null) ...[
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: sage),
                const SizedBox(height: 8),
                Text(
                  _galat!,
                  style: const TextStyle(height: 1.5, fontSize: 13),
                ),
                if (_foto != null)
                  TextButton(
                    onPressed: _sibuk ? null : () => _analisis(_foto!, retry: true),
                    child: const Text('Coba analisis lagi'),
                  ),
              ],
            ),
          ),
        ],
        if (hasil != null) ...[
          const SizedBox(height: 21),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HASIL AI DETECTOR',
                  style: TextStyle(color: sage, fontSize: 10, letterSpacing: 2),
                ),
                const SizedBox(height: 9),
                serif(hasil.name, size: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _sibuk ? null : () => _ucapkanHasil(hasil),
                    icon: const Icon(Icons.volume_up_rounded, size: 19),
                    label: const Text('Dengarkan hasil'),
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    Chip(label: Text(hasil.category)),
                    Chip(
                      label: Text(
                        hasil.recyclable
                            ? 'Potensi daur ulang'
                            : 'Penanganan khusus / residu',
                      ),
                    ),
                  ],
                ),
                Text(
                  hasil.material,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                serif('Cara Penanganan', size: 23),
                const SizedBox(height: 10),
                ...hasil.daftarLangkah.indexed.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${e.$1 + 1}. ${e.$2}',
                      style: const TextStyle(height: 1.6, fontSize: 13),
                    ),
                  ),
                ),
                if (hasil.warning.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      hasil.warning,
                      style: const TextStyle(color: sage, height: 1.5),
                    ),
                  ),
                const Text(
                  'Hasil AI dapat keliru. Periksa bahan dan petunjuk pengelola setempat.',
                  style: TextStyle(color: muted, fontSize: 10, height: 1.5),
                ),
                const SizedBox(height: 17),
                const Row(children: [
                  Icon(Icons.cloud_done_outlined, color: sage, size: 19),
                  SizedBox(width: 8),
                  Expanded(child: Text('Hasil dan kategori tersimpan ke akunmu.', style: TextStyle(color: muted, fontSize: 12))),
                ]),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: widget.onFindPlace,
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Cari Tempat Setor'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text(
          '${Settings.pointsPerScan} poin untuk foto baru yang dikenali sebagai sampah. Maksimal ${Settings.rewardedScansPerDay} scan berpoin per hari. Foto duplikat tidak menambah poin.',
          style: const TextStyle(color: muted, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }
}
