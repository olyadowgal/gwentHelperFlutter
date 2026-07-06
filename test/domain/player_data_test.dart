import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';

void main() {
  group('`PlayerData` defaults', () {
    test(
      'Given no arguments\n'
      'When `PlayerData` is created\n'
      'Then it starts with 2 `lives` and all row types present and empty',
      () {
        final player = PlayerData(name: 'Alice');
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
    test('Given cards in multiple rows\n'
        'When `totalPoints` is read\n'
        'Then it sums points across all rows', () {
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
      expect(player.totalPoints, 8);
    });
  });

  group('`minusLife`', () {
    test('Given 2 `lives`\n'
        'When `minusLife` is called\n'
        'Then `lives` becomes 1', () {
      expect(PlayerData().minusLife().lives, 1);
    });

    test('Given 0 `lives`\n'
        'When `minusLife` is called\n'
        'Then `lives` stays 0', () {
      final dead = PlayerData(lives: 0).minusLife();
      expect(dead.lives, 0);
    });
  });

  group('`clearCards`', () {
    test(
      'Given rows with cards, horn and weather set\n'
      'When `clearCards` is called\n'
      'Then `cards`/`horn`/`badWeather` reset and `name`/`lives` are kept',
      () {
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
        final cleared = player.clearCards();
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
}
