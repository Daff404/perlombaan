import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShionRepository {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  String get uid => auth.currentUser!.uid;
  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String collection) =>
      db.collection(collection).where('uid', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> catalog(String collection) =>
      db.collection(collection).where('active', isEqualTo: true).snapshots();
  Future<void> call(String name, Map<String, dynamic> data) async {
    await FirebaseFunctions.instance.httpsCallable(name).call(data);
  }
  Future<void> saveCarbon(String mode, double distance, DateTime date) =>
      call('recordCarbon', {'mode': mode, 'amount': distance, 'date': date.toUtc().toIso8601String()});
}
