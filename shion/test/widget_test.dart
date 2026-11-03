// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shion/core/api_client.dart';
import 'package:shion/core/api_store.dart';
import 'package:shion/main.dart';
import 'package:shion/features/leaderboard_page.dart';
import 'helpers.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('compact onboarding and signup have no admin selection', (tester) async {
    tester.view.physicalSize = const Size(360, 740); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(vault: fixtures.MemoryVault(), client: MockClient((_) async => fixtures.ok(fixtures.state())));
    final penyimpanan = ApiStore(api: api);
    await tester.pumpWidget(MaterialApp(home: ShionHome(store: penyimpanan))); await tester.pumpAndSettle();
    expect(find.text('Untuk bumi,\nhari ini.'), findsOneWidget);
    await tester.ensureVisible(find.text('Lanjutkan')); await tester.tap(find.text('Lanjutkan')); await tester.pumpAndSettle();
    expect(find.text('Pindai. Pahami.\nPilah dengan bijak.'), findsOneWidget);
    await tester.ensureVisible(find.text('Masuk atau daftar')); await tester.tap(find.text('Masuk atau daftar')); await tester.pumpAndSettle();
    expect(find.text('Masuk ke akunmu'), findsOneWidget);
    await tester.ensureVisible(find.text('Daftar')); await tester.tap(find.text('Daftar')); await tester.pumpAndSettle();
    expect(find.text('Nama lengkap'), findsOneWidget); expect(find.text('Nomor telepon'), findsOneWidget);
    expect(find.text('Daftar sebagai admin'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'Tidak boleh ada error layout/widget saat membuka form daftar.');
    await tester.pumpWidget(const SizedBox()); penyimpanan.dispose(); api.close();
  });
  testWidgets('podium and leaderboard tabs fit a compact phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(vault: fixtures.MemoryVault()..token = 'session', client: MockClient((request) async {
      if (request.url.path.endsWith('/state')) return fixtures.ok(fixtures.state());
      final daftarBaris = List.generate(5, (i) => {'id': '$i', 'name': i == 0 ? 'Daffa Putra' : 'Sahabat ${i + 1}', 'rank': i + 1, 'points': 200 - i * 20, 'deposits': 15 - i, 'totalKg': 20.0, 'totalUnits': 3, 'isMe': i == 0});
      return fixtures.ok({'metric': request.url.queryParameters['metric'], 'rows': daftarBaris, 'me': daftarBaris.first, 'totalUsers': 5});
    }));
    final penyimpanan = ApiStore(api: api); await penyimpanan.pulihkanSesi();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LeaderboardPage(store: penyimpanan)))); await tester.pumpAndSettle();
    expect(find.text('Poin tertinggi'), findsOneWidget); expect(tester.takeException(), isNull);
    await tester.tap(find.text('Setoran terbanyak')); await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); penyimpanan.dispose(); api.close();
  });
}
