// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'package:flutter/material.dart';
import '../core/api_store.dart';
import '../ui/forest.dart';
class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key, required this.store});
  final ApiStore store;
  @override
  State<PasswordPage> createState() => _kataSandiHalamanKeadaan();
}
class _kataSandiHalamanKeadaan extends State<PasswordPage> {
  final _formulir = GlobalKey<FormState>();
  final _lama = TextEditingController(), _berikutnya = TextEditingController(), _ulang = TextEditingController();
  bool _sibuk = false;
  String? _galat;
  @override
  void dispose() { _lama.dispose(); _berikutnya.dispose(); _ulang.dispose(); super.dispose(); }
  Future<void> _simpan() async {
    if (_sibuk || !_formulir.currentState!.validate()) return;
    setState(() { _sibuk = true; _galat = null; });
    try {
      await widget.store.ubahKataSandi(_lama.text, _berikutnya.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kata sandi diperbarui. Sesi perangkat lain diakhiri.')));
      Navigator.pop(context);
    } catch (e) { if (mounted) setState(() => _galat = e.toString()); }
    finally { if (mounted) setState(() => _sibuk = false); }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(22), children: [
    serif('Amankan akunmu.', size: 31), const SizedBox(height: 22),
    Form(key: _formulir, child: Glass(child: Column(children: [
      TextFormField(controller: _lama, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi saat ini'), validator: (v) => (v ?? '').isEmpty ? 'Isi kata sandi saat ini.' : null), const SizedBox(height: 16),
      TextFormField(controller: _berikutnya, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi baru'), validator: (v) => (v ?? '').length < 12 ? 'Gunakan minimal 12 karakter.' : null), const SizedBox(height: 16),
      TextFormField(controller: _ulang, obscureText: true, decoration: const InputDecoration(labelText: 'Ulangi kata sandi baru'), validator: (v) => v != _berikutnya.text ? 'Kata sandi belum sama.' : null), const SizedBox(height: 22),
      if (_galat != null) Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(_galat!, style: const TextStyle(color: terracotta))),
      LeafButton(_sibuk ? 'Menyimpan…' : 'Simpan kata sandi', onTap: _sibuk ? null : _simpan, icon: Icons.lock_outline),
    ]))),
  ]);
}
