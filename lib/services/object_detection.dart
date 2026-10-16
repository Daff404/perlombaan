import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../core/system_log.dart';

class DetectionFrame {
  const DetectionFrame(this.size, this.boxes);
  final Size size;
  final List<Rect> boxes;
}

/// Native ML Kit runs on Android; image bytes remain on the device.
class LiveObjectDetection {
  static const channel = MethodChannel('id.shion.app/object_detection');
  bool _busy = false, _closed = false;
  int _last = 0;
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<DetectionFrame?> detect(
    CameraImage frame,
    CameraController camera,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!supported || _busy || _closed || now - _last < 300) return null;
    _busy = true;
    _last = now;
    try {
      final bytes = nv21(frame);
      final orientation = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      }[camera.value.deviceOrientation]!;
      final sensor = camera.description.sensorOrientation;
      final rotation =
          camera.description.lensDirection == CameraLensDirection.front
          ? (sensor + orientation) % 360
          : (sensor - orientation + 360) % 360;
      final data = await channel.invokeMapMethod<String, dynamic>('detect', {
        'bytes': bytes,
        'width': frame.width,
        'height': frame.height,
        'rotation': rotation,
      });
      if (_closed || data == null) return null;
      return DetectionFrame(
        Size(
          (data['width'] as num).toDouble(),
          (data['height'] as num).toDouble(),
        ),
        (data['boxes'] as List).map((x) {
          final a = (x as List).cast<num>();
          return Rect.fromLTRB(
            a[0].toDouble(),
            a[1].toDouble(),
            a[2].toDouble(),
            a[3].toDouble(),
          );
        }).toList(),
      );
    } catch (e) {
      // Throttle error reporting as well as image processing.
      if (now - _lastError > 10000) {
        _lastError = now;
        SystemLog.add('object-detection', e);
      }
      return null;
    } finally {
      _busy = false;
    }
  }

  int _lastError = 0;
  void close() {
    _closed = true;
  }

  static Uint8List nv21(CameraImage image) {
    final width = image.width, height = image.height;
    if (image.planes.length == 1 && image.format.group == ImageFormatGroup.nv21)
      return image.planes.first.bytes;
    if (image.planes.length != 3)
      throw StateError('Expected Android YUV420 frame.');
    final out = Uint8List(width * height * 3 ~/ 2);
    final y = image.planes[0], u = image.planes[1], v = image.planes[2];
    var n = 0;
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        out[n++] = y.bytes[row * y.bytesPerRow + col * (y.bytesPerPixel ?? 1)];
      }
    }
    for (var row = 0; row < height ~/ 2; row++) {
      for (var col = 0; col < width ~/ 2; col++) {
        out[n++] = v.bytes[row * v.bytesPerRow + col * (v.bytesPerPixel ?? 1)];
        out[n++] = u.bytes[row * u.bytesPerRow + col * (u.bytesPerPixel ?? 1)];
      }
    }
    return out;
  }
}

class DetectionOverlay extends CustomPainter {
  DetectionOverlay(this.frame, {this.mirror = false});
  final DetectionFrame frame;
  final bool mirror;
  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.contain, frame.size, size);
    final target = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final sx = target.width / frame.size.width,
        sy = target.height / frame.size.height;
    final paint = Paint()
      ..color = const Color(0xffa1eb68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var i = 0; i < frame.boxes.length; i++) {
      final b = frame.boxes[i];
      final left = mirror ? frame.size.width - b.right : b.left;
      final rect = Rect.fromLTWH(
        target.left + left * sx,
        target.top + b.top * sy,
        b.width * sx,
        b.height * sy,
      ).intersect(target);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
      final label = TextPainter(
        text: TextSpan(
          text: 'Objek ${i + 1}',
          style: const TextStyle(
            color: Color(0xffa1eb68),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(rect.left + 4, (rect.top - 18).clamp(0, size.height).toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlay old) =>
      old.frame != frame || old.mirror != mirror;
}
