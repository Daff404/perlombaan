import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/local_store.dart';
import '../services/places_service.dart';
import '../settings.dart';
import '../ui/forest.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key, required this.store});
  final LocalStore store;
  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final _service = PlacesService();
  final _map = MapController();
  final _search = TextEditingController();
  LatLng _center = const LatLng(-6.9277, 106.93);
  LatLng? _device;
  LatLng _origin = const LatLng(-6.9277, 106.93);
  List<RecyclingPlace> _places = [];
  RecyclingPlace? _selected;
  bool _busy = false, _list = false, _gps = false, _searched = false;
  String? _error;
  @override
  void dispose() {
    _service.close();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _find({bool gps = false, String? city}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var center = _center;
      if (gps) {
        if (!await Geolocator.isLocationServiceEnabled())
          throw const PlacesException(
            'GPS belum aktif. Aktifkan lokasi perangkat lalu coba lagi.',
          );
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied)
          permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever)
          throw const PlacesException(
            'Izin lokasi belum diberikan. Izinkan lewat pengaturan perangkat atau cari berdasarkan kota.',
          );
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 25),
          ),
        );
        center = LatLng(p.latitude, p.longitude);
      } else if (city != null && city.trim().isNotEmpty) {
        center = await _service.searchCity(city);
      }
      if (!mounted) return;
      setState(() {
        _center = center;
        _origin = center;
        _gps = gps;
        if (gps) _device = center;
      });
      _map.move(center, 12.5);
      final found = await _service.nearby(center);
      if (!mounted) return;
      setState(() {
        _places = found;
        _selected = found.isEmpty ? null : found.first;
        _searched = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _route(RecyclingPlace place) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.point.latitude},${place.point.longitude}',
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw Exception();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplikasi rute tidak dapat dibuka.')),
        );
    }
  }

  Widget _card(RecyclingPlace p) {
    final km = const Distance()(_origin, p.point) / 1000;
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: serif(p.name, size: 23)),
              const SizedBox(width: 10),
              Text(
                '${km.toStringAsFixed(1)} km',
                style: const TextStyle(color: sage, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.address.isEmpty
                ? 'Alamat lengkap belum tercatat di OpenStreetMap.'
                : p.address,
            style: const TextStyle(color: muted, height: 1.5, fontSize: 12),
          ),
          if (p.hours.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Jam tercatat: ${p.hours}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
          if (p.materials.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Material tercatat: ${p.materials.join(', ')}',
                style: const TextStyle(fontSize: 11, color: sage),
              ),
            ),
          const SizedBox(height: 14),
          LeafButton(
            'Lihat Rute',
            icon: Icons.near_me_outlined,
            onTap: () => _route(p),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                if (!widget.store
                    .getList('places')
                    .any((x) => x['osmId'] == p.id))
                  await widget.store.addRecord('places', p.toJson());
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tempat disimpan ke catatan lokal.'),
                    ),
                  );
              } catch (_) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tempat gagal disimpan.')),
                  );
              }
            },
            icon: const Icon(Icons.bookmark_border, size: 17),
            label: const Text('Simpan Tempat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 5, 22, 25),
    children: [
      TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari kota atau wilayah…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _busy ? null : () => _find(city: _search.text),
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
        onSubmitted: _busy ? null : (x) => _find(city: x),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _find(gps: true),
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Lokasi Saya'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => _find(),
              child: const Text('Cari Sekitar Peta'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          ChoiceChip(
            label: const Text('Peta'),
            selected: !_list,
            onSelected: (_) => setState(() => _list = false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Daftar'),
            selected: _list,
            onSelected: (_) => setState(() => _list = true),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(color: sage),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Glass(
            child: Text(_error!, style: const TextStyle(height: 1.5)),
          ),
        ),
      // Keep map mounted while switching views so its controller stays valid.
      Offstage(
        offstage: _list,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 320,
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 12.5,
                onPositionChanged: (camera, gesture) {
                  if (gesture) _center = camera.center;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: Settings.mapTiles,
                  userAgentPackageName: 'id.shion.app',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    if (_device != null)
                      Marker(
                        point: _device!,
                        width: 22,
                        height: 22,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),
                    ..._places.map(
                      (p) => Marker(
                        point: p.point,
                        width: 42,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = p),
                          child: Icon(
                            Icons.location_on,
                            size: 42,
                            color: _selected?.id == p.id
                                ? const Color(0xff1e593d)
                                : const Color(0xff6c884f),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        _gps
            ? 'Hasil sekitar lokasi perangkat, radius ${Settings.searchRadiusMeters ~/ 1000} km.'
            : 'Pusat pencarian: ${_center.latitude.toStringAsFixed(3)}, ${_center.longitude.toStringAsFixed(3)}. Awal peta: Sukabumi.',
        style: const TextStyle(color: muted, fontSize: 10, height: 1.5),
      ),
      const SizedBox(height: 12),
      if (!_searched && !_busy)
        const Glass(
          child: Text(
            'Gunakan Lokasi Saya atau masukkan kota untuk mencari titik pengumpulan yang tercatat.',
            style: TextStyle(height: 1.5, color: muted, fontSize: 12),
          ),
        ),
      if (_searched && _places.isEmpty)
        const Glass(
          child: Text(
            'Belum ada titik yang tercatat dalam radius ini. Coba wilayah lain. Tidak ada lokasi buatan yang ditambahkan.',
            style: TextStyle(height: 1.5, color: muted, fontSize: 12),
          ),
        ),
      if (_list)
        ..._places.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _card(p),
          ),
        )
      else if (_selected != null)
        _card(_selected!),
      const SizedBox(height: 15),
      const Text(
        'Data komunitas OpenStreetMap / Overpass. Lokasi bukan otomatis mitra SHION. Hubungi pengelola untuk memastikan jam buka dan material yang diterima.',
        style: TextStyle(color: muted, fontSize: 10, height: 1.6),
      ),
    ],
  );
}
