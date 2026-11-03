// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
part of '../main.dart';

extension _profilHalaman on _shionHomeKeadaan {
  Future<void> _ubahProfilFoto() async {
    try {
      final foto = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 82);
      if (foto == null) return;
      final byte = await foto.readAsBytes();
      await _penyimpanan!.api.permintaan('POST', '/profile/photo', body: {'photoBase64': base64Encode(byte)});
      if (mounted) { setState(() => _profilFotoRevisi++); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui.'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto profil gagal diperbarui: $e'))); }
  }
  Widget _profil() {
    final daftarPindai = _penyimpanan!.ambilDaftar('scans').length;
    final daftarSetoran = _penyimpanan!.ambilDaftar('deposits').length;
    final namaTampilan = _penyimpanan!.name.trim().isEmpty
        ? 'Sahabat Bumi'
        : _penyimpanan!.name.trim();

    return _gulir([
      const SizedBox(height: 8),
      _profilUtama(namaTampilan),
      const SizedBox(height: 16),
      _profilRingkasan(scans: daftarPindai, deposits: daftarSetoran),
      const SizedBox(height: 16),
      LeafButton(_penyimpanan!.adalahAdmin ? 'Scan QR • tambahkan poin' : 'Tampilkan QR poin saya', onTap: _poinQr, icon: Icons.qr_code_rounded),
      const SizedBox(height: 10),
      SelectableText('@${_penyimpanan!.user['username'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: sage)),
      const SizedBox(height: 22),
      _profilBagianJudul('Informasi pribadi', 'Perbarui nama panggilanmu'),
      const SizedBox(height: 10),
      _profilIdentitasKartu(),
      const SizedBox(height: 12),
      _profilMenuGrup([_profilMenuData(icon: Icons.lock_outline, title: 'Ubah kata sandi', subtitle: 'Perbarui keamanan akunmu', color: surfaceHigh, onTap: () => _halaman('Ubah kata sandi', (_) => PasswordPage(store: _penyimpanan!)))]),
      const SizedBox(height: 22),
      _profilBagianJudul('Aktivitas SHION', 'Tersinkron ke akun SHION'),
      const SizedBox(height: 10),
      _profilMenuGrup([
        _profilMenuData(
          icon: Icons.history_rounded,
          title: 'Riwayat aktivitas',
          subtitle: 'Lihat scan dan catatan setoran',
          color: const Color(0xffe5efd4),
          onTap: () => _halaman('Riwayat Aktivitas', (_) => _semuaRiwayat()),
        ),
        _profilMenuData(
          icon: Icons.place_outlined,
          title: 'Tempat setor tersimpan',
          subtitle: 'Temukan bank sampah di sekitarmu',
          color: const Color(0xff493a2c),
          onTap: _daftarLokasi,
        ),
      ]),
      const SizedBox(height: 14),
      _profilMenuGrup([
        _profilMenuData(icon: Icons.groups_outlined, title: 'Komunitas saya', subtitle: 'Obrolan, undangan, dan teman baru', color: surfaceHigh, onTap: _komunitas),
        _profilMenuData(icon: Icons.security_outlined, title: 'Izin aplikasi', subtitle: 'Kamera, lokasi, dan notifikasi', color: surfaceHigh, onTap: () => DeviceAccess.mintaIzin(context, manual: true)),
        _profilMenuData(icon: Icons.leaderboard_outlined, title: 'Leaderboard komunitas', subtitle: 'Poin tertinggi dan setoran terbanyak', color: surfaceHigh, onTap: _papanPeringkat),
        if (_penyimpanan!.adalahAdmin) _profilMenuData(icon: Icons.admin_panel_settings_outlined, title: 'Panel admin', subtitle: 'Kirim notifikasi ke pengguna', color: surfaceHigh, onTap: _admin),
      ]),
      const SizedBox(height: 22),
      _profilBagianJudul('Bantuan & preferensi', 'Pengaturan aplikasi'),
      const SizedBox(height: 10),
      _profilMenuGrup([
        _profilMenuData(
          icon: Icons.language_rounded,
          title: 'Bahasa',
          subtitle: 'Indonesia',
          color: const Color(0xffe7eee5),
          onTap: () => _beriNotifikasi('Bahasa aplikasi: Indonesia.'),
        ),
        _profilMenuData(
          icon: Icons.help_outline_rounded,
          title: 'Pusat bantuan',
          subtitle: 'Cara menggunakan fitur SHION',
          color: const Color(0xff493a2c),
          onTap: () => _halaman(
            'Pusat Bantuan',
            (_) => _gulir([
              const SizedBox(height: 12),
              _bantuanTopik(
                'Memindai sampah',
                'Pilih foto atau buka kamera, arahkan ke satu benda dengan cahaya cukup, hasil dan kategorinya otomatis disimpan ke akunmu.',
                Icons.center_focus_strong_rounded,
              ),
              const SizedBox(height: 10),
              _bantuanTopik(
                'Mencatat setoran',
                'Pilih kategori dari scan yang belum digunakan, lalu pilih kilogram atau satuan. Satu scan hanya dapat dipakai sekali.',
                Icons.recycling_rounded,
              ),
              const SizedBox(height: 10),
              _bantuanTopik(
                'Privasi data',
                'Profil, scan, setoran dan percakapan tersimpan di server. Masuk dengan akun yang sama untuk mengaksesnya di perangkat lain.',
                Icons.lock_outline_rounded,
              ),
            ]),
          ),
        ),
        _profilMenuData(
          icon: Icons.eco_outlined,
          title: 'Tentang SHION',
          subtitle: 'Kenali misi dan cerita kami',
          color: const Color(0xffe5efd4),
          onTap: _tentang,
        ),
        _profilMenuData(
          icon: Icons.logout_rounded,
          title: 'Keluar dari akun',
          subtitle: 'Akhiri sesi di perangkat ini',
          color: const Color(0xff493a2c),
          onTap: _keluar,
        ),
      ]),
      const SizedBox(height: 20),
      _profilPenutupNote(),
      const SizedBox(height: 12),
    ]);
  }

  Widget _profilUtama(String namaTampilan) => Container(
    height: 184,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(27),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff143d2d), Color(0xff08281e)],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x1b173f30), blurRadius: 18, offset: Offset(0, 8)),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -18,
          bottom: -44,
          child: Image.asset(
            'assets/vector/plant_a_seedling.png',
            width: 215,
            height: 215,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(right: 22, top: 16, child: Container(width: 144, height: 144, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xffbfe49d).withValues(alpha: .18), width: 1.5)))),
        Positioned(right: 86, top: 45, child: Icon(Icons.auto_awesome, size: 13, color: const Color(0xffe3b866).withValues(alpha: .9))),
        Positioned(left: 22, bottom: 24, child: Icon(Icons.eco_outlined, size: 18, color: const Color(0xffb7df8c).withValues(alpha: .75))),
        Positioned(
          right: 128,
          top: 22,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: Color(0xffefb37b), shape: BoxShape.circle),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 18, 17, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(onTap: _ubahProfilFoto, child: Stack(children: [ApiAvatar(api: _penyimpanan!.api, path: '/profile/photo', refresh: _profilFotoRevisi, size: 48, fallback: Container(width: 48, height: 48, color: const Color(0xffd6e8ad), child: const BrandGlyph('leaf', size: 32, color: forestDeep))), Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Color(0xff009d20), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 10, color: Colors.white)))])),
                  const SizedBox(width: 10),
                  const Text(
                    'RUANG PRIBADI',
                    style: TextStyle(
                      color: Color(0xffc9dfae),
                      fontSize: 9,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Halo, $namaTampilan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xfffff8e9),
                  fontFamily: 'Cormorant',
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Terima kasih sudah merawat bumi.',
                style: TextStyle(color: Color(0xffe0e6d5), fontSize: 10.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x2bffffff),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x45ffffff)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.spa_outlined, size: 13, color: Color(0xffcde99a)),
                    SizedBox(width: 5),
                    Text('Langkah kecil, dampak nyata', style: TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _profilRingkasan({required int daftarPindai, required int daftarSetoran}) => Container(
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
    decoration: BoxDecoration(
      color: const Color(0xff173b2c),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xff55715c)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Perjalananmu bersama SHION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const VectorArtwork(asset: 'assets/vector/waste_sorting_people.png', width: 66, height: 52, background: Color(0xff294a34)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _profilMetrik('Green Point', '${_penyimpanan!.poin}', Icons.spa_outlined)),
            _profilMetrikPembatas(),
            Expanded(child: _profilMetrik('Sampah dipindai', '$daftarPindai', Icons.center_focus_weak_rounded)),
            _profilMetrikPembatas(),
            Expanded(child: _profilMetrik('Catatan setor', '$daftarSetoran', Icons.recycling_rounded)),
          ],
        ),
      ],
    ),
  );

  Widget _profilMetrik(String title, String value, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: sage),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 20, height: 1)),
      const SizedBox(height: 4),
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: muted)),
    ],
  );

  Widget _profilMetrikPembatas() => Container(
    width: 1,
    height: 44,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: const Color(0xff52725b),
  );

  Widget _profilBagianJudul(String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(child: serif(title, size: 22)),
      const SizedBox(width: 8),
      Flexible(child: Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(fontSize: 8.5, color: muted))),
    ],
  );

  Widget _profilIdentitasKartu() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xff173b2c),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xff52725b)),
      boxShadow: const [BoxShadow(color: Color(0x0c173f30), blurRadius: 13, offset: Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(color: const Color(0xffe5efd4), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_outline_rounded, color: forestDeep, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(child: serif('Kenali dirimu', size: 19)),
            const Text('TERSINKRON SERVER', style: TextStyle(fontSize: 7, letterSpacing: 1.1, color: muted)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nama,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama panggilan',
            prefixIcon: Icon(Icons.badge_outlined, size: 19),
            isDense: true,
          ),
        ),
        if (_penyimpanan!.email.isNotEmpty) ...[
          const SizedBox(height: 9),
          _profilKontakBaris(Icons.mail_outline_rounded, _penyimpanan!.email),
        ],
        if (_penyimpanan!.phone.isNotEmpty) ...[
          const SizedBox(height: 7),
          _profilKontakBaris(Icons.phone_iphone_rounded, _penyimpanan!.phone),
        ],
        const SizedBox(height: 12),
        LeafButton(
          _menyimpan ? 'Menyimpan…' : 'Simpan perubahan',
          icon: _menyimpan ? Icons.hourglass_top_rounded : Icons.check_rounded,
          onTap: _menyimpan ? null : () => _tulis(() => _penyimpanan!.aturNama(_nama.text)),
        ),
      ],
    ),
  );

  Widget _profilKontakBaris(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: muted, size: 15),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ],
  );

  Widget _profilMenuGrup(List<_profilMenuData> items) => Container(
    decoration: BoxDecoration(
      color: const Color(0xff173b2c),
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: const Color(0xff52725b)),
    ),
    child: Column(
      children: [
        for (var indeks = 0; indeks < items.length; indeks++) ...[
          _profilMenuBaris(items[indeks]),
          if (indeks != items.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 61),
              child: Divider(height: 1, color: Color(0xff385c45)),
            ),
        ],
      ],
    ),
  );

  Widget _profilMenuBaris(_profilMenuData item) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(13)),
              child: Icon(item.icon, color: forestDeep, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(item.subtitle, style: const TextStyle(fontSize: 9, color: muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 19, color: muted),
          ],
        ),
      ),
    ),
  );

  Widget _bantuanTopik(String title, String body, IconData icon) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xff173b2c), borderRadius: BorderRadius.circular(19)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: sage, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [serif(title, size: 19), const SizedBox(height: 5), Text(body, style: const TextStyle(fontSize: 11, height: 1.55, color: muted))])),
      ],
    ),
  );

  Widget _profilPenutupNote() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(color: const Color(0xff173b2c), borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        const VectorArtwork(asset: 'assets/vector/reusable_lifestyle.png', width: 64, height: 54, background: Color(0xff294a34)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Setiap pilihan kecil ikut menjaga rumah kita bersama.', style: TextStyle(fontSize: 10, height: 1.4, color: forest))),
        const Icon(Icons.favorite_border_rounded, color: sage, size: 18),
      ],
    ),
  );

  void _tentang() => _halaman(
    'Tentang SHION',
    (_) => _gulir([
      const SizedBox(height: 25),
      const ShionLogo(size: 180, showWord: true),
      const SizedBox(height: 25),
      const Text(
        'SHION adalah pilar kesadaran dan kompas menuju kehidupan yang selaras. Ia menghubungkan kecerdasan teknologi dengan komitmen abadi manusia untuk tidak melupakan dan merawat Buminya.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.9, fontSize: 16),
      ),
      const SizedBox(height: 28),
      const VectorArtwork(asset: 'assets/vector/eco_education.png', width: 240, height: 170, background: Color(0xff173d2b)),
      const SizedBox(height: 14),
      const Text(
        'Ilustrasi SHION dirancang khusus dengan bentuk dan warna yang terinspirasi alam.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: muted, height: 1.5),
      ),
    ]),
  );
}

class _profilMenuData {
  const _profilMenuData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}
