import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings.dart';

class ScanSave {
  const ScanSave(this.points, this.reason);
  final int points;
  final String reason;
}

class LocalStore {
  LocalStore(this._preferences);
  final SharedPreferences _preferences;
  static const _storageKey = 'shion.local.v1';
  Future<void> _pending = Future.value();
  Map<String, dynamic> _read() {
    try {
      final data = jsonDecode(_preferences.getString(_storageKey) ?? '{}');
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } catch (_) {
      return {};
    }
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
    final list = data[key];
    return list is List
        ? list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];
  }

  String get name => _read()['name'] as String? ?? '';
  List<Map<String, dynamic>> getList(String key) => _list(_read(), key);
  int get points => getList(
    'ledger',
  ).fold<int>(0, (sum, r) => sum + (r['delta'] as num).toInt());
  Future<T> _atomic<T>(Future<T> Function(Map<String, dynamic>) action) {
    final completer = Completer<T>();
    _pending = _pending.then((_) async {
      try {
        completer.complete(await action(_read()));
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<void> _write(Map<String, dynamic> data) async {
    if (!await _preferences.setString(_storageKey, jsonEncode(data)))
      throw StateError('Data gagal disimpan.');
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  Future<void> setName(String name) => _atomic((data) async {
    data['name'] = name.trim();
    await _write(data);
  });
  Future<void> addRecord(String key, Map<String, dynamic> record) => _atomic((
    data,
  ) async {
    if (['ledger', 'guides', 'scans'].contains(key))
      throw StateError('Gunakan transaksi khusus untuk data ini.');
    data[key] = [
      {'id': _id(), ...record, 'createdAt': DateTime.now().toIso8601String()},
      ..._list(data, key),
    ];
    await _write(data);
  });
  static bool similarHash(String a, String b) {
    if (a.length != 16 || b.length != 16) return false;
    try {
      var x = BigInt.parse(a, radix: 16) ^ BigInt.parse(b, radix: 16);
      var bits = 0;
      while (x > BigInt.zero) {
        bits++;
        x &= x - BigInt.one;
        if (bits > 4) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ScanSave> saveScan({
    required Map<String, dynamic> result,
    required String photoBase64,
    required String hash,
    required String perceptualHash,
    required String model,
  }) => _atomic((data) async {
    final scans = _list(data, 'scans');
    final ledger = _list(data, 'ledger');
    final now = DateTime.now();
    final today = now.toIso8601String().split('T').first;
    final duplicate = scans.any(
      (s) =>
          s['imageHash'] == hash ||
          similarHash(s['perceptualHash'] as String? ?? '', perceptualHash),
    );
    final eligible =
        result['isWaste'] == true &&
        result['category'] != 'Tidak jelas' &&
        (result['confidence'] as num? ?? 0) >= .65;
    final count = ledger
        .where(
          (l) =>
              l['kind'] == 'scan' &&
              (l['createdAt'] as String? ?? '').startsWith(today),
        )
        .length;
    final points =
        !duplicate && eligible && count < Settings.rewardedScansPerDay
        ? Settings.pointsPerScan
        : 0;
    final reason = duplicate
        ? 'Foto ini sama atau sangat mirip dengan foto yang pernah disimpan.'
        : !eligible
        ? 'Objek belum cukup jelas dikenali sebagai sampah.'
        : count >= Settings.rewardedScansPerDay
        ? 'Batas ${Settings.rewardedScansPerDay} scan berpoin per hari sudah tercapai.'
        : 'Scan AI baru berhasil dicatat.';
    final id = _id();
    data['scans'] = [
      {
        ...result,
        'id': id,
        'createdAt': now.toIso8601String(),
        'classification': 'Gemini AI',
        'photoBase64': photoBase64,
        'imageHash': hash,
        'perceptualHash': perceptualHash,
        'model': model,
        'earnedPoints': points,
      },
      ...scans,
    ];
    if (points > 0)
      data['ledger'] = [
        {
          'id': 'scan-$id',
          'scanId': id,
          'delta': points,
          'kind': 'scan',
          'description': 'Pindai ${result['name']}',
          'createdAt': now.toIso8601String(),
        },
        ...ledger,
      ];
    await _write(data);
    return ScanSave(points, reason);
  });
  Future<void> redeemGuide({
    required String guide,
    required String requestId,
  }) => _atomic((data) async {
    final guides = _list(data, 'guides');
    if (guides.any((g) => g['id'] == requestId)) return;
    final ledger = _list(data, 'ledger');
    final balance = ledger.fold<int>(
      0,
      (sum, l) => sum + (l['delta'] as num).toInt(),
    );
    if (balance < Settings.guideCost) throw StateError('Poin belum cukup.');
    if (guide.trim().length < 100)
      throw StateError('Panduan belum valid. Poin tidak dipotong.');
    final timestamp = DateTime.now().toIso8601String();
    data['guides'] = [
      {'id': requestId, 'text': guide, 'createdAt': timestamp},
      ...guides,
    ];
    data['ledger'] = [
      {
        'id': 'guide-$requestId',
        'delta': -Settings.guideCost,
        'kind': 'guide',
        'description': 'Panduan Pilah Personal',
        'createdAt': timestamp,
      },
      ...ledger,
    ];
    await _write(data);
  });
}
