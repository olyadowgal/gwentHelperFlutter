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

class MockGwentRepository extends Mock implements GwentRepository {}

Card card(int points, {String? id, List<Ability> abilities = const []}) =>
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

  group('initial state', () {
    test('players named, 2 lives, empty rows, first selected, round 0', () {
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
    });
  });

  group('`onPlayerSelected`', () {
    test('switches `selectedPlayer` and `selectedPlayerData` follows', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      expect(cubit.state.selectedPlayer, SelectedPlayer.second);
      expect(cubit.state.selectedPlayerData.name, 'Bob');
    });
  });

  group('`onAddCardRequested`', () {
    test('emits `ShowAddCardDialog`', () async {
      cubit.onAddCardRequested(CardsRowType.siege);
      await Future<void>.delayed(Duration.zero);
      verify(
        () =>
            sideEffectHandler.call(const ShowAddCardDialog(CardsRowType.siege)),
      ).called(1);
    });
  });

  group('`onCardAdded`', () {
    test('appends to selected player row only', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
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
    });

    test('adds to second player when selected', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      cubit.onCardAdded(CardsRowType.longRange, card(3));
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
    });
  });

  group('`onEditCardRequested`', () {
    test('emits `ShowEditCardDialog`', () async {
      final c = card(5);
      cubit.onCardAdded(CardsRowType.closeCombat, c);
      final row = cubit
          .state
          .gameData
          .firstPlayerData
          .cardsRows[CardsRowType.closeCombat]!;
      cubit.onEditCardRequested(row, c);
      await Future<void>.delayed(Duration.zero);
      verify(
        () => sideEffectHandler.call(ShowEditCardDialog(row, c)),
      ).called(1);
    });
  });

  group('`onCardEdited`', () {
    test('replaces card with matching `cardId`, leaves others', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5, id: 'c1'));
      cubit.onCardAdded(CardsRowType.closeCombat, card(3, id: 'c2'));
      cubit.onCardEdited(CardsRowType.closeCombat, card(9, id: 'c1'));
      final cards = cubit
          .state
          .gameData
          .firstPlayerData
          .cardsRows[CardsRowType.closeCombat]!
          .cards;
      expect(cards.firstWhere((c) => c.cardId == 'c1').points, 9);
      expect(cards.firstWhere((c) => c.cardId == 'c2').points, 3);
    });
  });

  group('`onCardDeleted`', () {
    test('removes card with matching `cardId`', () {
      cubit.onCardAdded(CardsRowType.siege, card(5, id: 'c1'));
      cubit.onCardAdded(CardsRowType.siege, card(3, id: 'c2'));
      cubit.onCardDeleted(CardsRowType.siege, card(5, id: 'c1'));
      final cards = cubit
          .state
          .gameData
          .firstPlayerData
          .cardsRows[CardsRowType.siege]!
          .cards;
      expect(cards.map((c) => c.cardId), ['c2']);
    });
  });

  group('`onHornChanged`', () {
    test('sets `horn` on the selected player specified row only', () {
      cubit.onHornChanged(CardsRowType.longRange, true);
      final p1 = cubit.state.gameData.firstPlayerData;
      final p2 = cubit.state.gameData.secondPlayerData;
      expect(p1.cardsRows[CardsRowType.longRange]!.horn, isTrue);
      expect(p1.cardsRows[CardsRowType.closeCombat]!.horn, isFalse);
      expect(p2.cardsRows[CardsRowType.longRange]!.horn, isFalse);
    });
  });

  group('`onWeatherChanged`', () {
    test('sets `badWeather` on the same row for BOTH players', () {
      cubit.onWeatherChanged(CardsRowType.closeCombat, true);
      final p1 = cubit.state.gameData.firstPlayerData;
      final p2 = cubit.state.gameData.secondPlayerData;
      expect(p1.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
      expect(p2.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
      expect(p1.cardsRows[CardsRowType.siege]!.badWeather, isFalse);
    });
  });

  group('`onEndRoundTapped`', () {
    test('loser loses a life, winner keeps lives', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5)); // Alice 5, Bob 0
      cubit.onEndRoundTapped();
      expect(cubit.state.gameData.firstPlayerData.lives, 2);
      expect(cubit.state.gameData.secondPlayerData.lives, 1);
    });

    test('tie: both players lose a life', () {
      cubit.onEndRoundTapped(); // 0 : 0 → tie
      expect(cubit.state.gameData.firstPlayerData.lives, 1);
      expect(cubit.state.gameData.secondPlayerData.lives, 1);
    });

    test('first player loses a life when second player wins the round', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      cubit.onCardAdded(CardsRowType.closeCombat, card(5)); // Alice 0, Bob 5
      cubit.onEndRoundTapped();
      expect(cubit.state.gameData.firstPlayerData.lives, 1);
      expect(cubit.state.gameData.secondPlayerData.lives, 2);
    });

    test(
      'cards cleared and round recorded in `roundsData` after non-fatal round',
      () {
        cubit.onCardAdded(CardsRowType.closeCombat, card(5));
        cubit.onPlayerSelected(SelectedPlayer.second);
        cubit.onCardAdded(CardsRowType.siege, card(2));
        cubit.onEndRoundTapped();

        final state = cubit.state;
        expect(state.roundCounter, 1);
        expect(state.roundsData.firstRoundFirst, 5);
        expect(state.roundsData.firstRoundSecond, 2);
        expect(state.gameData.firstPlayerData.totalPoints, 0);
        expect(state.gameData.secondPlayerData.totalPoints, 0);
        expect(state.gameOver, isNull);
      },
    );

    test('emits `ShowGameOverDialog` when a player runs out of lives; '
        'cards NOT cleared', () async {
      // Round 1: Alice wins, Bob 2→1
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onEndRoundTapped();
      // Round 2: Alice wins again, Bob 1→0 → game over
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onEndRoundTapped();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.gameOver, Winner.first);
      verify(
        () => sideEffectHandler.call(const ShowGameOverDialog(Winner.first)),
      ).called(1);
      // On game over the final board is preserved (not cleared).
      expect(cubit.state.gameData.firstPlayerData.totalPoints, 5);
    });

    test(
      '`gameOver` is `Winner.second` when first player runs out of lives',
      () async {
        cubit.onPlayerSelected(SelectedPlayer.second);
        cubit.onCardAdded(CardsRowType.closeCombat, card(5));
        cubit.onEndRoundTapped(); // Alice 2→1
        cubit.onCardAdded(CardsRowType.closeCombat, card(5));
        cubit.onEndRoundTapped(); // Alice 1→0 → game over
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.gameOver, Winner.second);
        verify(
          () => sideEffectHandler.call(const ShowGameOverDialog(Winner.second)),
        ).called(1);
      },
    );

    test('double game over (both at 0) is a tie', () async {
      cubit.onEndRoundTapped(); // tie: both 2→1
      cubit.onEndRoundTapped(); // tie: both 1→0 → game over tie
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.gameOver, Winner.tie);
      verify(
        () => sideEffectHandler.call(const ShowGameOverDialog(Winner.tie)),
      ).called(1);
    });

    test('is a no-op after game over', () {
      cubit.onEndRoundTapped();
      cubit.onEndRoundTapped(); // game over (tie)
      final roundsBefore = cubit.state.roundCounter;
      cubit.onEndRoundTapped(); // must do nothing
      expect(cubit.state.roundCounter, roundsBefore);
    });
  });

  group('`onGameOverConfirmed`', () {
    Future<void> playToGameOver() async {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onEndRoundTapped(); // Bob 2→1
      cubit.onCardAdded(CardsRowType.closeCombat, card(7));
      cubit.onEndRoundTapped(); // Bob 1→0 → game over Winner.first
      await Future<void>.delayed(Duration.zero);
    }

    test('saves the score once and emits `NavigateBack`', () async {
      await playToGameOver();
      await cubit.onGameOverConfirmed();
      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => repository.addGame(captureAny())).captured;
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
    });

    test('second call does not save again', () async {
      await playToGameOver();
      await cubit.onGameOverConfirmed();
      await cubit.onGameOverConfirmed();
      verify(() => repository.addGame(any())).called(1);
    });

    test('is a no-op when game is not over', () async {
      await cubit.onGameOverConfirmed();
      await Future<void>.delayed(Duration.zero);
      verifyZeroInteractions(repository);
      verifyZeroInteractions(sideEffectHandler);
    });
  });
}
