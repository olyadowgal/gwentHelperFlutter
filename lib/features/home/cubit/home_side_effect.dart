import 'package:equatable/equatable.dart';
import '../../../arch/side_effect.dart';

sealed class HomeSideEffect extends Equatable implements SideEffect {
  const HomeSideEffect();

  @override
  List<Object?> get props => [];
}

class NavigateToGame extends HomeSideEffect {
  final String player1Name;
  final String player2Name;
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const NavigateToGame({
    required this.player1Name,
    required this.player2Name,
    this.player1PhotoPath,
    this.player2PhotoPath,
  });

  @override
  List<Object?> get props => [player1Name, player2Name, player1PhotoPath, player2PhotoPath];
}

class NavigateToScores extends HomeSideEffect {
  const NavigateToScores();
}
