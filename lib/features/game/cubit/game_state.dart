import 'package:equatable/equatable.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/domain/models/game_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/domain/models/rounds_data.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/domain/scorch.dart';
import 'game_side_effect.dart';

/// Pick mode: the snapshot of Scorch targets the user may still remove.
final class ScorchPrompt extends Equatable {
  final List<ScorchTarget> targets;

  ScorchPrompt(List<ScorchTarget> targets)
    : assert(targets.isNotEmpty, 'A prompt needs at least one target'),
      targets = List.unmodifiable(targets);

  @override
  List<Object?> get props => [targets];
}

final class GameState extends Equatable
    with WithSideEffects<GameState, GameSideEffect> {
  final GameData gameData;
  final PlayerSide selectedPlayer;
  final Winner? gameOver;
  final int roundCounter;
  final RoundsData roundsData;
  final ScorchPrompt? scorchPrompt;

  @override
  final List<GameSideEffect> sideEffects;

  const GameState({
    required this.gameData,
    this.selectedPlayer = PlayerSide.first,
    this.gameOver,
    this.roundCounter = 0,
    this.roundsData = const RoundsData(),
    this.scorchPrompt,
    this.sideEffects = const [],
  });

  PlayerData get selectedPlayerData => selectedPlayer == PlayerSide.first
      ? gameData.firstPlayerData
      : gameData.secondPlayerData;

  GameState copyWith({
    GameData? gameData,
    PlayerSide? selectedPlayer,
    Winner? gameOver,
    bool clearGameOver = false,
    int? roundCounter,
    RoundsData? roundsData,
    ScorchPrompt? scorchPrompt,
    bool clearScorchPrompt = false,
    List<GameSideEffect>? sideEffects,
  }) => GameState(
    gameData: gameData ?? this.gameData,
    selectedPlayer: selectedPlayer ?? this.selectedPlayer,
    gameOver: clearGameOver ? null : (gameOver ?? this.gameOver),
    roundCounter: roundCounter ?? this.roundCounter,
    roundsData: roundsData ?? this.roundsData,
    scorchPrompt: clearScorchPrompt
        ? null
        : (scorchPrompt ?? this.scorchPrompt),
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
    scorchPrompt,
    sideEffects,
  ];
}
