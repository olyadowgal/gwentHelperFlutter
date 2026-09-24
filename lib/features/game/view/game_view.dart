import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/arch/bloc_side_effect_handler.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/domain/scorch.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_side_effect.dart';
import '../cubit/game_state.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/cards_row_widget.dart';
import '../widgets/edit_card_dialog.dart';
import '../widgets/stats_column_widget.dart';
import '../widgets/user_widget.dart';
import '../widgets/weather_widget.dart';

class GameView extends StatefulWidget {
  /// Names the sidebar panel so tests can read its chrome.
  static const sidebarKey = Key('game-sidebar');

  static const _sidebarWidth = 90.0;
  static const _buttonIconSize = 18.0;
  static const _buttonLabelSize = 10.0;
  static const _buttonPadding = 6.0;
  static const _dividerWidth = 1.0;

  /// Wider than [_dividerWidth] so the close/ranged/siege rows read as
  /// distinct bands instead of one continuous strip.
  static const _rowDividerWidth = 3.0;

  /// Keeps each row (and its divider) off the board's left/right edges.
  static const _rowHorizontalInset = 16.0;

  /// Olive is loud at full strength for a separator, so the in-board hairlines
  /// only hint at the grid.
  static const _hairlineAlpha = 0.24;

  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const GameView({super.key, this.player1PhotoPath, this.player2PhotoPath});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  String _winnerMessage(
    AppLocalizations l10n,
    Winner winner,
    String player1Name,
    String player2Name,
  ) => switch (winner) {
    Winner.first => l10n.playerWins(player1Name),
    Winner.second => l10n.playerWins(player2Name),
    Winner.tie => l10n.tie,
  };

