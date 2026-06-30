import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {
  final String player1Name;
  final String player2Name;
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const HomeState({
    this.player1Name = '',
    this.player2Name = '',
    this.player1PhotoPath,
    this.player2PhotoPath,
  });

  HomeState copyWith({
    String? player1Name,
    String? player2Name,
    String? player1PhotoPath,
    String? player2PhotoPath,
  }) {
    return HomeState(
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      player1PhotoPath: player1PhotoPath ?? this.player1PhotoPath,
      player2PhotoPath: player2PhotoPath ?? this.player2PhotoPath,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  void setPlayer1Name(String name) => state = state.copyWith(player1Name: name);
  void setPlayer2Name(String name) => state = state.copyWith(player2Name: name);
  void setPlayer1Photo(String path) => state = state.copyWith(player1PhotoPath: path);
  void setPlayer2Photo(String path) => state = state.copyWith(player2PhotoPath: path);
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);
