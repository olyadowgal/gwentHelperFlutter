import 'package:flutter/material.dart' hide Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'card_chip.dart';

class CardsRowWidget extends StatelessWidget {
  final CardsRow row;
  final void Function(CardsRowType) onAddCard;
  final void Function(CardsRow, Card) onCardLongPress;
  final Set<String> scorchTargetIds;
  final void Function(CardsRowType, Card) onScorchTargetTap;

  const CardsRowWidget({
    super.key,
    required this.row,
    required this.onAddCard,
    required this.onCardLongPress,
    this.scorchTargetIds = const {},
    this.onScorchTargetTap = _noopScorchTap,
  });

  static void _noopScorchTap(CardsRowType rowType, Card card) {}

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        ...row.cards.map((card) {
          final isTarget = scorchTargetIds.contains(card.cardId);
          return CardChip(
            key: ValueKey(card.cardId),
            card: card,
            displayPoints: row.pointsOf(card),
            onLongPress: () => onCardLongPress(row, card),
            isScorchTarget: isTarget,
            onTap: isTarget ? () => onScorchTargetTap(row.type, card) : null,
          );
        }),
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/ic_plus_in_circle.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primaryContainer,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => onAddCard(row.type),
        ),
      ],
    ),
  );
}
