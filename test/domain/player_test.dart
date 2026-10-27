import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';

void main() {
  final createdAt = DateTime.fromMillisecondsSinceEpoch(1783340000000);

  group('Player', () {
    group('`toMap` / `fromMap`', () {
      test(
        '''
      Given a `Player` with a photo
      When `toMap` then `fromMap` are called
      Then the restored `Player` equals the original
      ''',
        () {
          // Given
          final player = Player(
            id: 'player-1',
            name: 'Alice',
            photoFile: 'alice.jpg',
            createdAt: createdAt,
          );

          // When
          final restored = Player.fromMap(player.toMap());

          // Then
          expect(restored, player);
        },
      );

      test(
        '''
      Given a `Player` with a null `photoFile`
      When `toMap` then `fromMap` are called
      Then the restored `Player` equals the original and has no photo
      ''',
        () {
          // Given
          final player = Player(
            id: 'player-1',
            name: 'Alice',
            createdAt: createdAt,
          );

          // When
          final restored = Player.fromMap(player.toMap());

          // Then
          expect(restored, player);
          expect(restored.photoFile, isNull);
        },
      );

      test(
        '''
      Given a `Player`
      When `toMap` is called
      Then it uses the schema keys with `created_at` in epoch millis
      ''',
        () {
          // Given
          final player = Player(
            id: 'player-1',
            name: 'Alice',
            photoFile: 'alice.jpg',
            createdAt: createdAt,
          );

          // When
          final map = player.toMap();

          // Then
          expect(map, {
            'id': 'player-1',
            'name': 'Alice',
            'photo_file': 'alice.jpg',
            'created_at': createdAt.millisecondsSinceEpoch,
          });
        },
      );
    });

    group('`copyWith`', () {
      test(
        '''
      Given a `Player`
      When `copyWith` is called with a new `name`
      Then the name changes while `id` and `createdAt` are kept
      ''',
        () {
          // Given
          final player = Player(
            id: 'player-1',
            name: 'Alice',
            photoFile: 'alice.jpg',
            createdAt: createdAt,
          );

          // When
          final renamed = player.copyWith(name: 'Alicia');

          // Then
          expect(renamed.name, 'Alicia');
          expect(renamed.id, 'player-1');
          expect(renamed.createdAt, createdAt);
          expect(renamed.photoFile, 'alice.jpg');
        },
      );
    });

    group('constructor defaults', () {
      test(
        '''
      Given two `Player`s created without `id` or `createdAt`
      When they are constructed
      Then each gets a distinct generated `id` and a `createdAt`
      ''',
        () {
          // Given
          final before = DateTime.now();

          // When
          final first = Player(name: 'Alice');
          final second = Player(name: 'Bob');

          // Then
          expect(first.id, isNotEmpty);
          expect(first.id, isNot(second.id));
          expect(first.createdAt.isBefore(before), isFalse);
        },
      );
    });
  });
}
