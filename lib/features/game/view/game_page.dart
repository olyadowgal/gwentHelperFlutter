import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import '../cubit/game_cubit.dart';
import 'game_view.dart';

class GamePage extends StatelessWidget {
  final String player1Name;
  final String player2Name;
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const GamePage({
    super.key,
    required this.player1Name,
    required this.player2Name,
    this.player1PhotoPath,
    this.player2PhotoPath,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GameCubit(
      player1Name: player1Name,
      player2Name: player2Name,
      repository: context.read<GwentRepository>(),
    ),
    child: GameView(
      player1PhotoPath: player1PhotoPath,
      player2PhotoPath: player2PhotoPath,
    ),
  );
}
