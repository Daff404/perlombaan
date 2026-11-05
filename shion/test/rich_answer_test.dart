// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shion/ui/rich_answer.dart';
import 'package:shion/ui/forest.dart';
void main() {
  test('copy renders prose without formatting syntax and preserves percent and code', () {
    expect(jawabanTerbaca('**Plastik**\n* Kurangi 50%\n'), 'Plastik\n• Kurangi 50%\n');
    expect(jawabanTerbaca('```dart\nfinal marker = "**"; // 50%\n```'), 'final marker = "**"; // 50%\n');
  });
  testWidgets('app surface uses all available phone width', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ForestPage(child: SizedBox.expand(key: Key('content')))));
    expect(tester.getSize(find.byKey(const Key('content'))).width, 720);
  });
}
