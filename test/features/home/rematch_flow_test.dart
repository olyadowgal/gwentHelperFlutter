import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_cubit.dart';
import 'package:gwent_helper_flutter/features/game/view/game_view.dart';
import 'package:gwent_helper_flutter/features/home/view/home_page.dart';
import 'package:gwent_helper_flutter/features/home/widgets/player_input_widget.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

// region Mocks
class MockGwentRepository extends Mock implements GwentRepository {}
// endregion

void main() {
  late MockGwentRepository repository;
  late GameCubit cubit;

  setUpAll(() {
    registerFallbackValue(Player(name: ''));
    registerFallbackValue(
      GameScore(
        date: DateTime(2026),
        firstPlayer: '',
        secondPlayer: '',
        winner: '',
      ),
    );
  });

  setUp(() {
    repository = MockGwentRepository();
    when(() => repository.addGame(any())).thenAnswer((_) async {});

    // A tiny in-memory player store, so saved players behave as they would on
    // a device: created once, then found by name.
    final saved = <String, Player>{};
    when(
      () => repository.getPlayers(),
    ).thenAnswer((_) async => saved.values.toList());
    when(() => repository.findPlayerByName(any())).thenAnswer(
      (invocation) async => saved[invocation.positionalArguments.single],
    );
    when(
      () => repository.createPlayer(
        name: any(named: 'name'),
        photoTempPath: any(named: 'photoTempPath'),
      ),
    ).thenAnswer((invocation) async {
      final name = invocation.namedArguments[#name] as String;
      return saved[name] = Player(id: 'id-$name', name: name);
    });
    when(
      () => repository.updatePlayer(
        any(),
        name: any(named: 'name'),
        photoTempPath: any(named: 'photoTempPath'),
      ),
    ).thenAnswer((invocation) async => invocation.positionalArguments.first);
    when(() => repository.photoPathOf(any())).thenAnswer((_) async => null);
    cubit = GameCubit(
      player1Name: 'Anna',
      player2Name: 'Bea',
      repository: repository,
    );
  });

  tearDown(() async => cubit.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(2400, 1080)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/game',
          builder: (context, state) => BlocProvider<GameCubit>.value(
            value: cubit,
            child: const GameView(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      RepositoryProvider<GwentRepository>.value(
        value: repository,
        child: MaterialApp.router(
          theme: AppTheme.data,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder nameField(int index) => find.descendant(
    of: find.byType(PlayerInputWidget).at(index),
    matching: find.byType(TextField),
  );

  String nameIn(WidgetTester tester, int index) =>
      tester.widget<TextField>(nameField(index)).controller!.text;

  Future<void> playGameToTheEnd(WidgetTester tester) async {
    cubit.onCardAdded(
      CardsRowType.closeCombat,
      Card(points: 5, abilities: const []),
    );
    cubit.onEndRoundTapped();
    cubit.onCardAdded(
      CardsRowType.closeCombat,
      Card(points: 7, abilities: const []),
    );
    cubit.onEndRoundTapped();
    await tester.pumpAndSettle();
    expect(find.text('Game Over'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('Rematch flow', () {
    testWidgets(
      '''
      Given names `Anna` and `Bea` were typed on the home screen and a game started
      When the game is played to the end and the game-over dialog is confirmed
      Then the same home screen is shown with both names still filled in
      ''',
      (tester) async {
        // Given
        await pumpApp(tester);
        await tester.enterText(nameField(0), 'Anna');
        await tester.enterText(nameField(1), 'Bea');
        await tester.tap(find.text('PLAY'));
        await tester.pumpAndSettle();
        expect(find.byType(GameView), findsOneWidget);
        final homeBefore = tester.element(
          find.byType(HomePage, skipOffstage: false),
        );

        // When
        await playGameToTheEnd(tester);

        // Then
        expect(find.byType(GameView), findsNothing);
        expect(tester.element(find.byType(HomePage)), same(homeBefore));
        expect(find.byType(PlayerInputWidget), findsNWidgets(2));
        expect(nameIn(tester, 0), 'Anna');
        expect(nameIn(tester, 1), 'Bea');
        verify(
          () => repository.createPlayer(
            name: 'Anna',
            photoTempPath: any(named: 'photoTempPath'),
          ),
        ).called(1);
        verify(
          () => repository.createPlayer(
            name: 'Bea',
            photoTempPath: any(named: 'photoTempPath'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '''
      Given `Anna` and `Bea` were saved by the first game and it was played to the end
      When Play is pressed again on the same home screen
      Then no player is created or updated a second time
      ''',
      (tester) async {
        // Given
        await pumpApp(tester);
        await tester.enterText(nameField(0), 'Anna');
        await tester.enterText(nameField(1), 'Bea');
        await tester.tap(find.text('PLAY'));
        await tester.pumpAndSettle();
        await playGameToTheEnd(tester);
        clearInteractions(repository);

        // When
        await tester.tap(find.text('PLAY'));
        await tester.pumpAndSettle();

        // Then
        expect(find.byType(GameView), findsOneWidget);
        verifyNever(
          () => repository.createPlayer(
            name: any(named: 'name'),
            photoTempPath: any(named: 'photoTempPath'),
          ),
        );
        verifyNever(
          () => repository.updatePlayer(
            any(),
            name: any(named: 'name'),
            photoTempPath: any(named: 'photoTempPath'),
          ),
        );
      },
    );
  });
}
