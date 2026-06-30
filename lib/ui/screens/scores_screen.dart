import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/game_score.dart';
import '../../state/score_provider.dart';
import '../../state/game_provider.dart';

class ScoresScreen extends ConsumerWidget {
  const ScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(scoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear All Scores'),
                  content: const Text('This will delete all game history. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(gwentRepositoryProvider).clearGames();
                ref.invalidate(scoresProvider);
              }
            },
          ),
        ],
      ),
      body: scoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (scores) {
          if (scores.isEmpty) {
            return const Center(child: Text('No games recorded yet.'));
          }
          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) => _ScoreCard(score: scores[index]),
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final GameScore score;

  const _ScoreCard({required this.score});

  String _pts(int? v) => v?.toString() ?? '—';

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
                  child: Text(
                    score.firstPlayer,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Text('vs'),
                Expanded(
                  child: Text(
                    score.secondPlayer,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Winner: ${score.winner}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Table(
              children: [
                TableRow(
                  children: [
                    const _TableHeader('Round'),
                    _TableHeader(score.firstPlayer),
                    _TableHeader(score.secondPlayer),
                  ],
                ),
                TableRow(
                  children: [
                    const _TableCell('1'),
                    _TableCell(_pts(score.firstRoundFirstPlayerPoints)),
                    _TableCell(_pts(score.firstRoundSecondPlayerPoints)),
                  ],
                ),
                TableRow(
                  children: [
                    const _TableCell('2'),
                    _TableCell(_pts(score.secondRoundFirstPlayerPoints)),
                    _TableCell(_pts(score.secondRoundSecondPlayerPoints)),
                  ],
                ),
                TableRow(
                  children: [
                    const _TableCell('3'),
                    _TableCell(_pts(score.thirdRoundFirstPlayerPoints)),
                    _TableCell(_pts(score.thirdRoundSecondPlayerPoints)),
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

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}
