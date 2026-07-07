import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';

void main() {
  group('GameData', () {
    group('`winner`', () {
      PlayerData playerWithPoints(int points) {
        final card = Card(points: points, abilities: []);
        final row = CardsRow(type: CardsRowType.closeCombat, cards: [card]);
        return PlayerData(
          cardsRows: {
            CardsRowType.closeCombat: row,
            CardsRowType.longRange: CardsRow(type: CardsRowType.longRange),
            CardsRowType.siege: CardsRow(type: CardsRowType.siege),
          },
        );
      }

      test(
        '''
      Given the first player has more points
      When `winner` is read
      Then it is `Winner.first`
      ''',
        () {
          // Given
          final game = GameData(
            firstPlayerData: playerWithPoints(10),
            secondPlayerData: playerWithPoints(5),
          );

          // Then
          expect(game.winner, Winner.first);
        },
      );

      test(
        '''
      Given the second player has more points
      When `winner` is read
      Then it is `Winner.second`
      ''',
        () {
          // Given
          final game = GameData(
            firstPlayerData: playerWithPoints(3),
            secondPlayerData: playerWithPoints(8),
          );

          // Then
          expect(game.winner, Winner.second);
        },
      );

      test(
        '''
      Given equal points
      When `winner` is read
      Then it is `Winner.tie`
      ''',
        () {
          // Given
          final game = GameData(
            firstPlayerData: playerWithPoints(7),
            secondPlayerData: playerWithPoints(7),
          );

          // Then
          expect(game.winner, Winner.tie);
        },
      );
    });
  });
}
