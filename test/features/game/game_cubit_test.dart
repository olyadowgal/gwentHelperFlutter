import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
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
          expect(state.selectedPlayer, SelectedPlayer.first);
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
          expect(cubit.state.selectedPlayer, SelectedPlayer.first);

          // When
          cubit.onPlayerSelected(SelectedPlayer.second);

          // Then
          expect(cubit.state.selectedPlayer, SelectedPlayer.second);
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
          cubit.onPlayerSelected(SelectedPlayer.second);

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
          cubit.onPlayerSelected(SelectedPlayer.second);
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
          cubit.onPlayerSelected(SelectedPlayer.second);
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
          cubit.onPlayerSelected(SelectedPlayer.second);
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
