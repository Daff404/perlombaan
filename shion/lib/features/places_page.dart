// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng;
import 'package:url_launcher/url_launcher.dart';
import '../core/api_store.dart';
import '../core/system_log.dart';
import '../services/places_service.dart';
import '../ui/forest.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<PlacesPage> createState() => _daftarTempatHalamanKeadaan();
}

class _daftarTempatHalamanKeadaan extends State<PlacesPage> {
  late final PlacesService _layanan = PlacesService(widget.store.api);
  final _pencarian = TextEditingController();
  final MapController _pengendaliPeta = MapController();
  LatLng _tengah = const LatLng(-6.9277, 106.93);
  LatLng? _perangkat;
  LatLng _asal = const LatLng(-6.9277, 106.93);
  List<RecyclingPlace> _daftarTempat = [];
  List<Map<String, dynamic>> _kelurahan = [];
  RecyclingPlace? _terpilih;
  bool _sibuk = false, _daftar = true, _gps = false, _dicari = false;
  bool _petaSiap = false;
  String? _galat;
  String _ringkasan = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _cari(gps: true); });
  }
  @override
  void dispose() {
    _pengendaliPeta.dispose();
    _pencarian.dispose();
    super.dispose();
  }

  Future<void> _cari({bool gps = false, String? city}) async {
    if (_sibuk) return;
    setState(() {
      _sibuk = true;
      _galat = null;
      _dicari = true;
      _daftarTempat = [];
      _kelurahan = [];
      _terpilih = null;
      _ringkasan = '';
    });
    try {
      var tengah = _tengah;
      if (gps) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const PlacesException('GPS belum aktif. Aktifkan lokasi perangkat lalu coba lagi.');
        }
        var izin = await Geolocator.checkPermission();
        if (izin == LocationPermission.denied) izin = await Geolocator.requestPermission();
        if (izin == LocationPermission.denied || izin == LocationPermission.deniedForever) {
          throw const PlacesException('Izin lokasi belum diberikan. Izinkan lewat pengaturan perangkat atau cari berdasarkan wilayah.');
        }
        final posisi = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)));
        tengah = LatLng(posisi.latitude, posisi.longitude);
      }
      final hasil = city != null && city.trim().isNotEmpty
          ? await _layanan.cariWilayah(city)
          : await _layanan.terdekat(tengah);
      if (!mounted) return;
      setState(() {
        _tengah = hasil.tengah;
        _ringkasan = hasil.ringkasan;
        _asal = gps ? tengah : hasil.tengah;
        _perangkat = gps ? tengah : _perangkat;
        _gps = gps;
        _daftarTempat = hasil.tempat;
        _kelurahan = hasil.kelurahan;
        _terpilih = hasil.tempat.isEmpty ? null : hasil.tempat.first;
        _dicari = true;
      });
      if (_petaSiap) _pengendaliPeta.move(hasil.tengah, gps || (city?.isNotEmpty ?? false) ? 13 : 12);
    } catch (e) {
      if (mounted) setState(() => _galat = SystemLog.failure('places', e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  List<Marker> get _penanda => [
    ..._daftarTempat.map((tempat) => Marker(
      point: tempat.point,
      width: 42,
      height: 48,
      child: GestureDetector(
        onTap: () => setState(() => _terpilih = tempat),
        child: Icon(
          tempat.category == 'kelurahan' ? Icons.account_balance_rounded : Icons.recycling_rounded,
          color: tempat.category == 'kelurahan' ? const Color(0xffc6e5a0) : const Color(0xff8de276),
          size: 34,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 7)],
        ),
      ),
    )),
    if (_gps && _perangkat != null) Marker(
      point: _perangkat!, width: 24, height: 24,
      child: Container(decoration: BoxDecoration(color: const Color(0xff53a7e8), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),),
    ),
  ];

  Future<void> _rute(RecyclingPlace tempat) async {
    final alamat = Uri.parse('https://www.openstreetmap.org/?mlat=${tempat.point.latitude}&mlon=${tempat.point.longitude}#map=16/${tempat.point.latitude}/${tempat.point.longitude}');
    if (!await launchUrl(alamat, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peta tidak dapat dibuka.')));
    }
  }

  Widget _kartu(RecyclingPlace tempat) {
    final km = const Distance()(_asal, tempat.point) / 1000;
    final kantor = tempat.category == 'kelurahan';
    return Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: kantor ? const Color(0xff24483a) : const Color(0xff315a35), borderRadius: BorderRadius.circular(14)), child: Icon(kantor ? Icons.account_balance_outlined : Icons.recycling, color: sage, size: 22)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('KELURAHAN', style: TextStyle(color: sage, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          serif(tempat.name, size: 20),
        ])),
        const SizedBox(width: 8),
        Text('${km.toStringAsFixed(1)} km', style: const TextStyle(color: sage, fontSize: 11)),
      ]),
      if (tempat.address.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 9), child: Text(tempat.address, style: const TextStyle(color: muted, height: 1.45, fontSize: 11))),
      const SizedBox(height: 12),
      LeafButton('Buka lokasi', icon: Icons.directions_rounded, onTap: () => _rute(tempat)),
    ]));
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 5, 20, 26), children: [
    serif('Temukan titik di sekitarmu', size: 29),
    const SizedBox(height: 4),
    const Text('Daftar kelurahan di sekitar kota kamu akan dicari otomatis saat lokasi perangkat diizinkan.', style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
    const SizedBox(height: 15),
    if (_ringkasan.isNotEmpty) Glass(child: Text(_ringkasan)),
    TextField(controller: _pencarian, textInputAction: TextInputAction.search,
      decoration: InputDecoration(hintText: 'Kota, kecamatan, atau kelurahan…', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: _sibuk ? null : () => _cari(city: _pencarian.text), icon: const Icon(Icons.arrow_forward_rounded))),
      onSubmitted: _sibuk ? null : (teks) => _cari(city: teks),
    ),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: _sibuk ? null : () => _cari(gps: true), icon: const Icon(Icons.my_location, size: 17), label: const Text('Lokasi saya'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: _sibuk ? null : () => _cari(), icon: const Icon(Icons.refresh_rounded, size: 17), label: const Text('Cari sekitar'))),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      ChoiceChip(label: const Text('Peta'), selected: !_daftar, onSelected: (_) => setState(() => _daftar = false)),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Daftar'), selected: _daftar, onSelected: (_) => setState(() { _daftar = true; _petaSiap = false; })),
      const Spacer(),
      if (_gps) const Row(children: [Icon(Icons.my_location, color: sage, size: 13), SizedBox(width: 5), Text('Lokasi aktif', style: TextStyle(color: sage, fontSize: 10))]),
    ]),
    const SizedBox(height: 11),
    if (_sibuk) const Padding(padding: EdgeInsets.only(bottom: 10), child: LinearProgressIndicator(color: sage)),
    if (_galat != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(child: Text(_galat!, style: const TextStyle(height: 1.5, fontSize: 11)))),
    if (!_daftar) ClipRRect(borderRadius: BorderRadius.circular(23), child: SizedBox(height: 335, child: Stack(children: [
      FlutterMap(
        mapController: _pengendaliPeta,
        options: MapOptions(
          initialCenter: _tengah,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          onMapReady: () {
            _petaSiap = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _petaSiap) _pengendaliPeta.move(_tengah, 12);
            });
          },
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'id.shion.app', maxZoom: 19),
          MarkerLayer(markers: _penanda),
        ],
      ),
      Positioned(right: 8, top: 8, child: Material(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(12), child: IconButton(
        tooltip: 'Ke tengah peta', icon: const Icon(Icons.my_location_rounded, color: Color(0xff264c35)),
        onPressed: () => _pengendaliPeta.move(_gps && _perangkat != null ? _perangkat! : _tengah, 13),
      ))),
    ]))),
    const SizedBox(height: 12),
    if (_dicari && !_sibuk && _galat == null && _daftarTempat.isEmpty && _kelurahan.isEmpty) Glass(child: Row(children: [
      const Icon(Icons.location_searching_rounded, color: sage), const SizedBox(width: 10),
      const Expanded(child: Text('Belum ditemukan data kelurahan di area ini. Coba cari berdasarkan nama kota.', style: TextStyle(color: muted, fontSize: 11, height: 1.5))),
    ])),
    if (!_dicari && !_sibuk) const Glass(child: Text('Aktifkan lokasi atau masukkan nama kota untuk mulai mencari.', style: TextStyle(color: muted, fontSize: 11, height: 1.5))),
    if (_terpilih != null && !_daftar) _kartu(_terpilih!),
    if (_daftar) ..._daftarTempat.map((tempat) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _kartu(tempat))),
    if (_daftar) ..._kelurahan.map((wilayah) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Glass(child: Row(children: [
        const Icon(Icons.location_city_outlined, color: sage),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kelurahan ${wilayah['name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text('Kecamatan ${wilayah['district'] ?? 'Belum tersedia'}', style: const TextStyle(color: muted, fontSize: 11)),
        ])),
      ])),
    )),
    if (_dicari && _daftarTempat.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text('${_daftarTempat.length} kelurahan ditemukan', style: const TextStyle(color: muted, fontSize: 10))),
    const SizedBox(height: 10),
  ]);
}
