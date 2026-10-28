import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/score_player.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:gwent_helper_flutter/widgets/hud/hud_avatar.dart';

class ScoreCardWidget extends StatelessWidget {
  static const _cardWidth = 280.0;

  final GameScore score;

  /// The saved player each side is linked to (deleted players included), or
  /// null for a guest or an unknown id; the card then falls back to the name
  /// stored with the game and a placeholder avatar.
  final ScorePlayer? firstPlayer;
  final ScorePlayer? secondPlayer;

  const ScoreCardWidget({
    super.key,
    required this.score,
    this.firstPlayer,
    this.secondPlayer,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    // The history list scrolls horizontally, so each card gets a fixed
    // narrow width but fills the row's full height, leaving just the
    // margin as a gap top and bottom.
    width: _cardWidth,
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: _ScoreCardBody(
        score: score,
        firstPlayer: firstPlayer,
        secondPlayer: secondPlayer,
      ),
    ),
  );
}

class _ScoreCardBody extends StatelessWidget {
  const _ScoreCardBody({
    required this.score,
    required this.firstPlayer,
    required this.secondPlayer,
  });

  final GameScore score;
  final ScorePlayer? firstPlayer;
  final ScorePlayer? secondPlayer;

  static String _pts(int? v) => v?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('MMM d, yyyy  HH:mm').format(score.date);
    final firstName =
        firstPlayer?.name ?? score.displayedFirstPlayer(fallback: l10n.player1);
    final secondName =
        secondPlayer?.name ??
        score.displayedSecondPlayer(fallback: l10n.player2);
    final winnerName = score.firstPlayerWon
        ? firstName
        : score.secondPlayerWon
        ? secondName
        : l10n.scoresTie;
    return Padding(
      padding: const EdgeInsets.all(14),
      // A short landscape phone cannot always fit the date, names, winner and
      // three-round table, so the card scrolls rather than spilling out of
      // its bottom edge.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PlayerAvatar(player: firstPlayer),
                Expanded(
                  child: Text(
                    dateStr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _PlayerAvatar(player: secondPlayer),
              ],
            ),
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
                          firstName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(l10n.scoresVs),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          secondName,
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
                l10n.winner(winnerName),
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
                    _HeaderCell(l10n.round),
                    _HeaderCell(firstName),
                    _HeaderCell(secondName),
                  ],
                ),
                TableRow(
                  children: [
                    // Round numbers are plain numerals — universal across every
                    // supported language, no translation needed.
                    const _Cell('1'),
                    _Cell(_pts(score.firstRoundFirstPlayerPoints)),
                    _Cell(_pts(score.firstRoundSecondPlayerPoints)),
                  ],
                ),
                TableRow(
                  children: [
                    const _Cell('2'),
                    _Cell(_pts(score.secondRoundFirstPlayerPoints)),
                    _Cell(_pts(score.secondRoundSecondPlayerPoints)),
                  ],
                ),
                TableRow(
                  children: [
                    const _Cell('3'),
                    _Cell(_pts(score.thirdRoundFirstPlayerPoints)),
                    _Cell(_pts(score.thirdRoundSecondPlayerPoints)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player});

  static const _size = 32.0;

  final ScorePlayer? player;

  @override
  Widget build(BuildContext context) {
    final photoPath = player?.photoPath;
    return HudAvatar(
      size: _size,
      iconSize: _size / 2,
      image: photoPath == null ? null : FileImage(File(photoPath)),
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
