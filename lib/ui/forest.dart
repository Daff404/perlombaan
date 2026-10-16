import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const ink = Color(0xffeaf0df);
const sage = Color(0xffc5dba8);
const muted = Color(0xffb8c8b9);
const forest = Color(0xff0d281f);

// Original SHION artwork bundled locally. See ASSETS.md.
class Photos {
  static const leaves = 'assets/images/forest.png';
  static const detail = 'assets/images/forest.png';
  static const plant = 'assets/images/recycling.png';
  static const recycle = 'assets/images/recycling.png';
  static const bus = 'assets/images/transport.png';
  static const organic = 'assets/images/organic.png';
  static const reuse = 'assets/images/reuse.png';
  static const heroForest = 'assets/images/hero_forest_morning.jpg';
  static const heroPlant = 'assets/images/hero_planting_seedling.jpg';
  static const heroReuse = 'assets/images/hero_green_path.jpg';
  static const sorting = 'assets/images/earth_sorting_recycling.jpg';
  static const dailyReuse = 'assets/images/earth_reusable_daily.jpg';
  static const community = 'assets/images/earth_community_care.jpg';
}

class BrandGlyph extends StatelessWidget {
  const BrandGlyph(this.name, {super.key, this.size = 30, this.color = sage});
  final String name;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    semanticsLabel: name,
  );
}

Text metric(String text, {double size = 36}) => Text(
  text,
  style: TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    color: ink,
    height: 1.15,
  ),
);

Text serif(
  String text, {
  double size = 26,
  Color color = ink,
  TextAlign? align,
  int? maxLines,
}) => Text(
  text,
  textAlign: align,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: 'Cormorant',
    fontWeight: FontWeight.w600,
    fontFamilyFallback: const ['Noto Serif', 'serif'],
    fontSize: size,
    height: 1.18,
    color: color,
  ),
);

class RemotePhoto extends StatelessWidget {
  const RemotePhoto(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.asset(
    url,
    fit: fit,
    cacheWidth: 1100,
    errorBuilder: (_, error, stack) => const ColoredBox(
      color: forest,
      child: Center(child: BrandGlyph('leaf', size: 50)),
    ),
  );
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x35d5e4cd)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x805e7b60), Color(0x98253f32)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class PhotoPanel extends StatelessWidget {
  const PhotoPanel({
    super.key,
    required this.photo,
    required this.child,
    this.minHeight = 170,
  });
  final String photo;
  final Widget child;
  final double minHeight;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Stack(
        children: [
          Positioned.fill(child: RemotePhoto(photo)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xf0254230), Color(0x20254230)],
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    ),
  );
}

class PhotoCarouselPanel extends StatefulWidget {
  const PhotoCarouselPanel({
    super.key,
    required this.photos,
    required this.child,
    this.minHeight = 190,
  });
  final List<String> photos;
  final Widget child;
  final double minHeight;
  @override
  State<PhotoCarouselPanel> createState() => _PhotoCarouselPanelState();
}

class _PhotoCarouselPanelState extends State<PhotoCarouselPanel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.photos.length < 2) return;
      _controller.animateToPage(
        (_index + 1) % widget.photos.length,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOutCubic,
      );
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, i) => RemotePhoto(widget.photos[i]),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xe00a2419), Color(0x9a102b20), Color(0x20254230)],
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(21), child: widget.child),
          Positioned(
            right: 17,
            bottom: 15,
            child: Row(
              children: List.generate(widget.photos.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _index == i ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: _index == i ? sage : Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                ),
              )),
            ),
          ),
        ],
      ),
    ),
  );
}

class PhotoStory {
  const PhotoStory({required this.photo, required this.title, required this.subtitle});
  final String photo, title, subtitle;
}

