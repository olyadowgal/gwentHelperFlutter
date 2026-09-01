import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_data.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'game_side_effect.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final GwentRepository _repository;
  bool _saved = false;

  GameCubit({
    required String player1Name,
    required String player2Name,
    required GwentRepository repository,
  }) : _repository = repository,
       super(
         GameState(
           gameData: GameData(
             firstPlayerData: PlayerData(name: player1Name),
             secondPlayerData: PlayerData(name: player2Name),
           ),
         ),
       );

  void onPlayerSelected(SelectedPlayer player) =>
      emit(state.copyWith(selectedPlayer: player));

  void onAddCardRequested(CardsRowType rowType) =>
      emit(state + ShowAddCardDialog(rowType));

  void onCardAdded(CardsRowType rowType, Card card) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      return p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(cards: [...row.cards, card]),
        },
      );
    });
    emit(state.copyWith(gameData: updated));
  }

  void onEditCardRequested(CardsRow row, Card card) =>
      emit(state + ShowEditCardDialog(row, card));

  void onCardEdited(CardsRowType rowType, Card card) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      final newCards = row.cards
          .map((c) => c.cardId == card.cardId ? card : c)
          .toList();
      return p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(cards: newCards),
        },
      );
    });
    emit(state.copyWith(gameData: updated));
  }

  void onCardDeleted(CardsRowType rowType, Card card) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      return p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(
            cards: row.cards.where((c) => c.cardId != card.cardId).toList(),
          ),
        },
      );
    });
    emit(state.copyWith(gameData: updated));
  }

  void onHornChanged(CardsRowType rowType, bool value) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      return p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(horn: value),
        },
      );
    });
    emit(state.copyWith(gameData: updated));
  }

  void onWeatherChanged(CardsRowType rowType, bool value) {
    var data = state.gameData;
    for (final player in SelectedPlayer.values) {
      final p = player == SelectedPlayer.first
          ? data.firstPlayerData
          : data.secondPlayerData;
      final row = p.cardsRows[rowType]!;
      final updated = p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(badWeather: value),
        },
      );
      data = player == SelectedPlayer.first
          ? data.copyWith(firstPlayerData: updated)
          : data.copyWith(secondPlayerData: updated);
    }
    emit(state.copyWith(gameData: data));
  }

  void onEndRoundTapped() {
    if (state.gameOver != null) return;
    var data = state.gameData;
    final roundCounter = state.roundCounter + 1;
    final roundsData = state.roundsData.withRound(
      roundCounter,
      data.firstPlayerData.totalPoints,
      data.secondPlayerData.totalPoints,
    );

    switch (data.winner) {
      case Winner.first:
        data = data.copyWith(
          secondPlayerData: data.secondPlayerData.minusLife(),
        );
      case Winner.second:
        data = data.copyWith(firstPlayerData: data.firstPlayerData.minusLife());
      case Winner.tie:
        data = data.copyWith(
          firstPlayerData: data.firstPlayerData.minusLife(),
          secondPlayerData: data.secondPlayerData.minusLife(),
        );
    }

    final p1Dead = data.firstPlayerData.lives == 0;
    final p2Dead = data.secondPlayerData.lives == 0;

    if (p1Dead || p2Dead) {
      final gameOver = (p1Dead && p2Dead)
          ? Winner.tie
          : p1Dead
          ? Winner.second
          : Winner.first;
      emit(
        state.copyWith(
              gameData: data,
              roundCounter: roundCounter,
              roundsData: roundsData,
              gameOver: gameOver,
            ) +
            ShowGameOverDialog(gameOver),
      );
    } else {
      data = data.copyWith(
        firstPlayerData: data.firstPlayerData.clearCards(),
        secondPlayerData: data.secondPlayerData.clearCards(),
      );
      emit(
        state.copyWith(
          gameData: data,
          roundCounter: roundCounter,
          roundsData: roundsData,
        ),
      );
    }
  }

  Future<void> onGameOverConfirmed() async {
    final data = state.gameData;
    final rounds = state.roundsData;
    final gameOver = state.gameOver;
    if (gameOver == null || _saved) return;

    final score = GameScore(
      date: DateTime.now(),
      firstPlayer: data.firstPlayerData.name,
      secondPlayer: data.secondPlayerData.name,
      winner: gameOver.name,
      firstRoundFirstPlayerPoints: rounds.firstRoundFirst,
      secondRoundFirstPlayerPoints: rounds.secondRoundFirst,
      thirdRoundFirstPlayerPoints: rounds.thirdRoundFirst,
      firstRoundSecondPlayerPoints: rounds.firstRoundSecond,
      secondRoundSecondPlayerPoints: rounds.secondRoundSecond,
      thirdRoundSecondPlayerPoints: rounds.thirdRoundSecond,
    );
    try {
      await _repository.addGame(score);
      _saved = true;
      emit(state + const NavigateBack());
    } catch (e) {
      emit(state + ShowSaveFailed(e.toString()));
    }
  }

  GameData _updateSelectedPlayer(PlayerData Function(PlayerData) update) {
    final data = state.gameData;
    return state.selectedPlayer == SelectedPlayer.first
        ? data.copyWith(firstPlayerData: update(data.firstPlayerData))
        : data.copyWith(secondPlayerData: update(data.secondPlayerData));
  }
}
