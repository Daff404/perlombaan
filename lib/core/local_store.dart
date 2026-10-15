import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-only notebook. This data is not an authenticated account or a verified transaction.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'shion.device.v1';

  Map<String, dynamic> get _document {
    try {
      final decoded = jsonDecode(_prefs.getString(_key) ?? '{}');
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String get name => _document['name'] as String? ?? '';
  int get points => (_document['points'] as num?)?.toInt() ?? 0;
  List<Map<String, dynamic>> records(String collection) {
    final raw = _document[collection];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((value) => Map<String, dynamic>.from(value)).toList();
  }

  Future<void> setName(String value) async {
    final doc = _document..['name'] = value.trim();
    if (!await _prefs.setString(_key, jsonEncode(doc))) {
      throw StateError('Gagal menyimpan profil di perangkat.');
    }
  }

  Future<void> add(String collection, Map<String, dynamic> item) async {
    final doc = _document;
    final previous = records(collection);
    previous.insert(0, {...item, 'createdAt': DateTime.now().toIso8601String()});
    doc[collection] = previous;
    if (!await _prefs.setString(_key, jsonEncode(doc))) {
      throw StateError('Gagal menyimpan catatan di perangkat.');
    }
  }
}
