// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/api_client.dart';

const ink = Color(0xffeff5e9);
const sage = Color(0xff9be76b);
const muted = Color(0xffbfd0bd);
const forest = Color(0xffdcebd6);
const forestDeep = Color(0xff06251a);
const surface = Color(0xff09271d);
const surfaceLow = Color(0xff12382a);
const surfaceHigh = Color(0xff1d4935);
const terracotta = Color(0xffe89a70);

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

class ShionLogo extends StatelessWidget {
  const ShionLogo({super.key, this.size = 42, this.showWord = false});
  final double size;
  final bool showWord;
  @override
  Widget build(BuildContext context) {
    final gambar = Image.asset(
      showWord ? 'assets/images/shion_wordmark.png' : 'assets/images/shion_symbol.png',
      fit: BoxFit.contain,
      semanticLabel: showWord ? 'Logo SHION' : 'Simbol SHION',
    );
    if (!showWord) return SizedBox(width: size, height: size, child: gambar);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xfffffbf1), borderRadius: BorderRadius.circular(size * .12)),
      child: gambar,
    );
  }
}

class ApiAvatar extends StatefulWidget {
  const ApiAvatar({super.key, required this.api, required this.path, required this.fallback, this.size = 42, this.segarkan = 0});
  final ApiClient api;
  final String path;
  final Widget fallback;
  final double size;
  final int segarkan;
  @override State<ApiAvatar> createState() => _apiAvatarKeadaan();
}
class _apiAvatarKeadaan extends State<ApiAvatar> {
  late Future<Uint8List> _gambar;
  @override void initState() { super.initState(); _muat(); }
  @override void didUpdateWidget(covariant ApiAvatar oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.path != widget.path || oldWidget.api != widget.api || oldWidget.segarkan != widget.segarkan) _muat(); }
  void _muat() => _gambar = widget.api.ambilByte(widget.path);
  @override Widget build(BuildContext context) => ClipOval(child: SizedBox(width: widget.size, height: widget.size, child: FutureBuilder<Uint8List>(future: _gambar, builder: (context, snapshot) => snapshot.hasData ? Image.memory(snapshot.data!, fit: BoxFit.cover) : widget.fallback)));
}

class VectorArtwork extends StatelessWidget {
  const VectorArtwork({super.key, required this.asset, required this.width, required this.height, this.background = const Color(0xff183d2d)});
  final String asset;
  final double width, height;
  final Color background;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [background, background.withValues(alpha: .70)])))),
        Positioned(right: -width * .12, top: -height * .18, child: Container(width: height * .72, height: height * .72, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xffc8ed9c).withValues(alpha: .24), width: 1.5)))),
        Positioned(left: width * .10, top: height * .14, child: Icon(Icons.auto_awesome, size: height * .09, color: const Color(0xffefc46a))),
        Positioned(left: width * .16, bottom: height * .14, child: Icon(Icons.eco_outlined, size: height * .13, color: const Color(0xffb6df83).withValues(alpha: .65))),
        Image.asset(asset, width: width * .90, height: height * .90, fit: BoxFit.contain),
      ]),
    ),
  );
}

class SortingIllustration extends StatelessWidget {
  const SortingIllustration({super.key, this.width = 140});
  final double width;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/sorting_scene.svg',
    width: width,
    fit: BoxFit.contain,
    semanticsLabel: 'Ilustrasi pemilahan sampah dan tanaman',
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
      color: surfaceHigh,
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
    this.color = const Color(0xdd173a2b),
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: color,
      border: Border.all(color: const Color(0xff87a58a).withValues(alpha: .25)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x5000140d),
          blurRadius: 14,
          offset: Offset(0, 5),
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xb008251b), Color(0x9208251b)],
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
  State<PhotoCarouselPanel> createState() => _fotoCarouselPanelKeadaan();
}

