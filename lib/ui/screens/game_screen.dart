import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final String player1Name;
  final String player2Name;
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const GameScreen({
    super.key,
    required this.player1Name,
    required this.player2Name,
    this.player1PhotoPath,
    this.player2PhotoPath,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: const Center(child: Text('Game Screen — TODO')),
      );
}
