// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
part of '../main.dart';

extension _berandaHalaman on _shionHomeKeadaan {
  Widget _beranda() => _gulir([
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SELAMAT DATANG', style: TextStyle(
                color: muted, fontSize: 10, letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 5),
              serif(
                _penyimpanan!.name.isEmpty ? 'Halo, Sahabat Bumi' : 'Halo, ${_penyimpanan!.name}',
                size: 25, maxLines: 1,
              ),
            ],
          ),
        ),
        Material(
          color: const Color(0xff284a32),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _pilihTab(2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const BrandGlyph('leaf', size: 17),
                const SizedBox(width: 6),
                Text('${_penyimpanan!.poin} poin', style: const TextStyle(
                  color: forest, fontSize: 12, fontWeight: FontWeight.w700,
                )),
              ]),
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 18),
    PhotoCarouselPanel(
      photos: [Photos.heroForest, Photos.heroPlant, Photos.heroReuse],
      minHeight: 214,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: forestDeep.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('LANGKAH KECIL, DAMPAK NYATA',
                  style: TextStyle(color: forest, fontSize: 9, letterSpacing: 1,
                    fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              serif('Untuk Bumi,\nhari ini.', size: 29),
              const SizedBox(height: 5),
              const Text('Pilah satu benda. Mulai dari rumah.',
                style: TextStyle(fontSize: 12, height: 1.45)),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 19),
    Row(
      children: [
        Expanded(
          child: _fiturAksi(
            title: 'Pindai sampah',
            caption: 'Kenali jenisnya',
            icon: 'scan',
            color: forestDeep,
            foreground: const Color(0xffc8efa1),
            onTap: () => _pilihTab(1),
            large: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _fiturAksi(
            title: 'Catat setoran',
            caption: 'Simpan progresmu',
            icon: 'bag',
            color: const Color(0xff563a2b),
            foreground: const Color(0xffffdfbd),
            onTap: _setoran,
          ),
        ),
      ],
    ),
    const SizedBox(height: 11),
    Row(
      children: [
        Expanded(child: _kecilAksi(
          'Edukasi', 'book', () => _pilihTab(3),
          background: const Color(0xff1a3c2c),
        )),
        const SizedBox(width: 9),
        Expanded(child: _kecilAksi(
          'Bank sampah', 'pin', _daftarLokasi,
          background: const Color(0xff294535),
        )),
        const SizedBox(width: 9),
        Expanded(child: _kecilAksi(
          'Jejak karbon', 'carbon', _karbon,
          background: const Color(0xff49392f),
        )),
      ],
    ),
    const SizedBox(height: 13),
    Material(
      color: const Color(0xff153b2b),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: _daftarLokasi,
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          height: 106,
          child: Stack(children: [
            Positioned(right: 4, top: 5, bottom: 5, child: Image.asset(
              'assets/vector/community_waste_bank.png', width: 112,
              fit: BoxFit.contain,
            )),
            Positioned(right: 95, top: -24, child: Container(
              width: 92, height: 92,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x339be76b))),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('JELAJAHI SEKITARMU', style: TextStyle(color: sage, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  serif('Bank sampah terdekat', size: 20),
                  const SizedBox(height: 3),
                  const Text('Bank sampah & kantor kelurahan', style: TextStyle(color: muted, fontSize: 10)),
                ])),
                const SizedBox(width: 95),
                const Icon(Icons.arrow_forward_rounded, color: sage, size: 21),
              ]),
            ),
          ]),
        ),
      ),
    ),
    _judulBaris('Untuk Bumi, Hari Ini', action: 'Semua cerita', onTap: () => _pilihTab(3)),
    StoryCarousel(
      stories: [
        PhotoStory(photo: Photos.sorting, title: 'Pilah sampah dengan lebih bijak',
          subtitle: 'Daur ulang • Kebiasaan kecil yang berdampak'),
        PhotoStory(photo: Photos.dailyReuse, title: 'Pilih guna ulang untuk keseharian',
          subtitle: 'Gaya hidup • Kurangi barang sekali pakai'),
        PhotoStory(photo: Photos.community, title: 'Rawat ruang hijau bersama',
          subtitle: 'Lingkungan • Aksi nyata dari sekitar'),
        PhotoStory(photo: Photos.recycle, title: 'Kenali alur daur ulang',
          subtitle: 'Edukasi • Pastikan material diterima'),
      ],
      onTap: (_) => _pilihTab(3),
    ),
    _judulBaris('Kebiasaan yang membantu'),
    SizedBox(
      height: 122,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _tipsKartu('Bilas & keringkan', 'Sebelum menyimpan kemasan.', 'plastic', const Color(0xff1a3d2b)),
          _tipsKartu('Pisahkan material', 'Jaga kertas tetap kering.', 'paper', const Color(0xff48382c)),
          _tipsKartu('Bawa guna ulang', 'Kurangi kemasan sekali pakai.', 'recycle', const Color(0xff254638)),
        ],
      ),
    ),
    const SizedBox(height: 20),
    Glass(onTap: _papanPeringkat, child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xffc1e59e), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.leaderboard_outlined, color: forestDeep, size: 27)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        serif('Jejak komunitas', size: 22),
        const SizedBox(height: 4),
        const Text('Poin & setoran tertinggi', style: TextStyle(color: muted, fontSize: 11)),
      ])),
      const Icon(Icons.arrow_forward_rounded, color: sage, size: 22),
    ])),
    _judulBaris('Aktivitasmu'),
    Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: const BoxDecoration(color: Color(0xff244735), shape: BoxShape.circle),
          child: const Icon(Icons.eco_outlined, color: sage, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Catatan akunmu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('${_penyimpanan!.ambilDaftar('scans').length} scan  ·  ${_penyimpanan!.ambilDaftar('deposits').length} setoran',
            style: const TextStyle(color: muted, fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: muted, size: 14),
      ]),
    ),
    const SizedBox(height: 12),
  ]);

  Widget _fiturAksi({
    required String title,
    required String caption,
    required String icon,
    required Color color,
    required Color foreground,
    required VoidCallback onTap,
    bool large = false,
  }) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        height: large ? 158 : 142,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Stack(children: [
            if (large)
              Positioned(
                right: -17,
                top: -2,
                child: const VectorArtwork(
                  asset: 'assets/vector/ai_waste_scanner.png',
                  width: 130,
                  height: 125,
                  background: Color(0xff173d2b),
                ),
              )
            else
              Positioned(right: -17, top: -18, child: Icon(
                Icons.spa_outlined,
                size: 105, color: foreground.withValues(alpha: .07),
              )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BrandGlyph(icon, size: 29, color: foreground),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(caption, style: TextStyle(color: foreground.withValues(alpha: .75), fontSize: 10)),
                ]),
              ],
            ),
          ]),
        ),
      ),
    ),
  );

  Widget _kecilAksi(String label, String icon, VoidCallback onTap, {required Color background}) =>
    Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            BrandGlyph(icon, size: 22, color: icon == 'carbon' ? terracotta : sage),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );

  Widget _tipsKartu(String title, String subtitle, String icon, Color color) => Container(
    width: 220,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      BrandGlyph(icon, size: 29, color: icon == 'paper' ? terracotta : sage),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 10, height: 1.35)),
      ])),
    ]),
  );
}
