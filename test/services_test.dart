import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shion/core/local_store.dart';
import 'package:shion/services/gemini_service.dart';
import 'package:shion/services/places_service.dart';
import 'package:shion/settings.dart';

Map<String, dynamic> validWaste() => {
  'isWaste': true,
  'name': 'Botol PET',
  'category': 'Plastik',
  'material': 'PET',
  'recyclable': true,
  'steps': ['Kosongkan botol.', 'Pisahkan sesuai aturan tempat setor.'],
  'warning': '',
  'confidence': .9,
};
String aiResponse(Object data) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': data is String ? data : jsonEncode(data)},
        ],
      },
    },
  ],
});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Gemini request and response handling', () {
    test('sends image bytes, schema, model and API key in header', () async {
      final client = MockClient((req) async {
        expect(req.url.path, contains('/models/test-model:generateContent'));
        expect(req.url.queryParameters.containsKey('key'), isFalse);
        expect(req.headers['x-goog-api-key'], 'test-key');
        final j = jsonDecode(req.body) as Map;
        expect(
          j['contents'][0]['parts'][0]['inlineData']['data'],
          base64Encode([1, 2, 3]),
        );
        expect(j['generationConfig']['responseMimeType'], 'application/json');
        return http.Response(aiResponse(validWaste()), 200);
      });
      final service = GeminiService(
        client: client,
        apiKey: 'test-key',
        model: 'test-model',
      );
      addTearDown(service.close);
      final result = await service.classify(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );
      expect(result.category, 'Plastik');
      expect(result.name, 'Botol PET');
    });
    test('empty API key does not send a request', () async {
      final s = GeminiService(
        apiKey: '',
        client: MockClient((_) async => throw StateError('must not send')),
      );
      addTearDown(s.close);
      await expectLater(
        s.classify(Uint8List.fromList([1]), 'image/jpeg'),
        throwsA(isA<AiException>()),
      );
    });
    for (final status in [400, 403, 404, 429, 500]) {
      test('HTTP $status produces a usable error, no fake result', () async {
        final s = GeminiService(
          apiKey: 'key',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        addTearDown(s.close);
        await expectLater(
          s.classify(Uint8List.fromList([1]), 'image/jpeg'),
          throwsA(isA<AiException>()),
        );
      });
    }
    test('timeout produces an actionable error', () async {
      final s = GeminiService(
        apiKey: 'key',
        client: MockClient((_) async => throw TimeoutException('test')),
      );
      addTearDown(s.close);
      await expectLater(
        s.classify(Uint8List.fromList([1]), 'image/jpeg'),
        throwsA(isA<AiException>()),
      );
    });
    test('blocked empty candidates do not become a scan', () async {
      final s = GeminiService(
        apiKey: 'key',
        client: MockClient(
          (_) async => http.Response('{"candidates":[]}', 200),
        ),
      );
      addTearDown(s.close);
      await expectLater(
        s.classify(Uint8List.fromList([1]), 'image/jpeg'),
        throwsA(isA<AiException>()),
      );
    });
    test('unknown category or incomplete output is rejected', () {
      expect(
        () => WasteResult.fromJson({...validWaste(), 'category': 'unknown'}),
        throwsA(isA<AiException>()),
      );
      expect(
        () => WasteResult.fromJson({...validWaste(), 'steps': []}),
        throwsA(isA<AiException>()),
      );
    });
    test('guide requests contain scan summary and no photo', () async {
      final s = GeminiService(
        apiKey: 'key',
        client: MockClient((r) async {
          expect(r.body, contains('Botol PET'));
          expect(r.body, isNot(contains('secret-photo')));
          return http.Response(
            aiResponse(
              List.filled(
                10,
                'Gunakan wadah terpisah dan tanyakan aturan penerimaan.',
              ).join(' '),
            ),
            200,
          );
        }),
      );
      addTearDown(s.close);
      expect(
        (await s.createGuide([
          {
            'name': 'Botol PET',
            'category': 'Plastik',
            'material': 'PET',
            'photoBase64': 'secret-photo',
          },
        ])).length,
        greaterThan(100),
      );
    });
  });
  group('atomic local points ledger', () {
    late LocalStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = LocalStore(await SharedPreferences.getInstance());
    });
    Future<ScanSave> save(
      String hash,
      String ph, {
      Map<String, dynamic>? result,
    }) => store.saveScan(
      result: result ?? validWaste(),
      photoBase64: 'photo',
      hash: hash,
      perceptualHash: ph,
      model: 'test-model',
    );
    test('first scan earns points and persists with its ledger', () async {
      final r = await save('a', '0000000000000000');
      expect(r.points, Settings.pointsPerScan);
      final reopened = LocalStore(await SharedPreferences.getInstance());
      expect(reopened.points, Settings.pointsPerScan);
      expect(reopened.getList('scans').length, 1);
    });
    test('same or visually similar photo does not earn twice', () async {
      await save('a', '0000000000000000');
      expect((await save('a', 'ffffffffffffffff')).points, 0);
      expect((await save('b', '0000000000000001')).points, 0);
      expect(store.points, Settings.pointsPerScan);
    });
    test('unclear or non-waste photos do not earn points', () async {
      expect(
        (await save(
          'a',
          '0000000000000000',
          result: {...validWaste(), 'isWaste': false},
        )).points,
        0,
      );
      expect(
        (await save(
          'b',
          'ffffffffffffffff',
          result: {...validWaste(), 'confidence': .2},
        )).points,
        0,
      );
      expect(store.points, 0);
    });
    test('daily limit is enforced using ledger entries', () async {
      final hashes = [
        '0000000000000000',
        'ffffffffffffffff',
        'aaaaaaaaaaaaaaaa',
        '5555555555555555',
        '3333333333333333',
        'cccccccccccccccc',
      ];
      for (var i = 0; i < hashes.length; i++) {
        final r = await save('hash-$i', hashes[i]);
        expect(
          r.points,
          i < Settings.rewardedScansPerDay ? Settings.pointsPerScan : 0,
        );
      }
      expect(
        store.points,
        Settings.pointsPerScan * Settings.rewardedScansPerDay,
      );
    });
    test('concurrent duplicate save cannot double award', () async {
      await Future.wait([
        save('a', '0000000000000000'),
        save('a', '0000000000000000'),
      ]);
      expect(store.points, Settings.pointsPerScan);
    });
    test('redeem requires sufficient balance and successful guide', () async {
      final text = List.filled(10, 'Panduan lokal yang lengkap.').join(' ');
      await expectLater(
        store.redeemGuide(guide: text, requestId: 'x'),
        throwsStateError,
      );
      expect(store.points, 0);
      await save('a', '0000000000000000');
      await save('b', 'ffffffffffffffff');
      await expectLater(
        store.redeemGuide(guide: 'short', requestId: 'x'),
        throwsStateError,
      );
      expect(store.points, 20);
      await store.redeemGuide(guide: text, requestId: 'x');
      expect(store.points, 0);
      expect(store.getList('guides').length, 1);
      await store.redeemGuide(guide: text, requestId: 'x');
      expect(store.points, 0);
      expect(store.getList('guides').length, 1);
    });
    test('parallel redemption cannot overspend', () async {
      await save('a', '0000000000000000');
      await save('b', 'ffffffffffffffff');
      final text = List.filled(20, 'Panduan ini tersimpan.').join(' ');
      final outcomes = await Future.wait(
        ['x', 'y'].map((id) async {
          try {
            await store.redeemGuide(guide: text, requestId: id);
            return true;
          } catch (_) {
            return false;
          }
        }),
      );
      expect(outcomes.where((x) => x).length, 1);
      expect(store.points, 0);
    });
  });
  group('real map source parsing', () {
    test('parses node and way centers and sends recycling query', () async {
      final service = PlacesService(
        client: MockClient((r) async {
          expect(r.url.host, 'overpass-api.de');
          expect(r.body, contains('recycling'));
          expect(r.body, contains('15000'));
          return http.Response(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'id': 1,
                  'lat': -6.92,
                  'lon': 106.93,
                  'tags': {
                    'amenity': 'recycling',
                    'name': 'Recorded recycling place',
                    'recycling:plastic': 'yes',
                  },
                },
                {
                  'type': 'way',
                  'id': 2,
                  'center': {'lat': -6.93, 'lon': 106.94},
                  'tags': {'amenity': 'waste_disposal'},
                },
                {
                  'type': 'node',
                  'id': 3,
                  'tags': {'name': 'Missing coordinates'},
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      final places = await service.nearby(const LatLng(-6.9277, 106.93));
      expect(places.length, 2);
      expect(places.any((p) => p.materials.contains('plastic')), isTrue);
    });
    test('empty map data stays empty, no invented partners', () async {
      final s = PlacesService(
        client: MockClient((_) async => http.Response('{"elements":[]}', 200)),
      );
      addTearDown(s.close);
      expect(await s.nearby(const LatLng(-6.9, 106.9)), isEmpty);
    });
    test('city lookup uses submitted query and coordinates', () async {
      final s = PlacesService(
        client: MockClient((r) async {
          expect(r.url.queryParameters['q'], 'Sukabumi');
          return http.Response('[{"lat":"-6.9277","lon":"106.93"}]', 200);
        }),
      );
      addTearDown(s.close);
      expect((await s.searchCity('Sukabumi')).latitude, -6.9277);
    });
    test('unavailable map API returns a visible error', () async {
      final s = PlacesService(
        client: MockClient((_) async => http.Response('{}', 503)),
      );
      addTearDown(s.close);
      await expectLater(
        s.nearby(const LatLng(0, 0)),
        throwsA(isA<PlacesException>()),
      );
    });
  });
}
