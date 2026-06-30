import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/card.dart';
import '../../domain/models/cards_row.dart';
import '../../domain/models/cards_row_type.dart';
import '../../domain/models/winner.dart';
import '../../state/game_notifier.dart';
import '../../state/game_provider.dart';
import '../widgets/user_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/cards_row_widget.dart';
import '../dialogs/add_card_dialog.dart';
import '../dialogs/edit_card_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
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
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late GameNotifier _notifier;
  late GameState _state;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(gwentRepositoryProvider);
    _notifier = GameNotifier(widget.player1Name, widget.player2Name, repo);
    _state = _notifier.state;
    _notifier.onStateChanged = (newState) {
      if (mounted) setState(() => _state = newState);
    };
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _showAddCardDialog(CardsRowType rowType) async {
    final card = await showDialog<Card>(
      context: context,
      builder: (_) => AddCardDialog(rowType: rowType),
    );
    if (!mounted) return;
    if (card != null) {
      _notifier.addCard(rowType, card);
    }
  }

  Future<void> _showEditCardDialog(CardsRow row, Card card) async {
    final result = await showDialog<EditCardResult>(
      context: context,
      builder: (_) => EditCardDialog(card: card),
    );
    if (!mounted) return;
    if (result == null) return;
    switch (result) {
      case EditCardSave(:final card):
        _notifier.editCard(row.type, card);
      case EditCardDelete():
        _notifier.deleteCard(row.type, card);
    }
  }

  void _onEndRound() {
    _notifier.endRound();
    if (_state.gameOver != null) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    final winner = _state.gameOver!;
    final message = switch (winner) {
      Winner.first => '${widget.player1Name} wins!',
      Winner.second => '${widget.player2Name} wins!',
      Winner.tie => "It's a tie!",
    };
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _notifier.saveGame();
              if (mounted) {
                context.pop(); // dismisses dialog
                context.pop(); // returns to previous screen
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = _state.gameData;
    final p1 = game.firstPlayerData;
    final p2 = game.secondPlayerData;
    final selectedData = _state.selectedPlayerData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Round ${_state.roundCounter + 1}'),
        actions: [
          TextButton(
            onPressed: _onEndRound,
            child: const Text('END ROUND', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Player headers
          Row(
            children: [
              Expanded(
                child: UserWidget(
                  name: p1.name,
                  totalPoints: p1.totalPoints,
                  lives: p1.lives,
                  photoPath: widget.player1PhotoPath,
                  isSelected: _state.selectedPlayer == SelectedPlayer.first,
                  isWinning: p1.totalPoints > p2.totalPoints,
                  onTap: () => _notifier.selectPlayer(SelectedPlayer.first),
                ),
              ),
              Expanded(
                child: UserWidget(
                  name: p2.name,
                  totalPoints: p2.totalPoints,
                  lives: p2.lives,
                  photoPath: widget.player2PhotoPath,
                  isSelected: _state.selectedPlayer == SelectedPlayer.second,
                  isWinning: p2.totalPoints > p1.totalPoints,
                  onTap: () => _notifier.selectPlayer(SelectedPlayer.second),
                ),
              ),
            ],
          ),
          const Divider(),
          // Weather controls (shared - affects both players)
          WeatherWidget(
            frostActive:
                selectedData.cardsRows[CardsRowType.closeCombat]?.badWeather ??
                    false,
            fogActive:
                selectedData.cardsRows[CardsRowType.longRange]?.badWeather ??
                    false,
            rainActive:
                selectedData.cardsRows[CardsRowType.siege]?.badWeather ?? false,
            onChanged: (type, active) => _notifier.setWeather(type, active),
          ),
          const Divider(),
          // Card rows for selected player
          Expanded(
            child: ListView(
              children: CardsRowType.values.map((rowType) {
                final row = selectedData.cardsRows[rowType]!;
                return CardsRowWidget(
                  row: row,
                  onAddCard: _showAddCardDialog,
                  onCardLongPress: _showEditCardDialog,
                  onHornChanged: (type, value) => _notifier.setHorn(type, value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
