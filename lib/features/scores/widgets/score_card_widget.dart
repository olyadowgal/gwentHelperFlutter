import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import '../resources/scores_strings.dart';

class ScoreCardWidget extends StatelessWidget {
  final GameScore score;

  const ScoreCardWidget({super.key, required this.score});

  static String _pts(int? v) => v?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy  HH:mm').format(score.date);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
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
                      SvgPicture.asset(
                        'assets/icons/ic_crown.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          score.winner == score.firstPlayer
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score.firstPlayer,
                        style: Theme.of(context).textTheme.titleMedium,
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
                      SvgPicture.asset(
                        'assets/icons/ic_crown.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          score.winner == score.secondPlayer
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score.secondPlayer,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${ScoresStrings.winner}${score.winner}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              children: [
                TableRow(children: [
                  _HeaderCell(ScoresStrings.round),
                  _HeaderCell(score.firstPlayer),
                  _HeaderCell(score.secondPlayer),
                ]),
                TableRow(children: [
                  const _Cell(ScoresStrings.round1),
                  _Cell(_pts(score.firstRoundFirstPlayerPoints)),
                  _Cell(_pts(score.firstRoundSecondPlayerPoints)),
                ]),
                TableRow(children: [
                  const _Cell(ScoresStrings.round2),
                  _Cell(_pts(score.secondRoundFirstPlayerPoints)),
                  _Cell(_pts(score.secondRoundSecondPlayerPoints)),
                ]),
                TableRow(children: [
                  const _Cell(ScoresStrings.round3),
                  _Cell(_pts(score.thirdRoundFirstPlayerPoints)),
                  _Cell(_pts(score.thirdRoundSecondPlayerPoints)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.bold),
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
