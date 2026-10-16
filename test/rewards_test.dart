import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shion/core/local_store.dart';
import 'package:shion/core/system_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
  });
  test('confirmed deposit persists points and receipt together', () async {
    await store.confirmDeposit(
      category: 'Plastik',
      kg: 3,
      destination: 'Tempat Uji',
    );
    expect(store.points, 150);
    expect(store.getList('deposits').single['points'], 150);
    final restored = LocalStore(await SharedPreferences.getInstance());
    expect(restored.points, 150);
    expect(restored.getList('deposits').single['status'], 'Selesai');
  });
  test('reward debits balance and persists voucher', () async {
    await store.confirmDeposit(
      category: 'Plastik',
      kg: 5,
      destination: 'Tempat Uji',
    );
    final code = await store.redeemReward('transport');
    expect(store.points, 100);
    expect(code, startsWith('SHION-'));
    expect(store.getList('vouchers').single['code'], code);
  });
  test('concurrent redemptions cannot spend the same balance twice', () async {
    await store.confirmDeposit(
      category: 'Plastik',
      kg: 3,
      destination: 'Tempat Uji',
    );
    final results = await Future.wait(
      List.generate(2, (_) async {
        try {
          await store.redeemReward('transport');
          return true;
        } catch (_) {
          return false;
        }
      }),
    );
    expect(results.where((r) => r).length, 1);
    expect(store.points, 0);
    expect(store.getList('vouchers').length, 1);
  });
  test('invalid deposit never changes balance', () async {
    await expectLater(
      store.confirmDeposit(
        category: 'Plastik',
        kg: -1,
        destination: 'Tempat Uji',
      ),
      throwsStateError,
    );
    expect(store.points, 0);
    expect(store.getList('deposits'), isEmpty);
  });
  test('system console redacts credential patterns', () {
    SystemLog.add('test', 'x-goog-api-key=example-secret AQ.example_secret');
    expect(SystemLog.entries.value.first, isNot(contains('example-secret')));
    expect(SystemLog.entries.value.first, isNot(contains('AQ.example_secret')));
  });
}
