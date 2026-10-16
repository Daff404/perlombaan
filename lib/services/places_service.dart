import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../settings.dart';

class RecyclingPlace {
  const RecyclingPlace({
    required this.id,
    required this.name,
    required this.point,
    required this.address,
    required this.hours,
    required this.materials,
  });
  final String id, name, address, hours;
  final LatLng point;
  final List<String> materials;
  Map<String, dynamic> toJson() => {
    'osmId': id,
    'name': name,
    'lat': point.latitude,
    'lon': point.longitude,
    'address': address,
    'hours': hours,
    'materials': materials,
  };
  factory RecyclingPlace.fromJson(Map<String, dynamic> j) => RecyclingPlace(
    id: j['osmId'] as String,
    name: j['name'] as String,
    point: LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()),
    address: j['address'] as String? ?? '',
    hours: j['hours'] as String? ?? '',
    materials: (j['materials'] as List? ?? []).whereType<String>().toList(),
  );
}

class PlacesException implements Exception {
  const PlacesException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PlacesService {
  PlacesService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _headers = {
    'User-Agent': Settings.userAgent,
    'Accept': 'application/json',
    'Accept-Language': 'id',
  };
  void close() => _client.close();
  Future<LatLng> searchCity(String city) async {
    try {
      final uri = Uri.parse(Settings.geocodingUrl).replace(
        queryParameters: {'q': city.trim(), 'format': 'jsonv2', 'limit': '1'},
      );
      final r = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200)
        throw const PlacesException(
          'Pencarian wilayah sedang tidak tersedia. Coba lagi nanti.',
        );
      final list = jsonDecode(r.body) as List;
      if (list.isEmpty)
        throw const PlacesException(
          'Wilayah tidak ditemukan. Coba nama kota dan negara.',
        );
      final item = list.first as Map;
      final lat = double.parse(item['lat'] as String);
      final lon = double.parse(item['lon'] as String);
      if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180)
        throw const PlacesException('Koordinat wilayah tidak valid.');
      return LatLng(lat, lon);
    } on PlacesException {
      rethrow;
    } catch (_) {
      throw const PlacesException(
        'Pencarian wilayah gagal. Periksa koneksi internet.',
      );
    }
  }

  Future<List<RecyclingPlace>> nearby(LatLng center) async {
    final area =
        'around:${Settings.searchRadiusMeters},${center.latitude.toStringAsFixed(6)},${center.longitude.toStringAsFixed(6)}';
    final query =
        '[out:json][timeout:25];(nwr["amenity"="recycling"]($area);nwr["amenity"="waste_disposal"]($area);nwr["name"~"bank sampah",i]($area););out center tags 80;';
    try {
      final r = await _client
          .post(
            Uri.parse(Settings.overpassUrl),
            headers: _headers,
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 35));
      if (r.statusCode != 200)
        throw const PlacesException(
          'Server peta sedang sibuk. Coba lagi beberapa saat.',
        );
      final data = jsonDecode(r.body) as Map;
      final rows = data['elements'];
      if (rows is! List)
        throw const PlacesException('Respons lokasi tidak dapat dibaca.');
      final results = <RecyclingPlace>[];
      for (final element in rows.whereType<Map>()) {
        final tags = Map<String, dynamic>.from(element['tags'] as Map? ?? {});
        final coords = element['center'] as Map? ?? element;
        if (coords['lat'] is! num || coords['lon'] is! num) continue;
        final lat = (coords['lat'] as num).toDouble(),
            lon = (coords['lon'] as num).toDouble();
        if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180)
          continue;
        final rawName = tags['name'] as String?;
        final address = [
          tags['addr:street'],
          tags['addr:housenumber'],
          tags['addr:suburb'],
          tags['addr:city'],
        ].whereType<String>().where((v) => v.isNotEmpty).join(', ');
        final materials = tags.entries
            .where((e) => e.key.startsWith('recycling:') && e.value == 'yes')
            .map((e) => e.key.substring(10).replaceAll('_', ' '))
            .toList();
        results.add(
          RecyclingPlace(
            id: '${element['type']}/${element['id']}',
            name: rawName?.trim().isNotEmpty == true
                ? rawName!
                : tags['amenity'] == 'waste_disposal'
                ? 'Titik pengumpulan sampah'
                : 'Fasilitas daur ulang',
            point: LatLng(lat, lon),
            address: address,
            hours: tags['opening_hours'] as String? ?? '',
            materials: materials,
          ),
        );
      }
      const distance = Distance();
      results.sort(
        (a, b) =>
            distance(center, a.point).compareTo(distance(center, b.point)),
      );
      return results;
    } on PlacesException {
      rethrow;
    } catch (_) {
      throw const PlacesException(
        'Lokasi belum dapat dimuat. Periksa internet atau coba lagi.',
      );
    }
  }
}
