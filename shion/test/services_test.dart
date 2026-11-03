// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shion/services/places_service.dart';

void main() {
  group('SHION Sukabumi map data', () {
    test('lists curated local waste-bank points near Sukabumi', () async {
      final layanan = PlacesService();
      addTearDown(layanan.close);
      final daftarTempat = await layanan.terdekat(const LatLng(-6.9277, 106.93));
      expect(daftarTempat.length, greaterThanOrEqualTo(3));
      expect(daftarTempat.any((p) => p.name.contains('SAMMI')), isTrue);
      expect(daftarTempat.every((p) => p.point.latitude < 0 && p.point.longitude > 106), isTrue);
    });
    test('outside Sukabumi has no hard-coded map markers', () async {
      final layanan = PlacesService();
      expect(await layanan.terdekat(const LatLng(0, 0)), isEmpty);
    });
    test('city search stays on local Sukabumi data', () async {
      final layanan = PlacesService();
      expect((await layanan.cariKota('Sukabumi')).latitude, closeTo(-6.9277, .0001));
      await expectLater(layanan.cariKota('Jakarta'), throwsA(isA<PlacesException>()));
    });
  });
}
