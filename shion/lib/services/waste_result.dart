// ==== [ IDRUS - FRONTEND ] ==== //
class AiException implements Exception {
  const AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WasteResult {
  const WasteResult({
    required this.isWaste,
    required this.name,
    required this.category,
    required this.material,
    required this.recyclable,
    required this.steps,
    required this.warning,
    required this.confidence,
  });
  final bool isWaste, recyclable;
  final String name, category, material, warning;
  final List<String> daftarLangkah;
  final double confidence;
  static const categories = [
    'Plastik',
    'Kertas',
    'Organik',
    'Logam',
    'Kaca',
    'Elektronik',
    'B3',
    'Residu',
    'Tidak jelas',
  ];
  factory WasteResult.dariJson(Map<String, dynamic> j) {
    if (j['isWaste'] is! bool ||
        j['recyclable'] is! bool ||
        j['name'] is! String ||
        j['material'] is! String ||
        j['warning'] is! String ||
        !categories.contains(j['category']) ||
        j['steps'] is! List ||
        j['confidence'] is! num) {
      throw const AiException(
        'Hasil AI tidak lengkap. Ambil foto yang lebih jelas lalu coba lagi.',
      );
    }
    final daftarLangkah = (j['steps'] as List)
        .whereType<String>()
        .where((x) => x.trim().isNotEmpty)
        .take(6)
        .toList();
    if (daftarLangkah.isEmpty || (j['name'] as String).trim().isEmpty)
      throw const AiException('AI belum memberikan panduan yang valid.');
    return WasteResult(
      isWaste: j['isWaste'] as bool,
      name: j['name'] as String,
      category: j['category'] as String,
      material: j['material'] as String,
      recyclable: j['recyclable'] as bool,
      steps: daftarLangkah,
      warning: j['warning'] as String,
      confidence: (j['confidence'] as num).toDouble().clamp(0, 1).toDouble(),
    );
  }
  Map<String, dynamic> keJson() => {
    'isWaste': isWaste,
    'name': name,
    'category': category,
    'material': material,
    'recyclable': recyclable,
    'steps': daftarLangkah,
    'warning': warning,
    'confidence': confidence,
  };
}

