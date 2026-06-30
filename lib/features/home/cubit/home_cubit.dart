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

  void onPlayTapped() {
    emit(
      state +
          NavigateToGame(
            player1Name:
                state.player1Name.isEmpty ? 'Player 1' : state.player1Name,
            player2Name:
                state.player2Name.isEmpty ? 'Player 2' : state.player2Name,
            player1PhotoPath: state.player1PhotoPath,
            player2PhotoPath: state.player2PhotoPath,
          ),
    );
  }

  void onScoresTapped() => emit(state + const NavigateToScores());
}
