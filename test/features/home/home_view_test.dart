import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_cubit.dart';
import 'package:gwent_helper_flutter/features/home/view/home_view.dart';
import 'package:gwent_helper_flutter/features/home/widgets/player_input_widget.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:gwent_helper_flutter/widgets/hud/hud_avatar.dart';
import 'package:mocktail/mocktail.dart';

class MockGwentRepository extends Mock implements GwentRepository {}

void main() {
  late MockGwentRepository repository;
  late HomeCubit cubit;
  late GoRouter router;
  Object? gameExtra;

  final anna = Player(id: 'anna-id', name: 'Anna', photoFile: 'anna.jpg');
  final oleh = Player(id: 'oleh-id', name: 'Олег');
  const missingPhotoPath = '/definitely/not/on/disk/anna.jpg';

  setUpAll(() => registerFallbackValue(Player(name: 'fallback')));

  setUp(() {
    repository = MockGwentRepository();
    when(() => repository.getPlayers()).thenAnswer((_) async => [anna, oleh]);
    when(
      () => repository.photoPathOf(anna),
    ).thenAnswer((_) async => missingPhotoPath);
    when(() => repository.photoPathOf(oleh)).thenAnswer((_) async => null);
    cubit = HomeCubit(repository: repository);
    gameExtra = null;
  });
  tearDown(() => cubit.close());

  Future<void> pumpHomeView(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(2400, 1080)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<HomeCubit>.value(
            value: cubit,
            child: const HomeView(),
          ),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            gameExtra = state.extra;
            return const Scaffold(body: Text('game'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.data,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
  }

  Finder card(String hint) => find.byKey(Key('player-input-$hint'));

  Finder chipOf(String hint) =>
      find.descendant(of: card(hint), matching: find.text('Saved players'));

  Finder fieldOf(String hint) =>
      find.descendant(of: card(hint), matching: find.byType(TextField));

  String fieldText(WidgetTester tester, String hint) =>
      tester.widget<TextField>(fieldOf(hint)).controller!.text;

  Future<void> openSheet(WidgetTester tester, String hint) async {
    await tester.tap(chipOf(hint));
    await tester.pumpAndSettle();
  }

  group('HomeView photo source dialog', () {
    testWidgets(
      '''
      Given the home screen is rendered
      When a player's avatar is tapped
      Then a dialog offers Camera and Gallery
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);

        // When
        await tester.tap(find.byType(PlayerInputWidget).first);
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Choose Photo'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Gallery'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given the photo source dialog is open
      When the barrier is tapped
      Then the dialog closes without changing either photo
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);
        await tester.tap(find.byType(PlayerInputWidget).first);
        await tester.pumpAndSettle();

        // When
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Choose Photo'), findsNothing);
        expect(cubit.state.player1PhotoPath, isNull);
        expect(cubit.state.player2PhotoPath, isNull);
      },
    );
  });

  group('HomeView saved players sheet', () {
    testWidgets(
      '''
      Given the home screen is rendered
      When the first card's "Saved players" chip is tapped
      Then a sheet lists every saved player and a "New player" row
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);

        // When
        await openSheet(tester, 'Player 1');

        // Then
        expect(find.text('Anna'), findsOneWidget);
        expect(find.text('Олег'), findsOneWidget);
        expect(find.text('New player'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given there are no saved players
      When the "Saved players" chip is tapped
      Then the sheet shows only the "New player" row
      ''',
      (tester) async {
        // Given
        when(() => repository.getPlayers()).thenAnswer((_) async => []);
        await pumpHomeView(tester);

        // When
        await openSheet(tester, 'Player 1');

        // Then
        expect(find.text('New player'), findsOneWidget);
        expect(find.text('Anna'), findsNothing);
        expect(find.byType(HudAvatar), findsNWidgets(2)); // cards only
      },
    );

    testWidgets(
      '''
      Given a saved player whose photo file is missing on disk
      When the sheet is opened
      Then the row still renders with its name and nothing throws
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);

        // When
        await openSheet(tester, 'Player 1');
        await tester.pump(const Duration(seconds: 1));

        // Then
        expect(find.text('Anna'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given the sheet is open for the first card
      When a saved player is tapped
      Then the sheet closes and only that card's field shows the name
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);
        await openSheet(tester, 'Player 1');

        // When
        await tester.tap(find.text('Олег'));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('New player'), findsNothing);
        expect(fieldText(tester, 'Player 1'), 'Олег');
        expect(fieldText(tester, 'Player 2'), '');
        expect(cubit.state.player1Id, 'oleh-id');
      },
    );

    testWidgets(
      '''
      Given a saved player is selected on the first card
      When "New player" is chosen for that card
      Then its field is cleared and the saved link is dropped
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);
        await openSheet(tester, 'Player 1');
        await tester.tap(find.text('Олег'));
        await tester.pumpAndSettle();
        await openSheet(tester, 'Player 1');

        // When
        await tester.tap(find.text('New player'));
        await tester.pumpAndSettle();

        // Then
        expect(fieldText(tester, 'Player 1'), '');
        expect(cubit.state.player1Id, isNull);
      },
    );

    testWidgets(
      '''
      Given the sheet is open
      When the barrier is tapped
      Then the sheet closes and nothing changes
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);
        await tester.enterText(fieldOf('Player 1'), 'Typed');
        await openSheet(tester, 'Player 1');

        // When
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('New player'), findsNothing);
        expect(fieldText(tester, 'Player 1'), 'Typed');
        expect(cubit.state.player1Id, isNull);
      },
    );

    testWidgets(
      '''
      Given the first card has the saved player selected
      When the second card's chip is tapped
      Then the sheet does not offer that player again
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);
        await openSheet(tester, 'Player 1');
        await tester.tap(find.text('Олег'));
        await tester.pumpAndSettle();

        // When
        await openSheet(tester, 'Player 2');

        // Then
        expect(find.text('Anna'), findsOneWidget);
        expect(find.text('New player'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Олег'),
          ),
          findsNothing,
        );
      },
    );
  });

  group('HomeView name field sync', () {
    testWidgets(
      '''
      Given a lower-case name typed that matches the saved player "Олег"
      When PLAY is tapped and the game is left again
      Then the field shows "Олег" and tapping into it keeps the saved spelling
      And the game route carries the saved player's id
      ''',
      (tester) async {
        // Given
        when(
          () => repository.findPlayerByName('олег'),
        ).thenAnswer((_) async => oleh);
        await pumpHomeView(tester);
        await tester.enterText(fieldOf('Player 1'), 'олег');

        // When
        await tester.tap(find.text('PLAY'));
        await tester.pumpAndSettle();
        router.pop();
        await tester.pumpAndSettle();

        // Then
        expect((gameExtra! as Map)['player1Id'], 'oleh-id');
        expect((gameExtra! as Map)['player2Id'], isNull);
        expect(fieldText(tester, 'Player 1'), 'Олег');
        expect(cubit.state.player1Name, 'Олег');

        // When
        await tester.tap(fieldOf('Player 1'));
        await tester.pump();

        // Then
        expect(fieldText(tester, 'Player 1'), 'Олег');
        expect(cubit.state.player1Name, 'Олег');
      },
    );
  });
}
