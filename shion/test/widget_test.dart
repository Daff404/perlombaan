import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shion/core/local_store.dart';
import 'package:shion/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profil dan rencana setoran tersimpan di perangkat', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final store = LocalStore(preferences);
    await store.setName('Daffa');
    await store.addRecord('deposits', <String, dynamic>{'category': 'Kertas', 'estimatedKg': 1.5});

    final restored = LocalStore(preferences);
    expect(restored.name, 'Daffa');
    expect(restored.getList('deposits').single['estimatedKg'], 1.5);
  });

  testWidgets('aplikasi membuka navigasi SHION', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const ShionApp());
    await tester.pumpAndSettle();
    expect(find.text('SHION'), findsOneWidget);
    expect(find.text('Langkah Kecil,\nDampak Besar.'), findsOneWidget);
    expect(find.text('Setor'), findsOneWidget);
  });
}
