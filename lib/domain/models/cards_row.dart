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

  int get _hornsCount =>
      (horn ? 1 : 0) + cards.where((c) => c.abilities.contains(Ability.horn)).length;

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

    final effectiveHorns =
        card.abilities.contains(Ability.horn) ? _hornsCount - 1 : _hornsCount;
    if (effectiveHorns > 0) {
      for (var i = 0; i < effectiveHorns; i++) {
        points *= 2;
      }
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
