import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/domain/scorch.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_cubit.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_side_effect.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_side_effect_handler.dart';

// region Mocks
class MockGwentRepository extends Mock implements GwentRepository {}
// endregion

Card createCard(int points, {String? id, List<Ability> abilities = const []}) =>
    Card(cardId: id, points: points, abilities: abilities);

void main() {
  late MockGwentRepository repository;
  late MockSideEffectHandler<GameSideEffect> sideEffectHandler;
  late GameCubit cubit;
  late StreamSubscription<GameState> subscription;

  setUpAll(() {
    registerFallbackValue(
      GameScore(
        date: DateTime(2026),
        firstPlayer: '',
        secondPlayer: '',
        winner: '',
      ),
    );
    registerFallbackValue(const NavigateBack());
  });

  setUp(() {
    repository = MockGwentRepository();
    when(() => repository.addGame(any())).thenAnswer((_) async {});
  });

  setUp(() => sideEffectHandler = MockSideEffectHandler<GameSideEffect>());

  setUp(() {
    cubit = GameCubit(
      player1Name: 'Alice',
      player2Name: 'Bob',
      repository: repository,
    );
    subscription = attachSideEffectHandler(cubit, sideEffectHandler);
  });

  tearDown(() async {
    await subscription.cancel();
    await cubit.close();
  });

  group('GameCubit', () {
    group('initial state', () {
      test(
        '''
      Given player names
      When `GameCubit` is created
      Then players are named with 2 lives, empty rows, first selected, round 0
      ''',
        () {
          // Then
          final state = cubit.state;
          expect(state.gameData.firstPlayerData.name, 'Alice');
          expect(state.gameData.secondPlayerData.name, 'Bob');
          expect(state.gameData.firstPlayerData.lives, 2);
          expect(state.gameData.secondPlayerData.lives, 2);
          expect(state.gameData.firstPlayerData.totalPoints, 0);
          expect(state.selectedPlayer, PlayerSide.first);
          expect(state.roundCounter, 0);
          expect(state.gameOver, isNull);
          expect(state.sideEffects, isEmpty);
        },
      );
    });

    group('`onPlayerSelected`', () {
      test(
        '''
      Given the first player is selected
      When `onPlayerSelected` is called with the second player
      Then `selectedPlayer` switches and `selectedPlayerData` follows
      ''',
        () {
          // Given
          expect(cubit.state.selectedPlayer, PlayerSide.first);

          // When
          cubit.onPlayerSelected(PlayerSide.second);

          // Then
          expect(cubit.state.selectedPlayer, PlayerSide.second);
          expect(cubit.state.selectedPlayerData.name, 'Bob');
        },
      );
    });

    group('`onAddCardRequested`', () {
      test(
        '''
      Given a fresh game
      When `onAddCardRequested` is called
      Then `ShowAddCardDialog` is emitted
      ''',
        () async {
          // When
          cubit.onAddCardRequested(CardsRowType.siege);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const ShowAddCardDialog(CardsRowType.siege),
            ),
          ).called(1);
        },
      );
    });

    group('`onCardAdded`', () {
      test(
        '''
      Given the first player is selected
      When `onCardAdded` is called
      Then the card is appended to the selected player row only
      ''',
        () {
          // When
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));

          // Then
          final p1Row = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.closeCombat]!;
          final p2Row = cubit
              .state
              .gameData
              .secondPlayerData
              .cardsRows[CardsRowType.closeCombat]!;
          expect(p1Row.cards, hasLength(1));
          expect(p2Row.cards, isEmpty);
        },
      );

      test(
        '''
      Given the second player is selected
      When `onCardAdded` is called
      Then the card goes to the second player row
      ''',
        () {
          // Given
          cubit.onPlayerSelected(PlayerSide.second);

          // When
          cubit.onCardAdded(CardsRowType.longRange, createCard(3));

          // Then
          final p1Row = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.longRange]!;
          final p2Row = cubit
              .state
              .gameData
              .secondPlayerData
              .cardsRows[CardsRowType.longRange]!;
          expect(p1Row.cards, isEmpty);
          expect(p2Row.cards, hasLength(1));
        },
      );

      test(
        '''
      Given a Spy card
      When `onCardAdded` is called
      Then the card is placed on the other player's same row
      ''',
        () {
          // Given
          final spy = createCard(9, id: 'spy', abilities: [Ability.spy]);

          // When
          cubit.onCardAdded(CardsRowType.closeCombat, spy);

          // Then
          final p1Row = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.closeCombat]!;
          final p2Row = cubit
              .state
              .gameData
              .secondPlayerData
              .cardsRows[CardsRowType.closeCombat]!;
          expect(p1Row.cards, isEmpty);
          expect(p2Row.cards.single.cardId, 'spy');
          expect(cubit.state.gameData.secondPlayerData.totalPoints, 9);
          expect(cubit.state.gameData.firstPlayerData.totalPoints, 0);
        },
      );

      test(
        '''
      Given a Muster card
      When `onCardAdded` is called
      Then `ShowMusterCountDialog` is emitted for the owner
      ''',
        () async {
          // Given
          final card = createCard(4, id: 'm1', abilities: [Ability.muster]);

          // When
          cubit.onCardAdded(CardsRowType.siege, card);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              ShowMusterCountDialog(CardsRowType.siege, card, PlayerSide.first),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given a row-Scorch unit and an enemy row totaling 9
      When `onCardAdded` is called
      Then `ShowNoScorchTargets` with `rowBelowTen` is emitted
      ''',
        () async {
          // Given
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(9, id: 'b9'));
          cubit.onPlayerSelected(PlayerSide.first);

          // When
          cubit.onCardAdded(
            CardsRowType.closeCombat,
            createCard(7, id: 'vt', abilities: [Ability.scorchRow]),
          );
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const ShowNoScorchTargets(ScorchNoTargetReason.rowBelowTen),
            ),
          ).called(1);
          expect(cubit.state.scorchPrompt, isNull);
        },
      );

      test(
        '''
      Given a row-Scorch unit and an enemy row totaling 10
      When `onCardAdded` is called
      Then a prompt lists the strongest non-hero units on that row
      ''',
        () {
          // Given
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(6, id: 'b6'));
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(4, id: 'b4'));
          cubit.onPlayerSelected(PlayerSide.first);

          // When
          cubit.onCardAdded(
            CardsRowType.closeCombat,
            createCard(7, id: 'vt', abilities: [Ability.scorchRow]),
          );

          // Then
          expect(cubit.state.scorchPrompt?.targets, [
            const ScorchTarget(
              side: PlayerSide.second,
              rowType: CardsRowType.closeCombat,
              cardId: 'b6',
            ),
          ]);
        },
      );

      test(
        '''
      Given a row-Scorch unit and an enemy row of heroes totaling 10
      When `onCardAdded` is called
      Then `ShowNoScorchTargets` with `nothingToScorch` is emitted
      ''',
        () async {
          // Given
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(
            CardsRowType.closeCombat,
            createCard(10, id: 'hero', abilities: [Ability.hero]),
          );
          cubit.onPlayerSelected(PlayerSide.first);

          // When
          cubit.onCardAdded(
            CardsRowType.closeCombat,
            createCard(7, id: 'vt', abilities: [Ability.scorchRow]),
          );
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const ShowNoScorchTargets(ScorchNoTargetReason.nothingToScorch),
            ),
          ).called(1);
          expect(cubit.state.scorchPrompt, isNull);
        },
      );

      test(
        '''
      Given the game is over
      When `onCardAdded` is called
      Then the board is unchanged
      ''',
        () async {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));
          cubit.onEndRoundTapped();
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(7));
          cubit.onEndRoundTapped();
          await Future<void>.delayed(Duration.zero);
          final before = cubit.state.gameData;

          // When
          cubit.onCardAdded(
            CardsRowType.closeCombat,
            createCard(3, id: 'late'),
          );

          // Then
          expect(identical(cubit.state.gameData, before), isTrue);
        },
      );
    });

    group('`onMusterCountChosen`', () {
      test(
        '''
      Given a Muster card was just added
      When `onMusterCountChosen` is called with 3
      Then three extra copies are appended with unique ids
      ''',
        () {
          // Given
          final card = createCard(4, id: 'm1', abilities: [Ability.muster]);
          cubit.onCardAdded(CardsRowType.siege, card);

          // When
          cubit.onMusterCountChosen(
            CardsRowType.siege,
            card,
            3,
            PlayerSide.first,
          );

          // Then
          final row = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.siege]!;
          expect(row.cards, hasLength(4));
          expect(row.cards.map((c) => c.cardId).toSet(), hasLength(4));
          expect(row.cards.every((c) => c.points == 4), isTrue);
          expect(
            row.cards.every((c) => c.abilities.contains(Ability.muster)),
            isTrue,
          );
        },
      );

      test(
        '''
      Given a Spy Muster card on the opponent row
      When `onMusterCountChosen` is called
      Then copies stay on the opponent row
      ''',
        () {
          // Given
          final card = createCard(
            5,
            id: 'sm',
            abilities: [Ability.spy, Ability.muster],
          );
          cubit.onCardAdded(CardsRowType.longRange, card);

          // When
          cubit.onMusterCountChosen(
            CardsRowType.longRange,
            card,
            2,
            PlayerSide.first,
          );

          // Then
          final p1 = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.longRange]!;
          final p2 = cubit
              .state
              .gameData
              .secondPlayerData
              .cardsRows[CardsRowType.longRange]!;
          expect(p1.cards, isEmpty);
          expect(p2.cards, hasLength(3));
        },
      );

      test(
        '''
      Given an invalid extra-copy count
      When `onMusterCountChosen` is called
      Then no copies are added
      ''',
        () {
          // Given
          final card = createCard(4, id: 'm1', abilities: [Ability.muster]);
          cubit.onCardAdded(CardsRowType.siege, card);

          // When
          cubit.onMusterCountChosen(
            CardsRowType.siege,
            card,
            0,
            PlayerSide.first,
          );
          cubit.onMusterCountChosen(
            CardsRowType.siege,
            card,
            5,
            PlayerSide.first,
          );

          // Then
          expect(
            cubit
                .state
                .gameData
                .firstPlayerData
                .cardsRows[CardsRowType.siege]!
                .cards,
            hasLength(1),
          );
        },
      );
    });

    group('`onEditCardRequested`', () {
      test(
        '''
      Given a card in a row
      When `onEditCardRequested` is called
      Then `ShowEditCardDialog` is emitted
      ''',
        () async {
          // Given
          final card = createCard(5);
          cubit.onCardAdded(CardsRowType.closeCombat, card);
          final row = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.closeCombat]!;

          // When
          cubit.onEditCardRequested(row, card);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(ShowEditCardDialog(row, card)),
          ).called(1);
        },
      );
    });

    group('`onCardEdited`', () {
      test(
        '''
      Given two cards in a row
      When `onCardEdited` is called
      Then only the card with matching `cardId` is replaced
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'c1'));
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(3, id: 'c2'));

          // When
          cubit.onCardEdited(CardsRowType.closeCombat, createCard(9, id: 'c1'));

          // Then
          final cards = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.closeCombat]!
              .cards;
          expect(cards.firstWhere((c) => c.cardId == 'c1').points, 9);
          expect(cards.firstWhere((c) => c.cardId == 'c2').points, 3);
        },
      );
    });

    group('`onCardDeleted`', () {
      test(
        '''
      Given two cards in a row
      When `onCardDeleted` is called
      Then only the card with matching `cardId` is removed
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.siege, createCard(5, id: 'c1'));
          cubit.onCardAdded(CardsRowType.siege, createCard(3, id: 'c2'));

          // When
          cubit.onCardDeleted(CardsRowType.siege, createCard(5, id: 'c1'));

          // Then
          final cards = cubit
              .state
              .gameData
              .firstPlayerData
              .cardsRows[CardsRowType.siege]!
              .cards;
          expect(cards.map((c) => c.cardId), ['c2']);
        },
      );
    });

    group('`onHornChanged`', () {
      test(
        '''
      Given a fresh game
      When `onHornChanged` is called
      Then `horn` is set on the selected player specified row only
      ''',
        () {
          // When
          cubit.onHornChanged(CardsRowType.longRange, true);

          // Then
          final p1 = cubit.state.gameData.firstPlayerData;
          final p2 = cubit.state.gameData.secondPlayerData;
          expect(p1.cardsRows[CardsRowType.longRange]!.horn, isTrue);
          expect(p1.cardsRows[CardsRowType.closeCombat]!.horn, isFalse);
          expect(p2.cardsRows[CardsRowType.longRange]!.horn, isFalse);
        },
      );
    });

    group('`onWeatherChanged`', () {
      test(
        '''
      Given a fresh game
      When `onWeatherChanged` is called
      Then `badWeather` is set on the same row for both players
      ''',
        () {
          // When
          cubit.onWeatherChanged(CardsRowType.closeCombat, true);

          // Then
          final p1 = cubit.state.gameData.firstPlayerData;
          final p2 = cubit.state.gameData.secondPlayerData;
          expect(p1.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
          expect(p2.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
          expect(p1.cardsRows[CardsRowType.siege]!.badWeather, isFalse);
        },
      );
    });

    group('`onScorchTapped`', () {
      test(
        '''
      Given tied strongest non-hero units on both sides and a stronger hero
      When `onScorchTapped` is called
      Then a prompt holds exactly the tied non-hero targets
      ''',
        () async {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(8, id: 'a8'));
          cubit.onCardAdded(
            CardsRowType.longRange,
            createCard(10, id: 'aHero', abilities: const [Ability.hero]),
          );
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.siege, createCard(8, id: 'b8'));

          // When
          cubit.onScorchTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(
            cubit.state.scorchPrompt?.targets,
            unorderedEquals(const [
              ScorchTarget(
                side: PlayerSide.first,
                rowType: CardsRowType.closeCombat,
                cardId: 'a8',
              ),
              ScorchTarget(
                side: PlayerSide.second,
                rowType: CardsRowType.siege,
                cardId: 'b8',
              ),
            ]),
          );
          verifyZeroInteractions(sideEffectHandler);
        },
      );

      test(
        '''
      Given an empty battlefield
      When `onScorchTapped` is called
      Then `ShowNoScorchTargets` explains there is nothing to scorch
      ''',
        () async {
          // When
          cubit.onScorchTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.scorchPrompt, isNull);
          verify(
            () => sideEffectHandler.call(
              const ShowNoScorchTargets(ScorchNoTargetReason.nothingToScorch),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given a prompt whose only target was deleted from the board
      When `onScorchTapped` is called again
      Then the stale prompt is cleared and `ShowNoScorchTargets` is emitted
      ''',
        () async {
          // Given
          final card = createCard(8, id: 'a8');
          cubit.onCardAdded(CardsRowType.closeCombat, card);
          cubit.onScorchTapped();
          expect(cubit.state.scorchPrompt, isNotNull);
          cubit.onCardDeleted(CardsRowType.closeCombat, card);

          // When
          cubit.onScorchTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.scorchPrompt, isNull);
          verify(
            () => sideEffectHandler.call(
              const ShowNoScorchTargets(ScorchNoTargetReason.nothingToScorch),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given the game is over
      When `onScorchTapped` is called
      Then no prompt is created and no side effect is emitted
      ''',
        () async {
          // Given
          cubit.onEndRoundTapped(); // tie: both 2→1
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'a5'));
          cubit.onEndRoundTapped(); // Bob 1→0 → game over
          await Future<void>.delayed(Duration.zero);

          // When
          cubit.onScorchTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.scorchPrompt, isNull);
          verifyNever(
            () => sideEffectHandler.call(any(that: isA<ShowNoScorchTargets>())),
          );
        },
      );
    });

    group('`onScorchTargetTapped`', () {
      test(
        '''
      Given a prompt with targets on both sides
      When `onScorchTargetTapped` is called with one of them
      Then only that card is removed and the prompt keeps the other target
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(8, id: 'a8'));
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(3, id: 'a3'));
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.siege, createCard(8, id: 'b8'));
          cubit.onScorchTapped();
          const target = ScorchTarget(
            side: PlayerSide.first,
            rowType: CardsRowType.closeCombat,
            cardId: 'a8',
          );

          // When
          cubit.onScorchTargetTapped(target);

          // Then
          final data = cubit.state.gameData;
          expect(
            data.firstPlayerData.cardsRows[CardsRowType.closeCombat]!.cards.map(
              (c) => c.cardId,
            ),
            ['a3'],
          );
          expect(
            data.secondPlayerData.cardsRows[CardsRowType.siege]!.cards.map(
              (c) => c.cardId,
            ),
            ['b8'],
          );
          expect(cubit.state.scorchPrompt?.targets, const [
            ScorchTarget(
              side: PlayerSide.second,
              rowType: CardsRowType.siege,
              cardId: 'b8',
            ),
          ]);
        },
      );

      test(
        '''
      Given a prompt with a single target
      When `onScorchTargetTapped` removes it
      Then the card is gone and the prompt is cleared
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.siege, createCard(8, id: 'a8'));
          cubit.onScorchTapped();
          final target = cubit.state.scorchPrompt!.targets.single;

          // When
          cubit.onScorchTargetTapped(target);

          // Then
          expect(
            cubit
                .state
                .gameData
                .firstPlayerData
                .cardsRows[CardsRowType.siege]!
                .cards,
            isEmpty,
          );
          expect(cubit.state.scorchPrompt, isNull);
        },
      );

      test(
        '''
      Given a prompt that does not list a card
      When `onScorchTargetTapped` is called with that card
      Then the board and the prompt are unchanged
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(8, id: 'a8'));
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(3, id: 'a3'));
          cubit.onScorchTapped();
          final stateBefore = cubit.state;

          // When
          cubit.onScorchTargetTapped(
            const ScorchTarget(
              side: PlayerSide.first,
              rowType: CardsRowType.closeCombat,
              cardId: 'a3',
            ),
          );

          // Then
          expect(cubit.state, same(stateBefore));
        },
      );

      test(
        '''
      Given a target that was already scorched
      When `onScorchTargetTapped` is called with it again
      Then nothing changes
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(8, id: 'a8'));
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.siege, createCard(8, id: 'b8'));
          cubit.onScorchTapped();
          const target = ScorchTarget(
            side: PlayerSide.first,
            rowType: CardsRowType.closeCombat,
            cardId: 'a8',
          );
          cubit.onScorchTargetTapped(target);
          final stateBefore = cubit.state;

          // When
          cubit.onScorchTargetTapped(target);

          // Then
          expect(cubit.state, same(stateBefore));
        },
      );

      test(
        '''
      Given a prompt whose round ended before the target was tapped
      When `onScorchTargetTapped` is called with the now-stale target
      Then the prompt is already gone and the card stays on the board
      ''',
        () async {
          // Given
          cubit.onEndRoundTapped(); // tie: both 2→1
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'a5'));
          cubit.onScorchTapped();
          final target = cubit.state.scorchPrompt!.targets.single;
          cubit.onEndRoundTapped(); // Bob 1→0 → game over
          await Future<void>.delayed(Duration.zero);

          // When
          cubit.onScorchTargetTapped(target);

          // Then
          expect(cubit.state.scorchPrompt, isNull);
          expect(
            cubit
                .state
                .gameData
                .firstPlayerData
                .cardsRows[CardsRowType.closeCombat]!
                .cards
                .map((c) => c.cardId),
            ['a5'],
          );
        },
      );
    });

    group('`onScorchPickCancelled`', () {
      test(
        '''
      Given a prompt with remaining targets
      When `onScorchPickCancelled` is called
      Then the prompt is cleared and no card is removed
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(8, id: 'a8'));
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.siege, createCard(8, id: 'b8'));
          cubit.onScorchTapped();
          expect(cubit.state.scorchPrompt?.targets, hasLength(2));

          // When
          cubit.onScorchPickCancelled();

          // Then
          final data = cubit.state.gameData;
          expect(cubit.state.scorchPrompt, isNull);
          expect(
            data.firstPlayerData.cardsRows[CardsRowType.closeCombat]!.cards.map(
              (c) => c.cardId,
            ),
            ['a8'],
          );
          expect(
            data.secondPlayerData.cardsRows[CardsRowType.siege]!.cards.map(
              (c) => c.cardId,
            ),
            ['b8'],
          );
        },
      );

      test(
        '''
      Given no prompt
      When `onScorchPickCancelled` is called
      Then nothing changes
      ''',
        () {
          // Given
          final stateBefore = cubit.state;

          // When
          cubit.onScorchPickCancelled();

          // Then
          expect(cubit.state, same(stateBefore));
        },
      );

      test(
        '''
      Given a prompt whose round ended before it was cancelled
      When `onScorchPickCancelled` is called
      Then nothing changes because the round already cleared the prompt
      ''',
        () async {
          // Given
          cubit.onEndRoundTapped(); // tie: both 2→1
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'a5'));
          cubit.onScorchTapped();
          cubit.onEndRoundTapped(); // Bob 1→0 → game over
          await Future<void>.delayed(Duration.zero);
          final stateBefore = cubit.state;
          expect(stateBefore.scorchPrompt, isNull);

          // When
          cubit.onScorchPickCancelled();

          // Then
          expect(cubit.state, same(stateBefore));
        },
      );
    });

    group('`onEndRoundTapped`', () {
      test(
        '''
      Given the first player has more points
      When `onEndRoundTapped` is called
      Then the loser loses a life and the winner keeps lives
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));

          // When
          cubit.onEndRoundTapped();

          // Then
          expect(cubit.state.gameData.firstPlayerData.lives, 2);
          expect(cubit.state.gameData.secondPlayerData.lives, 1);
        },
      );

      test(
        '''
      Given equal points
      When `onEndRoundTapped` is called
      Then both players lose a life
      ''',
        () {
          // When
          cubit.onEndRoundTapped();

          // Then
          expect(cubit.state.gameData.firstPlayerData.lives, 1);
          expect(cubit.state.gameData.secondPlayerData.lives, 1);
        },
      );

      test(
        '''
      Given the second player has more points
      When `onEndRoundTapped` is called
      Then the first player loses a life
      ''',
        () {
          // Given
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));

          // When
          cubit.onEndRoundTapped();

          // Then
          expect(cubit.state.gameData.firstPlayerData.lives, 1);
          expect(cubit.state.gameData.secondPlayerData.lives, 2);
        },
      );

      test(
        '''
      Given a non-fatal round
      When `onEndRoundTapped` is called
      Then cards are cleared and the round is recorded in `roundsData`
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.siege, createCard(2));

          // When
          cubit.onEndRoundTapped();

          // Then
          final state = cubit.state;
          expect(state.roundCounter, 1);
          expect(state.roundsData.firstRoundFirst, 5);
          expect(state.roundsData.firstRoundSecond, 2);
          expect(state.gameData.firstPlayerData.totalPoints, 0);
          expect(state.gameData.secondPlayerData.totalPoints, 0);
          expect(state.gameOver, isNull);
        },
      );

      test(
        '''
      Given the losing player has one life left
      When `onEndRoundTapped` is called
      Then `ShowGameOverDialog` is emitted and the board is not cleared
      ''',
        () async {
          // Given: round 1 — Alice wins, Bob 2→1
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));
          cubit.onEndRoundTapped();
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));

          // When: round 2 — Alice wins again, Bob 1→0 → game over
          cubit.onEndRoundTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.gameOver, Winner.first);
          verify(
            () =>
                sideEffectHandler.call(const ShowGameOverDialog(Winner.first)),
          ).called(1);
          // On game over the final board is preserved (not cleared).
          expect(cubit.state.gameData.firstPlayerData.totalPoints, 5);
        },
      );

      test(
        '''
      Given the first player has one life left and loses
      When `onEndRoundTapped` is called
      Then `gameOver` is `Winner.second`
      ''',
        () async {
          // Given
          cubit.onPlayerSelected(PlayerSide.second);
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));
          cubit.onEndRoundTapped(); // Alice 2→1
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));

          // When
          cubit.onEndRoundTapped(); // Alice 1→0 → game over
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.gameOver, Winner.second);
          verify(
            () =>
                sideEffectHandler.call(const ShowGameOverDialog(Winner.second)),
          ).called(1);
        },
      );

      test(
        '''
      Given both players have one life left
      When a tie round ends
      Then `gameOver` is `Winner.tie`
      ''',
        () async {
          // Given
          cubit.onEndRoundTapped(); // tie: both 2→1

          // When
          cubit.onEndRoundTapped(); // tie: both 1→0 → game over tie
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.gameOver, Winner.tie);
          verify(
            () => sideEffectHandler.call(const ShowGameOverDialog(Winner.tie)),
          ).called(1);
        },
      );

      test(
        '''
      Given the game is over
      When `onEndRoundTapped` is called again
      Then nothing changes
      ''',
        () {
          // Given
          cubit.onEndRoundTapped();
          cubit.onEndRoundTapped(); // game over (tie)
          final roundsBefore = cubit.state.roundCounter;

          // When
          cubit.onEndRoundTapped();

          // Then
          expect(cubit.state.roundCounter, roundsBefore);
        },
      );

      test(
        '''
      Given an open Scorch prompt
      When `onEndRoundTapped` ends a non-terminal round
      Then the prompt is cleared along with the board
      ''',
        () {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'a5'));
          cubit.onScorchTapped();
          expect(cubit.state.scorchPrompt, isNotNull);

          // When
          cubit.onEndRoundTapped(); // Bob 2→1, board cleared

          // Then
          expect(cubit.state.gameOver, isNull);
          expect(cubit.state.scorchPrompt, isNull);
        },
      );

      test(
        '''
      Given an open Scorch prompt
      When `onEndRoundTapped` ends the game
      Then the prompt is cleared so no stale target survives game over
      ''',
        () async {
          // Given
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'a5'));
          cubit.onEndRoundTapped(); // Bob 2→1
          cubit.onCardAdded(CardsRowType.closeCombat, createCard(5, id: 'a6'));
          cubit.onScorchTapped();
          expect(cubit.state.scorchPrompt, isNotNull);

          // When
          cubit.onEndRoundTapped(); // Bob 1→0 → game over
          await Future<void>.delayed(Duration.zero);

          // Then
          expect(cubit.state.gameOver, Winner.first);
          expect(cubit.state.scorchPrompt, isNull);
        },
      );
    });

    group('`onGameOverConfirmed`', () {
      Future<void> playToGameOver() async {
        cubit.onCardAdded(CardsRowType.closeCombat, createCard(5));
        cubit.onEndRoundTapped(); // Bob 2→1
        cubit.onCardAdded(CardsRowType.closeCombat, createCard(7));
        cubit.onEndRoundTapped(); // Bob 1→0 → game over Winner.first
        await Future<void>.delayed(Duration.zero);
      }

      test(
        '''
      Given the game is over
      When `onGameOverConfirmed` is called
      Then the score is saved once and `NavigateBack` is emitted
      ''',
        () async {
          // Given
          await playToGameOver();

          // When
          await cubit.onGameOverConfirmed();
          await Future<void>.delayed(Duration.zero);

          // Then
          final captured = verify(
            () => repository.addGame(captureAny()),
          ).captured;
          expect(captured, hasLength(1));
          final score = captured.single as GameScore;
          expect(score.firstPlayer, 'Alice');
          expect(score.secondPlayer, 'Bob');
          expect(score.winner, 'first');
          expect(score.firstRoundFirstPlayerPoints, 5);
          expect(score.secondRoundFirstPlayerPoints, 7);
          expect(score.thirdRoundFirstPlayerPoints, isNull);
          expect(score.firstRoundSecondPlayerPoints, 0);
          verify(() => sideEffectHandler.call(const NavigateBack())).called(1);
        },
      );

      test(
        '''
      Given the score was already saved
      When `onGameOverConfirmed` is called again
      Then it does not save again
      ''',
        () async {
          // Given
          await playToGameOver();
          await cubit.onGameOverConfirmed();

          // When
          await cubit.onGameOverConfirmed();

          // Then
          verify(() => repository.addGame(any())).called(1);
        },
      );

      test(
        '''
      Given the game is not over
      When `onGameOverConfirmed` is called
      Then nothing happens
      ''',
        () async {
          // When
          await cubit.onGameOverConfirmed();
          await Future<void>.delayed(Duration.zero);

          // Then
          verifyZeroInteractions(repository);
          verifyZeroInteractions(sideEffectHandler);
        },
      );

      test(
        '''
      Given `addGame` throws
      When `onGameOverConfirmed` is called
      Then the score is not marked saved and `ShowSaveFailed` is emitted
      ''',
        () async {
          // Given
          await playToGameOver();
          when(
            () => repository.addGame(any()),
          ).thenThrow(Exception('disk full'));

          // When
          await cubit.onGameOverConfirmed();
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(() => repository.addGame(any())).called(1);
          verifyNever(() => sideEffectHandler.call(const NavigateBack()));
          verify(
            () => sideEffectHandler.call(any(that: isA<ShowSaveFailed>())),
          ).called(1);
        },
      );

      test(
        '''
      Given a previous save failed
      When `onGameOverConfirmed` is called again and save succeeds
      Then the score is saved and `NavigateBack` is emitted
      ''',
        () async {
          // Given
          await playToGameOver();
          when(
            () => repository.addGame(any()),
          ).thenThrow(Exception('disk full'));
          await cubit.onGameOverConfirmed();
          await Future<void>.delayed(Duration.zero);
          when(() => repository.addGame(any())).thenAnswer((_) async {});

          // When
          await cubit.onGameOverConfirmed();
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(() => repository.addGame(any())).called(2);
          verify(() => sideEffectHandler.call(const NavigateBack())).called(1);
        },
      );
    });
  });
}
