import 'package:equatable/equatable.dart';
import '../../../arch/side_effect.dart';
import '../../../domain/models/player.dart';

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
  final String? player1Id;
  final String? player2Id;

  const NavigateToGame({
    required this.player1Name,
    required this.player2Name,
    this.player1PhotoPath,
    this.player2PhotoPath,
    this.player1Id,
    this.player2Id,
  });

  @override
  List<Object?> get props => [
    player1Name,
    player2Name,
    player1PhotoPath,
    player2PhotoPath,
    player1Id,
    player2Id,
  ];
}

class NavigateToScores extends HomeSideEffect {
  const NavigateToScores();
}

/// A saved player offered for selection, with its resolved photo path (null if
/// the player has no photo or the file is missing).
class SavedPlayerOption extends Equatable {
  final Player player;
  final String? photoPath;

  const SavedPlayerOption({required this.player, this.photoPath});

  @override
  List<Object?> get props => [player, photoPath];
}

class ShowSavedPlayers extends HomeSideEffect {
  final bool isPlayer1;
  final List<SavedPlayerOption> options;

  const ShowSavedPlayers(this.isPlayer1, this.options);

  @override
  List<Object?> get props => [isPlayer1, options];
}