class StoryCarousel extends StatefulWidget {
  const StoryCarousel({super.key, required this.stories, this.onTap});
  final List<PhotoStory> stories;
  final ValueChanged<int>? onTap;
  @override
  State<StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<StoryCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .92);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.stories.length < 2) return;
      _controller.animateToPage((_index + 1) % widget.stories.length, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 224,
    child: PageView.builder(
      controller: _controller,
      itemCount: widget.stories.length,
      onPageChanged: (value) => setState(() => _index = value),
      itemBuilder: (context, i) {
        final story = widget.stories[i];
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: forest,
              child: InkWell(
                onTap: () => widget.onTap?.call(i),
                child: Stack(fit: StackFit.expand, children: [
                  RemotePhoto(story.photo),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0a061910), Color(0xe6092118)]))),
                  Positioned(left: 17, right: 17, bottom: 17, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1} / ${widget.stories.length}', style: const TextStyle(color: sage, fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 7),
                    serif(story.title, size: 22, maxLines: 2),
                    const SizedBox(height: 5),
                    Text(story.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11)),
                  ])),
                  Positioned(top: 14, right: 15, child: Row(children: List.generate(widget.stories.length, (dot) => AnimatedContainer(duration: const Duration(milliseconds: 250), width: _index == dot ? 15 : 5, height: 5, margin: const EdgeInsets.only(left: 4), decoration: BoxDecoration(color: _index == dot ? sage : Colors.white70, borderRadius: BorderRadius.circular(8))))),
                ]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class AnimatedBrandSplash extends StatefulWidget {
  const AnimatedBrandSplash({super.key, required this.child});
  final Widget child;
  @override
  State<AnimatedBrandSplash> createState() => _AnimatedBrandSplashState();
}

class _AnimatedBrandSplashState extends State<AnimatedBrandSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..repeat(reverse: true);
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1750), () {
      if (mounted) setState(() => _visible = false);
    });
  }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 500),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: _visible ? Scaffold(
      key: const ValueKey('shion-splash'),
      backgroundColor: forest,
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(animation: _pulse, builder: (_, child) => Transform.scale(scale: 1 + _pulse.value * .07, child: Container(width: 126, height: 126, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x1cc5dba8), border: Border.all(color: sage.withValues(alpha: .45), width: 1.2), boxShadow: [BoxShadow(color: sage.withValues(alpha: .12 + .14 * _pulse.value), blurRadius: 28 + 18 * _pulse.value, spreadRadius: 2)]), padding: const EdgeInsets.all(28), child: child)), child: const BrandGlyph('brand_mark', size: 70)),
        const SizedBox(height: 24),
        serif('SHION', size: 38),
        const SizedBox(height: 8),
        const Text('TECHNOLOGY IN HARMONY WITH NATURE', style: TextStyle(color: muted, fontSize: 9, letterSpacing: 2)),
        const SizedBox(height: 30),
        SizedBox(width: 84, child: LinearProgressIndicator(value: null, minHeight: 2, color: sage, backgroundColor: Colors.white12, borderRadius: BorderRadius.circular(8))),
      ])),
    ) : widget.child,
  );
}

class LeafButton extends StatelessWidget {
  const LeafButton(
    this.label, {
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: sage,
        foregroundColor: forest,
        disabledBackgroundColor: const Color(0xff51674c),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(icon, size: 21),
        ],
      ),
    ),
  );
}

class ForestPage extends StatelessWidget {
  const ForestPage({
    super.key,
    required this.child,
    this.bottom,
    this.crisp = false,
  });
  final Widget child;
  final Widget? bottom;
  final bool crisp;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff213b30),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: crisp ? 0 : 9,
                sigmaY: crisp ? 0 : 9,
              ),
              child: RemotePhoto(crisp ? Photos.leaves : Photos.detail),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: crisp
                      ? const [
                          Color(0x3d061910),
                          Color(0x84041911),
                          Color(0xe609241a),
                        ]
                      : const [
                          Color(0x8023432f),
                          Color(0xb0092119),
                          Color(0xdf0b261c),
                        ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: child),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
