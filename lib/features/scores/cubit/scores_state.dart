import 'package:equatable/equatable.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'score_player.dart';
import 'scores_side_effect.dart';

final class ScoresState extends Equatable
    with WithSideEffects<ScoresState, ScoresSideEffect> {
  final bool isLoading;
  final List<GameScore> scores;

  /// Saved players by id, for games linked to one.
  final Map<String, ScorePlayer> players;
  final String? errorMessage;

  @override
  final List<ScoresSideEffect> sideEffects;

  const ScoresState({
    this.isLoading = false,
    this.scores = const [],
    this.players = const {},
    this.errorMessage,
    this.sideEffects = const [],
  });

  ScoresState copyWith({
    bool? isLoading,
    List<GameScore>? scores,
    Map<String, ScorePlayer>? players,
    String? errorMessage,
    bool clearError = false,
    List<ScoresSideEffect>? sideEffects,
  }) => ScoresState(
    isLoading: isLoading ?? this.isLoading,
    scores: scores ?? this.scores,
    players: players ?? this.players,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    sideEffects: sideEffects ?? this.sideEffects,
  );

  @override
  ScoresState withSideEffects(List<ScoresSideEffect> sideEffects) =>
      copyWith(sideEffects: sideEffects);

  @override
  List<Object?> get props => [
    isLoading,
    scores,
    players,
    errorMessage,
    sideEffects,
  ];
}
