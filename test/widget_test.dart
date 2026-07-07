import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/main.dart';

void main() {
  group('GwentHelperApp', () {
    testWidgets(
      '''
      Given the app
      When it is launched
      Then player name inputs are shown
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
      },
    );
  });
}
