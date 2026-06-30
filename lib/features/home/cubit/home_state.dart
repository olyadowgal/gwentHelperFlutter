import 'package:equatable/equatable.dart';
import '../../../arch/side_effect.dart';
import 'home_side_effect.dart';

final class HomeState extends Equatable
    with WithSideEffects<HomeState, HomeSideEffect> {
  final String player1Name;
  final String player2Name;
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  @override
  final List<HomeSideEffect> sideEffects;

  const HomeState({
    this.player1Name = '',
    this.player2Name = '',
    this.player1PhotoPath,
    this.player2PhotoPath,
    this.sideEffects = const [],
  });

  HomeState copyWith({
    String? player1Name,
    String? player2Name,
    String? player1PhotoPath,
    String? player2PhotoPath,
    List<HomeSideEffect>? sideEffects,
  }) =>
      HomeState(
        player1Name: player1Name ?? this.player1Name,
        player2Name: player2Name ?? this.player2Name,
        player1PhotoPath: player1PhotoPath ?? this.player1PhotoPath,
        player2PhotoPath: player2PhotoPath ?? this.player2PhotoPath,
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
        sideEffects,
      ];
}
