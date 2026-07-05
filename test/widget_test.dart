import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mymusixworld/app.dart';

Widget createTestApp() {
  return const ProviderScope(
    child: MyMusixWorld(),
  );
}

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
