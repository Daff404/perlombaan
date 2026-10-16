import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../core/local_store.dart';
import '../core/system_log.dart';
import '../services/object_detection.dart';
import '../services/gemini_service.dart';
import '../services/photo_fingerprint.dart';
import '../settings.dart';
import '../ui/forest.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    required this.store,
    required this.onSaved,
    required this.onFindPlace,
  });
  final LocalStore store;
  final VoidCallback onSaved, onFindPlace;
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  CameraController? _camera;
  LiveObjectDetection? _live;
  DetectionFrame? _detection;
  final _gemini = GeminiService();
  Uint8List? _photo;
  WasteResult? _result;
  String? _error;
  bool _busy = false, _starting = false, _saved = false, _consent = false;
  bool _capturing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _live?.close();
    _camera?.dispose();
    _gemini.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _camera != null) {
      _live?.close();
      _detection = null;
      final old = _camera;
      _camera = null;
      old?.dispose();
      if (mounted) setState(() {});
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _permissionToSend() async {
    if (!Settings.aiConfigured) {
      setState(
        () => _error = 'AI Detector belum siap. Hubungi pengelola aplikasi.',
      );
      return false;
    }
    if (_consent) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisis dengan AI Detector'),
        content: const Text(
          'Foto yang kamu ambil atau pilih akan dikirim ke Google AI Detector untuk mengenali sampah. Hindari foto yang memuat wajah atau informasi pribadi.',
        ),
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
    _consent = ok == true;
    return _consent;
  }

  Future<void> _start() async {
    if (_starting || _busy) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty)
        throw CameraException('noCamera', 'Kamera tidak ditemukan.');
      final lens = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _live?.close();
      _live = LiveObjectDetection();
      controller = CameraController(
        lens,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _camera?.dispose();
      setState(() {
        _camera = controller;
        _photo = null;
        _result = null;
        _saved = false;
      });
      if (LiveObjectDetection.supported) {
        final active = controller;
        try {
          await active.startImageStream((frame) async {
            final detected = await _live?.detect(frame, active);
            if (mounted && _camera == active && detected != null) {
              setState(() => _detection = detected);
            }
          });
        } catch (e) {
          SystemLog.add('camera-stream', e);
        }
      }
    } on CameraException catch (e) {
      await controller?.dispose();
      if (mounted)
        setState(
          () => _error = e.code.contains('AccessDenied')
              ? 'Izin kamera ditolak. Izinkan kamera dari pengaturan perangkat atau pilih foto galeri.'
              : 'Kamera tidak dapat dibuka. Coba lagi atau gunakan galeri.',
        );
    } catch (_) {
      await controller?.dispose();
      if (mounted)
        setState(
          () => _error =
              'Kamera tidak tersedia pada perangkat ini. Gunakan galeri.',
        );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _busy || _capturing) return;
    if (!await _permissionToSend() || !mounted) return;
    setState(() => _capturing = true);
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      _live?.close();
      final photo = await camera.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      await _analyze(bytes);
    } catch (_) {
      if (mounted) _message('Foto gagal diambil. Coba lagi.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _gallery() async {
    if (_busy || !await _permissionToSend() || !mounted) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) await _analyze(bytes);
    } catch (_) {
      _message('Foto tidak dapat dibuka. Gunakan JPG, PNG, atau WebP.');
    }
  }

  Future<void> _analyze(Uint8List bytes) async {
    setState(() {
      _photo = bytes;
      _busy = true;
      _result = null;
      _error = null;
      _saved = false;
    });
    _live?.close();
    _detection = null;
    final old = _camera;
    _camera = null;
    try {
      await old?.dispose();
      final result = await _gemini.classify(bytes, photoMime(bytes));
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = SystemLog.failure('ai-detector', e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _saved || _result == null || _photo == null) return;
    setState(() => _busy = true);
    try {
      final hashes = await compute(fingerprint, _photo!);
      final saved = await widget.store.saveScan(
        result: _result!.toJson(),
        photoBase64: base64Encode(_photo!),
        hash: hashes['sha256']!,
        perceptualHash: hashes['perceptual']!,
        model: Settings.geminiModel,
      );
      if (mounted) {
        setState(() => _saved = true);
        widget.onSaved();
        _message(
          '${saved.points > 0 ? '+${saved.points} poin. ' : ''}${saved.reason}',
        );
      }
    } catch (e) {
      _message(SystemLog.failure('scan-save', e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 5, 22, 25),
      children: [
        const Text(
          'Bidik satu objek sampah dengan cahaya yang cukup. AI Detector mengenali jenisnya secara otomatis.',
          style: TextStyle(color: muted, height: 1.5, fontSize: 12),
          textAlign: TextAlign.center,
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
                    'Kotak deteksi objek langsung tersedia di APK Android. Di Chrome, gunakan kamera atau galeri untuk mengirim foto ke Gemini dan melihat hasil analisis.',
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
                if (_photo != null)
                  Image.memory(_photo!, fit: BoxFit.cover)
                else if (_camera?.value.isInitialized == true)
                  Center(child: CameraPreview(_camera!))
                else
                  const RemotePhoto(Photos.recycle),
                if (_photo == null && _camera == null)
                  const Center(
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: sage,
                      size: 70,
                    ),
                  ),
                if (_camera != null && _detection != null)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: DetectionOverlay(
                        _detection!,
                        mirror:
                            _camera!.description.lensDirection ==
                            CameraLensDirection.front,
                      ),
                    ),
                  ),
                const Positioned(
                  top: 20,
                  left: 20,
                  child: Icon(Icons.crop_free, color: sage, size: 32),
                ),
                if (_busy)
                  const ColoredBox(
                    color: Color(0xa00b2118),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: sage),
                          SizedBox(height: 18),
                          Text('AI Detector sedang menganalisis…'),
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
                _camera == null ? 'Buka Kamera' : 'Ambil & Analisis',
                icon: Icons.camera_alt_outlined,
                onTap: _busy || _starting || _capturing
                    ? null
                    : _camera == null
                    ? _start
                    : _capture,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LeafButton(
                'Galeri',
                icon: Icons.photo_outlined,
                onTap: _busy || _starting || _capturing ? null : _gallery,
              ),
            ),
          ],
        ),
        if (_starting)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(color: sage),
          ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: sage),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(height: 1.5, fontSize: 13),
                ),
                if (_photo != null)
                  TextButton(
                    onPressed: _busy ? null : () => _analyze(_photo!),
                    child: const Text('Coba analisis lagi'),
                  ),
              ],
            ),
          ),
        ],
        if (result != null) ...[
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
                serif(result.name, size: 30),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    Chip(label: Text(result.category)),
                    Chip(
                      label: Text(
                        result.recyclable
                            ? 'Potensi daur ulang'
                            : 'Penanganan khusus / residu',
                      ),
                    ),
                  ],
                ),
                Text(
                  result.material,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                serif('Cara Penanganan', size: 23),
                const SizedBox(height: 10),
                ...result.steps.indexed.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${e.$1 + 1}. ${e.$2}',
                      style: const TextStyle(height: 1.6, fontSize: 13),
                    ),
                  ),
                ),
                if (result.warning.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      result.warning,
                      style: const TextStyle(color: sage, height: 1.5),
                    ),
                  ),
                const Text(
                  'Hasil AI dapat keliru. Periksa bahan dan petunjuk pengelola setempat.',
                  style: TextStyle(color: muted, fontSize: 10, height: 1.5),
                ),
                const SizedBox(height: 17),
                LeafButton(
                  _saved ? 'Tersimpan' : 'Simpan Hasil & Poin',
                  icon: Icons.bookmark_border,
                  onTap: _busy || _saved ? null : _save,
                ),
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
