import 'package:equatable/equatable.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'scores_side_effect.dart';

final class ScoresState extends Equatable
    with WithSideEffects<ScoresState, ScoresSideEffect> {
  final bool isLoading;
  final List<GameScore> scores;
  final String? errorMessage;

  @override
  final List<ScoresSideEffect> sideEffects;

  const ScoresState({
    this.isLoading = false,
    this.scores = const [],
    this.errorMessage,
    this.sideEffects = const [],
  });

  ScoresState copyWith({
    bool? isLoading,
    List<GameScore>? scores,
    String? errorMessage,
    bool clearError = false,
    List<ScoresSideEffect>? sideEffects,
  }) =>
      ScoresState(
        isLoading: isLoading ?? this.isLoading,
        scores: scores ?? this.scores,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        sideEffects: sideEffects ?? this.sideEffects,
      );

  @override
  ScoresState withSideEffects(List<ScoresSideEffect> sideEffects) =>
      copyWith(sideEffects: sideEffects);

  @override
  List<Object?> get props => [isLoading, scores, errorMessage, sideEffects];
}
