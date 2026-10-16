import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/local_store.dart';
import 'ui/forest.dart';
import 'features/scanner_page.dart';
import 'features/places_page.dart';
import 'features/points_page.dart';
import 'settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShionApp());
}

class ShionApp extends StatelessWidget {
  const ShionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SHION',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Manrope',
      colorScheme: const ColorScheme.dark(
        primary: sage,
        secondary: sage,
        surface: forest,
        onSurface: ink,
        onPrimary: forest,
      ),
      scaffoldBackgroundColor: forest,
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Manrope',
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .055),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0x33d7e8cc)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0x33d7e8cc)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: sage,
        contentTextStyle: TextStyle(color: forest),
      ),
    ),
    home: const ShionHome(),
  );
}

class ShionHome extends StatefulWidget {
  const ShionHome({super.key});
  @override
  State<ShionHome> createState() => _ShionHomeState();
}

class _ShionHomeState extends State<ShionHome> {
  LocalStore? _store;
  SharedPreferences? _preferences;
  int _tab = 0;
  int _intro = -1;
  bool _saving = false;
  String _query = '';
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _preferences = prefs;
        _store = LocalStore(prefs);
        _name.text = _store!.name;
        _intro =
            prefs.getBool('shion.welcomed') == true || _store!.name.isNotEmpty
            ? -1
            : 0;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _notify(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _write(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      if (mounted) {
        setState(() {});
        _notify('Tersimpan di perangkat.');
      }
    } catch (_) {
      if (mounted) _notify('Gagal menyimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _page(String title, WidgetBuilder body) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => ForestPage(
              child: Column(
                children: [
                  _header(title, back: true),
                  Expanded(child: Builder(builder: body)),
                ],
              ),
            ),
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  Widget _header(String title, {bool back = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
    child: Row(
      children: [
        IconButton(
          onPressed: back ? () => Navigator.of(context).pop() : _menu,
          icon: Icon(
            back ? Icons.arrow_back_rounded : Icons.menu_rounded,
            size: 23,
          ),
        ),
        Expanded(child: serif(title, size: 23, align: TextAlign.center)),
        IconButton(
          onPressed: () => _page('Catatan Aktivitas', (_) => _allHistory()),
          icon: const Icon(Icons.notifications_none_rounded, size: 23),
        ),
      ],
    ),
  );

  void _menu() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: forest,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          serif('SHION'),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.recycling),
            title: const Text('Rencana Setoran'),
            onTap: () {
              Navigator.pop(context);
              _deposit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Jejak Aktivitas'),
            onTap: () {
              Navigator.pop(context);
              _carbon();
            },
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Tempat Setor Tersimpan'),
            onTap: () {
              Navigator.pop(context);
              _locations();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang SHION'),
            onTap: () {
              Navigator.pop(context);
              _about();
            },
          ),
        ],
      ),
    ),
  );

  Widget _scroll(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
    children: children,
  );
  Widget _titleRow(String title, {String? action, VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.only(top: 23, bottom: 12),
        child: Row(
          children: [
            Expanded(child: serif(title, size: 23)),
            if (action != null)
              TextButton(
                onPressed: onTap,
                child: Text(
                  action,
                  style: const TextStyle(color: sage, fontSize: 12),
                ),
              ),
          ],
        ),
      );

  Widget _welcome() => ForestPage(
    crisp: _intro == 0,
    child: LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: bounds.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _intro = 2),
                      child: const Text('Lewati'),
                    ),
                  ),
                  const Spacer(),
                  if (_intro == 0) ...[
                    const BrandGlyph('brand_mark', size: 78),
                    const SizedBox(height: 16),
                    serif('SHION', size: 48),
                    const SizedBox(height: 16),
                    serif(
                      'Langkah kecil.\nBumi yang lebih baik.',
                      size: 23,
                      align: TextAlign.center,
                    ),
                  ] else if (_intro == 1) ...[
                    serif('Kelola Sampah\nLebih Mudah', size: 38),
                    const SizedBox(height: 18),
                    const Text(
                      'Kenali sampah, pelajari cara memilah, dan simpan perjalanan hijaumu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: const SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: RemotePhoto(Photos.plant),
                      ),
                    ),
                  ] else ...[
                    const BrandGlyph('brand_mark', size: 68),
                    const SizedBox(height: 18),
                    serif('Selamat Datang', size: 34),
                    const SizedBox(height: 12),
                    const Text(
                      'Mulai perjalanan hijau bersama SHION.',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama panggilan',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Profil disimpan di perangkat ini. Tidak perlu akun.',
                      style: TextStyle(color: muted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  LeafButton(
                    _intro == 0
                        ? 'Mulai Perjalanan'
                        : _intro == 1
                        ? 'Selanjutnya'
                        : 'Masuk ke SHION',
                    onTap: () async {
                      if (_intro < 2) {
                        setState(() => _intro++);
                        return;
                      }
                      if (_name.text.trim().isEmpty) {
                        _notify('Isi nama panggilan terlebih dahulu.');
                        return;
                      }
                      try {
                        await _store!.setName(_name.text);
                        await _preferences!.setBool('shion.welcomed', true);
                        if (mounted) setState(() => _intro = -1);
                      } catch (_) {
                        if (mounted) _notify('Profil gagal disimpan.');
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _intro == i ? 22 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _intro == i ? sage : const Color(0xff6a826b),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _dashboard() => _scroll([
    TextField(
      decoration: const InputDecoration(
        hintText: 'Cari informasi, artikel...',
        prefixIcon: Icon(Icons.search, size: 20),
        isDense: true,
      ),
      onSubmitted: (value) => setState(() {
        _query = value;
        _tab = 3;
      }),
    ),
    const SizedBox(height: 17),
    PhotoPanel(
      photo: Photos.detail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          serif('Halo,', size: 22),
          Row(
            children: [
              Flexible(
                child: serif(
                  _store!.name.isEmpty ? 'Sahabat Bumi' : _store!.name,
                  size: 29,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.waving_hand_outlined, color: sage, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 190,
            child: Text(
              'Terus jaga bumi\ndengan langkah kecil\nsetiap hari.',
              style: TextStyle(height: 1.45, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    Glass(
      onTap: () => setState(() => _tab = 2),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sage.withValues(alpha: .2),
              border: Border.all(color: sage.withValues(alpha: .35)),
            ),
            child: const Icon(Icons.spa_outlined, color: sage, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Green Point', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                metric('${_store!.points}', size: 31),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: sage),
        ],
      ),
    ),
    const SizedBox(height: 12),
    const Text(
      'Poin dari hasil scan AI • tersimpan di perangkatmu',
      style: TextStyle(color: muted, fontSize: 10),
    ),
    const SizedBox(height: 20),
    GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.06,
      children: [
        _shortcut(
          Icons.document_scanner_outlined,
          'Scan Sampah',
          () => setState(() => _tab = 1),
        ),
        _shortcut(Icons.shopping_bag_outlined, 'Setor Sampah', _deposit),
        _shortcut(
          Icons.local_activity_outlined,
          'Tukar Poin',
          () => setState(() => _tab = 2),
        ),
        _shortcut(Icons.eco_outlined, 'Jejak Karbon', _carbon),
        _shortcut(
          Icons.menu_book_outlined,
          'Edukasi',
          () => setState(() => _tab = 3),
        ),
        _shortcut(Icons.place_outlined, 'Bank Sampah', _locations),
      ],
    ),
    _titleRow(
      'Untuk Bumi, Hari Ini',
      action: 'Lihat semua',
      onTap: () => setState(() => _tab = 3),
    ),
    _articleCard(articles.first, large: true),
    _titleRow('Perjalanan Hijaumu'),
    Glass(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${_store!.getList('scans').length}', 'Catatan scan'),
          _stat('${_store!.getList('deposits').length}', 'Rencana setor'),
          _stat('${_store!.getList('activities').length}', 'Aktivitas'),
        ],
      ),
    ),
  ]);
  Widget _stat(String value, String label) => Column(
    children: [
      metric(value, size: 27),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 10, color: muted)),
    ],
  );
  Widget _shortcut(IconData icon, String label, VoidCallback onTap) => Glass(
    padding: const EdgeInsets.all(8),
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrandGlyph(switch (label) {
          'Scan Sampah' => 'scan',
          'Setor Sampah' => 'bag',
          'Tukar Poin' => 'gift',
          'Jejak Karbon' => 'carbon',
          'Edukasi' => 'book',
          _ => 'pin',
        }, size: 30),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    ),
  );

  Widget _scanner() => ScannerPage(
    store: _store!,
    onSaved: () {
      if (mounted) setState(() {});
    },
    onFindPlace: _locations,
  );
  Widget _points() => PointsPage(
    store: _store!,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  Widget _education() {
    final matches = articles
        .where(
          (a) => ('${a.title} ${a.category}').toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return _scroll([
      TextFormField(
        initialValue: _query,
        decoration: const InputDecoration(
          hintText: 'Cari artikel...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (x) => setState(() => _query = x),
      ),
      const SizedBox(height: 15),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Semua', 'Daur Ulang', 'Tips', 'Gaya Hidup']
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    selected: _query == (c == 'Semua' ? '' : c),
                    onSelected: (_) =>
                        setState(() => _query = c == 'Semua' ? '' : c),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 17),
      if (matches.isEmpty)
        const Padding(
          padding: EdgeInsets.all(25),
          child: Text('Artikel belum ditemukan.'),
        ),
      for (int i = 0; i < matches.length; i++) ...[
        _articleCard(matches[i], large: i == 0),
        const SizedBox(height: 14),
      ],
    ]);
  }

  Widget _articleCard(Article a, {bool large = false}) => Glass(
    padding: EdgeInsets.zero,
    onTap: () => _page(
      'Edukasi',
      (_) => _scroll([
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(height: 245, child: RemotePhoto(a.photo)),
        ),
        const SizedBox(height: 22),
        serif(a.title, size: 30),
        const SizedBox(height: 14),
        Text(a.category, style: const TextStyle(color: sage, fontSize: 12)),
        const SizedBox(height: 20),
        Text(
          a.body,
          style: const TextStyle(height: 1.85, color: ink, fontSize: 15),
        ),
      ]),
    ),
    child: large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: RemotePhoto(a.photo),
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    serif(a.title, size: 23),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          a.category,
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, color: sage, size: 19),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : Row(
            children: [
              SizedBox(width: 95, height: 108, child: RemotePhoto(a.photo)),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(height: 1.4, fontSize: 13),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        a.category,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _profile() => _scroll([
    const SizedBox(height: 12),
    Row(
      children: [
        const ClipOval(
          child: SizedBox(
            width: 76,
            height: 76,
            child: RemotePhoto(Photos.detail),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              serif(
                _store!.name.isEmpty ? 'Sahabat Bumi' : _store!.name,
                size: 29,
              ),
              const SizedBox(height: 7),
              const Text(
                'Tumbuh bersama bumi.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 25),
    Glass(
      child: Column(
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama panggilan',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          LeafButton(
            'Simpan Profil',
            icon: Icons.check,
            onTap: _saving
                ? null
                : () => _write(() => _store!.setName(_name.text)),
          ),
        ],
      ),
    ),
    const SizedBox(height: 22),
    _profileRow(
      Icons.history,
      'Riwayat Aktivitas',
      () => _page('Riwayat Aktivitas', (_) => _allHistory()),
    ),
    _profileRow(Icons.place_outlined, 'Tempat Setor Tersimpan', _locations),
    _profileRow(
      Icons.language,
      'Bahasa',
      () => _notify('Bahasa aplikasi: Indonesia.'),
    ),
    _profileRow(
      Icons.help_outline,
      'Pusat Bantuan',
      () => _page(
        'Pusat Bantuan',
        (_) => _scroll([
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                serif('Data tetap di perangkatmu', size: 23),
                const SizedBox(height: 15),
                const Text(
                  'Gunakan Scan untuk menyimpan foto dan kategori, Setor untuk mencatat rencana, serta Jejak Karbon untuk mencatat aktivitas.\n\nGambar aplikasi tersedia di assets. Foto scan dikirim ke Gemini setelah persetujuan. Catatan disimpan lokal.\n\nMenghapus data aplikasi akan menghapus catatan lokal.',
                  style: TextStyle(height: 1.7),
                ),
              ],
            ),
          ),
        ]),
      ),
    ),
    _profileRow(
      Icons.settings_outlined,
      'Pengaturan Gemini',
      () => _page(
        'Pengaturan Gemini',
        (_) => _scroll([
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                serif('Gemini AI', size: 27),
                const SizedBox(height: 14),
                Text('Model: ${Settings.geminiModel}'),
                const SizedBox(height: 10),
                Text(
                  Settings.aiConfigured
                      ? 'API key sudah dikonfigurasi.'
                      : 'API key belum dikonfigurasi.',
                ),
                const SizedBox(height: 17),
                const Text(
                  'Isi GEMINI_API_KEY di settings/private.json lalu build ulang. Kunci tidak ditampilkan di aplikasi.',
                  style: TextStyle(color: muted, height: 1.6),
                ),
              ],
            ),
          ),
        ]),
      ),
    ),
    _profileRow(Icons.info_outline, 'Tentang SHION', _about),
    const SizedBox(height: 25),
    const Icon(Icons.spa_outlined, color: sage, size: 34),
    const SizedBox(height: 10),
    const Text(
      'SMALL ACTION. BIGGER TOMORROW.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 9, letterSpacing: 2, color: muted),
    ),
  ]);
  Widget _profileRow(IconData icon, String title, VoidCallback action) =>
      Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(icon, size: 22, color: muted),
            title: Text(title, style: const TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: action,
          ),
          const Divider(height: 1, color: Color(0x22d5e4cd)),
        ],
      );
  void _about() => _page(
    'Tentang SHION',
    (_) => _scroll([
      const SizedBox(height: 25),
      const BrandGlyph('brand_mark', size: 75),
      const SizedBox(height: 20),
      serif('SHION', size: 40, align: TextAlign.center),
      const SizedBox(height: 25),
      const Text(
        'SHION adalah pilar kesadaran dan kompas menuju kehidupan yang selaras. Ia menghubungkan kecerdasan teknologi dengan komitmen abadi manusia untuk tidak melupakan dan merawat Buminya.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.9, fontSize: 16),
      ),
      const SizedBox(height: 28),
      const Text(
        'Gambar asli SHION dibuat dengan ImageGen. Logo dan ikon vektor dirancang khusus untuk SHION.\nDaftar aset dan prompt tersedia di ASSETS.md.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: muted, height: 1.5),
      ),
    ]),
  );

  List<Widget> _recordWidgets(String key) {
    final rows = _store!.getList(key);
    if (rows.isEmpty) {
      return [
        const Glass(
          child: Row(
            children: [
              Icon(Icons.eco_outlined, color: sage),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belum ada catatan.\nMulai dari langkah kecil hari ini.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return rows
        .map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Glass(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    key == 'scans'
                        ? Icons.document_scanner_outlined
                        : key == 'deposits'
                        ? Icons.recycling
                        : Icons.eco_outlined,
                    color: sage,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key == 'activities'
                              ? '${r['activity']} • ${r['amount']} ${r['unit']}'
                              : key == 'deposits'
                              ? '${r['category']} • ${r['estimatedKg']} kg'
                              : '${r['name'] ?? r['category']} • ${r['classification'] ?? 'catatan'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${r['createdAt'] ?? ''}'.split('T').first,
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (key == 'scans' && r['photoBase64'] is String)
                    IconButton(
                      icon: const Icon(Icons.photo_outlined, size: 20),
                      onPressed: () {
                        try {
                          final bytes = base64Decode(
                            r['photoBase64'] as String,
                          );
                          _page(
                            'Foto Tersimpan',
                            (_) => Padding(
                              padding: const EdgeInsets.all(22),
                              child: Image.memory(bytes, fit: BoxFit.contain),
                            ),
                          );
                        } catch (_) {
                          _notify('Foto tidak dapat dibuka.');
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _allHistory() => _scroll([
    _titleRow('Pindai Sampah'),
    ..._recordWidgets('scans'),
    _titleRow('Rencana Setoran'),
    ..._recordWidgets('deposits'),
    _titleRow('Aktivitas'),
    ..._recordWidgets('activities'),
  ]);

  void _deposit() => _entryPage('Setor Sampah', deposit: true);
  void _carbon() => _entryPage('Jejak Karbon', deposit: false);
  void _entryPage(String title, {required bool deposit}) {
    _page(
      title,
      (context) => EntryForm(
        store: _store!,
        deposit: deposit,
        onSaved: () {
          setState(() {});
        },
      ),
    );
  }

  void _locations() =>
      _page('Lokasi Bank Sampah', (_) => PlacesPage(store: _store!));

  Widget _navigation() {
    const labels = ['Beranda', 'Scan', 'Poin', 'Edukasi', 'Profil'];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: const BoxDecoration(
        color: Color(0xe3193427),
        border: Border(top: BorderSide(color: Color(0x337f9f7b))),
      ),
      child: Row(
        children: List.generate(
          5,
          (i) => Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => setState(() => _tab = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandGlyph(
                      ['home', 'scan', 'leaf', 'book', 'profile'][i],
                      color: i == _tab ? sage : muted,
                      size: 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: i == _tab ? sage : muted,
                        fontSize: 10,
                        fontWeight: i == _tab
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_store == null) {
      return const ForestPage(
        child: Center(child: CircularProgressIndicator(color: sage)),
      );
    }
    if (_intro >= 0) return _welcome();
    final pages = <Widget Function()>[
      _dashboard,
      _scanner,
      _points,
      _education,
      _profile,
    ];
    return ForestPage(
      bottom: _navigation(),
      child: Column(
        children: [
          _header(
            [
              'SHION',
              'Pindai Sampah',
              'Green Point',
              'Edukasi',
              'Profil',
            ][_tab],
          ),
          Expanded(
            child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]()),
          ),
        ],
      ),
    );
  }
}

class EntryForm extends StatefulWidget {
  const EntryForm({
    super.key,
    required this.store,
    required this.deposit,
    required this.onSaved,
  });
  final LocalStore store;
  final bool deposit;
  final VoidCallback onSaved;
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final amount = TextEditingController();
  final destination = TextEditingController();
  String choice = '';
  bool saving = false;
  @override
  void initState() {
    super.initState();
    choice = widget.deposit ? 'Plastik' : 'Jalan kaki';
  }

  @override
  void dispose() {
    amount.dispose();
    destination.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0 || value > 100000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi jumlah positif yang valid.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.store.addRecord(
        widget.deposit ? 'deposits' : 'activities',
        widget.deposit
            ? {
                'category': choice,
                'estimatedKg': value,
                'destination': destination.text.trim(),
                'status': 'Rencana pribadi',
              }
            : {
                'activity': choice,
                'amount': value,
                'unit': choice == 'Listrik' ? 'kWh' : 'km',
              },
      );
      widget.onSaved();
      amount.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan tersimpan di perangkat.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan catatan.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.store.getList(
      widget.deposit ? 'deposits' : 'activities',
    );
    final km = rows
        .where((x) => x['unit'] == 'km')
        .fold<double>(0, (a, x) => a + (x['amount'] as num).toDouble());
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
      children: [
        if (!widget.deposit) ...[
          Center(
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sage, width: 8),
                color: forest.withValues(alpha: .3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa_outlined, color: sage),
                  const SizedBox(height: 10),
                  serif(km.toStringAsFixed(1), size: 42),
                  const Text(
                    'km tercatat',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Jejak dimulai dari kesadaran. Catat perjalanan dan konsumsi listrikmu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 22),
        ],
        Glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              serif(
                widget.deposit ? 'Rencanakan Setoranmu' : 'Catat Aktivitas',
                size: 24,
              ),
              const SizedBox(height: 17),
              DropdownButtonFormField<String>(
                initialValue: choice,
                decoration: InputDecoration(
                  labelText: widget.deposit ? 'Jenis sampah' : 'Aktivitas',
                ),
                items:
                    (widget.deposit
                            ? ['Plastik', 'Kertas', 'Organik']
                            : [
                                'Jalan kaki',
                                'Sepeda',
                                'Sepeda motor',
                                'Mobil',
                                'Transportasi umum',
                                'Listrik',
                              ])
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                onChanged: (x) => setState(() => choice = x!),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.deposit
                      ? 'Berat (kg)'
                      : choice == 'Listrik'
                      ? 'Pemakaian (kWh)'
                      : 'Jarak (km)',
                ),
              ),
              const SizedBox(height: 13),
              if (widget.deposit) ...[
                TextField(
                  controller: destination,
                  decoration: const InputDecoration(
                    labelText: 'Tempat setor (opsional)',
                  ),
                ),
                const SizedBox(height: 13),
              ],
              LeafButton(
                'Simpan Catatan',
                icon: Icons.check,
                onTap: saving ? null : save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.deposit
              ? 'Rencana tersimpan pribadi. Belum dikirim atau diverifikasi tempat setor.'
              : 'Angka emisi belum ditampilkan karena faktor emisi yang terverifikasi belum dipasang.',
          style: const TextStyle(color: muted, height: 1.5, fontSize: 11),
        ),
        const SizedBox(height: 24),
        serif('Riwayat', size: 23),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const Glass(
            child: Text('Belum ada catatan.', style: TextStyle(color: muted)),
          ),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Glass(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(
                    widget.deposit ? Icons.recycling : Icons.eco_outlined,
                    color: sage,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deposit
                              ? '${r['category']} • ${r['estimatedKg']} kg'
                              : '${r['activity']} • ${r['amount']} ${r['unit']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${r['createdAt']}'.split('T').first,
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Glass(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: sage),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tips Hari Ini\nSiapkan tas pakai ulang sebelum pergi. Langkah sederhana membantu mengurangi kemasan sekali pakai.',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Article {
  const Article(this.title, this.category, this.photo, this.body);
  final String title, category, photo, body;
}

const articles = [
  Article(
    '5 Cara Mudah Mengurangi Sampah Plastik di Rumah',
    'Tips',
    Photos.reuse,
    'Perubahan kecil bisa dimulai dari kebiasaan sehari-hari.\n\n1. Bawa tas belanja yang dapat dipakai berulang. Simpan di dekat pintu agar tidak tertinggal.\n\n2. Gunakan botol minum sendiri ketika akses isi ulang tersedia.\n\n3. Buat daftar belanja untuk menghindari barang yang tidak diperlukan.\n\n4. Pilih kemasan yang dapat digunakan kembali dan layanan isi ulang bila tersedia.\n\n5. Pisahkan sampah sesuai ketentuan pengelola di daerahmu. Kemasan yang diterima dapat berbeda di setiap tempat.',
  ),
  Article(
    'Apa itu Jejak Karbon dan Cara Menguranginya',
    'Gaya Hidup',
    Photos.bus,
    'Jejak karbon menggambarkan emisi gas rumah kaca yang terkait dengan aktivitas. Perjalanan dan penggunaan energi adalah beberapa sumbernya.\n\nCatat jarak perjalanan dan pemakaian listrik agar kamu memahami kebiasaan sendiri. Berjalan kaki, bersepeda pada rute aman, serta transportasi bersama dapat menjadi pilihan sesuai kebutuhan.\n\nMenghitung kg CO₂e memerlukan faktor emisi yang sesuai lokasi, kendaraan, sumber energi, dan periode. SHION saat ini menyimpan data aktivitas tanpa menampilkan estimasi yang belum terverifikasi.',
  ),
  Article(
    'Manfaat Daur Ulang untuk Lingkungan',
    'Daur Ulang',
    Photos.plant,
    'Pemilahan membantu material yang masih bernilai masuk ke aliran pengolahan yang sesuai.\n\nKosongkan kemasan, pisahkan material yang basah dari kertas kering, lalu tanyakan syarat penerimaan pada tempat setor. Hindari mencampurkan limbah berbahaya dengan sampah daur ulang rumah tangga.\n\nMengurangi konsumsi dan memakai ulang barang tetap penting. Tidak semua material dapat didaur ulang di semua daerah.',
  ),
  Article(
    'Jenis-Jenis Sampah dan Cara Menanganinya',
    'Daur Ulang',
    Photos.organic,
    'Organik: pisahkan dari kemasan dan gunakan pengolahan organik yang sesuai.\n\nKertas: simpan bersih dan kering. Kertas berminyak atau berlapis mungkin tidak diterima.\n\nPlastik: kelompokkan sesuai petunjuk tempat setor. Simbol pada kemasan tidak menjamin tersedianya fasilitas pengolahan lokal.\n\nBaterai, elektronik, dan limbah berbahaya perlu jalur pengumpulan khusus. Hubungi pengelola sampah setempat untuk petunjuk penanganan.',
  ),
];
