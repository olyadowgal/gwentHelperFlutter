import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';

void main() {
  group('`PlayerData` defaults', () {
    test('starts with 2 `lives` and all row types present and empty', () {
      final player = PlayerData(name: 'Alice');
      expect(player.lives, 2);
      expect(player.cardsRows.keys.toSet(), CardsRowType.values.toSet());
      for (final row in player.cardsRows.values) {
        expect(row.cards, isEmpty);
        expect(row.horn, isFalse);
        expect(row.badWeather, isFalse);
      }
    });
  });

  group('`totalPoints`', () {
    test('sums points across all rows', () {
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
    test('decrements `lives`', () {
      expect(PlayerData().minusLife().lives, 1);
    });

    test('clamps at 0', () {
      final dead = PlayerData(lives: 0).minusLife();
      expect(dead.lives, 0);
    });
  });

  group('`clearCards`', () {
    test(
      'empties `cards` and resets `horn`/`badWeather`, keeps `name` and `lives`',
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
