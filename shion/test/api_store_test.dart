// ==== [ IDRUS - FRONTEND ] ==== //
import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shion/core/api_client.dart';
import 'package:shion/core/api_store.dart';
import 'helpers.dart';

void main() {
  test('signup sends no role; only token persists and profile is read remotely', () async {
    final brankas = MemoryVault();
    final klien = ApiClient(vault: brankas, client: MockClient((request) async {
      if (request.url.path.endsWith('/auth/register')) {
        final isi = jsonDecode(request.body) as Map;
        expect(isi.containsKey('role'), isFalse);
        expect(isi['password'], 'safe-password');
        expect(request.url.host, 'app.daffaputra.id');
        return ok({'token': 'opaque-session', 'state': state()});
      }
      expect(request.headers['Authorization'], 'Bearer opaque-session');
      return ok(state(revision: 2));
    }));
    final penyimpanan = ApiStore(api: klien);
    addTearDown(() { penyimpanan.dispose(); klien.close(); });
    await penyimpanan.daftarkanAkun(name: 'Daffa', email: 'daffa@example.com', phone: '081234567890', password: 'safe-password');
    expect(brankas.token, 'opaque-session'); expect(brankas.writes, 1);
    expect(penyimpanan.adalahAdmin, false); expect(penyimpanan.name, 'Daffa');
    final another = ApiStore(api: ApiClient(vault: brankas, client: MockClient((request) async => ok(state(revision: 2)))));
    addTearDown(() { another.api.close(); another.dispose(); });
    expect(another.name, '');
    await another.pulihkanSesi(); expect(another.name, 'Daffa');
  });
  test('401 clears secure token and memory snapshot; no local data fallback', () async {
    final brankas = MemoryVault()..token = 'old-session';
    final klien = ApiClient(vault: brankas, client: MockClient((request) async => http.Response(jsonEncode({'status': false, 'error': {'code': 'SESSION_EXPIRED', 'message': 'Masuk kembali.'}}), 401)));
    final penyimpanan = ApiStore(api: klien);
    addTearDown(() { penyimpanan.dispose(); klien.close(); });
    await penyimpanan.pulihkanSesi();
    expect(penyimpanan.sudahMasuk, false); expect(penyimpanan.name, ''); expect(brankas.token, isNull);
  });
  test('logout revokes server session then clears token and snapshot', () async {
    final brankas = MemoryVault()..token = 'old-session';
    var revoked = false;
    final klien = ApiClient(vault: brankas, client: MockClient((request) async {
      if (request.url.path.endsWith('/auth/logout')) { revoked = true; return ok({'loggedOut': true}); }
      return ok(state());
    }));
    final penyimpanan = ApiStore(api: klien);
    addTearDown(() { penyimpanan.dispose(); klien.close(); });
    await penyimpanan.pulihkanSesi(); await penyimpanan.keluar();
    expect(revoked, true); expect(brankas.token, isNull); expect(penyimpanan.poin, 0); expect(penyimpanan.sudahMasuk, false);
  });
  test('old delayed refresh cannot overwrite a newer transaction', () async {
    final brankas = MemoryVault()..token = 'session';
    final delayed = Completer<http.Response>();
    var calls = 0;
    final klien = ApiClient(vault: brankas, client: MockClient((request) async {
      if (request.url.path.endsWith('/state')) {
        if (calls++ == 0) return ok(state());
        return delayed.future;
      }
      return ok(state(revision: 3, points: 30));
    }));
    final penyimpanan = ApiStore(api: klien);
    addTearDown(() { penyimpanan.dispose(); klien.close(); });
    await penyimpanan.pulihkanSesi(); final oldRefresh = penyimpanan.segarkan();
    await penyimpanan.tambahCatatan('activities', {'activity': 'Jalan kaki'});
    delayed.complete(ok(state(revision: 2, points: 10))); await oldRefresh;
    expect(penyimpanan.poin, 30);
  });
}
