import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shion/core/local_store.dart';
import 'package:shion/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rencana dan profil bertahan setelah store dibuat ulang', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    await store.setName('Daffa');
    await store.add('deposits', {'category': 'Kertas', 'estimatedKg': 1.5});
    final reopened = LocalStore(prefs);
    expect(reopened.name, 'Daffa');
    expect(reopened.records('deposits').single['estimatedKg'], 1.5);
    expect(reopened.points, 0);
  });

  testWidgets('navigasi utama membuka catatan setoran', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ShionApp());
    await tester.pumpAndSettle();
    expect(find.text('Langkah Kecil,\nDampak Besar.'), findsOneWidget);
    await tester.tap(find.text('Setor').last);
    await tester.pumpAndSettle();
    expect(find.text('Rencana Setoran'), findsOneWidget);
  });
}
