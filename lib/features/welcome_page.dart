part of '../main.dart';

extension _WelcomePage on _ShionHomeState {
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
                      onPressed: () => _refresh(() => _intro = 2),
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
                        _refresh(() => _intro++);
                        return;
                      }
                      if (_name.text.trim().isEmpty) {
                        _notify('Isi nama panggilan terlebih dahulu.');
                        return;
                      }
                      try {
                        await _store!.setName(_name.text);
                        await _preferences!.setBool('shion.welcomed', true);
                        if (mounted) _refresh(() => _intro = -1);
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
}
