// ==== [ IDRUS - FRONTEND ] ==== //
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../settings.dart';

class ApiException implements Exception {
  const ApiException(this.pesan, {this.statusCode = 0, this.code = ''});
  final String pesan;
  final int statusCode;
  final String code;
  @override
  String toString() => pesan;
}

abstract class SessionVault {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Only an opaque session token is persisted. No account or activity database
/// is written to the device. Web sessions are memory-only.
class SecureSessionVault implements SessionVault {
  static const _kunci = 'shion.api.session.v1';
  static const _penyimpanan = FlutterSecureStorage();
  String? _webToken;
  @override
  Future<String?> read() async {
    if (kIsWeb) return _webToken;
    return await _penyimpanan.read(key: _kunci);
  }
  @override
  Future<void> write(String token) async {
    if (kIsWeb) { _webToken = token; return; }
    await _penyimpanan.write(key: _kunci, value: token);
  }
  @override
  Future<void> clear() async {
    _webToken = null;
    if (!kIsWeb) await _penyimpanan.delete(key: _kunci);
  }
}

class ApiClient {
  static final activeRequests = ValueNotifier<int>(0);
  ApiClient({http.Client? client, SessionVault? vault, String? baseUrl})
      : _klien = client ?? http.Client(),
        _brankas = vault ?? SecureSessionVault(),
        baseUrl = (baseUrl ?? Settings.apiBaseUrl).replaceFirst(RegExp(r'/+$'), '');
  static final dibagikan = ApiClient();
  final http.Client _klien;
  final SessionVault _brankas;
  final String baseUrl;
  String? _token;
  VoidCallback? onExpired;
  bool get hasSession => _token != null;
  Map<String, String> get mediaHeaders => {'Authorization': 'Bearer $_token'};
  Future<void> unggahMediaGrup(String groupId, String kind, Uint8List bytes, String requestId, {String? replyToId}) async {
    activeRequests.value++;
    try {
      await _unggahMediaGrup(groupId, kind, bytes, requestId, replyToId: replyToId);
    } finally { activeRequests.value--; }
  }
  Future<void> _unggahMediaGrup(String groupId, String kind, Uint8List bytes, String requestId, {String? replyToId}) async {
    if (!hasSession) throw const ApiException('Silakan masuk terlebih dahulu.');
    if (bytes.length > 20 * 1024 * 1024) throw const ApiException('Ukuran media maksimal 20 MB.');
    final token = _token;
    final alamat = Uri.parse('$baseUrl/groups/$groupId/media').replace(queryParameters: {'kind': kind, 'requestId': requestId, if (replyToId != null) 'replyToId': replyToId});
    final balasan = await _klien.post(alamat, headers: {...mediaHeaders, 'Content-Type': 'application/octet-stream'}, body: bytes).timeout(const Duration(seconds: 120));
    if (token != _token) throw const ApiException('Sesi telah berubah.');
    if (balasan.statusCode == 401) { await clearSession(); onExpired?.call(); }
    if (balasan.statusCode >= 300) {
      String pesan = 'Media gagal dikirim (${balasan.statusCode}).';
      try { pesan = jsonDecode(balasan.body)['error']['message'] as String; } catch (_) {}
      throw ApiException(pesan, statusCode: balasan.statusCode);
    }
  }

  Future<void> restoreToken() async { _token = await _brankas.read(); }
  Future<void> acceptToken(String token) async {
    await _brankas.write(token);
    _token = token;
  }
  Future<void> clearSession() async {
    _token = null;
    await _brankas.clear();
  }
  void close() => _klien.close();

  static String buatIdPermintaan() => '${DateTime.now().microsecondsSinceEpoch}-${List.generate(12, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

  Future<http.Response> _kirim(String method, String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    activeRequests.value++;
    try {
      return await _kirimInternal(method, path, body: body, authenticated: authenticated);
    } finally {
      activeRequests.value--;
    }
  }

  Future<http.Response> _kirimInternal(String method, String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    if (authenticated && !hasSession) throw const ApiException('Silakan masuk terlebih dahulu.', statusCode: 401);
    final tokenTerkirim = _token;
    final permintaan = http.Request(method, Uri.parse('$baseUrl$path'));
    permintaan.headers.addAll({'Accept': 'application/json', 'Content-Type': 'application/json', if (authenticated) 'Authorization': 'Bearer $_token'});
    if (body != null) permintaan.body = jsonEncode(body);
    http.Response balasan;
    try {
      balasan = await _klien.send(permintaan).then(http.Response.fromStream).timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const ApiException('Server belum merespons. Periksa koneksi lalu coba lagi.');
    } catch (_) {
      throw const ApiException('Tidak dapat terhubung ke server SHION. Periksa koneksi dan alamat server.');
    }
    if (authenticated && tokenTerkirim != _token) {
      throw const ApiException('Sesi telah berubah. Buka kembali halaman ini.', statusCode: 401, code: 'SESSION_CHANGED');
    }
    if (balasan.statusCode == 401 && authenticated) {
      try { await clearSession(); } catch (_) {}
      onExpired?.call();
    }
    if (balasan.statusCode < 200 || balasan.statusCode >= 300) {
      var pesan = 'Permintaan gagal (HTTP ${balasan.statusCode}).';
      var kode = '';
      try {
        final json = jsonDecode(balasan.body) as Map;
        final galat = json['error'];
        if (galat is Map) { pesan = galat['message']?.toString() ?? pesan; kode = galat['code']?.toString() ?? ''; }
      } catch (_) {}
      throw ApiException(pesan, statusCode: balasan.statusCode, code: kode);
    }
    return balasan;
  }

  Future<Map<String, dynamic>> permintaan(String method, String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    final balasan = await _kirim(method, path, body: body, authenticated: authenticated);
    try {
      final json = jsonDecode(balasan.body);
      if (json is! Map || json['status'] != true || json['data'] is! Map) throw const FormatException();
      return Map<String, dynamic>.from(json['data'] as Map);
    } catch (_) {
      throw const ApiException('Respons server tidak dikenali. Pastikan server SHION sudah dipasang pada domain.');
    }
  }
  Future<Uint8List> ambilByte(String path) async => (await _kirim('GET', path)).bodyBytes;
}
