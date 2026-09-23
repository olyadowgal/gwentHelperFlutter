import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_cubit.dart';
import 'package:gwent_helper_flutter/features/scores/view/scores_view.dart';
import 'package:gwent_helper_flutter/features/scores/widgets/score_card_widget.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGwentRepository extends Mock implements GwentRepository {}

void main() {
  late _MockGwentRepository repository;
  late ScoresCubit cubit;

  setUp(() {
    repository = _MockGwentRepository();
    when(() => repository.getGames()).thenAnswer((_) async => []);
    cubit = ScoresCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: cubit, child: const ScoresView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ScoresView', () {
    testWidgets(
      '''
      Given the HUD theme
      When the scores screen is rendered
      Then its app bar and actions use panel, cream, and error colors
      ''',
      (tester) async {
        // When
        await pumpView(tester);

        // Then
        expect(
          tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
          AppTheme.panel,
        );
        expect(
          tester
              .widget<SvgPicture>(find.byKey(const Key('scores-back-icon')))
              .colorFilter,
          const ColorFilter.mode(AppTheme.cream, BlendMode.srcIn),
        );
        expect(
          tester
              .widget<SvgPicture>(find.byKey(const Key('scores-clear-icon')))
              .colorFilter,
          ColorFilter.mode(AppTheme.data.colorScheme.error, BlendMode.srcIn),
        );
      },
    );

    testWidgets(
      '''
      Given the clear-scores action
      When assistive technology reads the app bar
      Then it exposes one labelled long-press button
      ''',
      (tester) async {
        // Given
        final semantics = tester.ensureSemantics();

        // When
        await pumpView(tester);

        // Then
        expect(find.bySemanticsLabel('Clear All'), findsOneWidget);
        final node = tester.getSemantics(find.bySemanticsLabel('Clear All'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.longPress),
          isTrue,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      '''
      Given several saved games
      When the scores screen is rendered
      Then the cards line up side by side in a horizontally scrolling row
      ''',
      (tester) async {
        // Given
        final repo = _MockGwentRepository();
        final scores = List.generate(
          3,
          (i) => GameScore(
            date: DateTime(2026, 9, 1 + i),
            firstPlayer: 'Alice',
            secondPlayer: 'Bob',
            winner: Winner.first.name,
          ),
        );
        when(() => repo.getGames()).thenAnswer((_) async => scores);
        final scoresCubit = ScoresCubit(repository: repo);
        addTearDown(scoresCubit.close);

        // When
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.data,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider.value(
              value: scoresCubit,
              child: const ScoresView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        final list = tester.widget<ListView>(find.byType(ListView));
        expect(list.scrollDirection, Axis.horizontal);
        expect(find.byType(ScoreCardWidget), findsNWidgets(3));
        final cardFinder = find.byType(Card);
        final tops = {
          for (var i = 0; i < 3; i++) tester.getTopLeft(cardFinder.at(i)).dy,
        };
        expect(tops, hasLength(1));
      },
    );

    testWidgets(
      '''
      Given the scores list fills the body below the app bar
      When a card is rendered
      Then it stretches to that height, leaving only the 16px margin
      ''',
      (tester) async {
        // Given
        final repo = _MockGwentRepository();
        when(() => repo.getGames()).thenAnswer(
          (_) async => [
            GameScore(
              date: DateTime(2026, 9, 1),
              firstPlayer: 'Alice',
              secondPlayer: 'Bob',
              winner: Winner.first.name,
            ),
          ],
        );
        final scoresCubit = ScoresCubit(repository: repo);
        addTearDown(scoresCubit.close);

        // When
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.data,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider.value(
              value: scoresCubit,
              child: const ScoresView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        final listHeight = tester.getSize(find.byType(ListView)).height;
        // Card.margin is transparent space outside the visible card, so the
        // painted Material (not the Card element's own bounding box, which
        // includes that margin) is what should shrink by 16px top and bottom.
        final cardMaterial = tester.getSize(
          find
              .descendant(
                of: find.byType(Card),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(cardMaterial.height, closeTo(listHeight - 32, 1));
      },
    );
  });
}
