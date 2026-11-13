// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'forest.dart';

Future<void> bukaTautanWeb(BuildContext context, String? href) async {
  final alamat = Uri.tryParse(href ?? '');
  if (alamat == null || !['https', 'http'].contains(alamat.scheme) || alamat.host.isEmpty) return;
  try {
    if (!await launchUrl(alamat, mode: LaunchMode.externalApplication)) throw Exception();
  } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tautan belum bisa dibuka.'))); }
}
class RichAnswer extends StatelessWidget {
  const RichAnswer(this.data, {super.key});
  final String data;
  @override
  Widget build(BuildContext context) => SelectionArea(child: MarkdownBody(
    data: data,
    onTapLink: (_, href, __) => bukaTautanWeb(context, href),
    imageBuilder: (alamat, title, alt) => Text(alt ?? 'Gambar', style: const TextStyle(color: muted)),
    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(color: ink, height: 1.65, fontSize: 14),
      h1: const TextStyle(color: ink, fontSize: 23, height: 1.4, fontWeight: FontWeight.w700),
      h2: const TextStyle(color: ink, fontSize: 20, height: 1.4, fontWeight: FontWeight.w700),
      h3: const TextStyle(color: ink, fontSize: 17, height: 1.4, fontWeight: FontWeight.w700),
      a: const TextStyle(color: sage, decoration: TextDecoration.underline),
      listBullet: const TextStyle(color: sage, fontSize: 14),
      code: const TextStyle(color: sage, fontFamily: 'monospace', fontSize: 12),
      codeblockDecoration: BoxDecoration(color: forestDeep, borderRadius: BorderRadius.circular(12)),
      blockquoteDecoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(12)),
      tableBody: const TextStyle(color: ink, fontSize: 12),
      tableHead: const TextStyle(color: sage, fontWeight: FontWeight.bold),
    ),
  ));
}
String jawabanTerbaca(String source) {
  String prose(String text) => text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (m) => '${m[1]} (${m[2]})').replaceAll(RegExp(r'\*\*|__|`'), '').replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '').replaceAll(RegExp(r'^\s*[*-]\s+', multiLine: true), '• ');
  final keluaran = StringBuffer();
  var selisih = 0;
  for (final block in RegExp(r'```[^\n]*\n([\s\S]*?)```').allMatches(source)) {
    keluaran.write(prose(source.substring(selisih, block.start)));
    keluaran.write(block[1]);
    selisih = block.end;
  }
  keluaran.write(prose(source.substring(selisih)));
  return keluaran.toString();
}
Future<void> salinJawaban(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: jawabanTerbaca(text)));
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jawaban disalin.')));
}
