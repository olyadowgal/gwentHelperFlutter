import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import '../resources/scores_strings.dart';

class ScoreCardWidget extends StatelessWidget {
  static const _cardWidth = 280.0;

  final GameScore score;

  const ScoreCardWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) => SizedBox(
    // The history list scrolls horizontally, so each card gets a fixed
    // narrow width but fills the row's full height, leaving just the
    // margin as a gap top and bottom.
    width: _cardWidth,
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: _ScoreCardBody(score: score),
    ),
  );
}

class _ScoreCardBody extends StatelessWidget {
  const _ScoreCardBody({required this.score});

  final GameScore score;

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
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _Crown(
                      key: const Key('score-card-crown-first'),
                      won: score.firstPlayerWon,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(ScoresStrings.vs),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        secondPlayer,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _Crown(
                      key: const Key('score-card-crown-second'),
                      won: score.secondPlayerWon,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '${ScoresStrings.winner}${score.displayedWinner(tieLabel: ScoresStrings.tie, firstPlayerFallback: ScoresStrings.player1, secondPlayerFallback: ScoresStrings.player2)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          Table(
            // The round column only ever holds "1"/"2"/"3" — flexing it
            // equally with the player columns just stretches it with empty
            // space, which is exactly what made the old table look sparse.
            columnWidths: const {0: IntrinsicColumnWidth()},
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
  const _Crown({super.key, required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SvgPicture.asset(
      'assets/icons/ic_crown.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        won ? colorScheme.primary : colorScheme.outline,
        BlendMode.srcIn,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
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
  const _Cell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}
