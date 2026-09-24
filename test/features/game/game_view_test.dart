import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_cubit.dart';
import 'package:gwent_helper_flutter/features/game/view/game_view.dart';
import 'package:gwent_helper_flutter/features/game/widgets/user_widget.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:gwent_helper_flutter/widgets/hud/hud_avatar.dart';
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
        theme: AppTheme.data,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<GameCubit>.value(
          value: cubit,
          child: const GameView(),
        ),
      ),
    );
    await tester.pump();

    return physicalSize / devicePixelRatio;
  }

  Finder avatarFrameOf(int playerIndex) => find.descendant(
    of: find.byType(UserWidget).at(playerIndex),
    matching: find.byKey(HudAvatar.frameKey),
  );

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
        final passRect = tester.getRect(find.text('Pass'));
        expect(passRect.top, greaterThanOrEqualTo(0));
        expect(passRect.bottom, lessThanOrEqualTo(screen.height));
      },
    );

    testWidgets(
      '''
      Given a phone screen in landscape
      When the pass control is long-pressed
      Then a confirmation dialog appears and the round has not ended yet
      ''',
      (tester) async {
        // Given
        await pumpGameView(tester);

        // When
        await tester.longPress(find.text('Pass'));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('End the round?'), findsOneWidget);
        expect(cubit.state.roundCounter, 0);
      },
    );

    testWidgets(
      '''
      Given the pass confirmation dialog is open
      When END ROUND is tapped
      Then the round ends
      ''',
      (tester) async {
        // Given
        await pumpGameView(tester);
        await tester.longPress(find.text('Pass'));
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.text('END ROUND'));
        await tester.pumpAndSettle();

        // Then
        expect(cubit.state.roundCounter, 1);
      },
    );

    testWidgets(
      '''
      Given the pass confirmation dialog is open
      When CANCEL is tapped
      Then the round does not end
      ''',
      (tester) async {
        // Given
        await pumpGameView(tester);
        await tester.longPress(find.text('Pass'));
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('End the round?'), findsNothing);
        expect(cubit.state.roundCounter, 0);
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
              of: find.text('Exit'),
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

  group('GameView chrome', () {
    testWidgets(
      '''
      Given the first player is selected
      When the sidebar is rendered
      Then only that player's avatar frame is gold
      ''',
      (tester) async {
        // When
        await pumpGameView(tester);

        // Then
        expect(
          avatarFrameOf(0),
          paints..path(color: AppTheme.gold, style: PaintingStyle.stroke),
        );
        expect(
          avatarFrameOf(1),
          paints..path(color: AppTheme.olive, style: PaintingStyle.stroke),
        );
      },
    );

    testWidgets(
      '''
      Given the first player is selected
      When the second player is tapped
      Then the gold frame follows the selection
      ''',
      (tester) async {
        // Given
        await pumpGameView(tester);

        // When
        await tester.tap(find.text('Bob'));
        await tester.pump();

        // Then
        expect(cubit.state.selectedPlayer, PlayerSide.second);
        expect(
          avatarFrameOf(0),
          paints..path(color: AppTheme.olive, style: PaintingStyle.stroke),
        );
        expect(
          avatarFrameOf(1),
          paints..path(color: AppTheme.gold, style: PaintingStyle.stroke),
        );
      },
    );

    testWidgets(
      '''
      Given the game board is rendered
      When the sidebar is inspected
      Then it is a saddle panel with a wood-trim edge at its full width
      ''',
      (tester) async {
        // When
        await pumpGameView(tester);

        // Then
        final sidebar = tester.widget<Container>(
          find.byKey(GameView.sidebarKey),
        );
        final decoration = sidebar.decoration! as BoxDecoration;
        expect(decoration.color, AppTheme.sidebarSurface);
        expect(
          (decoration.border! as Border).right.color,
          AppTheme.sidebarTrim,
        );
        expect(tester.getSize(find.byKey(GameView.sidebarKey)).width, 90);
      },
    );
  });

  group('GameView Scorch', () {
    testWidgets(
      '''
      Given a phone screen in landscape
      When the game board is rendered
      Then the Scorch control is fully on screen
      ''',
      (tester) async {
        // When
        final screen = await pumpGameView(tester);

        // Then
        final scorchRect = tester.getRect(find.text('Scorch'));
        expect(scorchRect.top, greaterThanOrEqualTo(0));
        expect(scorchRect.bottom, lessThanOrEqualTo(screen.height));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given two tied strongest units
      When Scorch is tapped
      Then pick mode starts and a highlighted chip can be removed
      ''',
      (tester) async {
        // Given
        cubit.onCardAdded(
          CardsRowType.closeCombat,
          Card(cardId: 'a8', points: 8, abilities: const []),
        );
        cubit.onPlayerSelected(PlayerSide.second);
        cubit.onCardAdded(
          CardsRowType.siege,
          Card(cardId: 'b8', points: 8, abilities: const []),
        );
        cubit.onPlayerSelected(PlayerSide.first);
        await pumpGameView(tester);

        // When
        await tester.tap(find.text('Scorch'));
        await tester.pump();

        // Then
        expect(
          find.text(
            'Scorch targets remaining: 2. '
            'Targets also remain on the other player’s side.',
          ),
          findsOneWidget,
        );

        // When
        await tester.tap(find.byKey(const ValueKey('a8')));
        await tester.pump();

        // Then
        expect(find.byKey(const ValueKey('a8')), findsNothing);
        expect(cubit.state.scorchPrompt?.targets, hasLength(1));
      },
    );

    testWidgets(
      '''
      Given pick mode is active
      When Cancel is tapped
      Then the prompt is cleared and the card remains
      ''',
      (tester) async {
        // Given
        cubit.onCardAdded(
          CardsRowType.closeCombat,
          Card(cardId: 'a8', points: 8, abilities: const []),
        );
        await pumpGameView(tester);
        await tester.tap(find.text('Scorch'));
        await tester.pump();

        // When
        await tester.tap(find.text('CANCEL'));
        await tester.pump();

        // Then
        expect(cubit.state.scorchPrompt, isNull);
        expect(find.byKey(const ValueKey('a8')), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given a card on the board
      When it is tapped outside pick mode
      Then it is not removed
      ''',
      (tester) async {
        // Given
        cubit.onCardAdded(
          CardsRowType.closeCombat,
          Card(cardId: 'a5', points: 5, abilities: const []),
        );
        await pumpGameView(tester);

        // When
        await tester.tap(find.byKey(const ValueKey('a5')));
        await tester.pump();

        // Then
        expect(find.byKey(const ValueKey('a5')), findsOneWidget);
      },
    );
  });
}
