import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/gwent_repository.dart';
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
      emit(state.copyWith(isLoading: false, scores: scores));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void onClearAllTapped() => emit(state + const ShowClearConfirmDialog());

  Future<void> onClearConfirmed() async {
    await _repository.clearGames();
    emit(state.copyWith(scores: []));
  }
}
