part of '../main.dart';

extension _HistoryPage on _ShionHomeState {
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
                              : '${r['name'] ?? r['category']} • AI Detector',
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
    _titleRow('Riwayat Setoran'),
    ..._recordWidgets('deposits'),
    _titleRow('Aktivitas'),
    ..._recordWidgets('activities'),
  ]);
}
