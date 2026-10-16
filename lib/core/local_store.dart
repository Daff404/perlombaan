import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._preferences);

  final SharedPreferences _preferences;
  static const _storageKey = 'shion.local.v1';

  Map<String, dynamic> _read() {
    try {
      final value = jsonDecode(_preferences.getString(_storageKey) ?? '{}');
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String get name => _read()['name'] as String? ?? '';

  List<Map<String, dynamic>> getList(String key) {
    final value = _read()[key];
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _write(Map<String, dynamic> data) async {
    if (!await _preferences.setString(_storageKey, jsonEncode(data))) {
      throw StateError('Data gagal disimpan pada perangkat.');
    }
  }

  Future<void> setName(String value) async {
    final data = _read()..['name'] = value.trim();
    await _write(data);
  }

  Future<void> addRecord(String key, Map<String, dynamic> record) async {
    final data = _read();
    final records = getList(key);
    records.insert(0, <String, dynamic>{
      ...record,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    data[key] = records;
    await _write(data);
  }
}
