// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../core/api_client.dart';
import '../core/api_store.dart';
import '../ui/forest.dart';

List<Map<String, dynamic>> daftarBaris(dynamic value) => (value as List? ?? []).map((v) => Map<String, dynamic>.from(v as Map)).toList();
void pemberitahuanKomunitas(BuildContext context, Object value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value')));

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<CommunityPage> createState() => _komunitasHalamanKeadaan();
}
class _komunitasHalamanKeadaan extends State<CommunityPage> {
  final pencarian = TextEditingController();
  List<Map<String, dynamic>> daftarGrup = [], daftarUndangan = [];
  String? galat;
  bool sibuk = false;
  int generasi = 0;
  Timer? jeda;
  @override
  void initState() { super.initState(); unawaited(muat()); }
  @override
  void dispose() { jeda?.cancel(); pencarian.dispose(); super.dispose(); }
  Future<void> muat() async {
    final versi = ++generasi;
    setState(() { sibuk = true; galat = null; });
    try { final data = await widget.store.api.permintaan('GET', '/groups?q=${Uri.encodeQueryComponent(pencarian.text.trim())}'); if (mounted && versi == generasi) setState(() { daftarGrup = daftarBaris(data['groups']); daftarUndangan = daftarBaris(data['invites']); }); }
    catch (e) { if (mounted && versi == generasi) setState(() => galat = '$e'); }
    finally { if (mounted && versi == generasi) setState(() => sibuk = false); }
  }
  Future<void> lakukan(String path, Map<String, dynamic> body) async {
    if (sibuk) return;
    setState(() => sibuk = true);
    try { await widget.store.api.permintaan('POST', path, body: body); if (mounted) await muat(); }
    catch (e) { if (mounted) pemberitahuanKomunitas(context, e); }
    finally { if (mounted) setState(() => sibuk = false); }
  }
  Future<void> buat() async {
    final nama = TextEditingController(), desc = TextEditingController();
    bool approval = true;
    final value = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
      title: const Text('Komunitas baru'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nama, maxLength: 70, decoration: const InputDecoration(labelText: 'Nama grup')),
        const SizedBox(height: 12), TextField(controller: desc, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'Tentang komunitas')),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Persetujuan admin untuk bergabung'), value: approval, onChanged: (v) => update(() => approval = v)),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), FilledButton(onPressed: () { if (nama.text.trim().length >= 3) Navigator.pop(ctx, {'name': nama.text.trim(), 'description': desc.text.trim(), 'approvalRequired': approval, 'requestId': ApiClient.buatIdPermintaan()}); }, child: const Text('Buat grup'))],
    )));
    // Controllers are disposed after the dialog's exit animation.
    Future<void>.delayed(const Duration(milliseconds: 350), () { nama.dispose(); desc.dispose(); });
    if (value == null || !mounted) return;
    await lakukan('/groups', value);
  }
  Future<void> buka(Map<String, dynamic> g) async {
    if (g['myRole'] == null) {
      if (sibuk || g['pending'] == true) return;
      final disetujui = g['approvalRequired'] == true;
      final gabung = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Gabung komunitas'),
        content: Text('Kamu akan bergabung ke grup ini: ${g['nama']}. ${disetujui ? 'Admin akan meninjau permintaanmu.' : 'Kamu bisa langsung mulai mengobrol.'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(disetujui ? 'Minta Permintaan Bergabung' : 'Bergabung Sekarang'))],
      ));
      if (gabung != true || !mounted) return;
      await lakukan('/groups/${g['id']}/join', {});
      return;
    }
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => GroupChatPage(store: widget.store, groupId: g['id'] as String)));
    if (mounted) await muat();
  }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: muat, child: ListView(padding: const EdgeInsets.all(22), children: [
    const Text('Tumbuh bersama.', style: TextStyle(fontSize: 32, fontFamily: 'Cormorant')),
    const Text('Temukan teman untuk merawat bumi.', style: TextStyle(color: muted)),
    const SizedBox(height: 18), LeafButton('Buat komunitas', onTap: sibuk ? null : buat, icon: Icons.group_add_outlined),
    const SizedBox(height: 18), TextField(controller: pencarian, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama grup…'), onChanged: (_) { jeda?.cancel(); jeda = Timer(const Duration(milliseconds: 400), muat); }),
    if (sibuk) const LinearProgressIndicator(),
    if (galat != null) TextButton(onPressed: muat, child: Text('$galat • Coba lagi')),
    if (daftarUndangan.isNotEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Undangan untukmu', style: TextStyle(fontWeight: FontWeight.bold))),
    ...daftarUndangan.map((i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${i['groupName']}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('Diundang oleh ${i['inviter']}'),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(tooltip: 'Tolak undangan', onPressed: sibuk ? null : () => lakukan('/group-invites/${i['id']}/respond', {'accept': false}), icon: const Icon(Icons.close, color: Colors.orangeAccent)), IconButton(tooltip: 'Terima undangan', onPressed: sibuk ? null : () => lakukan('/group-invites/${i['id']}/respond', {'accept': true}), icon: const Icon(Icons.check, color: sage))]),
    ])))),
    const SizedBox(height: 18),
    ...daftarGrup.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Glass(child: ListTile(contentPadding: EdgeInsets.zero,
      leading: ApiAvatar(api: widget.store.api, path: '/groups/${g['id']}/avatar', refresh: g['hasPhoto'] == true ? 1 : 0, size: 46, fallback: CircleAvatar(backgroundColor: const Color(0xff009d20), child: Text((g['name'] as String).substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)))),
      title: Text('${g['nama']}'), subtitle: Text('${g['memberCount']} anggota • ${g['myRole'] ?? (g['pending'] == true ? 'Menunggu persetujuan' : g['approvalRequired'] == true ? 'Minta bergabung' : 'Gabung')}'),
      trailing: const Icon(Icons.chevron_right), onTap: () => buka(g),
    )))),
    if (!sibuk && daftarGrup.isEmpty) const Glass(child: Text('Belum ada grup yang cocok. Buat komunitas pertamamu.')),
  ]));
}

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.store, required this.groupId});
  final ApiStore store;
  final String groupId;
  @override
  State<GroupChatPage> createState() => _grupObrolanHalamanKeadaan();
}
class _grupObrolanHalamanKeadaan extends State<GroupChatPage> with WidgetsBindingObserver {
  final masukan = TextEditingController();
  final gulir = ScrollController();
  Map<String, dynamic>? data;
  List<Map<String, dynamic>> pesanLama = [];
  Timer? pengaturPemeriksaan;
  bool memuat = false, mengirim = false, aktif = true;
  String? galat, idTertunda, teksTertunda;
  int revisiAvatar = 0;
  Map<String, dynamic>? membalasPesan;
  Uint8List? mediaTertunda;
  String? jenisTertunda;
  String get jalurDasar => '/groups/${widget.groupId}';
  bool get adalahAdmin => data?['group']?['myRole'] == 'admin';
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); unawaited(muat()); pengaturPemeriksaan = Timer.periodic(const Duration(seconds: 3), (_) { if (aktif) unawaited(muat()); }); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { aktif = state == AppLifecycleState.resumed; if (aktif) unawaited(muat()); }
  @override
  void dispose() { pengaturPemeriksaan?.cancel(); WidgetsBinding.instance.removeObserver(this); masukan.dispose(); gulir.dispose(); super.dispose(); }
  Future<void> muat() async {
    if (memuat) return;
    memuat = true;
    try { final baru = await widget.store.api.permintaan('GET', jalurDasar); if (mounted) setState(() { data = baru; galat = null; }); }
    on ApiException catch (e) { if (mounted) { setState(() => galat = '$e'); if (e.statusCode == 403 || e.statusCode == 404) { pengaturPemeriksaan?.cancel(); data = null; } } }
    catch (e) { if (mounted) setState(() => galat = '$e'); }
    finally { memuat = false; }
  }
  Future<void> lakukan(String path, Map<String, dynamic> body, {String method = 'POST'}) async {
    try { await widget.store.api.permintaan(method, path, body: body); await muat(); }
    catch (e) { if (mounted) pemberitahuanKomunitas(context, e); }
  }
  Future<void> kirim() async {
    if (mengirim) return;
    final konten = teksTertunda ?? masukan.text.trim();
    if (konten.isEmpty && mediaTertunda == null) return;
    idTertunda ??= ApiClient.buatIdPermintaan(); teksTertunda ??= konten;
    setState(() => mengirim = true);
    try {
      if (mediaTertunda != null) { await widget.store.api.unggahMediaGrup(widget.groupId, jenisTertunda!, mediaTertunda!, idTertunda!, replyToId: membalasPesan?['id'] as String?); }
      else { await widget.store.api.permintaan('POST', '$jalurDasar/messages', body: {'body': teksTertunda, 'requestId': idTertunda, if (membalasPesan != null) 'replyToId': membalasPesan!['id']}); }
      idTertunda = null; teksTertunda = null; mediaTertunda = null; jenisTertunda = null; masukan.clear();
      membalasPesan = null;
      await muat();
      if (mounted && gulir.hasClients) unawaited(gulir.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut));
    } catch (e) { if (mounted) pemberitahuanKomunitas(context, '$e Ketuk kirim untuk mencoba lagi.'); }
    finally { if (mounted) setState(() => mengirim = false); }
  }
  Future<void> media(String jenis) async {
    if (mengirim || idTertunda != null) return;
    try {
      final pemilih = ImagePicker();
      final XFile? berkasTerpilih = jenis == 'image' ? await pemilih.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85) : await pemilih.pickVideo(source: ImageSource.gallery);
      if (berkasTerpilih == null) return;
      if (await berkasTerpilih.length() > 20 * 1024 * 1024) throw const ApiException('Maksimal 20 MB per media.');
      final byte = await berkasTerpilih.readAsBytes();
      if (!mounted) return;
      final konfirmasi = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text('Kirim ${jenis == 'image' ? 'gambar' : 'video'}?'), content: jenis == 'image' ? Image.memory(byte, height: 200, fit: BoxFit.contain) : Text('${berkasTerpilih.name}\n${(byte.length / 1048576).toStringAsFixed(1)} MB'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim'))]));
      if (konfirmasi != true || !mounted) return;
      mediaTertunda = byte; jenisTertunda = jenis; await kirim();
    } catch (e) { if (mounted) pemberitahuanKomunitas(context, e); }
  }
  Future<void> ubahFotoGrup() async {
    try {
      final foto = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 82);
      if (foto == null) return;
      await widget.store.api.permintaan('POST', '$jalurDasar/avatar', body: {'photoBase64': base64Encode(await foto.readAsBytes())});
      revisiAvatar++;
      await muat();
      if (mounted) pemberitahuanKomunitas(context, 'Foto grup berhasil diperbarui.');
    } catch (e) { if (mounted) pemberitahuanKomunitas(context, e); }
  }
  Future<void> undang() async {
    final namaPengguna = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('Undang anggota'), content: TextField(controller: namaPengguna, decoration: const InputDecoration(labelText: 'Username akun, tanpa @')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, namaPengguna.text.trim().replaceFirst(RegExp(r'^@'), '')), child: const Text('Undang'))]));
    Future<void>.delayed(const Duration(milliseconds: 350), namaPengguna.dispose);
    if (value != null && value.isNotEmpty) await lakukan('$jalurDasar/invite', {'username': value});
  }
  Future<void> detail() async {
    if (data == null) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: forestDeep, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .8, child: ListView(padding: const EdgeInsets.all(22), children: [
      Center(child: Column(children: [ApiAvatar(api: widget.store.api, path: '$jalurDasar/avatar', refresh: revisiAvatar, size: 92, fallback: CircleAvatar(radius: 46, backgroundColor: const Color(0xff009d20), child: Text('${data!['group']['nama']}'.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 34)))), const SizedBox(height: 10), Text('${data!['group']['nama']}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)), Text('${data!['group']['memberCount']} anggota • dibuat ${DateTime.tryParse('${data!['group']['createdAt'] ?? ''}')?.toLocal().toString().split(' ').first ?? ''}', style: const TextStyle(color: muted, fontSize: 11)), Text('${data!['group']['description']}', textAlign: TextAlign.center)])),
      if (adalahAdmin) TextButton.icon(onPressed: ubahFotoGrup, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Ubah foto grup')),
      const SizedBox(height: 14), LeafButton('Undang dengan username', onTap: undang, icon: Icons.person_add_alt),
      if (adalahAdmin) SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Persetujuan admin untuk join'), value: data!['group']['approvalRequired'] == true, onChanged: (v) async { await lakukan('$jalurDasar/settings', {'approvalRequired': v}, method: 'PUT'); if (ctx.mounted) update(() {}); }),
      if (adalahAdmin && daftarBaris(data!['requests']).isNotEmpty) const Text('Permintaan bergabung'),
      ...daftarBaris(data!['requests']).map((r) => ListTile(title: Text('${r['nama']}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () async { await lakukan('$jalurDasar/requests/${r['id']}', {'accept': false}); if (ctx.mounted) update(() {}); }, icon: const Icon(Icons.close)), IconButton(onPressed: () async { await lakukan('$jalurDasar/requests/${r['id']}', {'accept': true}); if (ctx.mounted) update(() {}); }, icon: const Icon(Icons.check, color: sage))]))),
      const Divider(), const Text('Anggota'),
      ...daftarBaris(data!['members']).map((m) => ListTile(contentPadding: EdgeInsets.zero, leading: ApiAvatar(api: widget.store.api, path: '$jalurDasar/members/${m['userId']}/avatar', size: 42, fallback: CircleAvatar(backgroundColor: surfaceHigh, child: Text('${m['nama']}'.isEmpty ? '?' : '${m['nama']}'.substring(0, 1).toUpperCase()))), title: Text('${m['nama']}'), subtitle: Text('@${m['namaPengguna']} • ${m['role']}'), trailing: adalahAdmin && m['role'] != 'admin' ? IconButton(tooltip: 'Jadikan admin', icon: const Icon(Icons.admin_panel_settings_outlined), onPressed: () async {
      final berhasil = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(title: const Text('Jadikan admin grup?'), content: Text('${m['nama']} dapat mengatur anggota dan pesan sematan.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Jadikan admin'))]));
        if (berhasil == true) { await lakukan('$jalurDasar/promote', {'userId': m['userId']}); if (ctx.mounted) update(() {}); }
      }) : null)),
      TextButton.icon(onPressed: () async {
        final berhasil = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(title: const Text('Keluar dari komunitas?'), content: const Text('Kamu tidak dapat membaca pesan grup setelah keluar.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Keluar'))]));
        if (berhasil != true) return;
        try { await widget.store.api.permintaan('POST', '$jalurDasar/leave', body: {}); if (ctx.mounted) Navigator.pop(ctx); if (mounted) Navigator.pop(context); }
        catch (e) { if (mounted) pemberitahuanKomunitas(context, e); }
      }, icon: const Icon(Icons.logout), label: const Text('Keluar grup')),
    ])))));
  }
  Future<void> riwayat() async {
    final semua = [...pesanLama, ...daftarBaris(data?['messages'])]; if (semua.isEmpty) return;
    try { final hasil = await widget.store.api.permintaan('GET', '$jalurDasar?before=${Uri.encodeQueryComponent(semua.first['createdAt'] as String)}'); if (mounted) setState(() { pesanLama = [...daftarBaris(hasil['messages']), ...pesanLama]; if (hasil['hasMore'] != true) data!['hasMore'] = false; }); }
    catch (e) { if (mounted) pemberitahuanKomunitas(context, e); }
  }
  Widget gelembung(Map<String, dynamic> m) {
    if (m['type'] == 'system') return Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Center(child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xff14211e), borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7), child: Text('${m['body']}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffaeb9b6), fontSize: 11))))));
    final milikSaya = m['userId'] == widget.store.user['id'];
    final waktu = DateTime.tryParse('${m['createdAt']}')?.toLocal();
    return Align(key: ValueKey(m['id']), alignment: milikSaya ? Alignment.centerRight : Alignment.centerLeft, child: GestureDetector(onLongPress: () => _pesanAksi(m, milikSaya), child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82), margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: milikSaya ? const Color(0xff075e4b) : const Color(0xff202c33), borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(milikSaya ? 18 : 3), bottomRight: Radius.circular(milikSaya ? 3 : 18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!milikSaya) Text('${m['nama']}', style: const TextStyle(color: sage, fontWeight: FontWeight.bold, fontSize: 12)),
        if (m['reply'] is Map) Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0x33202b29), border: Border(left: BorderSide(color: sage, width: 3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${m['reply']['nama']}', style: const TextStyle(color: sage, fontSize: 11, fontWeight: FontWeight.bold)), Text('${m['reply']['body']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: muted))])),
        if (m['media'] is Map) GroupMedia(api: widget.store.api, path: m['media']['url'] as String, video: m['media']['kind'] == 'video'),
        if (m['deletedForAll'] == true) const Text('Pesan ini dihapus', style: TextStyle(color: muted, fontStyle: FontStyle.italic)) else if ('${m['body']}'.isNotEmpty) SelectableText('${m['body']}', style: const TextStyle(height: 1.5)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (m['pinned'] == true) const Icon(Icons.push_pin, size: 12, color: sage),
          Text(waktu == null ? '' : '${waktu.day}/${waktu.month} ${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: muted, fontSize: 10)),
          if (!m['deletedForAll']) PopupMenuButton<String>(iconSize: 17, onSelected: (v) async { if (v == 'copy') { await Clipboard.setData(ClipboardData(text: '${m['body']}')); if (mounted) pemberitahuanKomunitas(context, 'Pesan disalin.'); } else if (v == 'reply') { setState(() => membalasPesan = m); } else if (v == 'delete') { final berhasil = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Hapus untuk semua orang?'), content: const Text('Pesan akan diganti dengan keterangan bahwa pesan telah dihapus.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus'))])); if (berhasil == true) await lakukan('$jalurDasar/messages/${m['id']}', {}, method: 'DELETE'); } else { await lakukan('$jalurDasar/pin', {'messageId': m['id'], 'pinned': m['pinned'] != true}); } }, itemBuilder: (_) => [const PopupMenuItem(value: 'reply', child: Text('Balas')), if ('${m['body']}'.isNotEmpty) const PopupMenuItem(value: 'copy', child: Text('Salin')), if (adalahAdmin) PopupMenuItem(value: 'pin', child: Text(m['pinned'] == true ? 'Lepas sematan' : 'Sematkan')), if (milikSaya || adalahAdmin) const PopupMenuItem(value: 'delete', child: Text('Hapus untuk semua orang'))]),
        ]),
      ]),
    )));
  }
  String _hariLabel(DateTime date) { final hariIni = DateTime.now(); final d = DateTime(date.year, date.month, date.day); final t = DateTime(hariIni.year, hariIni.month, hariIni.day); if (d == t) return 'Hari ini'; if (d == t.subtract(const Duration(days: 1))) return 'Kemarin'; return '${date.day} ${_bulan(date.month)} ${date.year}'; }
  String _bulan(int month) => const ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'][month - 1];
  List<Widget> _obrolanDaftarbutir(List<Map<String, dynamic>> daftarPesan) {
    final terurut = daftarPesan.reversed.toList();
    final keluar = <Widget>[];
    DateTime? previous;
    for (final pesan in terurut) {
      final dibuat = DateTime.tryParse('${pesan['createdAt']}')?.toLocal();
      if (dibuat != null && (previous == null || previous.year != dibuat.year || previous.month != dibuat.month || previous.day != dibuat.day)) {
        keluar.add(Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6), decoration: BoxDecoration(color: const Color(0xff192421), borderRadius: BorderRadius.circular(16)), child: Text(_hariLabel(dibuat), style: const TextStyle(color: muted, fontSize: 11)))));
      }
      keluar.add(gelembung(pesan)); previous = dibuat;
    }
    return keluar;
  }
  void _pesanAksi(Map<String, dynamic> m, bool milikSaya) => showModalBottomSheet<void>(context: context, backgroundColor: forestDeep, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.reply), title: const Text('Balas pesan'), onTap: () { setState(() => membalasPesan = m); Navigator.pop(ctx); }), if (milikSaya || adalahAdmin) ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Hapus untuk semua orang'), onTap: () { Navigator.pop(ctx); unawaited(lakukan('$jalurDasar/messages/${m['id']}', {}, method: 'DELETE')); })])));
  @override
  Widget build(BuildContext context) {
    final daftarPesan = <String, Map<String, dynamic>>{for (final m in [...pesanLama, ...daftarBaris(data?['messages'])]) m['id'] as String: m}.values.toList();
    return Scaffold(backgroundColor: const Color(0xff0b141a), appBar: AppBar(backgroundColor: const Color(0xff0b141a), title: GestureDetector(onTap: detail, child: Row(children: [ApiAvatar(api: widget.store.api, path: '$jalurDasar/avatar', refresh: revisiAvatar, size: 38, fallback: const CircleAvatar(backgroundColor: surfaceHigh, child: Icon(Icons.groups_2_outlined, color: sage, size: 20))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${data?['group']?['nama'] ?? 'Komunitas'}', style: const TextStyle(fontSize: 17)), Text('${data?['group']?['memberCount'] ?? '…'} anggota • info grup', style: const TextStyle(fontSize: 11, color: muted))]))])), actions: [IconButton(onPressed: detail, icon: const Icon(Icons.more_vert))]), body: SafeArea(child: Column(children: [
      if (galat != null) MaterialBanner(content: Text(galat!), actions: [TextButton(onPressed: muat, child: const Text('Coba lagi'))]),
      if (daftarBaris(data?['pinned']).isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(12), color: const Color(0xff16252b), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: daftarBaris(data!['pinned']).map((m) => Text('📌 ${m['body'] == '' ? 'Media disematkan' : m['body']}', maxLines: 2, overflow: TextOverflow.ellipsis)).toList())),
      Expanded(child: data == null && galat == null ? const Center(child: CircularProgressIndicator()) : ListView(controller: gulir, reverse: true, padding: const EdgeInsets.all(12), children: [
        ..._obrolanDaftarbutir(daftarPesan),
        if (data?['hasMore'] == true) TextButton(onPressed: riwayat, child: const Text('Muat pesan sebelumnya')),
        if (daftarPesan.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Mulai obrolan dengan komunitasmu.', textAlign: TextAlign.center, style: TextStyle(color: muted))),
      ])),
      if (idTertunda != null && !mengirim) const Padding(padding: EdgeInsets.all(8), child: Text('Pesan belum terkonfirmasi. Ketuk kirim untuk mencoba lagi.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12))),
      if (membalasPesan != null) Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 8, 8, 5), color: const Color(0xff16252b), child: Row(children: [Expanded(child: Text('Membalas ${membalasPesan!['nama']}: ${membalasPesan!['body']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12))), IconButton(onPressed: () => setState(() => membalasPesan = null), icon: const Icon(Icons.close, size: 18))])),
      Container(color: const Color(0xff0b141a), padding: const EdgeInsets.fromLTRB(8, 8, 8, 12), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        PopupMenuButton<String>(enabled: !mengirim && idTertunda == null && data != null, icon: const Icon(Icons.add_circle_outline, color: sage), onSelected: media, itemBuilder: (_) => const [PopupMenuItem(value: 'image', child: Text('Kirim gambar')), PopupMenuItem(value: 'video', child: Text('Kirim video (20 MB)'))]),
        Expanded(child: TextField(controller: masukan, enabled: idTertunda == null && data != null, minLines: 1, maxLines: 5, maxLength: 4000, decoration: const InputDecoration(hintText: 'Pesan komunitas…', counterText: ''))),
        IconButton.filled(onPressed: mengirim || data == null ? null : kirim, style: IconButton.styleFrom(backgroundColor: const Color(0xff009d20)), icon: mengirim ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white)),
      ])),
    ])));
  }
}

class GroupMedia extends StatefulWidget {
  const GroupMedia({super.key, required this.api, required this.path, required this.video});
  final ApiClient api;
  final String path;
  final bool video;
  @override
  State<GroupMedia> createState() => _grupMediaKeadaan();
}
class _grupMediaKeadaan extends State<GroupMedia> {
  late Future<Uint8List> image;
  @override
  void initState() { super.initState(); if (!widget.video) image = widget.api.ambilByte(widget.path); }
  @override
  Widget build(BuildContext context) => widget.video ? TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => _videoHalaman(api: widget.api, path: widget.path))), icon: const Icon(Icons.play_circle, size: 44), label: const Text('Putar video')) : FutureBuilder<Uint8List>(future: image, builder: (ctx, state) => state.hasData ? GestureDetector(onTap: () => showDialog<void>(context: context, builder: (c) => Dialog(child: Stack(children: [InteractiveViewer(child: Image.memory(state.data!)), Positioned(right: 0, top: 0, child: IconButton.filled(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)))]))), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(state.data!, width: 260, height: 220, fit: BoxFit.cover))) : Padding(padding: const EdgeInsets.all(18), child: state.hasError ? const Text('Gambar tidak dapat dimuat.') : const CircularProgressIndicator()));
}
class _videoHalaman extends StatefulWidget {
  const _videoHalaman({required this.api, required this.path}); final ApiClient api; final String path;
  @override State<_videoHalaman> createState() => _videoHalamanKeadaan();
}
class _videoHalamanKeadaan extends State<_videoHalaman> with WidgetsBindingObserver {
  late final VideoPlayerController player = VideoPlayerController.networkUrl(Uri.parse('${widget.api.baseUrl}${widget.path}'), httpHeaders: widget.api.mediaHeaders);
  String? galat;
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); player.initialize().then((_) { if (mounted) setState(() {}); }).catchError((Object e) { if (mounted) setState(() => galat = 'Video tidak dapat diputar di perangkat ini.'); }); }
  @override void didChangeAppLifecycleState(AppLifecycleState s) { if (s != AppLifecycleState.resumed) unawaited(player.pause()); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); unawaited(player.dispose()); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Video komunitas')), body: Center(child: galat != null ? Text(galat!) : !player.value.isInitialized ? const CircularProgressIndicator() : Column(mainAxisSize: MainAxisSize.min, children: [AspectRatio(aspectRatio: player.value.aspectRatio, child: VideoPlayer(player)), VideoProgressIndicator(player, allowScrubbing: true), IconButton(onPressed: () { setState(() { if (player.value.isPlaying) { unawaited(player.pause()); } else { unawaited(player.play()); } }); }, icon: Icon(player.value.isPlaying ? Icons.pause : Icons.play_arrow))])));
}
