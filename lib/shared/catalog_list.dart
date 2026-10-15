import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataList extends StatelessWidget {
  const DataList({super.key, required this.stream, required this.empty, required this.builder});
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String empty;
  final Widget Function(Map<String, dynamic>, String) builder;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: stream,
    builder: (context, state) {
      if (state.hasError) return const Padding(padding: EdgeInsets.all(24), child: Text('Data tidak dapat dimuat. Periksa koneksi dan izin akun.'));
      if (!state.hasData) return const Center(child: CircularProgressIndicator());
      if (state.data!.docs.isEmpty) return Padding(padding: const EdgeInsets.all(24), child: Text(empty));
      return Column(children: state.data!.docs.map((doc) => builder(doc.data(), doc.id)).toList());
    },
  );
}

Future<void> perform(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil diproses.')));
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses: $error')));
  }
}
