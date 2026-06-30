import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../widgets/user_widget.dart';
import '../widgets/weather_widget.dart';

class GameView extends StatelessWidget {
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const GameView({
    super.key,
    this.player1PhotoPath,
    this.player2PhotoPath,
  });

  String _winnerMessage(Winner winner, String player1Name, String player2Name) =>
      switch (winner) {
        Winner.first => '$player1Name ${GameStrings.wins}',
        Winner.second => '$player2Name ${GameStrings.wins}',
        Winner.tie => GameStrings.tie,
      };

  @override
  Widget build(BuildContext context) =>
      BlocSideEffectHandler<GameCubit, GameState, GameSideEffect>(
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
                  content: Text(_winnerMessage(
                    winner,
                    state.gameData.firstPlayerData.name,
                    state.gameData.secondPlayerData.name,
                  )),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<GameCubit>().onGameOverConfirmed();
                      },
                      child: const Text(GameStrings.ok),
                    ),
                  ],
                ),
              );

            case NavigateBack():
              context.pop();
          }
        },
        child: BlocBuilder<GameCubit, GameState>(
          builder: (context, state) {
            final p1 = state.gameData.firstPlayerData;
            final p2 = state.gameData.secondPlayerData;
            final selectedData = state.selectedPlayerData;
            final cubit = context.read<GameCubit>();

            return Scaffold(
              appBar: AppBar(
                title: Text('${GameStrings.roundPrefix}${state.roundCounter + 1}'),
                actions: [
                  TextButton(
                    onPressed: cubit.onEndRoundTapped,
                    child: Text(
                      GameStrings.endRound,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: UserWidget(
                          name: p1.name,
                          totalPoints: p1.totalPoints,
                          lives: p1.lives,
                          photoPath: player1PhotoPath,
                          isSelected:
                              state.selectedPlayer == SelectedPlayer.first,
                          isWinning: p1.totalPoints > p2.totalPoints,
                          onTap: () =>
                              cubit.onPlayerSelected(SelectedPlayer.first),
                        ),
                      ),
                      Expanded(
                        child: UserWidget(
                          name: p2.name,
                          totalPoints: p2.totalPoints,
                          lives: p2.lives,
                          photoPath: player2PhotoPath,
                          isSelected:
                              state.selectedPlayer == SelectedPlayer.second,
                          isWinning: p2.totalPoints > p1.totalPoints,
                          onTap: () =>
                              cubit.onPlayerSelected(SelectedPlayer.second),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  WeatherWidget(
                    frostActive: selectedData
                            .cardsRows[CardsRowType.closeCombat]
                            ?.badWeather ??
                        false,
                    fogActive: selectedData
                            .cardsRows[CardsRowType.longRange]
                            ?.badWeather ??
                        false,
                    rainActive: selectedData
                            .cardsRows[CardsRowType.siege]
                            ?.badWeather ??
                        false,
                    onChanged: cubit.onWeatherChanged,
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: CardsRowType.values.map((rowType) {
                        final row = selectedData.cardsRows[rowType]!;
                        return CardsRowWidget(
                          row: row,
                          onAddCard: cubit.onAddCardRequested,
                          onCardLongPress: cubit.onEditCardRequested,
                          onHornChanged: cubit.onHornChanged,
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
