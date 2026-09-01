import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/arch/bloc_side_effect_handler.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_side_effect.dart';
import '../cubit/game_state.dart';
import '../resources/game_strings.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/cards_row_widget.dart';
import '../widgets/edit_card_dialog.dart';
import '../widgets/stats_column_widget.dart';
import '../widgets/user_widget.dart';
import '../widgets/weather_widget.dart';

class GameView extends StatefulWidget {
  static const _sidebarWidth = 90.0;
  static const _buttonIconSize = 20.0;
  static const _buttonLabelSize = 10.0;
  static const _buttonPadding = 8.0;
  static const _dividerWidth = 1.0;

  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const GameView({super.key, this.player1PhotoPath, this.player2PhotoPath});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _winnerMessage(
    Winner winner,
    String player1Name,
    String player2Name,
  ) => switch (winner) {
    Winner.first => '$player1Name ${GameStrings.wins}',
    Winner.second => '$player2Name ${GameStrings.wins}',
    Winner.tie => GameStrings.tie,
  };

  void _showExitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(GameStrings.exitTitle),
        content: const Text(GameStrings.exitContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(GameStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            child: const Text(GameStrings.exit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocSideEffectHandler<GameCubit, GameState, GameSideEffect>(
    listener: (context, sideEffect) {
      switch (sideEffect) {
        case ShowAddCardDialog(:final rowType):
          showDialog<Card>(
            context: context,
            builder: (_) => AddCardDialog(rowType: rowType),
          ).then((card) {
            if (card != null && context.mounted) {
              context.read<GameCubit>().onCardAdded(rowType, card);
            }
          });

        case ShowEditCardDialog(:final row, :final card):
          showDialog<EditCardResult>(
            context: context,
            builder: (_) => EditCardDialog(card: card),
          ).then((result) {
            if (result == null || !context.mounted) return;
            switch (result) {
              case EditCardSave(:final card):
                context.read<GameCubit>().onCardEdited(row.type, card);
              case EditCardDelete():
                context.read<GameCubit>().onCardDeleted(row.type, card);
            }
          });

        case ShowGameOverDialog(:final winner):
          final state = context.read<GameCubit>().state;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text(GameStrings.gameOverTitle),
              content: Text(
                _winnerMessage(
                  winner,
                  state.gameData.firstPlayerData.name,
                  state.gameData.secondPlayerData.name,
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    context.read<GameCubit>().onGameOverConfirmed();
                  },
                  child: const Text(GameStrings.ok),
                ),
              ],
            ),
          );

        case NavigateBack():
          context.go('/');
        case ShowSaveFailed():
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text(GameStrings.saveFailed)));
      }
    },
    child: BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final p1 = state.gameData.firstPlayerData;
        final p2 = state.gameData.secondPlayerData;
        final selectedData = state.selectedPlayerData;
        final cubit = context.read<GameCubit>();
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: Row(
            children: [
              // Zone 1: Sidebar
              Container(
                width: GameView._sidebarWidth,
                color: colorScheme.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Exit button
                    _SidebarButton(
                      iconAsset: 'assets/icons/ic_exit.svg',
                      label: GameStrings.exit,
                      onTap: () => _showExitDialog(context),
                    ),
                    // Player 1
                    UserWidget(
                      name: p1.name,
                      totalPoints: p1.totalPoints,
                      lives: p1.lives,
                      photoPath: widget.player1PhotoPath,
                      isSelected: state.selectedPlayer == SelectedPlayer.first,
                      isWinning: p1.totalPoints > p2.totalPoints,
                      onTap: () => cubit.onPlayerSelected(SelectedPlayer.first),
                    ),
                    // Weather
                    WeatherWidget(
                      frostActive:
                          selectedData
                              .cardsRows[CardsRowType.closeCombat]
                              ?.badWeather ??
                          false,
                      fogActive:
                          selectedData
                              .cardsRows[CardsRowType.longRange]
                              ?.badWeather ??
                          false,
                      rainActive:
                          selectedData
                              .cardsRows[CardsRowType.siege]
                              ?.badWeather ??
                          false,
                      onChanged: cubit.onWeatherChanged,
                    ),
                    // Player 2
                    UserWidget(
                      name: p2.name,
                      totalPoints: p2.totalPoints,
                      lives: p2.lives,
                      photoPath: widget.player2PhotoPath,
                      isSelected: state.selectedPlayer == SelectedPlayer.second,
                      isWinning: p2.totalPoints > p1.totalPoints,
                      onTap: () =>
                          cubit.onPlayerSelected(SelectedPlayer.second),
                    ),
                    // Pass button (long-press to end round)
                    _SidebarButton(
                      iconAsset: 'assets/icons/ic_reset.svg',
                      label: GameStrings.pass,
                      onLongPress: cubit.onEndRoundTapped,
                      tooltip: 'Long-press to end round',
                    ),
                  ],
                ),
              ),
              // Zone 2: Stats column
              StatsColumnWidget(
                cardsRows: selectedData.cardsRows,
                onHornChanged: cubit.onHornChanged,
              ),
              // Zone 3: Divider
              Container(
                width: GameView._dividerWidth,
                color: colorScheme.outline.withValues(alpha: 0.24),
              ),
              // Zone 4: Card rows
              Expanded(
                child: Column(
                  children: CardsRowType.values.map((rowType) {
                    final row = selectedData.cardsRows[rowType]!;
                    return Expanded(
                      child: CardsRowWidget(
                        row: row,
                        onAddCard: cubit.onAddCardRequested,
                        onCardLongPress: cubit.onEditCardRequested,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _SidebarButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;

  const _SidebarButton({
    required this.iconAsset,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(GameView._buttonPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: GameView._buttonIconSize,
              height: GameView._buttonIconSize,
              colorFilter: ColorFilter.mode(
                colorScheme.outline,
                BlendMode.srcIn,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: GameView._buttonLabelSize,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}
