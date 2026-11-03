// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:latlong2/latlong.dart';
import '../settings.dart';

class RecyclingPlace {
  const RecyclingPlace({required this.id, required this.name, required this.point, required this.address, required this.hours, required this.materials, this.sourceUrl = ''});
  final String id, name, address, hours;
  final LatLng point;
  final List<String> materials;
  final String sourceUrl;
  Map<String, dynamic> keJson() => {'osmId': id, 'name': name, 'lat': point.latitude, 'lon': point.longitude, 'address': address, 'hours': hours, 'materials': materials, 'sourceUrl': sourceUrl};
  factory RecyclingPlace.dariJson(Map<String, dynamic> j) => RecyclingPlace(id: j['osmId'] as String, name: j['name'] as String, point: LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()), address: j['address'] as String? ?? '', hours: j['hours'] as String? ?? '', materials: (j['materials'] as List? ?? []).whereType<String>().toList(), sourceUrl: j['sourceUrl'] as String? ?? '');
}

class PlacesException implements Exception {
  const PlacesException(this.message);
  final String message;
  @override String toString() => message;
}

/// Titik komunitas disimpan bersama aplikasi. Titik tingkat RW/kelurahan
/// ditandai sebagai perkiraan agar tidak dianggap alamat pintu yang presisi.
class PlacesService {
  String? warning;
  static const sukabumi = <RecyclingPlace>[
    RecyclingPlace(id: 'sammi-citamiang', name: 'Bank Sampah Induk SAMMI', point: LatLng(-6.94506, 106.92658), address: 'Jl. Pramuka No. 71, Citamiang, Kota Sukabumi', hours: 'Konfirmasi jam layanan sebelum berkunjung', materials: ['Sampah anorganik terpilah'], sourceUrl: 'https://portal.sukabumikota.go.id/bank-sammi-ajak-masyarakat-bergabung-menjadi-nasabah/'),
    RecyclingPlace(id: 'bsu-mandiri-subangjaya', name: 'BSU Mandiri • Subang Jaya', point: LatLng(-6.9148, 106.9365), address: 'RW 14 Perum Taman Asri, Kelurahan Subang Jaya. Titik perkiraan wilayah; tanyakan lokasi tepat ke pengurus setempat.', hours: 'Hubungi pengurus RW sebelum datang', materials: ['Sampah anorganik terpilah']),
    RecyclingPlace(id: 'swapilah-cisarua', name: 'Swa-pilah Percis • Cisarua', point: LatLng(-6.9166, 106.9275), address: 'Perpustakaan Kelurahan Cisarua, Kecamatan Cikole. Titik perkiraan wilayah, bukan pin pintu masuk.', hours: 'Cek jadwal layanan kelurahan', materials: ['Sampah terpilah']),
    RecyclingPlace(id: 'raksa-buana-situmekar', name: 'Bank Sampah Raksa Buana • Situmekar', point: LatLng(-6.9112, 106.9545), address: 'Kelurahan Situmekar, Kota Sukabumi. Titik perkiraan wilayah; konfirmasi alamat kepada pengelola.', hours: 'Konfirmasi pengelola sebelum berkunjung', materials: ['Sampah anorganik terpilah']),
  ];
  void close() {}
  Future<LatLng> cariKota(String city) async {
    final q = city.toLowerCase().trim();
    if (q.isEmpty || q.contains('sukabumi') || q.contains('citamiang') || q.contains('cikole') || q.contains('subang jaya') || q.contains('situme')) return const LatLng(-6.9277, 106.93);
    throw const PlacesException('Saat ini daftar titik SHION tersedia untuk wilayah Sukabumi.');
  }
  List<RecyclingPlace> dikenalTerdekat(LatLng center) => sukabumi.where((p) => const Distance()(center, p.point) <= Settings.searchRadiusMeters).toList()..sort((a,b) => const Distance().call(center, a.point).compareTo(const Distance().call(center, b.point)));
  Future<List<RecyclingPlace>> terdekat(LatLng center) async { warning = null; return dikenalTerdekat(center); }
}
