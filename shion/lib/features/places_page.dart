// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng;
import '../core/api_store.dart';
import '../core/system_log.dart';
import '../services/places_service.dart';
import '../settings.dart';
import '../ui/forest.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<PlacesPage> createState() => _daftarTempatHalamanKeadaan();
}

class _daftarTempatHalamanKeadaan extends State<PlacesPage> {
  final _layanan = PlacesService();
  final _pencarian = TextEditingController();
  LatLng _tengah = const LatLng(-6.9277, 106.93);
  LatLng? _perangkat;
  LatLng _asal = const LatLng(-6.9277, 106.93);
  List<RecyclingPlace> _daftarTempat = List.of(PlacesService.sukabumi);
  RecyclingPlace? _terpilih = PlacesService.sukabumi.first;
  bool _sibuk = false, _daftar = false, _gps = false, _dicari = false;
  String? _galat;
  @override
  void initState() {
    super.initState();
    _dicari = true;
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _cari(); });
  }
  @override
  void dispose() {
    _layanan.close();
    _pencarian.dispose();
    super.dispose();
  }

  Future<void> _cari({bool gps = false, String? city}) async {
    if (_sibuk) return;
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      var tengah = _tengah;
      if (gps) {
        if (!await Geolocator.isLocationServiceEnabled())
          throw const PlacesException(
            'GPS belum aktif. Aktifkan lokasi perangkat lalu coba lagi.',
          );
        var izin = await Geolocator.checkPermission();
        if (izin == LocationPermission.denied)
          izin = await Geolocator.requestPermission();
        if (izin == LocationPermission.denied ||
            izin == LocationPermission.deniedForever)
          throw const PlacesException(
            'Izin lokasi belum diberikan. Izinkan lewat pengaturan perangkat atau cari berdasarkan kota.',
          );
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 25),
          ),
        );
        tengah = LatLng(p.latitude, p.longitude);
      } else if (city != null && city.trim().isNotEmpty) {
        tengah = await _layanan.cariKota(city);
      }
      if (!mounted) return;
      setState(() {
        _tengah = tengah;
        _asal = tengah;
        _gps = gps;
        if (gps) _perangkat = tengah;
      });
      final ditemukan = await _layanan.terdekat(tengah);
      if (!mounted) return;
      setState(() {
        _daftarTempat = ditemukan;
        _terpilih = ditemukan.isEmpty ? null : ditemukan.first;
        _dicari = true;
        _galat = _layanan.warning;
      });
    } catch (e) {
      if (mounted) setState(() => _galat = SystemLog.failure('places', e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _rute(RecyclingPlace place) async {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(place.name), content: Text('${place.address}\n\nKoordinat titik: ${place.point.latitude.toStringAsFixed(5)}, ${place.point.longitude.toStringAsFixed(5)}'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))]));
  }

  Widget _kartu(RecyclingPlace p) {
    final km = const Distance()(_asal, p.point) / 1000;
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
                ? 'Alamat lengkap belum tercatat.'
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
            onTap: () => _rute(p),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                if (!widget.store
                    .ambilDaftar('places')
                    .any((x) => x['osmId'] == p.id))
                  await widget.store.tambahCatatan('places', p.keJson());
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tempat disimpan ke akunmu.'),
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

  List<Widget> _petaPenanda(double width, double height) => _daftarTempat.map((place) {
    final kiri = (width * ((place.point.longitude - 106.89) / 0.10)).clamp(18.0, width - 42.0).toDouble();
    final atas = (height * ((-6.89 - place.point.latitude) / 0.09)).clamp(48.0, height - 52.0).toDouble();
    return Positioned(left: kiri, top: atas, child: GestureDetector(onTap: () => setState(() => _terpilih = place), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.location_on, color: _terpilih?.id == place.id ? const Color(0xff009d20) : const Color(0xffe7c46d), size: 34),
      if (_terpilih?.id == place.id) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: forestDeep, borderRadius: BorderRadius.circular(8)), child: Text(place.name.split(' • ').first, style: const TextStyle(fontSize: 9, color: ink))),
    ])));
  }).toList();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 5, 22, 25),
    children: [
      TextField(
        controller: _pencarian,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari kota atau wilayah…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _sibuk ? null : () => _cari(city: _pencarian.text),
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
        onSubmitted: _sibuk ? null : (x) => _cari(city: x),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sibuk ? null : () => _cari(gps: true),
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Lokasi Saya'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _sibuk ? null : () => _cari(),
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
            selected: !_daftar,
            onSelected: (_) => setState(() => _daftar = false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Daftar'),
            selected: _daftar,
            onSelected: (_) => setState(() => _daftar = true),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_sibuk)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(color: sage),
        ),
      if (_galat != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Glass(
            child: Text(_galat!, style: const TextStyle(height: 1.5)),
          ),
        ),
      Offstage(
        offstage: _daftar,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 320,
            child: LayoutBuilder(builder: (context, box) => Stack(children: [
              const Positioned.fill(child: CustomPaint(painter: _sukabumiPetaPelukis())),
              Positioned(left: 16, top: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: const Color(0xe8092b20), borderRadius: BorderRadius.circular(14)), child: const Text('SUKABUMI • PETA SHION', style: TextStyle(color: ink, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)))),
              ..._petaPenanda(box.maxWidth, box.maxHeight),
              if (_perangkat != null) Positioned(right: 20, bottom: 18, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xdd082b20), shape: BoxShape.circle), child: const Icon(Icons.my_location, size: 18, color: Color(0xff9be76b)))),
            ])),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        _gps
            ? 'Hasil sekitar lokasi perangkat, radius ${Settings.searchRadiusMeters ~/ 1000} km.'
            : 'Pusat pencarian: ${_tengah.latitude.toStringAsFixed(3)}, ${_tengah.longitude.toStringAsFixed(3)}. Awal peta: Sukabumi.',
        style: const TextStyle(color: muted, fontSize: 10, height: 1.5),
      ),
      const SizedBox(height: 12),
      if (!_dicari && !_sibuk)
        const Glass(
          child: Text(
            'Gunakan Lokasi Saya atau masukkan kota untuk mencari titik pengumpulan yang tercatat.',
            style: TextStyle(height: 1.5, color: muted, fontSize: 12),
          ),
        ),
      if (_dicari && _daftarTempat.isEmpty)
        const Glass(
          child: Text(
            'Belum ada titik yang tercatat dalam radius ini. Coba wilayah lain. Tidak ada lokasi buatan yang ditambahkan.',
            style: TextStyle(height: 1.5, color: muted, fontSize: 12),
          ),
        ),
      if (_daftar)
        ..._daftarTempat.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _kartu(p),
          ),
        )
      else if (_terpilih != null)
        _kartu(_terpilih!),
      const SizedBox(height: 15),
      const Text(
        'Peta dan titik dikelola oleh SHION. Beberapa pin menunjukkan wilayah RW/kelurahan, bukan alamat presisi. Konfirmasi alamat, jam buka, dan material ke pengelola sebelum berkunjung.',
        style: TextStyle(color: muted, fontSize: 10, height: 1.6),
      ),
    ],
  );
}

