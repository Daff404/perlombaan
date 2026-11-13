// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'dart:async';
import 'package:flutter/material.dart';
import 'forest.dart';

/// Short entry transition; futures owned by pages still report their actual state.
class PageLoading extends StatefulWidget {
  const PageLoading({super.key, required this.child});
  final Widget child;
  @override
  State<PageLoading> createState() => _halamanMemuatKeadaan();
}

class _halamanMemuatKeadaan extends State<PageLoading> {
  bool _siap = false;
  Timer? _pengaturWaktu;
  @override
  void initState() {
    super.initState();
    _pengaturWaktu = Timer(const Duration(milliseconds: 360), () {
      if (mounted) setState(() => _siap = true);
    });
  }

  @override
  void dispose() {
    _pengaturWaktu?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _siap ? widget.child : const PageSkeleton();
}

class PageSkeleton extends StatefulWidget {
  const PageSkeleton({super.key});
  @override
  State<PageSkeleton> createState() => _halamanSkeletonKeadaan();
}

class _halamanSkeletonKeadaan extends State<PageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _denyut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _denyut.dispose();
    super.dispose();
  }

  Widget block(double h, {double? width}) => Container(
    height: h,
    width: width,
    decoration: BoxDecoration(
      color: sage,
      borderRadius: BorderRadius.circular(18),
    ),
  );
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .15, end: .35).animate(_denyut),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            block(46, width: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(13, width: 130),
                  const SizedBox(height: 10),
                  block(10, width: 90),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        block(44),
        const SizedBox(height: 20),
        block(175),
        const SizedBox(height: 20),
        for (var indeks = 0; indeks < 3; indeks++) ...[
          Row(
            children: [
              Expanded(child: block(92)),
              const SizedBox(width: 12),
              Expanded(child: block(92)),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
    ),
  );
}
