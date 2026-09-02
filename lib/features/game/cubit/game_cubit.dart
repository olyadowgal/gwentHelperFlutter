import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_data.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/domain/scorch.dart';
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

  void onPlayerSelected(PlayerSide player) =>
      emit(state.copyWith(selectedPlayer: player));

  void onAddCardRequested(CardsRowType rowType) =>
      emit(state + ShowAddCardDialog(rowType));

  void onCardAdded(CardsRowType rowType, Card card) {
    if (state.gameOver != null) return;

    final owner = state.selectedPlayer;
    final destination = card.abilities.contains(Ability.spy)
        ? owner.opposite
        : owner;
    final data = _withCardOnSide(state.gameData, destination, rowType, card);
    var next = state.copyWith(gameData: data);

    if (card.abilities.contains(Ability.muster)) {
      emit(next + ShowMusterCountDialog(rowType, card, owner));
      return;
    }

    if (card.abilities.contains(Ability.scorchRow)) {
      emit(_withRowScorch(next, owner: owner, rowType: rowType));
      return;
    }

    emit(next);
  }

  void onMusterCountChosen(
    CardsRowType rowType,
    Card card,
    int extraCopies,
    PlayerSide owner,
  ) {
    if (state.gameOver != null) return;
    if (extraCopies < 1 || extraCopies > 4) return;

    final destination = card.abilities.contains(Ability.spy)
        ? owner.opposite
        : owner;
    var data = state.gameData;
    for (var i = 0; i < extraCopies; i++) {
      data = _withCardOnSide(
        data,
        destination,
        rowType,
        Card(points: card.points, abilities: card.abilities),
      );
    }
    emit(state.copyWith(gameData: data));
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
    for (final player in PlayerSide.values) {
      final p = player == PlayerSide.first
          ? data.firstPlayerData
          : data.secondPlayerData;
      final row = p.cardsRows[rowType]!;
      final updated = p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(badWeather: value),
        },
      );
      data = player == PlayerSide.first
          ? data.copyWith(firstPlayerData: updated)
          : data.copyWith(secondPlayerData: updated);
    }
    emit(state.copyWith(gameData: data));
  }

  void onScorchTapped() {
    if (state.gameOver != null) return;

    final targets = specialScorchTargets(state.gameData).toList();
    if (targets.isEmpty) {
      emit(
        state.copyWith(clearScorchPrompt: true) +
            const ShowNoScorchTargets(ScorchNoTargetReason.nothingToScorch),
      );
      return;
    }

    emit(state.copyWith(scorchPrompt: ScorchPrompt(targets)));
  }

  void onScorchTargetTapped(ScorchTarget target) {
    if (state.gameOver != null) return;

    final prompt = state.scorchPrompt;
    if (prompt == null || !prompt.targets.contains(target)) return;

    final data = _withoutCard(target);
    final remaining = prompt.targets.where((t) => t != target).toList();

    emit(
      remaining.isEmpty
          ? state.copyWith(gameData: data, clearScorchPrompt: true)
          : state.copyWith(
              gameData: data,
              scorchPrompt: ScorchPrompt(remaining),
            ),
    );
  }

  void onScorchPickCancelled() {
    if (state.gameOver != null || state.scorchPrompt == null) return;
    emit(state.copyWith(clearScorchPrompt: true));
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
              clearScorchPrompt: true,
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
          clearScorchPrompt: true,
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

  GameState _withRowScorch(
    GameState next, {
    required PlayerSide owner,
    required CardsRowType rowType,
  }) {
    final targets = rowScorchTargets(
      next.gameData,
      owner: owner,
      rowType: rowType,
    ).toList();
    if (targets.isNotEmpty) {
      return next.copyWith(scorchPrompt: ScorchPrompt(targets));
    }

    final enemy = owner.opposite == PlayerSide.first
        ? next.gameData.firstPlayerData
        : next.gameData.secondPlayerData;
    final reason = (enemy.cardsRows[rowType]?.totalPoints ?? 0) < 10
        ? ScorchNoTargetReason.rowBelowTen
        : ScorchNoTargetReason.nothingToScorch;
    return next.copyWith(clearScorchPrompt: true) + ShowNoScorchTargets(reason);
  }

  GameData _withCardOnSide(
    GameData data,
    PlayerSide side,
    CardsRowType rowType,
    Card card,
  ) {
    final player = side == PlayerSide.first
        ? data.firstPlayerData
        : data.secondPlayerData;
    final row = player.cardsRows[rowType]!;
    final updated = player.copyWith(
      cardsRows: {
        ...player.cardsRows,
        rowType: row.copyWith(cards: [...row.cards, card]),
      },
    );
    return side == PlayerSide.first
        ? data.copyWith(firstPlayerData: updated)
        : data.copyWith(secondPlayerData: updated);
  }

  GameData _withoutCard(ScorchTarget target) {
    final data = state.gameData;
    final player = target.side == PlayerSide.first
        ? data.firstPlayerData
        : data.secondPlayerData;
    final row = player.cardsRows[target.rowType]!;
    final updated = player.copyWith(
      cardsRows: {
        ...player.cardsRows,
        target.rowType: row.copyWith(
          cards: row.cards.where((c) => c.cardId != target.cardId).toList(),
        ),
      },
    );
    return target.side == PlayerSide.first
        ? data.copyWith(firstPlayerData: updated)
        : data.copyWith(secondPlayerData: updated);
  }

  GameData _updateSelectedPlayer(PlayerData Function(PlayerData) update) {
    final data = state.gameData;
    return state.selectedPlayer == PlayerSide.first
        ? data.copyWith(firstPlayerData: update(data.firstPlayerData))
        : data.copyWith(secondPlayerData: update(data.secondPlayerData));
  }
}
