import 'cards_row.dart';
import 'cards_row_type.dart';

class PlayerData {
  final String name;
  final int lives;
  final Map<CardsRowType, CardsRow> cardsRows;

  PlayerData({
    this.name = '',
    this.lives = 2,
    Map<CardsRowType, CardsRow>? cardsRows,
  }) : cardsRows = cardsRows ??
            {for (final t in CardsRowType.values) t: CardsRow(type: t)};

  int get totalPoints =>
      cardsRows.values.fold(0, (sum, row) => sum + row.totalPoints);

  PlayerData copyWith({
    String? name,
    int? lives,
    Map<CardsRowType, CardsRow>? cardsRows,
  }) {
    return PlayerData(
      name: name ?? this.name,
      lives: lives ?? this.lives,
      cardsRows: cardsRows ?? Map.from(this.cardsRows),
    );
  }

  PlayerData minusLife() {
    return copyWith(lives: (lives - 1).clamp(0, 2));
  }

  PlayerData clearCards() {
    return copyWith(
      cardsRows: {
        for (final entry in cardsRows.entries)
          entry.key: entry.value.copyWith(cards: [])
      },
    );
  }
}
