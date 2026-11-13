// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:latlong2/latlong.dart';
import '../core/api_client.dart';

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
  const HasilPencarianTempat({required this.tengah, required this.tempat, this.kelurahan = const [], this.kota = '', this.ringkasan = ''});
  final String ringkasan;
  final String kota;
  final List<Map<String, dynamic>> kelurahan;
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

  Future<HasilPencarianTempat> terdekat(LatLng pusat, {int radius = 50000}) async {
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
      final data = await api.permintaan('GET', jalur);
      final pusat = data['center'] is Map
          ? LatLng((data['center']['lat'] as num).toDouble(), (data['center']['lng'] as num).toDouble())
          : pusatAwal;
      final tempat = (data['places'] as List? ?? [])
          .whereType<Map>()
          .where((r) => r['category'] == 'kelurahan')
          .where((r) => r['id'] is String && r['name'] is String && r['name'] != 'null' && r['lat'] is num && r['lng'] is num)
          .map((baris) => RecyclingPlace.dariOpenStreetMap(Map<String, dynamic>.from(baris)))
          .toList();
      final kelurahan = (data['villages'] as List? ?? []).whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r)).where((r) => r['name'] is String && (r['name'] as String).trim().isNotEmpty).toList();
      return HasilPencarianTempat(tengah: pusat, tempat: tempat, kelurahan: kelurahan,
          kota: data['city'] as String? ?? '', ringkasan: data['summary'] as String? ?? '');
  }
}
