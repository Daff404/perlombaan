// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
part of '../main.dart';

extension _riwayatHalaman on _shionHomeKeadaan {
  List<Widget> _catatanWidget(String key) {
    final daftarBaris = _penyimpanan!.ambilDaftar(key);
    if (daftarBaris.isEmpty) {
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
    return daftarBaris
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
                              ? '${r['category']} • ${r['quantity'] ?? r['estimatedKg'] ?? 0} ${r['unit'] ?? 'kg'}'
                              : '${r['name'] ?? r['category']} • Hasil pemindaian',
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
                  if (key == 'scans' && r['hasPhoto'] == true)
                    IconButton(
                      icon: const Icon(Icons.photo_outlined, size: 20),
                      onPressed: () async {
                        try {
                          final byte = await _penyimpanan!.api.ambilByte('/scans/${Uri.encodeComponent(r['id'] as String)}/photo');
                          if (!mounted) return;
                          _halaman(
                            'Foto Tersimpan',
                            (_) => Padding(
                              padding: const EdgeInsets.all(22),
                              child: Image.memory(byte, fit: BoxFit.contain),
                            ),
                          );
                        } catch (_) {
                          _beriNotifikasi('Foto tidak dapat dibuka.');
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

  Widget _semuaRiwayat() => _gulir([
    _judulBaris('Pindai Sampah'),
    ..._catatanWidget('scans'),
    _judulBaris('Riwayat Setoran'),
    ..._catatanWidget('deposits'),
    _judulBaris('Aktivitas'),
    ..._catatanWidget('activities'),
  ]);
}
