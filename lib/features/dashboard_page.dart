part of '../main.dart';

extension _DashboardPage on _ShionHomeState {
  Widget _dashboard() => _scroll([
    TextField(
      decoration: const InputDecoration(
        hintText: 'Cari informasi, artikel...',
        prefixIcon: Icon(Icons.search, size: 20),
        isDense: true,
      ),
      onSubmitted: (value) => _refresh(() {
        _query = value;
        _tab = 3;
      }),
    ),
    const SizedBox(height: 17),
    PhotoCarouselPanel(
      photos: [Photos.heroForest, Photos.heroPlant, Photos.heroReuse],
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
      onTap: () => _selectTab(2),
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
      'Poin setoran dan scan • pilih reward favoritmu',
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
          () => _selectTab(1),
        ),
        _shortcut(Icons.shopping_bag_outlined, 'Setor Sampah', _deposit),
        _shortcut(
          Icons.local_activity_outlined,
          'Tukar Poin',
          () => _selectTab(2),
        ),
        _shortcut(Icons.eco_outlined, 'Jejak Karbon', _carbon),
        _shortcut(Icons.menu_book_outlined, 'Edukasi', () => _selectTab(3)),
        _shortcut(Icons.place_outlined, 'Bank Sampah', _locations),
      ],
    ),
    _titleRow(
      'Untuk Bumi, Hari Ini',
      action: 'Lihat semua',
      onTap: () => _selectTab(3),
    ),
    StoryCarousel(
      stories: [
        PhotoStory(
          photo: Photos.sorting,
          title: 'Pilah sampah dengan lebih bijak',
          subtitle: 'Daur ulang • Kebiasaan kecil yang berdampak',
        ),
        PhotoStory(
          photo: Photos.dailyReuse,
          title: 'Pilih guna ulang untuk keseharian',
          subtitle: 'Gaya hidup • Kurangi barang sekali pakai',
        ),
        PhotoStory(
          photo: Photos.community,
          title: 'Rawat ruang hijau bersama',
          subtitle: 'Lingkungan • Aksi nyata dari sekitar',
        ),
        PhotoStory(
          photo: Photos.recycle,
          title: 'Kenali alur daur ulang',
          subtitle: 'Edukasi • Pastikan material diterima',
        ),
      ],
      onTap: (_) => _selectTab(3),
    ),
    _titleRow('Perjalanan Hijaumu'),
    Glass(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${_store!.getList('scans').length}', 'Catatan scan'),
          _stat('${_store!.getList('deposits').length}', 'Setoran'),
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
}
