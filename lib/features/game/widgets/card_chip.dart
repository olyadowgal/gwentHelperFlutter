import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';

class CardChip extends StatelessWidget {
  final Card card;
  final int displayPoints;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  const CardChip({
    super.key,
    required this.card,
    required this.displayPoints,
    this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isHero = card.abilities.contains(Ability.hero);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isHero ? colorScheme.primaryContainer : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.secondaryContainer),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$displayPoints',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (card.abilities.isNotEmpty)
              Text(
                card.abilities.map((a) => a.shortName).join(' '),
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
