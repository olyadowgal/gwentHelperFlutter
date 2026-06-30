import '../domain/models/card.dart';
import '../domain/models/cards_row_type.dart';
import '../domain/models/game_data.dart';
import '../domain/models/game_score.dart';
import '../domain/models/player_data.dart';
import '../domain/models/rounds_data.dart';
import '../domain/models/winner.dart';
import '../data/gwent_repository.dart';

enum SelectedPlayer { first, second }

class GameState {
  final GameData gameData;
  final SelectedPlayer selectedPlayer;
  final Winner? gameOver;
  final int roundCounter;
  final RoundsData roundsData;

  const GameState({
    required this.gameData,
    this.selectedPlayer = SelectedPlayer.first,
    this.gameOver,
    this.roundCounter = 0,
    this.roundsData = const RoundsData(),
  });

  PlayerData get selectedPlayerData => selectedPlayer == SelectedPlayer.first
      ? gameData.firstPlayerData
      : gameData.secondPlayerData;

  GameState copyWith({
    GameData? gameData,
    SelectedPlayer? selectedPlayer,
    Winner? gameOver,
    bool clearGameOver = false,
    int? roundCounter,
    RoundsData? roundsData,
  }) {
    return GameState(
      gameData: gameData ?? this.gameData,
      selectedPlayer: selectedPlayer ?? this.selectedPlayer,
      gameOver: clearGameOver ? null : (gameOver ?? this.gameOver),
      roundCounter: roundCounter ?? this.roundCounter,
      roundsData: roundsData ?? this.roundsData,
    );
  }
}

class GameNotifier {
  GameState _state;
  final GwentRepository _repository;
  void Function(GameState)? onStateChanged;
  bool _saved = false;

  GameNotifier(String player1Name, String player2Name, this._repository)
      : _state = GameState(
          gameData: GameData(
            firstPlayerData: PlayerData(name: player1Name),
            secondPlayerData: PlayerData(name: player2Name),
          ),
        );

  GameState get state => _state;

  void _emit(GameState newState) {
    _state = newState;
    onStateChanged?.call(_state);
  }

  void selectPlayer(SelectedPlayer player) {
    _emit(_state.copyWith(selectedPlayer: player));
  }

  void addCard(CardsRowType rowType, Card card) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      return p.copyWith(
        cardsRows: {...p.cardsRows, rowType: row.copyWith(cards: [...row.cards, card])},
      );
    });
    _emit(_state.copyWith(gameData: updated));
  }

  void editCard(CardsRowType rowType, Card card) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      final newCards = row.cards.map((c) => c.cardId == card.cardId ? card : c).toList();
      return p.copyWith(
        cardsRows: {...p.cardsRows, rowType: row.copyWith(cards: newCards)},
      );
    });
    _emit(_state.copyWith(gameData: updated));
  }

  void deleteCard(CardsRowType rowType, Card card) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      return p.copyWith(
        cardsRows: {
          ...p.cardsRows,
          rowType: row.copyWith(cards: row.cards.where((c) => c.cardId != card.cardId).toList()),
        },
      );
    });
    _emit(_state.copyWith(gameData: updated));
  }

  void setHorn(CardsRowType rowType, bool value) {
    final updated = _updateSelectedPlayer((p) {
      final row = p.cardsRows[rowType]!;
      return p.copyWith(
        cardsRows: {...p.cardsRows, rowType: row.copyWith(horn: value)},
      );
    });
    _emit(_state.copyWith(gameData: updated));
  }

  void setWeather(CardsRowType rowType, bool value) {
    // Weather affects both players simultaneously
    GameData data = _state.gameData;
    for (final player in [SelectedPlayer.first, SelectedPlayer.second]) {
      final p = player == SelectedPlayer.first
          ? data.firstPlayerData
          : data.secondPlayerData;
      final row = p.cardsRows[rowType]!;
      final updated = p.copyWith(
        cardsRows: {...p.cardsRows, rowType: row.copyWith(badWeather: value)},
      );
      data = player == SelectedPlayer.first
          ? data.copyWith(firstPlayerData: updated)
          : data.copyWith(secondPlayerData: updated);
    }
    _emit(_state.copyWith(gameData: data));
  }

  void endRound() {
    if (_state.gameOver != null) return;
    var data = _state.gameData;
    final roundCounter = _state.roundCounter + 1;
    final roundsData = _state.roundsData.withRound(
      roundCounter,
      data.firstPlayerData.totalPoints,
      data.secondPlayerData.totalPoints,
    );

    switch (data.winner) {
      case Winner.first:
        data = data.copyWith(secondPlayerData: data.secondPlayerData.minusLife());
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
      _emit(_state.copyWith(
        gameData: data,
        roundCounter: roundCounter,
        roundsData: roundsData,
        gameOver: gameOver,
      ));
    } else {
      data = data.copyWith(
        firstPlayerData: data.firstPlayerData.clearCards(),
        secondPlayerData: data.secondPlayerData.clearCards(),
      );
      _emit(_state.copyWith(
        gameData: data,
        roundCounter: roundCounter,
        roundsData: roundsData,
      ));
    }
  }

  Future<void> saveGame() async {
    final data = _state.gameData;
    final rounds = _state.roundsData;
    final gameOver = _state.gameOver;
    if (gameOver == null || _saved) return;
    _saved = true;

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
    await _repository.addGame(score);
  }

  void dispose() {
    onStateChanged = null;
  }

  GameData _updateSelectedPlayer(PlayerData Function(PlayerData) update) {
    final data = _state.gameData;
    return _state.selectedPlayer == SelectedPlayer.first
        ? data.copyWith(firstPlayerData: update(data.firstPlayerData))
        : data.copyWith(secondPlayerData: update(data.secondPlayerData));
  }
}
