// ==== [ IDRUS - FRONTEND ] ==== //
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shion/core/api_client.dart';

class MemoryVault implements SessionVault {
  String? token;
  int writes = 0;
  @override Future<String?> read() async => token;
  @override Future<void> write(String value) async { token = value; writes++; }
  @override Future<void> clear() async { token = null; }
}
Map<String, dynamic> state({int revision = 1, int poin = 10, String role = 'user'}) => {
  'revision': revision,
  'user': {'id': 'one', 'name': 'Daffa', 'email': 'daffa@example.com', 'phone': '081234567890', 'role': role},
  'points': poin, 'scans': [], 'deposits': [], 'ledger': [], 'notifications': [], 'rewards': [], 'messages': [],
};
http.Response ok(Map<String, dynamic> data) => http.Response(jsonEncode({'status': true, 'data': data}), 200);
