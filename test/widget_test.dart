import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shion/core/local_store.dart';
import 'package:shion/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local profile and deposit survive store recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    await store.setName('Daffa');
    await store.addRecord('deposits', {
      'category': 'Kertas',
      'estimatedKg': 1.5,
    });
    final restored = LocalStore(prefs);
    expect(restored.name, 'Daffa');
    expect(restored.getList('deposits').single['estimatedKg'], 1.5);
  });

  testWidgets('welcome works on a compact phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ShionApp());
    await tester.pumpAndSettle();
    expect(find.text('Mulai Perjalanan'), findsOneWidget);
    await tester.tap(find.text('Mulai Perjalanan'));
    await tester.pumpAndSettle();
    expect(find.text('Kelola Sampah\nLebih Mudah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop keeps phone layout, tabs and local activity work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'shion.welcomed': true});
    await tester.pumpWidget(const ShionApp());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(SafeArea).first).width,
      lessThanOrEqualTo(480),
    );
    for (final label in ['Scan', 'Poin', 'Edukasi', 'Profil', 'Beranda']) {
      await tester.tap(
        label == 'Scan' ? find.bySemanticsLabel('Scan') : find.text(label).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(find.text('Jejak Karbon'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '2.5');
    await tester.ensureVisible(find.text('Simpan Catatan'));
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();
    final store = LocalStore(await SharedPreferences.getInstance());
    expect(store.getList('activities').single['amount'], 2.5);
    expect(tester.takeException(), isNull);
  });
}
