import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gwent_helper_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GwentHelperApp()));
    await tester.pumpAndSettle();
    expect(find.text('GwentHelper'), findsOneWidget);
  });
}
