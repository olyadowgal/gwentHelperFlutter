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
    test(
      'Given player names\n'
      'When `GameCubit` is created\n'
      'Then players are named with 2 lives, empty rows, first selected, round 0',
      () {
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
    test('Given the first player is selected\n'
        'When `onPlayerSelected` is called with the second player\n'
        'Then `selectedPlayer` switches and `selectedPlayerData` follows', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      expect(cubit.state.selectedPlayer, SelectedPlayer.second);
      expect(cubit.state.selectedPlayerData.name, 'Bob');
    });
  });

  group('`onAddCardRequested`', () {
    test('Given a fresh game\n'
        'When `onAddCardRequested` is called\n'
        'Then `ShowAddCardDialog` is emitted', () async {
      cubit.onAddCardRequested(CardsRowType.siege);
      await Future<void>.delayed(Duration.zero);
      verify(
        () =>
            sideEffectHandler.call(const ShowAddCardDialog(CardsRowType.siege)),
      ).called(1);
    });
  });

  group('`onCardAdded`', () {
    test('Given the first player is selected\n'
        'When `onCardAdded` is called\n'
        'Then the card is appended to the selected player row only', () {
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

    test('Given the second player is selected\n'
        'When `onCardAdded` is called\n'
        'Then the card goes to the second player row', () {
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
    test('Given a card in a row\n'
        'When `onEditCardRequested` is called\n'
        'Then `ShowEditCardDialog` is emitted', () async {
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
    test('Given two cards in a row\n'
        'When `onCardEdited` is called\n'
        'Then only the card with matching `cardId` is replaced', () {
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
    test('Given two cards in a row\n'
        'When `onCardDeleted` is called\n'
        'Then only the card with matching `cardId` is removed', () {
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
    test('Given a fresh game\n'
        'When `onHornChanged` is called\n'
        'Then `horn` is set on the selected player specified row only', () {
      cubit.onHornChanged(CardsRowType.longRange, true);
      final p1 = cubit.state.gameData.firstPlayerData;
      final p2 = cubit.state.gameData.secondPlayerData;
      expect(p1.cardsRows[CardsRowType.longRange]!.horn, isTrue);
      expect(p1.cardsRows[CardsRowType.closeCombat]!.horn, isFalse);
      expect(p2.cardsRows[CardsRowType.longRange]!.horn, isFalse);
    });
  });

  group('`onWeatherChanged`', () {
    test('Given a fresh game\n'
        'When `onWeatherChanged` is called\n'
        'Then `badWeather` is set on the same row for both players', () {
      cubit.onWeatherChanged(CardsRowType.closeCombat, true);
      final p1 = cubit.state.gameData.firstPlayerData;
      final p2 = cubit.state.gameData.secondPlayerData;
      expect(p1.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
      expect(p2.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
      expect(p1.cardsRows[CardsRowType.siege]!.badWeather, isFalse);
    });
  });

  group('`onEndRoundTapped`', () {
    test('Given the first player has more points\n'
        'When `onEndRoundTapped` is called\n'
        'Then the loser loses a life and the winner keeps lives', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5)); // Alice 5, Bob 0
      cubit.onEndRoundTapped();
      expect(cubit.state.gameData.firstPlayerData.lives, 2);
      expect(cubit.state.gameData.secondPlayerData.lives, 1);
    });

    test('Given equal points\n'
        'When `onEndRoundTapped` is called\n'
        'Then both players lose a life', () {
      cubit.onEndRoundTapped(); // 0 : 0 → tie
      expect(cubit.state.gameData.firstPlayerData.lives, 1);
      expect(cubit.state.gameData.secondPlayerData.lives, 1);
    });

    test('Given the second player has more points\n'
        'When `onEndRoundTapped` is called\n'
        'Then the first player loses a life', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      cubit.onCardAdded(CardsRowType.closeCombat, card(5)); // Alice 0, Bob 5
      cubit.onEndRoundTapped();
      expect(cubit.state.gameData.firstPlayerData.lives, 1);
      expect(cubit.state.gameData.secondPlayerData.lives, 2);
    });

    test('Given a non-fatal round\n'
        'When `onEndRoundTapped` is called\n'
        'Then cards are cleared and the round is recorded in `roundsData`', () {
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
    });

    test(
      'Given the losing player has one life left\n'
      'When `onEndRoundTapped` is called\n'
      'Then `ShowGameOverDialog` is emitted and the board is not cleared',
      () async {
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
      },
    );

    test('Given the first player has one life left and loses\n'
        'When `onEndRoundTapped` is called\n'
        'Then `gameOver` is `Winner.second`', () async {
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
    });

    test('Given both players have one life left\n'
        'When a tie round ends\n'
        'Then `gameOver` is `Winner.tie`', () async {
      cubit.onEndRoundTapped(); // tie: both 2→1
      cubit.onEndRoundTapped(); // tie: both 1→0 → game over tie
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.gameOver, Winner.tie);
      verify(
        () => sideEffectHandler.call(const ShowGameOverDialog(Winner.tie)),
      ).called(1);
    });

    test('Given the game is over\n'
        'When `onEndRoundTapped` is called again\n'
        'Then nothing changes', () {
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

    test('Given the game is over\n'
        'When `onGameOverConfirmed` is called\n'
        'Then the score is saved once and `NavigateBack` is emitted', () async {
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

    test('Given the score was already saved\n'
        'When `onGameOverConfirmed` is called again\n'
        'Then it does not save again', () async {
      await playToGameOver();
      await cubit.onGameOverConfirmed();
      await cubit.onGameOverConfirmed();
      verify(() => repository.addGame(any())).called(1);
    });

    test('Given the game is not over\n'
        'When `onGameOverConfirmed` is called\n'
        'Then nothing happens', () async {
      await cubit.onGameOverConfirmed();
      await Future<void>.delayed(Duration.zero);
      verifyZeroInteractions(repository);
      verifyZeroInteractions(sideEffectHandler);
    });
  });
}
