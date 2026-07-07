import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';

void main() {
  group('PlayerData', () {
    group('defaults', () {
      test(
        '''
      Given no arguments
      When `PlayerData` is created
      Then it starts with 2 `lives` and all row types present and empty
      ''',
        () {
          // When
          final player = PlayerData(name: 'Alice');

          // Then
          expect(player.lives, 2);
          expect(player.cardsRows.keys.toSet(), CardsRowType.values.toSet());
          for (final row in player.cardsRows.values) {
            expect(row.cards, isEmpty);
            expect(row.horn, isFalse);
            expect(row.badWeather, isFalse);
          }
        },
      );
    });

    group('`totalPoints`', () {
      test(
        '''
      Given cards in multiple rows
      When `totalPoints` is read
      Then it sums points across all rows
      ''',
        () {
          // Given
          final player = PlayerData(
            cardsRows: {
              CardsRowType.closeCombat: CardsRow(
                type: CardsRowType.closeCombat,
                cards: [Card(points: 5, abilities: const [])],
              ),
              CardsRowType.longRange: CardsRow(
                type: CardsRowType.longRange,
                cards: [Card(points: 3, abilities: const [])],
              ),
              CardsRowType.siege: const CardsRow(type: CardsRowType.siege),
            },
          );

          // Then
          expect(player.totalPoints, 8);
        },
      );
    });

    group('`minusLife`', () {
      test(
        '''
      Given 2 `lives`
      When `minusLife` is called
      Then `lives` becomes 1
      ''',
        () {
          // When / Then
          expect(PlayerData().minusLife().lives, 1);
        },
      );

      test(
        '''
      Given 0 `lives`
      When `minusLife` is called
      Then `lives` stays 0
      ''',
        () {
          // When
          final dead = PlayerData(lives: 0).minusLife();

          // Then
          expect(dead.lives, 0);
        },
      );
    });

    group('`clearCards`', () {
      test(
        '''
      Given rows with cards, horn and weather set
      When `clearCards` is called
      Then `cards`/`horn`/`badWeather` reset and `name`/`lives` are kept
      ''',
        () {
          // Given
          final player = PlayerData(
            name: 'Alice',
            lives: 1,
            cardsRows: {
              for (final t in CardsRowType.values)
                t: CardsRow(
                  type: t,
                  cards: [Card(points: 4, abilities: const [])],
                  horn: true,
                  badWeather: true,
                ),
            },
          );

          // When
          final cleared = player.clearCards();

          // Then
          expect(cleared.name, 'Alice');
          expect(cleared.lives, 1);
          for (final row in cleared.cardsRows.values) {
            expect(row.cards, isEmpty);
            expect(row.horn, isFalse);
            expect(row.badWeather, isFalse);
          }
        },
      );
    });
  });
}
