import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/local_store.dart';

const ink = Color(0xffeaf0df);
const sage = Color(0xffc5dba8);
const muted = Color(0xffb8c8b9);
const forest = Color(0xff0d281f);

// Public photo URLs. Credits and original pages: IMAGE_CREDITS.md.
class Photos {
  static const leaves =
      'https://images.pexels.com/photos/11833356/pexels-photo-11833356.jpeg?auto=compress&cs=tinysrgb&w=1000';
  static const detail =
      'https://images.pexels.com/photos/8478542/pexels-photo-8478542.jpeg?auto=compress&cs=tinysrgb&w=900';
  static const plant =
      'https://images.pexels.com/photos/2248529/pexels-photo-2248529.jpeg?auto=compress&cs=tinysrgb&w=800';
  static const bus =
      'https://images.pexels.com/photos/5790050/pexels-photo-5790050.jpeg?auto=compress&cs=tinysrgb&w=800';
}

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
      colorScheme: const ColorScheme.dark(
        primary: sage,
        secondary: sage,
        surface: forest,
        onSurface: ink,
        onPrimary: forest,
      ),
      scaffoldBackgroundColor: forest,
      textTheme: ThemeData.dark().textTheme.apply(
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

Text serif(
  String text, {
  double size = 26,
  Color color = ink,
  TextAlign? align,
  int? maxLines,
}) => Text(
  text,
  textAlign: align,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: 'Cormorant',
    fontWeight: FontWeight.w600,
    fontFamilyFallback: const ['Noto Serif', 'serif'],
    fontSize: size,
    height: 1.18,
    color: color,
  ),
);

class RemotePhoto extends StatelessWidget {
  const RemotePhoto(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    fit: fit,
    gaplessPlayback: true,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const ColoredBox(
            color: Color(0xff214535),
            child: Center(
              child: Icon(Icons.spa_outlined, color: sage, size: 42),
            ),
          ),
    errorBuilder: (_, error, stack) => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xff31563e), forest]),
      ),
      child: Center(child: Icon(Icons.spa_outlined, color: sage, size: 54)),
    ),
  );
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x35d5e4cd)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x805e7b60), Color(0x98253f32)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class PhotoPanel extends StatelessWidget {
  const PhotoPanel({
    super.key,
    required this.photo,
    required this.child,
    this.minHeight = 170,
  });
  final String photo;
  final Widget child;
  final double minHeight;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(child: RemotePhoto(photo)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xf0254230), Color(0x20254230)],
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    ),
  );
}

class LeafButton extends StatelessWidget {
  const LeafButton(
    this.label, {
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: sage,
        foregroundColor: forest,
        disabledBackgroundColor: const Color(0xff51674c),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(icon, size: 21),
        ],
      ),
    ),
  );
}

