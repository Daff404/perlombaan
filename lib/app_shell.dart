part of 'main.dart';

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
    } catch (e) {
      SystemLog.add('local-save', e);
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
                  Expanded(
                    child: PageLoading(child: Builder(builder: body)),
                  ),
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

  void _deposit() => _entryPage('Setor Sampah', deposit: true);
  void _carbon() => _entryPage('Jejak Karbon', deposit: false);
  void _entryPage(String title, {required bool deposit}) {
    _page(
      title,
      (_) => deposit
          ? DepositPage(store: _store!, onSaved: () => setState(() {}))
          : CarbonPage(store: _store!, onSaved: () => setState(() {})),
    );
  }

  void _locations() =>
      _page('Lokasi Bank Sampah', (_) => PlacesPage(store: _store!));

  Widget _navigation() => ShionNavigation(selected: _tab, onSelect: _selectTab);
  void _selectTab(int value) {
    if (value != _tab) setState(() => _tab = value);
  }

  void _refresh(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) {
    if (_store == null) {
      return const ForestPage(child: PageSkeleton());
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
            child: PageLoading(
              key: ValueKey(_tab),
              child: PageSkin(index: _tab, child: pages[_tab]()),
            ),
          ),
        ],
      ),
    );
  }
}
