// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';

class ShionNavigation extends StatelessWidget {
  const ShionNavigation({super.key, required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
    child: SizedBox(
      height: 99,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xff082b1e).withValues(alpha: .98),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xff83aa72).withValues(alpha: .42)),
              boxShadow: const [BoxShadow(color: Color(0x5000140d), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Row(children: [
              item(0, Icons.home_outlined, 'Beranda'),
              item(2, Icons.eco_outlined, 'Poin'),
              const Expanded(child: SizedBox()),
              item(3, Icons.menu_book_outlined, 'Edukasi'),
              item(4, Icons.person_outline_rounded, 'Profil'),
            ]),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true, label: 'Pindai sampah', selected: selected == 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(1),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 82, height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff0b3423),
                      border: Border.all(color: const Color(0xffa5ed70), width: 4),
                      boxShadow: const [BoxShadow(color: Color(0x669be76b), blurRadius: 19, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.document_scanner_outlined, size: 35, color: Color(0xffc8f1a1)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget item(int index, IconData icon, String label) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () => onSelect(index),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8, left: 2, right: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected == index ? const Color(0xff315c38) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 23, color: selected == index ? const Color(0xffa6eb76) : const Color(0xffbfd1bd)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, style: TextStyle(fontSize: 10, color: selected == index ? const Color(0xffa6eb76) : const Color(0xffbfd1bd))),
        ]),
      ),
    ),
  );
}
