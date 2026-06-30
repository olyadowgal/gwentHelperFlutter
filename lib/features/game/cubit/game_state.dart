import 'package:equatable/equatable.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/domain/models/game_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';
import 'package:gwent_helper_flutter/domain/models/rounds_data.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'game_side_effect.dart';

enum SelectedPlayer { first, second }

final class GameState extends Equatable
    with WithSideEffects<GameState, GameSideEffect> {
  final GameData gameData;
  final SelectedPlayer selectedPlayer;
  final Winner? gameOver;
  final int roundCounter;
  final RoundsData roundsData;

  @override
  final List<GameSideEffect> sideEffects;

  const GameState({
    required this.gameData,
    this.selectedPlayer = SelectedPlayer.first,
    this.gameOver,
    this.roundCounter = 0,
    this.roundsData = const RoundsData(),
    this.sideEffects = const [],
  });

  PlayerData get selectedPlayerData =>
      selectedPlayer == SelectedPlayer.first
          ? gameData.firstPlayerData
          : gameData.secondPlayerData;

  GameState copyWith({
    GameData? gameData,
    SelectedPlayer? selectedPlayer,
    Winner? gameOver,
    bool clearGameOver = false,
    int? roundCounter,
    RoundsData? roundsData,
    List<GameSideEffect>? sideEffects,
  }) =>
      GameState(
        gameData: gameData ?? this.gameData,
        selectedPlayer: selectedPlayer ?? this.selectedPlayer,
        gameOver: clearGameOver ? null : (gameOver ?? this.gameOver),
        roundCounter: roundCounter ?? this.roundCounter,
        roundsData: roundsData ?? this.roundsData,
        sideEffects: sideEffects ?? this.sideEffects,
      );

  @override
  GameState withSideEffects(List<GameSideEffect> sideEffects) =>
      copyWith(sideEffects: sideEffects);

  @override
  List<Object?> get props => [
        gameData,
        selectedPlayer,
        gameOver,
        roundCounter,
        roundsData,
        sideEffects,
      ];
}
