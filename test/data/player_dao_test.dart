import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/database.dart';
import 'package:gwent_helper_flutter/data/player_dao.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Test files run in parallel isolates; give each its own database
    // directory so they don't lock the same `gwent_helper.db`.
    final dir = Directory.systemTemp.createTempSync('gwent_helper_db_');
    addTearDown(() => dir.deleteSync(recursive: true));
    await databaseFactory.setDatabasesPath(dir.path);
  });

  late String path;
  late PlayerDao dao;

  // `createdAt` is stored in milliseconds, so fixtures use a whole-millisecond
  // timestamp to compare equal after a round trip.
  final createdAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  setUp(() async {
    path = join(await databaseFactory.getDatabasesPath(), 'gwent_helper.db');
    await databaseFactory.deleteDatabase(path);
    AppDatabase.resetForTest();
    dao = PlayerDao();
  });

  tearDown(() async {
    AppDatabase.resetForTest();
    await databaseFactory.deleteDatabase(path);
  });

  group('`PlayerDao`', () {
    test(
      '''
      Given a `Player`
      When `insert` then `getAll` are called
      Then the player is returned
      ''',
      () async {
        // Given
        final player = Player(
          name: 'Geralt',
          photoFile: 'geralt.jpg',
          createdAt: createdAt,
        );

        // When
        await dao.insert(player);
        final players = await dao.getAll();

        // Then
        expect(players, [player]);
      },
    );

    test(
      '''
      Given a stored `Player`
      When `update` is called with a new name and `photoFile`
      Then `getAll` returns the changed player with the same id
      ''',
      () async {
        // Given
        final player = Player(name: 'Geralt');
        await dao.insert(player);
        final changed = player.copyWith(name: 'Ciri', photoFile: 'ciri.jpg');

        // When
        await dao.update(changed);
        final players = await dao.getAll();

        // Then
        expect(players, hasLength(1));
        expect(players.single.id, player.id);
        expect(players.single.name, 'Ciri');
        expect(players.single.photoFile, 'ciri.jpg');
      },
    );

    test(
      '''
      Given players named `Łukasz`, `anna` and `Олег`
      When `getAll` is called
      Then they are sorted case-insensitively by name
      ''',
      () async {
        // Given
        await dao.insert(Player(name: 'Олег', createdAt: createdAt));
        await dao.insert(Player(name: 'anna'));
        await dao.insert(Player(name: 'Łukasz', createdAt: createdAt));

        // When
        final players = await dao.getAll();

        // Then
        expect(players.map((p) => p.name), ['anna', 'Łukasz', 'Олег']);
      },
    );

    test(
      '''
      Given players named `Łukasz` and `Олег`
      When `findByName` is called with different case and surrounding spaces
      Then the matching player is returned
      ''',
      () async {
        // Given
        final oleh = Player(name: 'Олег', createdAt: createdAt);
        final lukasz = Player(name: 'Łukasz', createdAt: createdAt);
        await dao.insert(oleh);
        await dao.insert(lukasz);

        // When
        final foundOleh = await dao.findByName('олег');
        final foundLukasz = await dao.findByName('  łukasz ');

        // Then
        expect(foundOleh, oleh);
        expect(foundLukasz, lukasz);
      },
    );

    test(
      '''
      Given a stored `Player` whose name has surrounding spaces
      When `findByName` is called with the trimmed name
      Then the player is returned
      ''',
      () async {
        // Given
        final player = Player(name: ' Anna ', createdAt: createdAt);
        await dao.insert(player);

        // When
        final found = await dao.findByName('anna');

        // Then
        expect(found, player);
      },
    );

    test(
      '''
      Given a stored `Player`
      When `findByName` is called with an unknown name
      Then null is returned
      ''',
      () async {
        // Given
        await dao.insert(Player(name: 'Geralt'));

        // When
        final found = await dao.findByName('Triss');

        // Then
        expect(found, isNull);
      },
    );

    test(
      '''
      Given a stored `Player`
      When `markDeleted` is called
      Then `getAll` hides it but `getAll(includeDeleted: true)` returns it with `deletedAt` set
      ''',
      () async {
        // Given
        final player = Player(name: 'Geralt', createdAt: createdAt);
        final other = Player(name: 'Ciri', createdAt: createdAt);
        await dao.insert(player);
        await dao.insert(other);
        final deletedAt = DateTime.fromMillisecondsSinceEpoch(1800000000000);

        // When
        await dao.markDeleted(player.id, deletedAt);
        final active = await dao.getAll();
        final all = await dao.getAll(includeDeleted: true);

        // Then
        expect(active, [other]);
        expect(all, [other, player.copyWith(deletedAt: deletedAt)]);
        expect(all.last.deletedAt, deletedAt);
        expect(all.last.isDeleted, isTrue);
      },
    );

    test(
      '''
      Given a deleted `Player` and an active player added afterwards with the same name
      When `findByName` is called
      Then only the active player is returned
      ''',
      () async {
        // Given
        final old = Player(name: 'Geralt', createdAt: createdAt);
        await dao.insert(old);
        await dao.markDeleted(
          old.id,
          DateTime.fromMillisecondsSinceEpoch(1800000000000),
        );
        final deletedOnly = await dao.findByName('geralt');
        final fresh = Player(name: 'Geralt', createdAt: createdAt);
        await dao.insert(fresh);

        // When
        final found = await dao.findByName(' geralt ');

        // Then
        expect(deletedOnly, isNull);
        expect(found, fresh);
        expect(found!.id, isNot(old.id));
      },
    );

    test(
      '''
      Given no player with the id
      When `markDeleted` is called with an unknown id
      Then nothing throws and other players are untouched
      ''',
      () async {
        // Given
        final player = Player(name: 'Geralt', createdAt: createdAt);
        await dao.insert(player);

        // When
        await dao.markDeleted('missing', createdAt);

        // Then
        expect(await dao.getAll(), [player]);
      },
    );
  });
}
