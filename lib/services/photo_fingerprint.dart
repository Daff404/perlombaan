import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

Map<String, String> fingerprint(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null)
    throw const FormatException(
      'Foto tidak dapat dibaca. Gunakan JPG, PNG, atau WebP.',
    );
  final small = img.copyResize(
    decoded,
    width: 9,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  var bits = BigInt.zero;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final a = small.getPixel(x, y);
      final b = small.getPixel(x + 1, y);
      final av = a.r * .299 + a.g * .587 + a.b * .114;
      final bv = b.r * .299 + b.g * .587 + b.b * .114;
      bits = (bits << 1) | (av > bv ? BigInt.one : BigInt.zero);
    }
  }
  return {
    'sha256': sha256.convert(bytes).toString(),
    'perceptual': bits.toRadixString(16).padLeft(16, '0'),
  };
}

String photoMime(Uint8List bytes) {
  if (bytes.length > 3 && bytes[0] == 0xff && bytes[1] == 0xd8)
    return 'image/jpeg';
  if (bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50)
    return 'image/png';
  if (bytes.length > 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP')
    return 'image/webp';
  throw const FormatException('Gunakan foto JPG, PNG, atau WebP.');
}
