import 'dart:ui' as ui;
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
