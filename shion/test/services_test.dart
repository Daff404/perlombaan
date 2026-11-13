// ==== [ IDRUS - FRONTEND ] ==== //
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shion/core/api_client.dart';
import 'package:shion/services/places_service.dart';
import 'helpers.dart';

void main() {
  group('Daftar kelurahan SHION', () {
    test('membaca daftar kelurahan dari server dan pusat peta', () async {
      final klien = ApiClient(
        baseUrl: 'https://contoh.test/api',
        vault: MemoryVault(),
        client: MockClient((permintaan) async {
          expect(permintaan.url.path, '/api/places/nearby');
          expect(permintaan.url.queryParameters['lat'], '-6.9277');
          expect(permintaan.url.queryParameters['lng'], '106.93');
          expect(permintaan.headers['Authorization'], 'Bearer sesi-uji');
          return http.Response(jsonEncode({
            'status': true,
            'data': {
              'center': {'lat': -6.92, 'lng': 106.93},
              'city': 'Kota Sukabumi',
              'places': [],
              'villages': [
                {'id': '32.72.01.1001', 'name': 'Cikole', 'district': 'Cikole', 'type': 'Kelurahan'},
                {'id': '32.72.01.1002', 'name': 'Selabatu', 'district': 'Cikole', 'type': 'Kelurahan'},
              ],
            },
          }), 200);
        }),
      );
      await klien.acceptToken('sesi-uji');
      final layanan = PlacesService(klien);
      addTearDown(klien.close);

      final hasil = await layanan.terdekat(const LatLng(-6.9277, 106.93));
      expect(hasil.tempat, isEmpty);
      expect(hasil.kota, 'Kota Sukabumi');
      expect(hasil.kelurahan, hasLength(2));
      expect(hasil.kelurahan.first['name'], 'Cikole');
      expect(hasil.kelurahan.last['district'], 'Cikole');
      expect(hasil.tengah, const LatLng(-6.92, 106.93));
    });

    test('menolak nama wilayah yang terlalu pendek sebelum meminta server', () async {
      final klien = ApiClient(vault: MemoryVault(), client: MockClient((_) async => http.Response('', 500)));
      final layanan = PlacesService(klien);
      await expectLater(layanan.cariWilayah(' '), throwsA(isA<PlacesException>()));
      klien.close();
    });

    test('menampilkan pesan dari server jika layanan lokasi sedang tidak tersedia', () async {
      final klien = ApiClient(vault: MemoryVault(), client: MockClient((_) async => http.Response(jsonEncode({
        'status': false,
        'error': {'code': 'CITY_NOT_FOUND', 'message': 'Kota belum dikenali dari GPS.'},
      }), 503)));
      await klien.acceptToken('sesi-uji');
      final layanan = PlacesService(klien);
      await expectLater(
        layanan.terdekat(const LatLng(-6.92, 106.93)),
        throwsA(isA<ApiException>().having((galat) => galat.statusCode, 'statusCode', 503)),
      );
      klien.close();
    });
  });
}
