import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shion/services/photo_fingerprint.dart';
import 'package:shion/core/local_store.dart';

void main() {
  test(
    'resized copies have different exact hashes but similar perceptual hashes',
    () {
      final image = img.Image(width: 100, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          image.setPixelRgb(x, y, x * 2, y * 2, 50);
        }
      }
      final a = fingerprint(Uint8List.fromList(img.encodePng(image)));
      final b = fingerprint(
        Uint8List.fromList(
          img.encodePng(img.copyResize(image, width: 80, height: 80)),
        ),
      );
      expect(a['sha256'], isNot(b['sha256']));
      expect(
        LocalStore.similarHash(a['perceptual']!, b['perceptual']!),
        isTrue,
      );
    },
  );
  test('unreadable photo and unsupported MIME are rejected', () {
    expect(() => fingerprint(Uint8List(0)), throwsFormatException);
    expect(
      () => photoMime(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
