import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_side_effect.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void onPlayer1NameChanged(String name) =>
      emit(state.copyWith(player1Name: name));

  void onPlayer2NameChanged(String name) =>
      emit(state.copyWith(player2Name: name));

  void onPlayer1PhotoPicked(String path) =>
      emit(state.copyWith(player1PhotoPath: path));

  void onPlayer2PhotoPicked(String path) =>
      emit(state.copyWith(player2PhotoPath: path));

  // Fallback names are passed in rather than read from a Strings class here,
  // since Cubits don't depend on Flutter's localization APIs (no BuildContext).
  void onPlayTapped({
    required String player1Fallback,
    required String player2Fallback,
  }) {
    emit(
      state +
          NavigateToGame(
            player1Name: _nameOr(state.player1Name, player1Fallback),
            player2Name: _nameOr(state.player2Name, player2Fallback),
            player1PhotoPath: state.player1PhotoPath,
            player2PhotoPath: state.player2PhotoPath,
          ),
    );
  }

  void onScoresTapped() => emit(state + const NavigateToScores());

  static String _nameOr(String name, String fallback) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
