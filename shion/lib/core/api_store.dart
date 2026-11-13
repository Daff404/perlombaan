// ==== [ IDRUS - FRONTEND ] ==== //
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Server-owned account data. This snapshot exists only in RAM for rendering.
/// Every write is an authenticated REST transaction; there is no offline DB.
class ApiStore extends ChangeNotifier {
  ApiStore({ApiClient? api}) : api = api ?? ApiClient.dibagikan {
    this.api.onExpired = _kedaluwarsa;
  }
  final ApiClient api;
  Map<String, dynamic> _cuplikan = {};
  bool get sudahMasuk => api.hasSession && _cuplikan['user'] is Map;
  Map<String, dynamic> get user => Map<String, dynamic>.from(_cuplikan['user'] as Map? ?? {});
  String get name {
    if (!sudahMasuk) return '';
    final value = user['name']?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    final username = user['username']?.toString().trim() ?? '';
    return username.isNotEmpty && username.toLowerCase() != 'null' ? username : 'Pengguna SHION';
  }
  String get email => user['email'] as String? ?? '';
  String get phone => user['phone'] as String? ?? '';
  bool get adalahAdmin => user['role'] == 'admin';
  int get poin => (_cuplikan['points'] as num? ?? 0).toInt();
  int get notifikasiBelumDibaca => ambilDaftar('notifications').where((n) => n['read'] != true).length;
  Map<String, dynamic>? get pemindaianTerakhir => _cuplikan['lastDetection'] is Map ? Map<String, dynamic>.from(_cuplikan['lastDetection'] as Map) : null;
  List<Map<String, dynamic>> ambilDaftar(String key) => (_cuplikan[key] as List? ?? []).whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList();
  List<Map<String, dynamic>> get katalogHadiah => ambilDaftar('rewards');

  void _ganti(Map<String, dynamic> data) {
    final penggunaMasuk = data['user'] as Map?;
    if (penggunaMasuk?['id'] == user['id'] && (data['revision'] as num? ?? 0) < (_cuplikan['revision'] as num? ?? 0)) return;
    _cuplikan = data;
    notifyListeners();
  }
  void _kedaluwarsa() { _cuplikan = {}; notifyListeners(); }
  Future<void> pulihkanSesi() async {
    await api.restoreToken();
    if (!api.hasSession) return;
    try { await segarkan(); }
    on ApiException catch (error) { if (error.statusCode != 401) rethrow; }
  }
  Future<void> segarkan() async => _ganti(await api.permintaan('GET', '/state'));
  Future<void> _terimaAutentikasi(Map<String, dynamic> response) async {
    await api.acceptToken(response['token'] as String);
    _ganti(Map<String, dynamic>.from(response['state'] as Map));
  }
  Future<void> autentikasi({required String email, required String password}) async {
    await _terimaAutentikasi(await api.permintaan('POST', '/auth/login', authenticated: false, body: {'email': email.trim(), 'password': password}));
  }
  Future<void> daftarkanAkun({required String name, required String email, required String phone, required String password}) async {
    await _terimaAutentikasi(await api.permintaan('POST', '/auth/register', authenticated: false, body: {'name': name.trim(), 'email': email.trim(), 'phone': phone.trim(), 'password': password}));
  }
  Future<void> keluar() async {
    await api.permintaan('POST', '/auth/logout', body: {});
    await api.clearSession();
    _kedaluwarsa();
  }
  Future<void> aturNama(String name) => aturProfil(name: name, email: email, phone: phone);
  Future<void> aturProfil({required String name, required String email, required String phone}) async => _ganti(await api.permintaan('PUT', '/profile', body: {'name': name, 'email': email, 'phone': phone}));

  Future<Map<String, dynamic>> analisisPindai(Uint8List bytes, String requestId) async {
    final hasil = await api.permintaan('POST', '/scans', body: {'photoBase64': base64Encode(bytes), 'requestId': requestId});
    _ganti(Map<String, dynamic>.from(hasil['state'] as Map));
    return hasil;
  }
  Future<void> konfirmasiSetoran({required String category, required String scanId, required double kg, String unit = 'kg', required String kelurahanId, required String requestId}) async => _ganti(await api.permintaan('POST', '/deposits', body: {'scanId': scanId, 'quantity': kg, 'unit': unit, 'kelurahanId': kelurahanId, 'requestId': requestId}));
  Future<void> tambahCatatan(String key, Map<String, dynamic> record) async {
    if (!['activities', 'places'].contains(key)) throw const ApiException('Jenis catatan tidak didukung.');
    _ganti(await api.permintaan('POST', '/$key', body: record));
  }
  Future<String> tukarHadiah(String rewardId, String requestId) async {
    final hasil = await api.permintaan('POST', '/rewards/${Uri.encodeComponent(rewardId)}/redeem', body: {'requestId': requestId});
    _ganti(Map<String, dynamic>.from(hasil['state'] as Map));
    return hasil['code'] as String;
  }
  Future<String> buatPanduan(String requestId) async {
    final hasil = await api.permintaan('POST', '/guides', body: {'requestId': requestId});
    _ganti(Map<String, dynamic>.from(hasil['state'] as Map));
    return hasil['guide'] as String;
  }
  Future<String> kirimPesanAi(String message, String requestId) async {
    final hasil = await api.permintaan('POST', '/chat', body: {'message': message, 'requestId': requestId});
    _ganti(Map<String, dynamic>.from(hasil['state'] as Map));
    return hasil['answer'] as String;
  }
  Future<void> tandaiNotifikasiDibaca(List<String> ids) async {
    final hasil = await api.permintaan('POST', '/notifications/read', body: {'ids': ids});
    _ganti(hasil);
  }
  Future<Map<String, dynamic>> papanPeringkat(String metric) => api.permintaan('GET', '/leaderboard?metric=$metric');
  Future<Map<String, dynamic>> daftarPenggunaAdmin() => api.permintaan('GET', '/admin/users');
  Future<Map<String, dynamic>> notifikasiAdmin() => api.permintaan('GET', '/admin/notifications');
  Future<int> kirimNotifikasi({required String title, required String body, String? gambar, required String requestId}) async {
    final hasil = await api.permintaan('POST', '/admin/notifications', body: {'title': title, 'body': body, 'gambar': gambar, 'requestId': requestId});
    return (hasil['recipients'] as num).toInt();
  }
  Future<Map<String, dynamic>> edukasi() => api.permintaan('GET', '/education');
  Future<Map<String, dynamic>> edukasiAdmin() => api.permintaan('GET', '/admin/education');
  Future<void> terbitkanEdukasi(Map<String, dynamic> article) async { await api.permintaan('POST', '/admin/education', body: article); }
  Future<void> hapusEdukasi(String id) async { await api.permintaan('DELETE', '/admin/education/${Uri.encodeComponent(id)}'); }
  Future<void> ubahKataSandi(String current, String next) async { await api.permintaan('PUT', '/auth/password', body: {'currentPassword': current, 'newPassword': next}); }
  @override
  void dispose() { api.onExpired = null; super.dispose(); }
}
