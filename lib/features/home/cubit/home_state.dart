import 'package:equatable/equatable.dart';
import '../../../arch/side_effect.dart';
import 'home_side_effect.dart';

final class HomeState extends Equatable
    with WithSideEffects<HomeState, HomeSideEffect> {
  final String player1Name;
  final String player2Name;
  final String? player1PhotoPath;
  final String? player2PhotoPath;
  final String? player1Id;
  final String? player2Id;
  final bool player1PhotoChanged;
  final bool player2PhotoChanged;

  @override
  final List<HomeSideEffect> sideEffects;

  const HomeState({
    this.player1Name = '',
    this.player2Name = '',
    this.player1PhotoPath,
    this.player2PhotoPath,
    this.player1Id,
    this.player2Id,
    this.player1PhotoChanged = false,
    this.player2PhotoChanged = false,
    this.sideEffects = const [],
  });

  /// [clearPlayer1] / [clearPlayer2] reset that side's id, photo path and
  /// changed flag (the `??` fallback can't set a nullable field back to null);
  /// values passed for the same side are applied after the reset.
  HomeState copyWith({
    String? player1Name,
    String? player2Name,
    String? player1PhotoPath,
    String? player2PhotoPath,
    String? player1Id,
    String? player2Id,
    bool? player1PhotoChanged,
    bool? player2PhotoChanged,
    bool clearPlayer1 = false,
    bool clearPlayer2 = false,
    List<HomeSideEffect>? sideEffects,
  }) => HomeState(
    player1Name: player1Name ?? this.player1Name,
    player2Name: player2Name ?? this.player2Name,
    player1PhotoPath:
        player1PhotoPath ?? (clearPlayer1 ? null : this.player1PhotoPath),
    player2PhotoPath:
        player2PhotoPath ?? (clearPlayer2 ? null : this.player2PhotoPath),
    player1Id: player1Id ?? (clearPlayer1 ? null : this.player1Id),
    player2Id: player2Id ?? (clearPlayer2 ? null : this.player2Id),
    player1PhotoChanged:
        player1PhotoChanged ?? (!clearPlayer1 && this.player1PhotoChanged),
    player2PhotoChanged:
        player2PhotoChanged ?? (!clearPlayer2 && this.player2PhotoChanged),
    sideEffects: sideEffects ?? this.sideEffects,
  );

  @override
  HomeState withSideEffects(List<HomeSideEffect> sideEffects) =>
      copyWith(sideEffects: sideEffects);

  @override
  List<Object?> get props => [
    player1Name,
    player2Name,
    player1PhotoPath,
    player2PhotoPath,
    player1Id,
    player2Id,
    player1PhotoChanged,
    player2PhotoChanged,
    sideEffects,
  ];
}
