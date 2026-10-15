import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shion/app/app.dart';
void main() {
  testWidgets('Firebase yang belum dikonfigurasi ditampilkan dengan jujur', (tester) async {
    await tester.pumpWidget(const ShionApp(configurationError: 'Firebase belum dikonfigurasi.'));
    expect(find.text('Firebase belum dikonfigurasi.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
