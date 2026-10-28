import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'score_player.dart';
import 'scores_side_effect.dart';
import 'scores_state.dart';

class ScoresCubit extends Cubit<ScoresState> {
  final GwentRepository _repository;

  ScoresCubit({required GwentRepository repository})
    : _repository = repository,
      super(const ScoresState()) {
    onScreenOpened();
  }

  Future<void> onScreenOpened() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final scores = await _repository.getGames();
      final players = await _loadPlayers();
      emit(state.copyWith(isLoading: false, scores: scores, players: players));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Includes deleted players: past games keep their name and photo.
  /// Photos are a nicety: the scoreboard must still open when the saved
  /// players, or any one photo, cannot be read.
  Future<Map<String, ScorePlayer>> _loadPlayers() async {
    try {
      final players = <String, ScorePlayer>{};
      for (final player in await _repository.getPlayersIncludingDeleted()) {
        String? photoPath;
        try {
          photoPath = await _repository.photoPathOf(player);
        } catch (_) {}
        players[player.id] = ScorePlayer(
          name: player.name,
          photoPath: photoPath,
        );
      }
      return players;
    } catch (_) {
      return const {};
    }
  }

  void onClearAllTapped() => emit(state + const ShowClearConfirmDialog());

  Future<void> onClearConfirmed() async {
    await _repository.clearGames();
    emit(state.copyWith(scores: []));
  }
}
