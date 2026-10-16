import 'package:flutter/material.dart';
import 'forest.dart';

class ShionNavigation extends StatelessWidget {
  const ShionNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
    child: SizedBox(
      height: 105,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 79,
            decoration: BoxDecoration(
              color: const Color(0xf0193929),
              borderRadius: BorderRadius.circular(31),
              border: Border.all(color: const Color(0x507b9c72)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 22,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                item(0, 'home', 'Beranda'),
                item(2, 'leaf', 'Poin'),
                const Expanded(child: SizedBox()),
                item(3, 'book', 'Edukasi'),
                item(4, 'profile', 'Profil'),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: 'Scan',
              selected: selected == 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(1),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff173c26),
                      border: Border.all(
                        color: const Color(0xffa1eb68),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x555cbd45),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      size: 39,
                      color: Color(0xffd5edbc),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget item(int index, String glyph, String label) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () => onSelect(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected == index
                    ? const Color(0xff456b38)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: BrandGlyph(
                glyph,
                size: 25,
                color: selected == index ? const Color(0xffa1eb68) : muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected == index ? const Color(0xffa1eb68) : muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