class ForestPage extends StatelessWidget {
  const ForestPage({
    super.key,
    required this.child,
    this.bottom,
    this.crisp = false,
  });
  final Widget child;
  final Widget? bottom;
  final bool crisp;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff213b30),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: crisp ? 0 : 9,
                sigmaY: crisp ? 0 : 9,
              ),
              child: RemotePhoto(crisp ? Photos.leaves : Photos.detail),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: crisp
                      ? const [
                          Color(0x3d061910),
                          Color(0x84041911),
                          Color(0xe609241a),
                        ]
                      : const [
                          Color(0x8023432f),
                          Color(0xb0092119),
                          Color(0xdf0b261c),
                        ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: child),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
          ],
        ),
      ),
    ),
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
                    const Icon(Icons.spa_outlined, size: 78, color: sage),
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
                    const Icon(Icons.spa_outlined, size: 68, color: sage),
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
                serif('0', size: 31),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: sage),
        ],
      ),
    ),
    const SizedBox(height: 12),
    const Text(
      'Poin tersedia setelah verifikasi setoran oleh mitra.',
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
      serif(value, size: 27),
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
        Icon(icon, color: ink, size: 27),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    ),
  );

  Uint8List? _photo;
  String _category = 'Plastik';
  Future<void> _pick(ImageSource source) async {
    try {
      final selected = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 65,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) _notify('Foto tidak dapat dibuka. Coba dari galeri.');
    }
  }

  Widget _scanner() => _scroll([
    const Text(
      'Arahkan kamera ke sampah yang ingin kamu catat.',
      textAlign: TextAlign.center,
      style: TextStyle(color: muted, height: 1.5),
    ),
    const SizedBox(height: 18),
    ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_photo != null)
              Image.memory(_photo!, fit: BoxFit.cover)
            else
              const RemotePhoto(Photos.detail),
            const ColoredBox(color: Color(0x33000000)),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: CustomPaint(painter: ScanFramePainter()),
              ),
            ),
            if (_photo == null)
              const Center(
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 65,
                  color: sage,
                ),
              ),
            const Positioned(
              left: 15,
              bottom: 14,
              child: Text(
                'Foto diproses sebagai catatan lokal',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 18),
    Row(
      children: [
        Expanded(
          child: LeafButton(
            'Foto',
            icon: Icons.photo_camera_outlined,
            onTap: () => _pick(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LeafButton(
            'Galeri',
            icon: Icons.photo_outlined,
            onTap: () => _pick(ImageSource.gallery),
          ),
        ),
      ],
    ),
    const SizedBox(height: 22),
    Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          serif('Kenali Sampahmu', size: 24),
          const SizedBox(height: 10),
          const Text(
            'Pilih jenis sampah pada foto. Klasifikasi otomatis belum tersedia.',
            style: TextStyle(color: muted, height: 1.5, fontSize: 12),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Jenis sampah'),
            items: [
              'Plastik',
              'Kertas',
              'Organik',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (x) => setState(() => _category = x!),
          ),
          const SizedBox(height: 16),
          Text(
            _guide(_category),
            style: const TextStyle(height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 18),
          LeafButton(
            'Simpan ke Riwayat',
            icon: Icons.bookmark_border,
            onTap: _saving
                ? null
                : () {
                    if (_photo == null) {
                      _notify('Ambil atau pilih foto terlebih dahulu.');
                      return;
                    }
                    _write(
                      () => _store!.addRecord('scans', {
                        'category': _category,
                        'classification': 'manual',
                        'photoBase64': base64Encode(_photo!),
                      }),
                    );
                  },
          ),
        ],
      ),
    ),
    _titleRow('Riwayat Pindai'),
    ..._recordWidgets('scans'),
  ]);
  String _guide(String category) => switch (category) {
    'Kertas' =>
      '1. Pisahkan kertas yang bersih dan kering.\n2. Ratakan kardus agar mudah disimpan.\n3. Tanyakan jenis kertas yang diterima tempat setor.',
    'Organik' =>
      '1. Pisahkan sisa makanan dari kemasan.\n2. Simpan dalam wadah tertutup.\n3. Olah dengan metode kompos yang sesuai.',
    _ =>
      '1. Kosongkan isi kemasan.\n2. Bersihkan seperlunya dan keringkan.\n3. Pilah berdasarkan jenis yang diterima tempat setor.',
  };

  Widget _points() => _scroll([
    Glass(
      child: Row(
        children: [
          const Icon(Icons.spa_outlined, color: sage, size: 52),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Poin Kamu',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 5),
              serif('0', size: 39),
            ],
          ),
          const Spacer(),
          const Icon(Icons.lock_outline, color: sage),
        ],
      ),
    ),
    const SizedBox(height: 14),
    const Text(
      'Poin dan penukaran memerlukan mitra terverifikasi. Catatan lokal tidak menerbitkan poin.',
      style: TextStyle(color: muted, fontSize: 12, height: 1.5),
    ),
    _titleRow('Pilihan Reward'),
    _reward('Transportasi Umum', 'Perjalanan yang lebih hijau', Photos.bus),
    const SizedBox(height: 14),
    _reward(
      'Produk Ramah Lingkungan',
      'Kurangi barang sekali pakai',
      Photos.plant,
    ),
    _titleRow('Catatan Setoran'),
    ..._recordWidgets('deposits'),
  ]);
  Widget _reward(String title, String subtitle, String photo) => PhotoPanel(
    photo: photo,
    minHeight: 155,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        serif(title, size: 22),
        const SizedBox(height: 7),
        Text(subtitle, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 22),
        const Row(
          children: [
            Icon(Icons.lock_outline, size: 15, color: sage),
            SizedBox(width: 7),
            Text('Menunggu mitra', style: TextStyle(fontSize: 11, color: sage)),
          ],
        ),
      ],
    ),
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
                  'Gunakan Scan untuk menyimpan foto dan kategori, Setor untuk mencatat rencana, serta Jejak Karbon untuk mencatat aktivitas.\n\nGambar dekorasi dimuat melalui internet. Catatan pribadi tetap disimpan lokal.\n\nMenghapus data aplikasi akan menghapus catatan lokal.',
                  style: TextStyle(height: 1.7),
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
      const Icon(Icons.spa_outlined, color: sage, size: 75),
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
        'Foto: Thiha Myokyaw, Animesh Srivastava, Lisa Fotios, Teddy Yang / Pexels.\nSumber lengkap tersedia di IMAGE_CREDITS.md.',
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
                              : '${r['category']} • pilihan manual',
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
      _page('Tempat Setor', (_) => LocationPage(store: _store!));

  Widget _navigation() {
    const icons = [
      Icons.home_rounded,
      Icons.document_scanner_outlined,
      Icons.spa_outlined,
      Icons.menu_book_outlined,
      Icons.person_outline,
    ];
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
                    Icon(icons[i], color: i == _tab ? sage : muted, size: 23),
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

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.store});
  final LocalStore store;
  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final name = TextEditingController();
  final address = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Icon(Icons.place_outlined, size: 64, color: sage),
      const SizedBox(height: 16),
      serif('Tempat Setor Pilihanmu', size: 28, align: TextAlign.center),
      const SizedBox(height: 12),
      const Text(
        'Simpan tempat yang sudah kamu ketahui. Konfirmasikan jam buka dan jenis sampah langsung ke pengelola.',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, height: 1.6, fontSize: 12),
      ),
      const SizedBox(height: 23),
      Glass(
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama tempat'),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            const SizedBox(height: 17),
            LeafButton(
              'Simpan Tempat',
              icon: Icons.bookmark_border,
              onTap: saving
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty ||
                          address.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lengkapi nama dan alamat.'),
                          ),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await widget.store.addRecord('places', {
                          'name': name.text.trim(),
                          'address': address.text.trim(),
                        });
                        name.clear();
                        address.clear();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tempat gagal disimpan.'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
            ),
          ],
        ),
      ),
      const SizedBox(height: 23),
      ...widget.store
          .getList('places')
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    serif('${r['name']}', size: 23),
                    const SizedBox(height: 10),
                    Text(
                      '${r['address']}',
                      style: const TextStyle(color: muted, height: 1.5),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: '${r['name']} ${r['address']}'),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Alamat disalin. Tempel ke aplikasi peta.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 17),
                      label: const Text('Salin alamat'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ],
  );
}

class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = sage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const length = 30.0;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final x = corner.dx == 0 ? length : -length;
      final y = corner.dy == 0 ? length : -length;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + x, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Article {
  const Article(this.title, this.category, this.photo, this.body);
  final String title, category, photo, body;
}

const articles = [
  Article(
    '5 Cara Mudah Mengurangi Sampah Plastik di Rumah',
    'Tips',
    Photos.detail,
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
    Photos.leaves,
    'Organik: pisahkan dari kemasan dan gunakan pengolahan organik yang sesuai.\n\nKertas: simpan bersih dan kering. Kertas berminyak atau berlapis mungkin tidak diterima.\n\nPlastik: kelompokkan sesuai petunjuk tempat setor. Simbol pada kemasan tidak menjamin tersedianya fasilitas pengolahan lokal.\n\nBaterai, elektronik, dan limbah berbahaya perlu jalur pengumpulan khusus. Hubungi pengelola sampah setempat untuk petunjuk penanganan.',
  ),
];
