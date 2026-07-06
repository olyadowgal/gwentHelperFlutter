import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';

void main() {
  group('`CardsRow.totalPoints`', () {
    test('sums all cards', () {
      final c1 = Card(points: 3, abilities: []);
      final c2 = Card(points: 4, abilities: []);
      final row = CardsRow(type: CardsRowType.closeCombat, cards: [c1, c2]);
      expect(row.totalPoints, 7);
    });
  });

  group('`CardsRow.pointsOf`', () {
    test('decoy card is always 0', () {
      final card = Card(points: 10, abilities: [Ability.decoy]);
      final row = CardsRow(type: CardsRowType.closeCombat, cards: [card]);
      expect(row.pointsOf(card), 0);
    });

    test('hero is immune to weather', () {
      final card = Card(points: 10, abilities: [Ability.hero]);
      final row = CardsRow(
        type: CardsRowType.closeCombat,
        cards: [card],
        badWeather: true,
      );
      expect(row.pointsOf(card), 10);
    });

    test('bad weather clamps non-hero to 1', () {
      final card = Card(points: 5, abilities: []);
      final row = CardsRow(
        type: CardsRowType.closeCombat,
        cards: [card],
        badWeather: true,
      );
      expect(row.pointsOf(card), 1);
    });

    test('tight bond multiplies by count of same-value tight bond cards', () {
      final c1 = Card(points: 5, abilities: [Ability.tightBond]);
      final c2 = Card(points: 5, abilities: [Ability.tightBond]);
      final row = CardsRow(type: CardsRowType.closeCombat, cards: [c1, c2]);
      expect(row.pointsOf(c1), 10); // 5 * 2
    });

    test('horn doubles points', () {
      final card = Card(points: 5, abilities: []);
      final row = CardsRow(
        type: CardsRowType.closeCombat,
        cards: [card],
        horn: true,
      );
      expect(row.pointsOf(card), 10);
    });

    test('morale boost adds 1 to others but not itself', () {
      final booster = Card(points: 1, abilities: [Ability.moraleBoost]);
      final target = Card(points: 5, abilities: []);
      final row = CardsRow(
        type: CardsRowType.closeCombat,
        cards: [booster, target],
      );
      expect(row.pointsOf(target), 6); // 5 + 1 morale
      expect(row.pointsOf(booster), 1); // 1 + 1 morale - 1 self = 1
    });
  });
}
