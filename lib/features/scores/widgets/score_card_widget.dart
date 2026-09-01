import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import '../resources/scores_strings.dart';

class ScoreCardWidget extends StatelessWidget {
  final GameScore score;

  const ScoreCardWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Cards are light while the app's color scheme is dark, so the card needs
    // its own text colors to stay readable.
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: AppTheme.onLightCard,
          displayColor: AppTheme.onLightCard,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: _ScoreCardBody(score: score),
      ),
    );
  }
}

class _ScoreCardBody extends StatelessWidget {
  final GameScore score;

  const _ScoreCardBody({required this.score});

  static String _pts(int? v) => v?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy  HH:mm').format(score.date);
    final firstPlayer = score.displayedFirstPlayer(
      fallback: ScoresStrings.player1,
    );
    final secondPlayer = score.displayedSecondPlayer(
      fallback: ScoresStrings.player2,
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Crown(won: score.firstPlayerWon),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        firstPlayer,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(ScoresStrings.vs),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _Crown(won: score.secondPlayerWon),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        secondPlayer,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${ScoresStrings.winner}${score.displayedWinner(tieLabel: ScoresStrings.tie, firstPlayerFallback: ScoresStrings.player1, secondPlayerFallback: ScoresStrings.player2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Table(
            children: [
              TableRow(
                children: [
                  _HeaderCell(ScoresStrings.round),
                  _HeaderCell(firstPlayer),
                  _HeaderCell(secondPlayer),
                ],
              ),
              TableRow(
                children: [
                  const _Cell(ScoresStrings.round1),
                  _Cell(_pts(score.firstRoundFirstPlayerPoints)),
                  _Cell(_pts(score.firstRoundSecondPlayerPoints)),
                ],
              ),
              TableRow(
                children: [
                  const _Cell(ScoresStrings.round2),
                  _Cell(_pts(score.secondRoundFirstPlayerPoints)),
                  _Cell(_pts(score.secondRoundSecondPlayerPoints)),
                ],
              ),
              TableRow(
                children: [
                  const _Cell(ScoresStrings.round3),
                  _Cell(_pts(score.thirdRoundFirstPlayerPoints)),
                  _Cell(_pts(score.thirdRoundSecondPlayerPoints)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Crown extends StatelessWidget {
  final bool won;

  const _Crown({required this.won});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/ic_crown.svg',
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(
      won
          ? Theme.of(context).colorScheme.secondaryContainer
          : AppTheme.onLightCard,
      BlendMode.srcIn,
    ),
  );
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _Cell extends StatelessWidget {
  final String text;

  const _Cell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}