  void _showExitDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitTitle),
        content: Text(l10n.exitContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.gameCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
  }

  void _showPassConfirmDialog(BuildContext context) {
    final cubit = context.read<GameCubit>();
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.passConfirmTitle),
        content: Text(l10n.passConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.gameCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.onEndRoundTapped();
            },
            child: Text(l10n.endRound),
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
      final l10n = AppLocalizations.of(context)!;
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
              title: Text(l10n.gameOverTitle),
              content: Text(
                _winnerMessage(
                  l10n,
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
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );

        case NavigateBack():
          context.go('/');
        case ShowSaveFailed():
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
        case ShowNoScorchTargets(:final reason):
          final message = switch (reason) {
            ScorchNoTargetReason.nothingToScorch => l10n.nothingToScorch,
            ScorchNoTargetReason.rowBelowTen => l10n.rowBelowTen,
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        case ShowMusterCountDialog(:final rowType, :final card, :final owner):
          showDialog<int>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.musterTitle),
              content: Text(l10n.musterCount),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.gameCancel),
                ),
                for (var count = 1; count <= 4; count++)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(count),
                    child: Text('$count'),
                  ),
              ],
            ),
          ).then((count) {
            if (count == null || !context.mounted) return;
            context.read<GameCubit>().onMusterCountChosen(
              rowType,
              card,
              count,
              owner,
            );
          });
      }
    },
    child: BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final p1 = state.gameData.firstPlayerData;
        final p2 = state.gameData.secondPlayerData;
        final selectedData = state.selectedPlayerData;
        final cubit = context.read<GameCubit>();
        final colorScheme = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                // Zone 1: Sidebar
                Container(
                  key: GameView.sidebarKey,
                  width: GameView._sidebarWidth,
                  decoration: BoxDecoration(
                    color: AppTheme.sidebarSurface,
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.sidebarTrim,
                        width: GameView._dividerWidth,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Exit button
                      _SidebarButton(
                        iconAsset: 'assets/icons/ic_exit.svg',
                        label: l10n.exit,
                        onTap: () => _showExitDialog(context),
                      ),
                      // Players and weather shrink to fit so that the exit and
                      // pass buttons always stay on screen.
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Player 1
                              UserWidget(
                                name: p1.name,
                                totalPoints: p1.totalPoints,
                                lives: p1.lives,
                                photoPath: widget.player1PhotoPath,
                                isSelected:
                                    state.selectedPlayer == PlayerSide.first,
                                isWinning: p1.totalPoints > p2.totalPoints,
                                onTap: () =>
                                    cubit.onPlayerSelected(PlayerSide.first),
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
                              // Scorch sits between the two players — it
                              // reads as a shared action, not one belonging
                              // to whichever player happens to be below it.
                              _SidebarButton(
                                icon: Icons.local_fire_department,
                                label: l10n.scorch,
                                onTap: cubit.onScorchTapped,
                                tooltip: l10n.scorchHint,
                              ),
                              // Player 2
                              UserWidget(
                                name: p2.name,
                                totalPoints: p2.totalPoints,
                                lives: p2.lives,
                                photoPath: widget.player2PhotoPath,
                                isSelected:
                                    state.selectedPlayer == PlayerSide.second,
                                isWinning: p2.totalPoints > p1.totalPoints,
                                onTap: () =>
                                    cubit.onPlayerSelected(PlayerSide.second),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Pass button (long-press, then confirm, to end round)
                      _SidebarButton(
                        iconAsset: 'assets/icons/ic_reset.svg',
                        label: l10n.pass,
                        onLongPress: () => _showPassConfirmDialog(context),
                        tooltip: l10n.passHint,
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
                  color: colorScheme.outline.withValues(
                    alpha: GameView._hairlineAlpha,
                  ),
                ),
                // Zone 4: Card rows
                Expanded(
                  child: Column(
                    // Each row's Container shrink-wraps to its cards by
                    // default, so its bottom-border divider would only span
                    // the cards instead of the full board width.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.scorchPrompt != null)
                        _ScorchBanner(
                          prompt: state.scorchPrompt!,
                          selectedPlayer: state.selectedPlayer,
                          onCancel: cubit.onScorchPickCancelled,
                        ),
                      ...CardsRowType.values.indexed.map((entry) {
                        final (index, rowType) = entry;
                        final isLastRow =
                            index == CardsRowType.values.length - 1;
                        final row = selectedData.cardsRows[rowType]!;
                        final targetIds = <String>{
                          for (final target
                              in state.scorchPrompt?.targets ?? const [])
                            if (target.side == state.selectedPlayer &&
                                target.rowType == rowType)
                              target.cardId,
                        };
                        return Expanded(
                          child: Container(
                            // Insets the row itself, not just the divider —
                            // a full-bleed board reads as harsh, not sleek.
                            margin: const EdgeInsets.symmetric(
                              horizontal: GameView._rowHorizontalInset,
                            ),
                            decoration: isLastRow
                                ? null
                                : BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: colorScheme.outline.withValues(
                                          alpha: GameView._hairlineAlpha,
                                        ),
                                        width: GameView._rowDividerWidth,
                                      ),
                                    ),
                                  ),
                            child: CardsRowWidget(
                              row: row,
                              onAddCard: cubit.onAddCardRequested,
                              onCardLongPress: cubit.onEditCardRequested,
                              scorchTargetIds: targetIds,
                              onScorchTargetTap: (type, card) {
                                cubit.onScorchTargetTapped(
                                  ScorchTarget(
                                    side: state.selectedPlayer,
                                    rowType: type,
                                    cardId: card.cardId,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _SidebarButton extends StatelessWidget {
  final String? iconAsset;
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;

  const _SidebarButton({
    this.iconAsset,
    this.icon,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Every sidebar control is an action rather than a toggle, so its mark
    // stays gold and its label reads in cream.
    final markColor = colorScheme.primary;
    final mark = icon != null
        ? Icon(icon, size: GameView._buttonIconSize, color: markColor)
        : SvgPicture.asset(
            iconAsset!,
            width: GameView._buttonIconSize,
            height: GameView._buttonIconSize,
            colorFilter: ColorFilter.mode(markColor, BlendMode.srcIn),
          );
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(GameView._buttonPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            Text(
              label,
              style: TextStyle(
                fontSize: GameView._buttonLabelSize,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
    return tooltip != null
        ? Tooltip(
            message: tooltip!,
            triggerMode: TooltipTriggerMode.tap,
            child: button,
          )
        : button;
  }
}

class _ScorchBanner extends StatelessWidget {
  final ScorchPrompt prompt;
  final PlayerSide selectedPlayer;
  final VoidCallback onCancel;

  const _ScorchBanner({
    required this.prompt,
    required this.selectedPlayer,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final otherSide = prompt.targets.any((t) => t.side != selectedPlayer);
    final l10n = AppLocalizations.of(context)!;
    final remaining = l10n.scorchRemaining(prompt.targets.length);
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                otherSide ? '$remaining. ${l10n.scorchOtherSide}' : remaining,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(onPressed: onCancel, child: Text(l10n.gameCancel)),
          ],
        ),
      ),
    );
  }
}
