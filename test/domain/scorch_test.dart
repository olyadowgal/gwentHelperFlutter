import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/domain/scorch.dart';

void main() {
  Card unit(int points, {List<Ability> abilities = const []}) =>
      Card(points: points, abilities: abilities);

  PlayerData player({
    CardsRow? closeCombat,
    CardsRow? longRange,
    CardsRow? siege,
  }) => PlayerData(
    cardsRows: {
      CardsRowType.closeCombat:
          closeCombat ?? CardsRow(type: CardsRowType.closeCombat),
      CardsRowType.longRange:
          longRange ?? CardsRow(type: CardsRowType.longRange),
      CardsRowType.siege: siege ?? CardsRow(type: CardsRowType.siege),
    },
  );

  ScorchTarget target(PlayerSide side, CardsRowType rowType, Card card) =>
      ScorchTarget(side: side, rowType: rowType, cardId: card.cardId);

  group('specialScorchTargets', () {
    test(
      '''
      Given a single strongest non-hero unit on the battlefield
      When `specialScorchTargets` is called
      Then only that unit is returned
      ''',
      () {
        // Given
        final strongest = unit(7);
        final weaker = unit(4);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [strongest],
            ),
          ),
          secondPlayerData: player(
            siege: CardsRow(type: CardsRowType.siege, cards: [weaker]),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.closeCombat, strongest),
        ]);
      },
    );

    test(
      '''
      Given tied strongest units on both sides
      When `specialScorchTargets` is called
      Then every tied unit is returned
      ''',
      () {
        // Given
        final firstTied = unit(8);
        final secondTied = unit(8);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [firstTied, unit(3)],
            ),
          ),
          secondPlayerData: player(
            longRange: CardsRow(
              type: CardsRowType.longRange,
              cards: [secondTied],
            ),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.closeCombat, firstTied),
          target(PlayerSide.second, CardsRowType.longRange, secondTied),
        ]);
      },
    );

    test(
      '''
      Given a hero stronger than every regular unit
      When `specialScorchTargets` is called
      Then the hero is excluded and the strongest regular unit is returned
      ''',
      () {
        // Given
        final hero = unit(10, abilities: [Ability.hero]);
        final regular = unit(8);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [hero, regular],
            ),
          ),
          secondPlayerData: player(
            siege: CardsRow(type: CardsRowType.siege, cards: [unit(6)]),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.closeCombat, regular),
        ]);
      },
    );

    test(
      '''
      Given bad weather flattening the printed strongest unit
      When `specialScorchTargets` is called
      Then the target is chosen by current strength
      ''',
      () {
        // Given
        final flattened = unit(10);
        final survivor = unit(3);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [flattened],
              badWeather: true,
            ),
          ),
          secondPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [survivor],
            ),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.second, CardsRowType.closeCombat, survivor),
        ]);
      },
    );

    test(
      '''
      Given a weather-flattened row of mixed printed strengths
      When `specialScorchTargets` is called
      Then every non-hero unit is strength 1 and all of them are returned
      ''',
      () {
        // Given
        final firstFlattened = unit(10);
        final secondFlattened = unit(4);
        final otherSideUnit = unit(1);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [
                firstFlattened,
                secondFlattened,
                unit(8, abilities: [Ability.hero]),
              ],
              badWeather: true,
            ),
          ),
          secondPlayerData: player(
            siege: CardsRow(type: CardsRowType.siege, cards: [otherSideUnit]),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.closeCombat, firstFlattened),
          target(PlayerSide.first, CardsRowType.closeCombat, secondFlattened),
          target(PlayerSide.second, CardsRowType.siege, otherSideUnit),
        ]);
      },
    );

    test(
      '''
      Given row modifiers boosting a weaker printed unit
      When `specialScorchTargets` is called
      Then the boosted unit is returned instead of the higher printed one
      ''',
      () {
        // Given
        final boosted = unit(6);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [
                boosted,
                unit(1, abilities: [Ability.moraleBoost]),
              ],
              horn: true,
            ),
          ),
          secondPlayerData: player(
            longRange: CardsRow(
              type: CardsRowType.longRange,
              cards: [unit(11)],
            ),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.closeCombat, boosted),
        ]);
      },
    );

    test(
      '''
      Given tight-bond units whose bonded strength exceeds a higher printed unit
      When `specialScorchTargets` is called
      Then the bonded units are returned instead of the higher printed one
      ''',
      () {
        // Given
        final firstBond = unit(5, abilities: [Ability.tightBond]);
        final secondBond = unit(5, abilities: [Ability.tightBond]);
        final higherPrinted = unit(8);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [firstBond, secondBond],
            ),
          ),
          secondPlayerData: player(
            longRange: CardsRow(
              type: CardsRowType.longRange,
              cards: [higherPrinted],
            ),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.closeCombat, firstBond),
          target(PlayerSide.first, CardsRowType.closeCombat, secondBond),
        ]);
      },
    );

    test(
      '''
      Given an empty battlefield
      When `specialScorchTargets` is called
      Then no targets are returned
      ''',
      () {
        // Given
        final data = GameData(
          firstPlayerData: player(),
          secondPlayerData: player(),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, isEmpty);
      },
    );

    test(
      '''
      Given only zero-strength units on the battlefield
      When `specialScorchTargets` is called
      Then no targets are returned
      ''',
      () {
        // Given
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [
                unit(10, abilities: [Ability.decoy]),
              ],
            ),
          ),
          secondPlayerData: player(
            siege: CardsRow(
              type: CardsRowType.siege,
              cards: [
                unit(4, abilities: [Ability.decoy]),
              ],
            ),
          ),
        );

        // When
        final targets = specialScorchTargets(data);

        // Then
        expect(targets, isEmpty);
      },
    );
  });

  group('rowScorchTargets', () {
    test(
      '''
      Given an enemy row totaling nine
      When `rowScorchTargets` is called
      Then no targets are returned
      ''',
      () {
        // Given
        final data = GameData(
          firstPlayerData: player(),
          secondPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [unit(5), unit(4)],
            ),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.first,
          rowType: CardsRowType.closeCombat,
        );

        // Then
        expect(targets, isEmpty);
      },
    );

    test(
      '''
      Given an enemy row totaling exactly ten with tied strongest units
      When `rowScorchTargets` is called
      Then every tied unit of that row is returned
      ''',
      () {
        // Given
        final firstTied = unit(5);
        final secondTied = unit(5);
        final data = GameData(
          firstPlayerData: player(),
          secondPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [firstTied, secondTied],
            ),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.first,
          rowType: CardsRowType.closeCombat,
        );

        // Then
        expect(targets, [
          target(PlayerSide.second, CardsRowType.closeCombat, firstTied),
          target(PlayerSide.second, CardsRowType.closeCombat, secondTied),
        ]);
      },
    );

    test(
      '''
      Given hero strength pushing the enemy row to ten
      When `rowScorchTargets` is called
      Then the hero counts towards the threshold but cannot be targeted
      ''',
      () {
        // Given
        final regular = unit(3);
        final data = GameData(
          firstPlayerData: player(),
          secondPlayerData: player(
            longRange: CardsRow(
              type: CardsRowType.longRange,
              cards: [
                unit(7, abilities: [Ability.hero]),
                regular,
              ],
            ),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.first,
          rowType: CardsRowType.longRange,
        );

        // Then
        expect(targets, [
          target(PlayerSide.second, CardsRowType.longRange, regular),
        ]);
      },
    );

    test(
      '''
      Given an enemy row of heroes only reaching ten
      When `rowScorchTargets` is called
      Then no targets are returned
      ''',
      () {
        // Given
        final data = GameData(
          firstPlayerData: player(),
          secondPlayerData: player(
            siege: CardsRow(
              type: CardsRowType.siege,
              cards: [
                unit(6, abilities: [Ability.hero]),
                unit(6, abilities: [Ability.hero]),
              ],
            ),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.first,
          rowType: CardsRowType.siege,
        );

        // Then
        expect(targets, isEmpty);
      },
    );

    test(
      '''
      Given zero-strength units in a qualifying enemy row
      When `rowScorchTargets` is called
      Then only units of at least one strength are returned
      ''',
      () {
        // Given
        final strongest = unit(6);
        final data = GameData(
          firstPlayerData: player(),
          secondPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [
                unit(10, abilities: [Ability.decoy]),
                strongest,
                unit(4),
              ],
            ),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.first,
          rowType: CardsRowType.closeCombat,
        );

        // Then
        expect(targets, [
          target(PlayerSide.second, CardsRowType.closeCombat, strongest),
        ]);
      },
    );

    test(
      '''
      Given strong units in the owner's row and in other enemy rows
      When `rowScorchTargets` is called
      Then only the enemy's matching row is inspected
      ''',
      () {
        // Given
        final enemyCloseCombat = unit(6);
        final data = GameData(
          firstPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [unit(20)],
            ),
          ),
          secondPlayerData: player(
            closeCombat: CardsRow(
              type: CardsRowType.closeCombat,
              cards: [enemyCloseCombat, unit(4)],
            ),
            siege: CardsRow(type: CardsRowType.siege, cards: [unit(15)]),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.first,
          rowType: CardsRowType.closeCombat,
        );

        // Then
        expect(targets, [
          target(PlayerSide.second, CardsRowType.closeCombat, enemyCloseCombat),
        ]);
      },
    );

    test(
      '''
      Given the second player owns the row Scorch
      When `rowScorchTargets` is called
      Then the first player's matching row is targeted
      ''',
      () {
        // Given
        final enemyStrongest = unit(8);
        final data = GameData(
          firstPlayerData: player(
            longRange: CardsRow(
              type: CardsRowType.longRange,
              cards: [enemyStrongest, unit(2)],
            ),
          ),
          secondPlayerData: player(
            longRange: CardsRow(type: CardsRowType.longRange, cards: [unit(9)]),
          ),
        );

        // When
        final targets = rowScorchTargets(
          data,
          owner: PlayerSide.second,
          rowType: CardsRowType.longRange,
        );

        // Then
        expect(targets, [
          target(PlayerSide.first, CardsRowType.longRange, enemyStrongest),
        ]);
      },
    );
  });
}