class _fotoCarouselPanelKeadaan extends State<PhotoCarouselPanel> {
  late final PageController _pengendali;
  Timer? _pengaturWaktu;
  int _indeks = 0;
  @override
  void initState() {
    super.initState();
    _pengendali = PageController();
    _pengaturWaktu = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.photos.length < 2) return;
      _pengendali.animateToPage(
        (_indeks + 1) % widget.photos.length,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOutCubic,
      );
    });
  }
  @override
  void dispose() {
    _pengaturWaktu?.cancel();
    _pengendali.dispose();
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
              controller: _pengendali,
              itemCount: widget.photos.length,
              onPageChanged: (value) => setState(() => _indeks = value),
              itemBuilder: (_, indeks) => RemotePhoto(widget.photos[indeks]),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xd608251b), Color(0x7808251b), Color(0x0808251b)],
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(21), child: widget.child),
          Positioned(
            right: 17,
            bottom: 15,
            child: Row(
              children: List.generate(widget.photos.length, (indeks) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _indeks == indeks ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: _indeks == indeks ? sage : Colors.white70,
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
  State<StoryCarousel> createState() => _ceritaCarouselKeadaan();
}

class _ceritaCarouselKeadaan extends State<StoryCarousel> {
  late final PageController _pengendali;
  Timer? _pengaturWaktu;
  int _indeks = 0;
  @override
  void initState() {
    super.initState();
    _pengendali = PageController(viewportFraction: .92);
    _pengaturWaktu = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.stories.length < 2) return;
      _pengendali.animateToPage((_indeks + 1) % widget.stories.length, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }
  @override
  void dispose() {
    _pengaturWaktu?.cancel();
    _pengendali.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 224,
    child: PageView.builder(
      controller: _pengendali,
      itemCount: widget.stories.length,
      onPageChanged: (value) => setState(() => _indeks = value),
      itemBuilder: (context, indeks) {
        final cerita = widget.stories[indeks];
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: forestDeep,
              child: InkWell(
                onTap: () => widget.onTap?.call(indeks),
                child: Stack(fit: StackFit.expand, children: [
                  RemotePhoto(cerita.photo),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0a061910), Color(0xe6092118)]))),
                  Positioned(left: 17, right: 17, bottom: 17, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${indeks + 1} / ${widget.stories.length}', style: const TextStyle(color: sage, fontSize: 10, letterSpacing: 1.2)),
                    const SizedBox(height: 7),
                    serif(cerita.title, size: 22, maxLines: 2, color: Colors.white),
                    const SizedBox(height: 5),
                    Text(cerita.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xfff1eee5), fontSize: 11)),
                  ])),
                  Positioned(
                    top: 14,
                    right: 15,
                    child: Row(
                      children: List.generate(
                        widget.stories.length,
                        (dot) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _indeks == dot ? 15 : 5,
                          height: 5,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _indeks == dot ? sage : Colors.white70,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
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
  State<AnimatedBrandSplash> createState() => _animatedMerekSplashKeadaan();
}

class _animatedMerekSplashKeadaan extends State<AnimatedBrandSplash>
    with TickerProviderStateMixin {
  late final AnimationController _denyut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);
  late final AnimationController _kemunculan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  )..forward();
  late final Animation<double> _tampilkan = CurvedAnimation(
    parent: _kemunculan,
    curve: const Interval(0, .72, curve: Curves.elasticOut),
  );
  late final Animation<double> _putar = CurvedAnimation(
    parent: _kemunculan,
    curve: const Interval(0, .82, curve: Curves.easeOutCubic),
  );
  bool _terlihat = true;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2850), () {
      if (mounted) setState(() => _terlihat = false);
    });
  }
  @override
  void dispose() {
    _denyut.dispose();
    _kemunculan.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 700),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: _terlihat ? Scaffold(
      key: const ValueKey('shion-splash'),
      backgroundColor: surface,
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: Listenable.merge([_denyut, _kemunculan]),
          builder: (_, child) => Opacity(
            opacity: _kemunculan.value.clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: _tampilkan.value * (1 + _denyut.value * .045),
              child: Transform.rotate(
                angle: (1 - _putar.value) * -.42,
                child: SizedBox(
                  width: 156,
                  height: 156,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _denyut.value * .35,
                        child: Container(
                          width: 142,
                          height: 142,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sage.withValues(alpha: .32),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sage.withValues(
                                  alpha: .08 + .12 * _denyut.value,
                                ),
                                blurRadius: 30 + 18 * _denyut.value,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: -_denyut.value * .55,
                        child: Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sage.withValues(alpha: .07),
                            border: Border.all(
                              color: sage.withValues(alpha: .20),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              sage.withValues(alpha: .23),
                              sage.withValues(alpha: .035),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(17),
                        child: child,
                      ),
                      for (var indeks = 0; indeks < 3; indeks++)
                        Transform.rotate(
                          angle: (_denyut.value * 2 * 3.14159) + indeks * 2.094,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 6 + indeks * 1.5,
                              height: 6 + indeks * 1.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              color: indeks == 1 ? forest : sage,
                                boxShadow: [
                                  BoxShadow(
                                    color: sage.withValues(alpha: .7),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child: const ShionLogo(size: 60),
        ),
        const SizedBox(height: 24),
        serif('SHION', size: 38),
        const SizedBox(height: 8),
        const Text('TECHNOLOGY IN HARMONY WITH NATURE', style: TextStyle(color: muted, fontSize: 9, letterSpacing: 2)),
        const SizedBox(height: 30),
        SizedBox(width: 84, child: LinearProgressIndicator(value: null, minHeight: 2, color: sage, backgroundColor: forest.withValues(alpha: .12), borderRadius: BorderRadius.circular(8))),
      ])),
    ) : widget.child,
  );
}

class LeafButton extends StatelessWidget {
  const LeafButton(this.label, {super.key, required this.onTap, this.icon = Icons.arrow_forward_rounded});
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final aktif = onTap != null;
    return Semantics(
      button: true, enabled: aktif,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: aktif ? const Color(0xff009d20) : const Color(0xff355441),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: aktif ? const Color(0xffdff7c6) : const Color(0xff4a6652)),
          boxShadow: aktif ? const [BoxShadow(color: Color(0x332c631e), blurRadius: 18, offset: Offset(0, 7))] : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: const Color(0x3366a743),
            child: Stack(children: [
              Positioned(left: -13, top: -24, child: IgnorePointer(child: Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x28ffffff), width: 2))))),
              const Positioned(left: 48, bottom: 7, child: IgnorePointer(child: Icon(Icons.eco_outlined, size: 18, color: Color(0x35ffffff)))),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
              child: Row(children: [
                Expanded(child: Text(label, textAlign: TextAlign.center,
                  style: TextStyle(color: aktif ? Colors.white : muted, fontSize: 13, fontWeight: FontWeight.w800))),
                const SizedBox(width: 10),
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: aktif ? const Color(0xff1c4b30) : const Color(0xff3c5e46), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 19, color: aktif ? const Color(0xffd4f1b9) : muted)),
              ]),
            ),]),
          ),
        ),
      ),
    );
  }
}

class ForestPage extends StatelessWidget {
  const ForestPage({
    super.key,
    required this.child,
    this.bottom,
  });
  final Widget child;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: surface,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: Image.asset(Photos.heroForest, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: surface))),
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xd908251b), Color(0xf208251b)])))),
            Positioned(
              top: -95,
              right: -105,
              child: IgnorePointer(
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sage.withValues(alpha: .10),
                  ),
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
