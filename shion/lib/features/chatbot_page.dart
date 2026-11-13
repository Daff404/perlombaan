// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../core/api_client.dart';
import '../ui/forest.dart';
import '../ui/rich_answer.dart';

class _obrolanPesan {
  const _obrolanPesan(this.text, this.isUser, this.time);
  final String text;
  final bool isUser;
  final DateTime time;
}

class ShionChatPage extends StatefulWidget {
  const ShionChatPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<ShionChatPage> createState() => _shionObrolanHalamanKeadaan();
}

class _shionObrolanHalamanKeadaan extends State<ShionChatPage> {
  static const _pertanyaanKumpulan = <List<String>>[
    [
      'Bagaimana memilah gelas plastik?',
      'Apa yang termasuk sampah B3?',
      'Tips mengurangi sampah sekali pakai',
      'Bagaimana mengolah sampah organik?',
    ],
    [
      'Apakah kertas basah bisa didaur ulang?',
      'Cara menyimpan botol sebelum disetor',
      'Apa yang bisa dibuat dari kardus bekas?',
      'Bagaimana mulai kompos di rumah?',
    ],
    [
      'Bagaimana memilah sampah elektronik?',
      'Tips membawa tas belanja guna ulang',
      'Bagaimana mengurangi sisa makanan?',
      'Apa beda sampah residu dan daur ulang?',
    ],
  ];

  final _pengendali = TextEditingController();
  final _gulirPengendali = ScrollController();
  final List<_obrolanPesan> _daftarPesan = [
    _obrolanPesan(
      'Halo! Aku SHION. Aku bisa bantu soal memilah sampah, daur ulang, dan kebiasaan ramah lingkungan. Mau tanya apa?',
      false,
      DateTime.now(),
    ),
  ];
  bool _mengirim = false;
  int _saranKumpulan = 0;
  String? _gagalInstruksi, _gagalPermintaanId;
  String? _galat;
  List<String> get _daftarSaran {
    final topik = _daftarPesan.last.text.toLowerCase();
    if (topik.contains('b3') || topik.contains('baterai')) return ['Di mana saya bisa menyerahkan baterai bekas?', 'Bagaimana menyimpan limbah B3 sementara?', 'Apa yang harus dipisahkan dari sampah biasa?'];
    if (topik.contains('plastik')) return ['Apakah kemasan ini harus dicuci?', 'Bagaimana mengenali jenis plastik?', 'Apa alternatif kemasan sekali pakai?'];
    if (topik.contains('kompos') || topik.contains('organik')) return ['Apa saja bahan kompos yang cocok?', 'Bagaimana mengatasi kompos berbau?', 'Berapa lama proses kompos?'];
    return _pertanyaanKumpulan[_saranKumpulan];
  }

  @override
  void initState() {
    super.initState();
    final tersimpan = widget.store.ambilDaftar('messages');
    if (tersimpan.isNotEmpty) {
      _daftarPesan.clear();
      _daftarPesan.addAll(tersimpan.map((m) => _obrolanPesan(m['text'] as String, m['isUser'] == true, DateTime.parse(m['createdAt'] as String).toLocal())));
    }
    _gulirKeTerbaru();
  }

  @override
  void dispose() {
    _pengendali.dispose();
    _gulirPengendali.dispose();
    super.dispose();
  }

