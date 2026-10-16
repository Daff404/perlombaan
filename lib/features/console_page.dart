import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/system_log.dart';

class ConsolePage extends StatelessWidget {
  const ConsolePage({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff07100d),
    child: Column(
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'SHION SYSTEM',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xffb8ed92),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Salin log',
              onPressed: () => Clipboard.setData(
                ClipboardData(text: SystemLog.entries.value.join('\n')),
              ),
              icon: const Icon(Icons.copy, size: 18),
            ),
            IconButton(
              tooltip: 'Bersihkan',
              onPressed: () => SystemLog.entries.value = [],
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: SystemLog.entries,
            builder: (context, lines, _) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                SelectableText(
                  lines.isEmpty
                      ? '> Sistem siap. Belum ada log.'
                      : lines.join('\n\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.7,
                    color: Color(0xffb8ed92),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
