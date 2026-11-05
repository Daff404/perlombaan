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
  group('Pencarian lokasi SHION dari OpenStreetMap', () {
    test('mengubah hasil bank sampah dan kantor kelurahan menjadi lokasi peta', () async {
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
              'places': [
                {'id': 'bank-1', 'name': 'Bank Sampah Sukabumi', 'lat': -6.91, 'lng': 106.92, 'address': 'Sukabumi', 'category': 'bank_sampah', 'sourceUrl': 'https://www.openstreetmap.org/node/1'},
                {'id': 'kantor-1', 'name': 'Kantor Kelurahan', 'lat': -6.92, 'lng': 106.94, 'address': 'Sukabumi', 'category': 'kelurahan'},
              ],
            },
          }), 200);
        }),
      );
      await klien.acceptToken('sesi-uji');
      final layanan = PlacesService(klien);
      addTearDown(klien.close);

      final hasil = await layanan.terdekat(const LatLng(-6.9277, 106.93));
      expect(hasil.tempat, hasLength(2));
      expect(hasil.tempat.first.name, 'Bank Sampah Sukabumi');
      expect(hasil.tempat.first.category, 'bank_sampah');
      expect(hasil.tempat.last.category, 'kelurahan');
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
        'error': {'code': 'MAPS_NOT_CONFIGURED', 'message': 'Peta Google belum dikonfigurasi pada server.'},
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
