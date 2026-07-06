import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/main.dart';

void main() {
  testWidgets('Given the app\n'
      'When it is launched\n'
      'Then player name inputs are shown', (WidgetTester tester) async {
    await tester.pumpWidget(const GwentHelperApp());
    await tester.pumpAndSettle();
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
  });
}
