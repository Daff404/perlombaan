// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
part of 'main.dart';

class ShionHome extends StatefulWidget {
  const ShionHome({super.key, this.store});
  final ApiStore? store;
  @override
  State<ShionHome> createState() => _shionHomeKeadaan();
}

class _shionHomeKeadaan extends State<ShionHome> with WidgetsBindingObserver {
  Future<void> _ubahProfilFoto() async {
    try {
      final foto = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 82);
      if (foto == null) return;
      final byte = await foto.readAsBytes();
      await _penyimpanan!.api.permintaan('POST', '/profile/photo', body: {'photoBase64': base64Encode(byte)});
      if (mounted) {
        setState(() => _profilFotoRevisi++);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto profil gagal diperbarui: $error')));
    }
  }
  ApiStore? _penyimpanan;
  Timer? _sinkronPengaturwaktu;
  bool _memulai = true, _menyinkronkan = false, _diLatardepan = true;
  String? _awalGalat, _sinkronGalat;
  int _tab = 0;
  int _revisiPemindai = 0;
  int _profilFotoRevisi = 0;
  bool _terautentikasi = false;
  bool _menyimpan = false;
  final String _kueri = '';
  final _nama = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _penyimpanan = widget.store ?? ApiStore();
    _penyimpanan!.addListener(_penyimpananBerubah);
    unawaited(_mulai());
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && widget.store == null) unawaited(DeviceAccess.mintaIzin(context)); });
    _sinkronPengaturwaktu = Timer.periodic(const Duration(seconds: 30), (_) => _sinkron());
  }

  Future<void> _mulai() async {
    setState(() { _memulai = true; _awalGalat = null; });
    try {
      await _penyimpanan!.pulihkanSesi();
      if (!mounted) return;
      setState(() {
        _terautentikasi = _penyimpanan!.sudahMasuk;
        _nama.text = _penyimpanan!.name;
      });
    } catch (error) {
      if (mounted) setState(() => _awalGalat = error.toString());
    } finally {
      if (mounted) setState(() => _memulai = false);
    }
  }

  void _penyimpananBerubah() {
    if (!mounted) return;
    final kedaluwarsa = _terautentikasi && !_penyimpanan!.sudahMasuk;
    setState(() { if (kedaluwarsa) { _terautentikasi = false; _tab = 0; } });
    if (kedaluwarsa) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  Future<void> _sinkron() async {
    if (!_terautentikasi || !_diLatardepan || _menyinkronkan || !mounted) return;
    _menyinkronkan = true;
    try {
      await _penyimpanan!.segarkan();
      if (widget.store == null) await DeviceAccess.sinkronkan(_penyimpanan!.api);
      if (mounted) setState(() => _sinkronGalat = null);
    } catch (error) {
      if (mounted && _terautentikasi) setState(() => _sinkronGalat = error.toString());
    } finally { _menyinkronkan = false; }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _diLatardepan = state == AppLifecycleState.resumed;
    if (_diLatardepan) unawaited(_sinkron());
  }

  @override
  void dispose() {
    _sinkronPengaturwaktu?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _penyimpanan?.removeListener(_penyimpananBerubah);
    if (widget.store == null) _penyimpanan?.dispose();
    _nama.dispose();
    super.dispose();
  }

  void _beriNotifikasi(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _tulis(Future<void> Function() action) async {
    if (_menyimpan) return;
    setState(() => _menyimpan = true);
    try {
      await action();
      if (mounted) {
        setState(() {});
        _beriNotifikasi('Tersimpan ke akunmu.');
      }
    } catch (e) {
      SystemLog.add('api-save', e);
      if (mounted) _beriNotifikasi(e.toString());
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  void _halaman(String title, WidgetBuilder body) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => AnimatedBuilder(
              animation: _penyimpanan!,
              builder: (context, _) => ForestPage(
              child: Column(
                children: [
                  _kepala(title, back: true),
                  Expanded(
                    child: PageLoading(child: Builder(builder: body)),
                  ),
                ],
              ),
              ),
            ),
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  Widget _kepala(String title, {bool back = false}) => Padding(
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
        Expanded(child: serif(title, size: 23, align: TextAlign.center, maxLines: 1)),
        if (title != 'Chatbot SHION') IconButton(
          tooltip: 'Chatbot SHION',
          onPressed: _obrolanAi,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
        ),
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: () => _halaman('Notifikasi', (_) => NotificationsPage(store: _penyimpanan!)),
          icon: Badge(
            isLabelVisible: _penyimpanan!.notifikasiBelumDibaca > 0,
            label: Text('${_penyimpanan!.notifikasiBelumDibaca}'),
            child: const Icon(Icons.notifications_none_rounded, size: 23),
          ),
        ),
      ],
    ),
  );

  void _menu() => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup menu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, _, __) => Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: const Color(0xff0b2b20),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: MediaQuery.sizeOf(dialogContext).width < 400
              ? MediaQuery.sizeOf(dialogContext).width * .78
              : 312,
          height: MediaQuery.sizeOf(dialogContext).height,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const ShionLogo(size: 42),
                    const SizedBox(width: 12),
                    Expanded(child: serif('SHION', size: 27, color: const Color(0xfff4f4e8))),
                    IconButton(
                      tooltip: 'Tutup menu',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: Color(0xffe4eee0)),
                    ),
                  ]),
                  const Divider(color: Color(0xff41604d), height: 30),
                  Expanded(child: ListView(padding: EdgeInsets.zero, children: [
                  ListTile(
                    textColor: const Color(0xffedf4e9),
                    iconColor: const Color(0xffb3d59a),
                    leading: const Icon(Icons.recycling),
                    title: const Text('Rencana Setoran'),
                    onTap: () { Navigator.pop(dialogContext); _setoran(); },
                  ),
                  ListTile(
                    textColor: const Color(0xffedf4e9),
                    iconColor: const Color(0xffb3d59a),
                    leading: const Icon(Icons.public),
                    title: const Text('Jejak Aktivitas'),
                    onTap: () { Navigator.pop(dialogContext); _karbon(); },
                  ),
                  ListTile(
                    textColor: const Color(0xffedf4e9),
                    iconColor: const Color(0xffb3d59a),
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('Tempat Setor Tersimpan'),
                    onTap: () { Navigator.pop(dialogContext); _daftarLokasi(); },
                  ),
                  ListTile(
                    textColor: const Color(0xffedf4e9),
                    iconColor: const Color(0xffb3d59a),
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('Chatbot SHION'),
                    onTap: () { Navigator.pop(dialogContext); _obrolanAi(); },
                  ),
                  ListTile(
                    textColor: const Color(0xffedf4e9),
                    iconColor: const Color(0xffb3d59a),
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Tentang SHION'),
                    onTap: () { Navigator.pop(dialogContext); _tentang(); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.leaderboard_outlined, color: sage),
                    title: const Text('Leaderboard'),
                    onTap: () { Navigator.pop(dialogContext); _papanPeringkat(); },
                  ),
                  ListTile(leading: const Icon(Icons.groups_outlined, color: sage), title: const Text('Komunitas'), onTap: () { Navigator.pop(dialogContext); _komunitas(); }),
                  if (_penyimpanan!.adalahAdmin) ListTile(leading: const Icon(Icons.qr_code_scanner_rounded, color: sage), title: const Text('Scan QR setoran'), onTap: () { Navigator.pop(dialogContext); _scanQrSetoran(); }),
                  if (_penyimpanan!.adalahAdmin) ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, color: terracotta),
                    title: const Text('Panel admin'),
                    onTap: () { Navigator.pop(dialogContext); _admin(); },
                  ),
                  ])),
                  const Divider(color: Color(0xff41604d)),
                  ListTile(
                    textColor: const Color(0xffffc4ad),
                    iconColor: const Color(0xffffa98c),
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Keluar dari akun'),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _keluar();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );


  Future<void> _keluar() async {
    final terkonfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Sesi akan diakhiri. Data akun dan aktivitas tetap tersimpan di server SHION.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (terkonfirmasi != true || !mounted) return;
    try {
      await _penyimpanan!.keluar();
      if (!mounted) return;
      setState(() { _terautentikasi = false; _tab = 0; });
    } catch (error) {
      if (mounted) _beriNotifikasi(error.toString());
    }
  }

  void _papanPeringkat() => _halaman('Leaderboard', (_) => LeaderboardPage(store: _penyimpanan!));
  void _admin() => _halaman('Panel admin', (_) => AdminPage(store: _penyimpanan!));
  void _komunitas() => _halaman('Komunitas', (_) => CommunityPage(store: _penyimpanan!));
  void _scanQrSetoran() => _halaman('Scan QR setoran', (_) => AdminDepositQrPage(store: _penyimpanan!));

  void _obrolanAi() => _halaman('Chatbot SHION', (_) => ShionChatPage(store: _penyimpanan!));

  Widget _gulir(List<Widget> children) => RefreshIndicator(
    color: sage,
    onRefresh: _penyimpanan!.segarkan,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      children: children,
    ),
  );
  Widget _judulBaris(String title, {String? action, VoidCallback? onTap}) =>
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

  Widget _pemindai() => ScannerPage(
    store: _penyimpanan!,
    onSaved: () {
      if (mounted) setState(() {});
    },
    onFindPlace: _daftarLokasi,
  );
  Widget _poin() => PointsPage(
    store: _penyimpanan!,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  void _setoran() => _masukHalaman('Setor Sampah', deposit: true);
  void _karbon() => _masukHalaman('Jejak Karbon', deposit: false);
  void _masukHalaman(String title, {required bool deposit}) {
    _halaman(
      title,
      (_) => deposit
          ? DepositPage(
              store: _penyimpanan!,
              onSaved: () => setState(() {}),
              onScan: () {
                Navigator.of(context).pop();
                _pilihTab(1);
              },
            )
          : CarbonPage(store: _penyimpanan!, onSaved: () => setState(() {})),
    );
  }

  void _daftarLokasi() =>
      _halaman('Lokasi Kelurahan', (_) => PlacesPage(store: _penyimpanan!));

  Widget _navigasi() => ShionNavigation(selected: _tab, onSelect: _pilihTab);
  void _pilihTab(int value) {
    if (value == 1 && value == _tab) {
      setState(() => _revisiPemindai++);
    } else if (value != _tab) {
      setState(() => _tab = value);
    }
  }

  Future<void> _selesaikanAutentikasi(
    String name,
    String email,
    String phone,
  ) async {
    if (!mounted) return;
    setState(() {
      _nama.text = name;
      _terautentikasi = true;
    });
    if (widget.store == null) unawaited(DeviceAccess.sinkronkan(_penyimpanan!.api));
  }

  @override
  Widget build(BuildContext context) {
    if (_memulai) {
      return const ForestPage(child: PageSkeleton());
    }
    if (_awalGalat != null) {
      return ForestPage(child: Center(child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, color: sage, size: 48),
          const SizedBox(height: 18),
          serif('Belum terhubung', align: TextAlign.center),
          const SizedBox(height: 12),
          Text(_awalGalat!, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          LeafButton('Coba lagi', onTap: _mulai, icon: Icons.refresh_rounded),
        ]),
      )));
    }
    if (!_terautentikasi) {
      return ShionAuthFlow(
        store: _penyimpanan!,
        onAuthenticated: _selesaikanAutentikasi,
      );
    }
    final daftarHalaman = <Widget Function()>[
      _beranda,
      _pemindai,
      _poin,
      _edukasi,
      _profil,
    ];
    return ForestPage(
      bottom: _navigasi(),
      child: Column(
        children: [
          _kepala(
            [
              'SHION',
              'Pindai Sampah',
              'Green Point',
              'Edukasi',
              'Profil',
            ][_tab],
          ),
          if (_sinkronGalat != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              const Icon(Icons.cloud_off_outlined, color: terracotta, size: 17),
              const SizedBox(width: 8),
              const Expanded(child: Text('Sinkronisasi tertunda. Periksa koneksi.', style: TextStyle(fontSize: 10, color: muted))),
              IconButton(onPressed: _sinkron, icon: const Icon(Icons.refresh, size: 18)),
            ]),
          ),
          Expanded(
            child: PageLoading(
              key: ValueKey('$_tab:$_revisiPemindai'),
              child: PageSkin(index: _tab, child: daftarHalaman[_tab]()),
            ),
          ),
        ],
      ),
    );
  }
}
