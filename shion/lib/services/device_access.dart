// ==== [ IDRUS - FRONTEND ] ==== //
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/api_client.dart';
import '../core/system_log.dart';

/// Permission prompts and server-backed notification polling. No push-token
/// provider is used; the API remains the source of truth for notifications.
class DeviceAccess {
  static const channel = MethodChannel('id.shion.app/notifications');
  static bool _ditanyakan = false, _kanalSiap = false, _pemeriksaan = false;
  static String? _sesiKunci;
  static final Set<String> _sudahDilihat = {};
  static bool get android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> mintaIzin(BuildContext context, {bool manual = false}) async {
    if (!android || (_ditanyakan && !manual)) return;
    _ditanyakan = true;
    final daftarIzin = [Permission.camera, Permission.locationWhenInUse, Permission.notification];
    final daftarStatus = await Future.wait(daftarIzin.map((p) => p.status));
    if (!context.mounted || (!manual && daftarStatus.every((s) => s.isGranted))) return;
    final disetujui = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Siapkan SHION'),
      content: const Text('Kamera untuk scan sampah dan QR. Lokasi untuk bank sampah terdekat. Notifikasi untuk kabar dari server.\n\nFoto dan video dipilih lewat galeri saat diperlukan.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nanti')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjutkan'))],
    ));
    if (disetujui != true) return;
    bool blocked = false;
    for (final izin in daftarIzin) {
      final status = await izin.status;
      if (status.isPermanentlyDenied) { blocked = true; continue; }
      if (!status.isGranted && !status.isRestricted) await izin.request();
    }
    if (blocked && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Sebagian izin diblokir. Ubah melalui pengaturan aplikasi.'), action: SnackBarAction(label: 'Pengaturan', onPressed: () { unawaited(openAppSettings()); })));
  }

  /// Call after a successful server refresh. New notifications produce native
  /// Android notifications while the app is open; history remains in-app.
  static Future<void> sinkronkan(ApiClient api) async {
    if (!android || !api.hasSession || _pemeriksaan) return;
    _pemeriksaan = true;
    try {
      if (!_kanalSiap) {
        await channel.invokeMethod<void>('channel');
        _kanalSiap = true;
      }
      final kunciSesi = api.mediaHeaders['Authorization'];
      final hasil = await api.permintaan('GET', '/notifications');
      final daftarBaris = (hasil['notifications'] as List? ?? const [])
          .whereType<Map>().map((n) => Map<String, dynamic>.from(n));
      if (_sesiKunci != kunciSesi) {
        _sesiKunci = kunciSesi;
        _sudahDilihat
          ..clear()
          ..addAll(daftarBaris.map((n) => n['id']?.toString() ?? '').where((id) => id.isNotEmpty));
        return;
      }
      if (!await Permission.notification.isGranted) return;
      for (final baris in daftarBaris) {
        final id = baris['id']?.toString() ?? '';
        if (id.isEmpty || !_sudahDilihat.add(id)) continue;
        await channel.invokeMethod<void>('show', {
          'id': id,
          'title': baris['judul']?.toString() ?? baris['title']?.toString() ?? 'SHION',
          'body': baris['desk']?.toString() ?? baris['body']?.toString() ?? '',
        });
      }
    } catch (e) {
      SystemLog.add('server-notification-poll', e);
    } finally {
      _pemeriksaan = false;
    }
  }
}
