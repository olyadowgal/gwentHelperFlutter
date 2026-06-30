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
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isHero ? Colors.amber : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.brown),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$displayPoints',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (card.abilities.isNotEmpty)
              Text(
                card.abilities.map((a) => a.shortName).join(' '),
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
