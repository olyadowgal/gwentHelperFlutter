import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';

class StatsColumnWidget extends StatelessWidget {
  final Map<CardsRowType, CardsRow> cardsRows;
  final void Function(CardsRowType, bool) onHornChanged;

  const StatsColumnWidget({
    super.key,
    required this.cardsRows,
    required this.onHornChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: CardsRowType.values.map((rowType) {
          final row = cardsRows[rowType]!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${row.cards.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => onHornChanged(rowType, !row.horn),
                child: SvgPicture.asset(
                  'assets/icons/ic_horn.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    row.horn ? colorScheme.primaryContainer : Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
