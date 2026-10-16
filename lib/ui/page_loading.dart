import 'dart:async';
import 'package:flutter/material.dart';

/// Short entry transition; futures owned by pages still report their actual state.
class PageLoading extends StatefulWidget {
  const PageLoading({super.key, required this.child});
  final Widget child;
  @override
  State<PageLoading> createState() => _PageLoadingState();
}

class _PageLoadingState extends State<PageLoading> {
  bool _ready = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 360), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.child : const PageSkeleton();
}

class PageSkeleton extends StatefulWidget {
  const PageSkeleton({super.key});
  @override
  State<PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<PageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget block(double h, {double? width}) => Container(
    height: h,
    width: width,
    decoration: BoxDecoration(
      color: const Color(0xffb7c8ba),
      borderRadius: BorderRadius.circular(18),
    ),
  );
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .15, end: .35).animate(_pulse),
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
        for (var i = 0; i < 3; i++) ...[
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
