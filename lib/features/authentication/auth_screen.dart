import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/catalog_list.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    setState(() => busy = true);
    await perform(context, () async {
      final auth = FirebaseAuth.instance;
      if (register) {
        final credential = await auth.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
        await credential.user!.sendEmailVerification();
      } else {
        await auth.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      }
    });
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.eco_outlined, size: 64, color: Color(0xffddf4b5)),
    const Text('SHION', textAlign: TextAlign.center, style: TextStyle(fontSize: 40, letterSpacing: 8)),
    const Text('Technology in Harmony with Nature', textAlign: TextAlign.center),
    const SizedBox(height: 40),
    Text(register ? 'Mulai langkah baikmu.' : 'Selamat datang kembali.', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 20),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
    const SizedBox(height: 12),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi')),
    const SizedBox(height: 20),
    FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Memproses…' : register ? 'Daftar' : 'Masuk')),
    TextButton(onPressed: busy ? null : () => setState(() => register = !register), child: Text(register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
    TextButton(onPressed: () => perform(context, () => FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim())), child: const Text('Lupa kata sandi')),
  ]))))));
}