  String _waktu(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  void _gulirKeTerbaru() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gulirPengendali.hasClients) {
        _gulirPengendali.animateTo(
          _gulirPengendali.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _kirim([String? suggested, bool retry = false]) async {
    if (_mengirim) return;
    final mintaIzin = (retry ? _gagalInstruksi ?? '' : suggested ?? _pengendali.text).trim();
    final idPermintaan = retry ? _gagalPermintaanId! : ApiClient.buatIdPermintaan();
    if (mintaIzin.isEmpty) return;
    _pengendali.clear();
    setState(() {
      if (!retry) _daftarPesan.add(_obrolanPesan(mintaIzin, true, DateTime.now()));
      _galat = null;
      _mengirim = true;
    });
    _gulirKeTerbaru();
    try {
      final jawaban = await widget.store.kirimPesanAi(mintaIzin, idPermintaan);
      if (!mounted) return;
      setState(() {
        _daftarPesan.add(_obrolanPesan(jawaban, false, DateTime.now()));
        _gagalInstruksi = null; _gagalPermintaanId = null;
        _saranKumpulan = (_saranKumpulan + 1) % _pertanyaanKumpulan.length;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _galat = error.toString(); _gagalInstruksi = mintaIzin; _gagalPermintaanId = idPermintaan; });
    } finally {
      if (mounted) {
        setState(() => _mengirim = false);
        _gulirKeTerbaru();
      }
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(color: surface, child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _gulirPengendali,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _daftarPesan.length + (_mengirim ? 1 : 0),
              itemBuilder: (context, index) {
                if (_mengirim && index == _daftarPesan.length) {
                  return const _mengetikGelembung();
                }
                final pesan = _daftarPesan[index];
                return _pesanGelembung(pesan: pesan, time: _waktu(pesan.time), onFollowUp: () { _pengendali.text = 'Jelaskan lebih lanjut tentang: ${pesan.text.length > 160 ? pesan.text.substring(0, 160) : pesan.text}'; });
              },
            ),
          ),
          if (_galat != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Column(children: [Text(_galat!, style: const TextStyle(color: terracotta)), TextButton.icon(onPressed: _mengirim ? null : () => _kirim(null, true), icon: const Icon(Icons.refresh), label: const Text('Coba kirim lagi'))])),
          if (!_mengirim)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _daftarSaran.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(_daftarSaran[index], style: const TextStyle(fontSize: 11)),
                  backgroundColor: surfaceLow,
                  side: const BorderSide(color: Color(0xff52725b)),
                  onPressed: () => _kirim(_daftarSaran[index]),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pengendali,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirim(),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan…',
                        filled: true,
                        fillColor: surfaceLow,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: sage,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Kirim pesan',
                      onPressed: _mengirim ? null : () => _kirim(),
                      icon: Icon(_mengirim ? Icons.hourglass_top_rounded : Icons.send_rounded, color: forestDeep),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ));
}

class _pesanGelembung extends StatelessWidget {
  const _pesanGelembung({required this.pesan, required this.time, required this.onFollowUp});
  final _obrolanPesan pesan;
  final String time;
  final VoidCallback onFollowUp;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) => Align(
    alignment: pesan.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      width: pesan.isUser ? null : constraints.maxWidth,
      constraints: BoxConstraints(maxWidth: pesan.isUser ? constraints.maxWidth * .86 : constraints.maxWidth),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(pesan.isUser ? 15 : 3),
      decoration: pesan.isUser ? BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!pesan.isUser) const Padding(padding: EdgeInsets.only(bottom: 12), child: Row(children: [Icon(Icons.eco_outlined, color: sage, size: 19), SizedBox(width: 8), Text('SHION', style: TextStyle(color: sage, fontSize: 11, fontWeight: FontWeight.w700))])),
        if (pesan.isUser) SelectableText(pesan.text, style: const TextStyle(color: ink, height: 1.6, fontSize: 14)) else RichAnswer(pesan.text),
        const SizedBox(height: 7),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (!pesan.isUser) ...[
            IconButton(tooltip: 'Salin jawaban', visualDensity: VisualDensity.compact, onPressed: () => salinJawaban(context, pesan.text), icon: const Icon(Icons.copy_outlined, color: muted, size: 17)),
            IconButton(tooltip: 'Tanyakan lebih lanjut', visualDensity: VisualDensity.compact, onPressed: onFollowUp, icon: const Icon(Icons.add_comment_outlined, color: muted, size: 17)),
          ],
          Text(time, style: const TextStyle(color: muted, fontSize: 10)),
        ]),
      ]),
    ),
  ));
}

class _mengetikGelembung extends StatelessWidget {
  const _mengetikGelembung();
  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 7),
          child: Chip(
            avatar: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: sage)),
            label: Text('SHION sedang mengetik…', style: TextStyle(color: muted, fontSize: 11)),
            backgroundColor: surfaceLow,
            side: BorderSide(color: Color(0xff52725b)),
          ),
        ),
      );
}
