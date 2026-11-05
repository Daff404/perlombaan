// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:latlong2/latlong.dart';
import '../core/api_client.dart';
import '../settings.dart';

class RecyclingPlace {
  const RecyclingPlace({required this.id, required this.name, required this.point, required this.address, required this.category, this.sourceUrl = ''});
  final String id, name, address, category, sourceUrl;
  final LatLng point;

  factory RecyclingPlace.dariOpenStreetMap(Map<String, dynamic> data) => RecyclingPlace(
    id: data['id'] as String,
    name: data['name'] as String? ?? 'Lokasi tanpa nama',
    point: LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble()),
    address: data['address'] as String? ?? '',
    category: data['category'] as String? ?? 'bank_sampah',
    sourceUrl: data['sourceUrl'] as String? ?? '',
  );
}

class HasilPencarianTempat {
  const HasilPencarianTempat({required this.tengah, required this.tempat});
  final LatLng tengah;
  final List<RecyclingPlace> tempat;
}

class PlacesException implements Exception {
  const PlacesException(this.pesan);
  final String pesan;
  @override
  String toString() => pesan;
}

class PlacesService {
  PlacesService(this.api);
  final ApiClient api;

  Future<HasilPencarianTempat> terdekat(LatLng pusat, {int radius = Settings.searchRadiusMeters}) async {
    final query = Uri(queryParameters: {
      'lat': '${pusat.latitude}', 'lng': '${pusat.longitude}', 'radius': '$radius',
    }).query;
    return _baca('/places/nearby?$query', pusat);
  }

  Future<HasilPencarianTempat> cariWilayah(String wilayah) async {
    final namaWilayah = wilayah.trim();
    if (namaWilayah.length < 2 || namaWilayah.length > 120) {
      throw const PlacesException('Masukkan nama kota, kecamatan, atau kelurahan yang valid.');
    }
    final query = Uri(queryParameters: {'query': namaWilayah}).query;
    return _baca('/places/search?$query', const LatLng(-6.9277, 106.93));
  }

  Future<HasilPencarianTempat> _baca(String jalur, LatLng pusatAwal) async {
    try {
      final data = await api.permintaan('GET', jalur);
      final pusat = data['center'] is Map
          ? LatLng((data['center']['lat'] as num).toDouble(), (data['center']['lng'] as num).toDouble())
          : pusatAwal;
      final tempat = (data['places'] as List? ?? [])
          .whereType<Map>()
          .map((baris) => RecyclingPlace.dariOpenStreetMap(Map<String, dynamic>.from(baris)))
          .toList();
      return HasilPencarianTempat(tengah: pusat, tempat: tempat);
    } on ApiException catch (error) {
      rethrow;
    }
  }
}
