import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_cubit.dart';
import 'package:gwent_helper_flutter/features/game/resources/game_strings.dart';
import 'package:gwent_helper_flutter/features/game/view/game_view.dart';
import 'package:mocktail/mocktail.dart';

// region Mocks
class MockGwentRepository extends Mock implements GwentRepository {}
// endregion

void main() {
  // Pixel 8 held in landscape: status bar along the top, navigation bar on the
  // right. This is the device the sidebar used to overflow on.
  const physicalSize = Size(2400, 1080);
  const devicePixelRatio = 2.625;
  const viewPadding = FakeViewPadding(top: 74, right: 126);

  late MockGwentRepository repository;
  late GameCubit cubit;

  setUp(() {
    repository = MockGwentRepository();
    cubit = GameCubit(
      player1Name: 'Alice',
      player2Name: 'Bob',
      repository: repository,
    );
  });

  tearDown(() async => cubit.close());

  Future<Size> pumpGameView(WidgetTester tester) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = devicePixelRatio
      ..padding = viewPadding
      ..viewPadding = viewPadding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<GameCubit>.value(
          value: cubit,
          child: const GameView(),
        ),
      ),
    );
    await tester.pump();

    return physicalSize / devicePixelRatio;
  }

  group('GameView sidebar', () {
    testWidgets(
      '''
      Given a phone screen in landscape
      When the game board is rendered
      Then nothing overflows
      ''',
      (tester) async {
        // When
        await pumpGameView(tester);

        // Then
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given a phone screen in landscape
      When the game board is rendered
      Then the pass control is fully on screen
      ''',
      (tester) async {
        // When
        final screen = await pumpGameView(tester);

        // Then
        final passRect = tester.getRect(find.text(GameStrings.pass));
        expect(passRect.top, greaterThanOrEqualTo(0));
        expect(passRect.bottom, lessThanOrEqualTo(screen.height));
      },
    );

    testWidgets(
      '''
      Given a phone screen in landscape
      When the pass control is long-pressed
      Then the round ends
      ''',
      (tester) async {
        // Given
        await pumpGameView(tester);

        // When
        await tester.longPress(find.text(GameStrings.pass));
        await tester.pump();

        // Then
        expect(cubit.state.roundCounter, 1);
      },
    );

    testWidgets(
      '''
      Given a phone screen in landscape
      When the game board is rendered
      Then the exit control is below the status bar
      ''',
      (tester) async {
        // When
        await pumpGameView(tester);

        // Then
        final exitButton = find
            .ancestor(
              of: find.text(GameStrings.exit),
              matching: find.byType(GestureDetector),
            )
            .first;
        expect(
          tester.getRect(exitButton).top,
          greaterThanOrEqualTo(viewPadding.top / devicePixelRatio),
        );
      },
    );
  });
}
