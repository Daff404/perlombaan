// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
part of '../main.dart';

/// Onboarding and REST account screens. Public signup creates user accounts.
class ShionAuthFlow extends StatefulWidget {
  const ShionAuthFlow({super.key, required this.store, required this.onAuthenticated});

  final ApiStore store;
  final Future<void> Function(String name, String email, String phone)
      onAuthenticated;

  @override
  State<ShionAuthFlow> createState() => _shionAutentikasiFlowKeadaan();
}

class _shionAutentikasiFlowKeadaan extends State<ShionAuthFlow> {
  final _masukFormulirKunci = GlobalKey<FormState>();
  final _daftarFormulirKunci = GlobalKey<FormState>();
  final _kataSandiFormulirKunci = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _surel = TextEditingController();
  final _telepon = TextEditingController();
  final _kataSandi = TextEditingController();
  final _konfirmasiKatasandi = TextEditingController();
  int _layar = 0; // intro, feature, login, register, password, account created
  bool _sibuk = false;
  bool _syaratDisetujui = false;
  bool _tampilkanKatasandi = false;
  bool _tampilkanKonfirmasi = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _surel.dispose();
    _telepon.dispose();
    _kataSandi.dispose();
    _konfirmasiKatasandi.dispose();
    super.dispose();
  }

  void _pergi(int screen) => setState(() {
    _layar = screen;
    _galat = null;
  });

  Future<void> _masuk() async {
    if (!_masukFormulirKunci.currentState!.validate()) return;
    setState(() { _sibuk = true; _galat = null; });
    try {
      await widget.store.autentikasi(email: _surel.text, password: _kataSandi.text);
      if (!mounted) return;
      await widget.onAuthenticated(widget.store.name, widget.store.email, widget.store.phone);
    } catch (error) {
      if (mounted) setState(() => _galat = error.toString());
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _daftar() async {
    if (!_daftarFormulirKunci.currentState!.validate()) return;
    if (!_syaratDisetujui) {
      setState(() => _galat = 'Setujui syarat dan kebijakan privasi untuk lanjut.');
      return;
    }
    _pergi(4);
  }

  Future<void> _buatAkun() async {
    if (!_kataSandiFormulirKunci.currentState!.validate()) return;
    if (_kataSandi.text != _konfirmasiKatasandi.text) {
      setState(() => _galat = 'Kata sandi belum sama.');
      return;
    }
    setState(() { _sibuk = true; _galat = null; });
    try {
      await widget.store.daftarkanAkun(
        name: _nama.text,
        email: _surel.text,
        phone: _telepon.text,
        password: _kataSandi.text,
      );
      if (mounted) _pergi(5);
    } catch (error) {
      if (mounted) setState(() => _galat = error.toString());
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: surface,
    body: SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 340),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_layar), child: _layarKonten()),
      ),
    ),
  );

  Widget _layarKonten() => switch (_layar) {
    0 => _perkenalanHalaman(feature: false),
    1 => _perkenalanHalaman(feature: true),
    2 => _masukHalaman(),
    3 => _daftarHalaman(),
    4 => _kataSandiHalaman(),
    _ => _berhasilHalaman(),
  };

  Widget _penggulir(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    ),
  );

  Widget _merek({bool light = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ShionLogo(size: 42),
      const SizedBox(width: 9),
      serif('SHION', size: 23, color: light ? const Color(0xfff0f3e8) : forest),
    ],
  );

  Widget _perkenalanHalaman({required bool feature}) => _penggulir([
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _pergi(2),
        child: const Text('Lewati'),
      ),
    ),
    const SizedBox(height: 8),
    _merek(light: true),
    const SizedBox(height: 24),
    Text(
      feature ? 'KENALI SEBELUM MEMILAH' : 'LANGKAH KECIL, DAMPAK NYATA',
      style: const TextStyle(color: sage, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 8),
    serif(
      feature ? 'Pindai. Pahami.\nPilah dengan bijak.' : 'Untuk bumi,\nhari ini.',
      size: 35,
      color: const Color(0xfff0f3e8),
    ),
    const SizedBox(height: 14),
    Text(
      feature
          ? 'Arahkan kamera ke satu benda. SHION bantu mengenali jenis sampah dan cara menanganinya.'
          : 'Kenali sampah, pelajari cara memilah, dan mulai merawat bumi dari rumah.',
      style: const TextStyle(color: Color(0xffd2dfce), height: 1.55, fontSize: 13),
    ),
    const SizedBox(height: 25),
    Container(
      height: 270,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff376342), Color(0xff0c3225), Color(0xff173d2b)]),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xffb2d694).withValues(alpha: .35)),
        boxShadow: const [BoxShadow(color: Color(0x5500110b), blurRadius: 18, offset: Offset(0, 9))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -25, top: -38,
            child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .16))),
          ),
          Positioned(left: 22, top: 24, child: _orbitTitik(12, const Color(0xffe2b75e))),
          Positioned(right: 30, top: 55, child: _orbitTitik(8, const Color(0xffc6e78f))),
          Positioned(left: 44, bottom: 24, child: _orbitTitik(7, const Color(0xffe59663))),
          Positioned(right: -25, bottom: -35, child: Container(width: 145, height: 145, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xffc4e49b).withValues(alpha: .22), width: 2)))),
          Image.asset(
            feature ? 'assets/vector/onboarding_scan.png' : 'assets/vector/onboarding_hello.png',
            width: 310, height: 260, fit: BoxFit.contain,
          ),
          Positioned(left: 16, bottom: 15, child: _ilustrasiTag(feature ? Icons.center_focus_strong_rounded : Icons.spa_outlined, feature ? 'AI Pindai' : 'Rawat bumi')),
        ],
      ),
    ),
    const SizedBox(height: 18),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _titik(!feature), const SizedBox(width: 7), _titik(feature),
    ]),
    const SizedBox(height: 18),
    LeafButton(
      feature ? 'Masuk atau daftar' : 'Lanjutkan',
      onTap: () => _pergi(feature ? 2 : 1),
    ),
    const SizedBox(height: 10),
    if (feature)
      TextButton(onPressed: () => _pergi(2), child: const Text('Saya sudah punya akun', style: TextStyle(color: Color(0xffd7e7ce)))),
  ]);


  Widget _orbitTitik(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 12)]));

  Widget _ilustrasiTag(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xdd06251a), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xffc9eea5), size: 15), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))]),
  );

  Widget _titik(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    width: active ? 22 : 7,
    height: 7,
    decoration: BoxDecoration(color: active ? sage : const Color(0xff62836b), borderRadius: BorderRadius.circular(8)),
  );

  Widget _utamaKepala({required String title, required String subtitle, required int art}) =>
      LayoutBuilder(builder: (context, constraints) {
      final ringkas = constraints.maxWidth < 390;
      return Container(
        height: ringkas ? (art == 0 ? 254 : 260) : (art == 0 ? 278 : 226),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
        decoration: const BoxDecoration(
          color: forestDeep,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _merek(light: true),
          const SizedBox(height: 18),
          Expanded(
            child: Row(children: [
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                serif(title, size: ringkas ? 22 : (art == 0 ? 29 : 26), color: const Color(0xfff0f3e8)),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: const Color(0xffdce7d7), fontSize: ringkas ? 10 : 11, height: 1.4)),
              ])),
              SizedBox(width: ringkas ? 2 : 6),
              Container(
                width: ringkas ? 88 : (art == 0 ? 142 : 112),
                height: ringkas ? 96 : (art == 0 ? 148 : 114),
                decoration: BoxDecoration(
                  color: const Color(0xff17412d),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xffa6d488).withValues(alpha: .3)),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Positioned(right: 7, top: 7, child: _orbitTitik(7, const Color(0xffdfae5d))),
                  Image.asset(
                  art == 0
                      ? 'assets/vector/auth_login.png'
                      : art == 1
                          ? 'assets/vector/auth_register.png'
                          : 'assets/vector/auth_password.png',
                  width: ringkas ? 84 : (art == 0 ? 138 : 108), height: ringkas ? 92 : (art == 0 ? 143 : 108), fit: BoxFit.contain,
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      );
      });

  Widget _panel({required Widget header, required List<Widget> children}) =>
      LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            header,
            Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 26), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
          ]),
        ),
      ));

  Widget _masukHalaman() => _panel(
    header: _utamaKepala(title: 'Selamat datang\nkembali.', subtitle: 'Rawat bumi bersama, mulai dari satu langkah kecil.', art: 0),
    children: [
      serif('Masuk ke akunmu', size: 24, color: forest),
      const SizedBox(height: 16),
      Form(key: _masukFormulirKunci, child: Column(children: [
        _surelKolom(),
        const SizedBox(height: 12),
        _kataSandiKolom(controller: _kataSandi, label: 'Kata sandi', show: _tampilkanKatasandi, toggle: () => setState(() => _tampilkanKatasandi = !_tampilkanKatasandi)),
      ])),
      Align(alignment: Alignment.centerRight, child: TextButton(
        onPressed: () => _pesan('Hubungi pengelola SHION untuk bantuan pemulihan akun. Jangan bagikan kata sandi.'),
        child: const Text('Lupa kata sandi?'),
      )),
      if (_galat != null) _galatTeks(),
      LeafButton(_sibuk ? 'Memeriksa…' : 'Masuk', onTap: _sibuk ? null : _masuk, icon: Icons.arrow_forward_rounded),
      const SizedBox(height: 12),
      const SizedBox(height: 18),
      _alihTautan('Belum punya akun?', 'Daftar', () => _pergi(3)),
    ],
  );

  Widget _daftarHalaman() => _panel(
    header: _utamaKepala(title: 'Bergabung merawat\nbumi bersama.', subtitle: 'Buat akun SHION untuk memulai langkah baikmu.', art: 1),
    children: [
      serif('Data diri', size: 24, color: forest),
      const SizedBox(height: 5),
      const Text('Isi data berikut untuk membuat akun.', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 16),
      Form(key: _daftarFormulirKunci, child: Column(children: [
        TextFormField(
          controller: _nama,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => (v ?? '').trim().length < 2 ? 'Masukkan nama lengkap.' : null,
        ),
        const SizedBox(height: 12),
        _surelKolom(),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telepon,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Nomor telepon', hintText: '+62 812-3456-7890', prefixIcon: Icon(Icons.phone_outlined)),
          validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'Masukkan nomor telepon yang valid.' : null,
        ),
      ])),
      const SizedBox(height: 10),
      CheckboxListTile(
        value: _syaratDisetujui,
        onChanged: (v) => setState(() => _syaratDisetujui = v ?? false),
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Saya setuju dengan Syarat Layanan dan Kebijakan Privasi.', style: TextStyle(fontSize: 11, height: 1.35)),
      ),
      if (_galat != null) _galatTeks(),
      LeafButton('Lanjutkan', onTap: _daftar),
      const SizedBox(height: 15),
      _alihTautan('Sudah punya akun?', 'Masuk', () => _pergi(2)),
      const SizedBox(height: 10),
      const Text('Akunmu terhubung ke server SHION. Tidak perlu kode verifikasi.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 10)),
      const SizedBox(height: 8),
      const Text('Nama dan total aktivitasmu dapat tampil di leaderboard komunitas.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 10)),
    ],
  );

  Widget _kataSandiHalaman() => _panel(
    header: _utamaKepala(title: 'Satu langkah lagi\nuntuk akunmu.', subtitle: 'Buat kata sandi yang aman dan mudah diingat.', art: 2),
    children: [
      serif('Amankan akunmu', size: 24, color: forest),
      const SizedBox(height: 6),
      const Text('Gunakan minimal 8 karakter untuk melindungi akunmu.', style: TextStyle(color: muted, fontSize: 11)),
      const SizedBox(height: 18),
      Form(key: _kataSandiFormulirKunci, child: Column(children: [
        _kataSandiKolom(controller: _kataSandi, label: 'Kata sandi', show: _tampilkanKatasandi, toggle: () => setState(() => _tampilkanKatasandi = !_tampilkanKatasandi), validate: true),
        const SizedBox(height: 12),
        _kataSandiKolom(controller: _konfirmasiKatasandi, label: 'Ulangi kata sandi', show: _tampilkanKonfirmasi, toggle: () => setState(() => _tampilkanKonfirmasi = !_tampilkanKonfirmasi), validate: true),
      ])),
      const SizedBox(height: 14),
      const Row(children: [Icon(Icons.check_circle_outline, size: 16, color: sage), SizedBox(width: 8), Text('Minimal 8 karakter', style: TextStyle(color: muted, fontSize: 12))]),
      if (_galat != null) _galatTeks(),
      const SizedBox(height: 22),
      LeafButton(_sibuk ? 'Membuat akun…' : 'Buat akun', onTap: _sibuk ? null : _buatAkun),
      const SizedBox(height: 12),
      TextButton(onPressed: () => _pergi(3), child: const Text('Kembali ke data diri')),
    ],
  );

  Future<void> _selesaikanPendaftaran() => widget.onAuthenticated(
        _nama.text.trim(), _surel.text.trim(), _telepon.text.trim(),
      );

  Widget _berhasilHalaman() => _penggulir([
        const SizedBox(height: 12),
        Align(alignment: Alignment.center, child: _merek(light: true)),
        const SizedBox(height: 28),
        Container(
          height: 330,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff285638), Color(0xff0b3023), Color(0xff1b472f)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xffb2d694).withValues(alpha: .35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(alignment: Alignment.center, children: [
            Positioned(left: -45, top: -38, child: Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffc5e89c).withValues(alpha: .12)))),
            Positioned(right: -35, bottom: -38, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xffc5e89c).withValues(alpha: .24), width: 2)))),
            Image.asset('assets/vector/auth_success.png', width: 310, height: 320, fit: BoxFit.contain),
            Positioned(right: 22, top: 20, child: _orbitTitik(10, const Color(0xffe2b75e))),
          ]),
        ),
        const SizedBox(height: 28),
        Text('AKUN SIAP DIGUNAKAN', textAlign: TextAlign.center, style: const TextStyle(color: sage, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        serif('Selamat datang,\n${_nama.text.trim().split(' ').first}!', size: 32, color: const Color(0xfff0f3e8), align: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Satu langkah kecilmu sudah dimulai. Yuk, kenali sampah dan rawat bumi bersama SHION.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xffd2dfce), height: 1.55, fontSize: 13)),
        const SizedBox(height: 26),
        LeafButton('Masuk ke SHION', onTap: _selesaikanPendaftaran, icon: Icons.arrow_forward_rounded),
      ]);

  Widget _surelKolom() => TextFormField(
    controller: _surel,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    decoration: const InputDecoration(labelText: 'Email', hintText: 'nama@email.com', prefixIcon: Icon(Icons.mail_outline)),
    validator: (v) {
      final value = (v ?? '').trim();
      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? null : 'Masukkan email yang valid.';
    },
  );

  Widget _kataSandiKolom({required TextEditingController controller, required String label, required bool show, required VoidCallback toggle, bool validate = false}) => TextFormField(
    controller: controller,
    obscureText: !show,
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(onPressed: toggle, icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
    ),
    validator: (v) {
      if (!validate && (v ?? '').isEmpty) return 'Masukkan kata sandi.';
      if (validate && (v ?? '').length < 8) return 'Gunakan minimal 8 karakter.';
      return null;
    },
  );

  Widget _alihTautan(String prefix, String action, VoidCallback onTap) => Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
    Text(prefix, style: const TextStyle(color: muted, fontSize: 12)),
    TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700))),
  ]);

  Widget _galatTeks() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(_galat!, style: const TextStyle(color: terracotta, fontSize: 12)),
  );

  void _pesan(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
