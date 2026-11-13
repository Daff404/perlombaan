// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../ui/forest.dart';

String notificationTime(Object? input) {
  final tanggal = DateTime.tryParse('$input')?.toLocal();
  if (tanggal == null) return '';
  return '${tanggal.day}/${tanggal.month}/${tanggal.year} • ${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}';
}
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<NotificationsPage> createState() => _notifikasiHalamanKeadaan();
}
class _notifikasiHalamanKeadaan extends State<NotificationsPage> {
  String? _galat;
  bool _sibuk = false;
  @override
  void initState() { super.initState(); _segarkan(); }
  Future<void> _segarkan() async {
    try { await widget.store.segarkan(); if (mounted) setState(() => _galat = null); }
    catch (error) { if (mounted) setState(() => _galat = error.toString()); }
  }
  Future<void> _baca(List<String> ids) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    try {
      for (var selisih = 0; selisih < ids.length; selisih += 200) {
        await widget.store.tandaiNotifikasiDibaca(ids.skip(selisih).take(200).toList());
      }
      if (mounted) setState(() => _galat = null);
    } catch (error) { if (mounted) setState(() => _galat = error.toString()); }
    finally { if (mounted) setState(() => _sibuk = false); }
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final daftarBaris = widget.store.ambilDaftar('notifications');
      return RefreshIndicator(onRefresh: _segarkan, color: sage, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(22),
        children: [
          serif('Kabar untukmu', size: 31),
          const SizedBox(height: 8),
          const Text('Informasi terbaru dari pengelola SHION.', style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 16),
          if (widget.store.notifikasiBelumDibaca > 0) TextButton.icon(
            onPressed: _sibuk ? null : () => _baca(daftarBaris.where((n) => n['read'] != true).map((n) => n['id'] as String).toList()),
            icon: const Icon(Icons.done_all, size: 18), label: const Text('Tandai semua dibaca'),
          ),
          if (_galat != null) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_galat!, style: const TextStyle(color: terracotta))),
          if (daftarBaris.isEmpty) const Glass(child: Column(children: [
            Icon(Icons.notifications_none_rounded, color: sage, size: 45),
            SizedBox(height: 13),
            Text('Belum ada kabar baru.', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 7),
            Text('Pesan dari admin akan muncul di sini.', style: TextStyle(color: muted, fontSize: 12)),
          ])),
          for (final baris in daftarBaris) Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Glass(onTap: () async {
              if (baris['read'] != true) await _baca([baris['id'] as String]);
              if (!context.mounted) return;
              await showDialog<void>(context: context, builder: (context) => AlertDialog(
                title: Text('${baris['title']}'),
                content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (baris['gambar'] is String && (baris['gambar'] as String).isNotEmpty) ...[SizedBox(height: 180, width: double.infinity, child: RemotePhoto(baris['gambar'] as String)), const SizedBox(height: 14)],
                  Text('${baris['body']}', style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 15),
                  Text(notificationTime(baris['createdAt']), style: const TextStyle(color: muted, fontSize: 11)),
                ])),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
              ));
            }, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: baris['read'] == true ? surfaceHigh : const Color(0xffc7e6a6), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.campaign_outlined, color: baris['read'] == true ? sage : forestDeep)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${baris['title']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Text('${baris['body']}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 8),
                Text(notificationTime(baris['createdAt']), style: const TextStyle(color: muted, fontSize: 10)),
              ])),
              if (baris['read'] != true) const Padding(padding: EdgeInsets.only(left: 5, top: 3), child: Icon(Icons.circle, color: sage, size: 8)),
            ])),
          ),
        ],
      ));
    },
  );
}
