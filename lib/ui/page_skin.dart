import 'package:flutter/material.dart';

class PageSkin extends StatelessWidget {
  const PageSkin({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0x00122d21), Color(0x00122d21)],
      [Color(0xff081810), Color(0xff142b20)],
      [Color(0xff354c27), Color(0xff10291d)],
      [Color(0xff3d4430), Color(0xff182d24)],
      [Color(0xff153a32), Color(0xff071b17)],
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palettes[index],
        ),
        borderRadius: BorderRadius.circular(index == 4 ? 40 : 24),
      ),
      child: child,
    );
  }
}