class _sukabumiPetaPelukis extends CustomPainter {
  const _sukabumiPetaPelukis();
  @override
  void paint(Canvas canvas, Size size) {
    final persegi = Offset.zero & size;
    canvas.drawRect(persegi, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff244c39), Color(0xff102f25), Color(0xff183d2e)]).createShader(persegi));
    final taman = Paint()..color = const Color(0xff3d6342).withValues(alpha: .72);
    canvas.drawOval(Rect.fromLTWH(size.width * .05, size.height * .42, size.width * .30, size.height * .36), taman);
    canvas.drawOval(Rect.fromLTWH(size.width * .62, size.height * .08, size.width * .30, size.height * .27), taman);
    final jalan = Paint()..color = const Color(0xffa0aa84).withValues(alpha: .34)..style = PaintingStyle.stroke..strokeWidth = 13..strokeCap = StrokeCap.round;
    final jalur = Path()..moveTo(-12, size.height * .79)..cubicTo(size.width * .28, size.height * .66, size.width * .39, size.height * .78, size.width * .57, size.height * .53)..cubicTo(size.width * .74, size.height * .30, size.width * .8, size.height * .45, size.width + 12, size.height * .21);
    canvas.drawPath(jalur, jalan);
    final kecil = Paint()..color = const Color(0xffd5d3b6).withValues(alpha: .20)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    for (final fraction in [.25, .47, .66]) { final p = Path()..moveTo(size.width * fraction, -10)..cubicTo(size.width * (fraction + .12), size.height * .35, size.width * (fraction - .12), size.height * .55, size.width * (fraction + .05), size.height + 10); canvas.drawPath(p, kecil); }
    final label = TextPainter(textDirection: TextDirection.ltr, text: const TextSpan(text: 'KOTA SUKABUMI', style: TextStyle(color: Color(0x99eff5e9), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)))..layout();
    label.paint(canvas, Offset((size.width-label.width)/2, size.height*.53));
  }
  @override bool shouldRepaint(covariant _sukabumiPetaPelukis oldDelegate) => false;
}
