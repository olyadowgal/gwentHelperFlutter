import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import '../resources/game_strings.dart';
import 'card_chip.dart';

class CardsRowWidget extends StatelessWidget {
  final CardsRow row;
  final void Function(CardsRowType) onAddCard;
  final void Function(CardsRow, Card) onCardLongPress;
  final void Function(CardsRowType, bool) onHornChanged;

  const CardsRowWidget({
    super.key,
    required this.row,
    required this.onAddCard,
    required this.onCardLongPress,
    required this.onHornChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  Text(row.type.displayName,
                      style: const TextStyle(fontSize: 10)),
                  Text(
                    '${row.totalPoints}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(GameStrings.horn,
                          style: TextStyle(fontSize: 10)),
                      Checkbox(
                        value: row.horn,
                        onChanged: (v) => onHornChanged(row.type, v ?? false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...row.cards.map(
                      (card) => CardChip(
                        card: card,
                        displayPoints: row.pointsOf(card),
                        onLongPress: () => onCardLongPress(row, card),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => onAddCard(row.type),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
