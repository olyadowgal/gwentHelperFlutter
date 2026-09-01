import 'package:flutter_bloc/flutter_bloc.dart';
import '../resources/home_strings.dart';
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

  void onPlayTapped() {
    emit(
      state +
          NavigateToGame(
            player1Name: _nameOr(state.player1Name, HomeStrings.player1),
            player2Name: _nameOr(state.player2Name, HomeStrings.player2),
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
