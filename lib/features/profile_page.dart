part of '../main.dart';

extension _ProfilePage on _ShionHomeState {
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
                  'Gunakan Scan untuk menyimpan foto dan kategori, Setor untuk mencatat rencana, serta Jejak Karbon untuk mencatat aktivitas.\n\nGambar aplikasi tersedia di assets. Foto scan dikirim ke AI Detector setelah persetujuan. Catatan disimpan lokal.\n\nMenghapus data aplikasi akan menghapus catatan lokal.',
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
}
