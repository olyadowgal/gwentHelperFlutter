import 'dart:math';
import 'ability.dart';
import 'card.dart';
import 'cards_row_type.dart';

class CardsRow {
  final CardsRowType type;
  final List<Card> cards;
  final bool horn;
  final bool badWeather;

  const CardsRow({
    required this.type,
    this.cards = const [],
    this.horn = false,
    this.badWeather = false,
  });

  int get totalPoints => cards.fold(0, (sum, card) => sum + pointsOf(card));

  int pointsOf(Card card) {
    assert(cards.contains(card), 'Card does not belong to this row');

    if (card.abilities.contains(Ability.decoy)) return 0;
    if (card.abilities.contains(Ability.hero)) return card.points;

    var points = card.points;

    if (badWeather) {
      points = min(points, 1);
    }

    if (card.abilities.contains(Ability.tightBond)) {
      final bondCount = cards
          .where((c) =>
              c.points == card.points && c.abilities.contains(Ability.tightBond))
          .length;
      points *= bondCount;
    }

    final moraleCount =
        cards.where((c) => c.abilities.contains(Ability.moraleBoost)).length;
    points += moraleCount;
    if (card.abilities.contains(Ability.moraleBoost)) {
      points--;
    }

    // Horn does not stack in Witcher 3 Gwent: any number of horn sources on
    // a row still only doubles it once, and a card's own horn ability never
    // doubles itself.
    final hornFromOtherSource =
        horn ||
        cards.any(
          (c) => c.cardId != card.cardId && c.abilities.contains(Ability.horn),
        );
    if (hornFromOtherSource) {
      points *= 2;
    }

    return points;
  }

  CardsRow copyWith({
    List<Card>? cards,
    bool? horn,
    bool? badWeather,
  }) {
    return CardsRow(
      type: type,
      cards: cards ?? this.cards,
      horn: horn ?? this.horn,
      badWeather: badWeather ?? this.badWeather,
    );
  }
}
