import 'package:flutter/material.dart';

class ScanSweep extends StatefulWidget {
  const ScanSweep({super.key});
  @override
  State<ScanSweep> createState() => _ScanSweepState();
}

class _ScanSweepState extends State<ScanSweep> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this,
    duration: const Duration(seconds: 3))..repeat(reverse: true);
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: controller,
    builder: (_, __) => Align(
      alignment: Alignment(0, -0.75 + 1.5 * controller.value),
      child: Container(height: 32, margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xffa5ed70), width: 2)),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x00a5ed70), Color(0x88a5ed70)]),
        ),
      ),
    ),
  ));
}
