import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';

void main() {
  group('CardsRow', () {
    group('`totalPoints`', () {
      test(
        '''
      Given two cards in a row
      When `totalPoints` is read
      Then it sums all cards
      ''',
        () {
          // Given
          final c1 = Card(points: 3, abilities: []);
          final c2 = Card(points: 4, abilities: []);
          final row = CardsRow(type: CardsRowType.closeCombat, cards: [c1, c2]);

          // Then
          expect(row.totalPoints, 7);
        },
      );
    });

    group('`pointsOf`', () {
      test(
        '''
      Given a decoy card
      When `pointsOf` is called
      Then it is always 0
      ''',
        () {
          // Given
          final card = Card(points: 10, abilities: [Ability.decoy]);
          final row = CardsRow(type: CardsRowType.closeCombat, cards: [card]);

          // Then
          expect(row.pointsOf(card), 0);
        },
      );

      test(
        '''
      Given a hero card under bad weather
      When `pointsOf` is called
      Then points are unchanged
      ''',
        () {
          // Given
          final card = Card(points: 10, abilities: [Ability.hero]);
          final row = CardsRow(
            type: CardsRowType.closeCombat,
            cards: [card],
            badWeather: true,
          );

          // Then
          expect(row.pointsOf(card), 10);
        },
      );

      test(
        '''
      Given a non-hero card under bad weather
      When `pointsOf` is called
      Then points clamp to 1
      ''',
        () {
          // Given
          final card = Card(points: 5, abilities: []);
          final row = CardsRow(
            type: CardsRowType.closeCombat,
            cards: [card],
            badWeather: true,
          );

          // Then
          expect(row.pointsOf(card), 1);
        },
      );

      test(
        '''
      Given two same-value tight bond cards
      When `pointsOf` is called
      Then points multiply by the bond count
      ''',
        () {
          // Given
          final c1 = Card(points: 5, abilities: [Ability.tightBond]);
          final c2 = Card(points: 5, abilities: [Ability.tightBond]);
          final row = CardsRow(type: CardsRowType.closeCombat, cards: [c1, c2]);

          // Then
          expect(row.pointsOf(c1), 10); // 5 * 2
        },
      );

      test(
        '''
      Given a horn on the row
      When `pointsOf` is called
      Then points double
      ''',
        () {
          // Given
          final card = Card(points: 5, abilities: []);
          final row = CardsRow(
            type: CardsRowType.closeCombat,
            cards: [card],
            horn: true,
          );

          // Then
          expect(row.pointsOf(card), 10);
        },
      );

      test(
        '''
      Given a morale boost card in the row
      When `pointsOf` is called
      Then other cards gain 1 but not itself
      ''',
        () {
          // Given
          final booster = Card(points: 1, abilities: [Ability.moraleBoost]);
          final target = Card(points: 5, abilities: []);
          final row = CardsRow(
            type: CardsRowType.closeCombat,
            cards: [booster, target],
          );

          // Then
          expect(row.pointsOf(target), 6); // 5 + 1 morale
          expect(row.pointsOf(booster), 1); // 1 + 1 morale - 1 self = 1
        },
      );
    });
  });
}
