import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/database.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/data/player_dao.dart';
import 'package:gwent_helper_flutter/data/player_photo_store.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _ThrowingPlayerDao extends PlayerDao {
  @override
  Future<void> insert(Player player) async {
    throw StateError('insert failed');
  }

  @override
  Future<void> update(Player player) async {
    throw StateError('update failed');
  }
}

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

  late String dbPath;
  late Directory documents;
  late Directory photosDir;
  late File source;
  late PlayerPhotoStore photoStore;
  late GwentRepository repository;

  setUp(() async {
    dbPath = join(await databaseFactory.getDatabasesPath(), 'gwent_helper.db');
    await databaseFactory.deleteDatabase(dbPath);
    AppDatabase.resetForTest();

    documents = Directory.systemTemp.createTempSync('gwent_repository_test');
    photosDir = Directory('${documents.path}/player_photos');
    source = File('${documents.path}/cropped_source.jpg')
      ..writeAsBytesSync([1, 2, 3, 4, 5]);
    photoStore = PlayerPhotoStore(documentsDirectory: () async => documents);
    repository = GwentRepository(photoStore: photoStore);
  });

  tearDown(() async {
    AppDatabase.resetForTest();
    await databaseFactory.deleteDatabase(dbPath);
    documents.deleteSync(recursive: true);
  });

  group('`GwentRepository` players', () {
    test(
      '''
      Given a name with surrounding spaces and a temporary photo
      When `createPlayer` is called
      Then the player has the trimmed name and a stored `photoFile`
      And `getPlayers` returns it
      ''',
      () async {
        // Given
        const name = '  Geralt ';

        // When
        final created = await repository.createPlayer(
          name: name,
          photoTempPath: source.path,
        );
        final players = await repository.getPlayers();

        // Then
        expect(created.name, 'Geralt');
        expect(created.photoFile, isNotNull);
        expect(
          File('${photosDir.path}/${created.photoFile}').existsSync(),
          isTrue,
        );
        expect(players, [created]);
      },
    );

    test(
      '''
      Given no photo
      When `createPlayer` is called
      Then `photoFile` is null
      ''',
      () async {
        // Given
        const name = 'Geralt';

        // When
        final created = await repository.createPlayer(name: name);
        final players = await repository.getPlayers();

        // Then
        expect(created.photoFile, isNull);
        expect(players.single.photoFile, isNull);
      },
    );

    test(
      '''
      Given a stored player with a photo
      When `updatePlayer` is called with a new name only
      Then the name changes and the `photoFile` is kept
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(
          name: 'Geralt',
          photoTempPath: source.path,
        );

        // When
        final updated = await repository.updatePlayer(created, name: ' Ciri ');
        final players = await repository.getPlayers();

        // Then
        expect(updated.name, 'Ciri');
        expect(updated.photoFile, created.photoFile);
        expect(players, [updated]);
        expect(
          File('${photosDir.path}/${created.photoFile}').existsSync(),
          isTrue,
        );
      },
    );

    test(
      '''
      Given a stored player with a photo
      When `updatePlayer` is called with a new `photoTempPath`
      Then the player gets a new `photoFile`
      And the new file exists and the old file is gone
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(
          name: 'Geralt',
          photoTempPath: source.path,
        );

        // When
        final updated = await repository.updatePlayer(
          created,
          photoTempPath: source.path,
        );
        final players = await repository.getPlayers();

        // Then
        expect(updated.photoFile, isNotNull);
        expect(updated.photoFile, isNot(created.photoFile));
        expect(players, [updated]);
        expect(
          File('${photosDir.path}/${updated.photoFile}').existsSync(),
          isTrue,
        );
        expect(
          File('${photosDir.path}/${created.photoFile}').existsSync(),
          isFalse,
        );
      },
    );

    test(
      '''
      Given a stored player with a photo
      When `photoPathOf` is called
      Then the absolute path of the existing file is returned
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(
          name: 'Geralt',
          photoTempPath: source.path,
        );

        // When
        final path = await repository.photoPathOf(created);

        // Then
        expect(path, '${photosDir.path}/${created.photoFile}');
      },
    );

    test(
      '''
      Given a player without a photo
      When `photoPathOf` is called
      Then null is returned
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(name: 'Geralt');

        // When
        final path = await repository.photoPathOf(created);

        // Then
        expect(path, isNull);
      },
    );

    test(
      '''
      Given a stored player whose photo file was deleted from disk
      When `photoPathOf` is called
      Then null is returned
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(
          name: 'Geralt',
          photoTempPath: source.path,
        );
        File('${photosDir.path}/${created.photoFile}').deleteSync();

        // When
        final path = await repository.photoPathOf(created);

        // Then
        expect(path, isNull);
      },
    );

    test(
      '''
      Given a stored player named `Łukasz`
      When `findPlayerByName` is called with `ŁUKASZ`
      Then the player is returned
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(name: 'Łukasz');

        // When
        final found = await repository.findPlayerByName('ŁUKASZ');

        // Then
        expect(found, created);
      },
    );

    test(
      '''
      Given a `PlayerDao` whose `insert` throws
      When `createPlayer` is called with a photo
      Then the error is rethrown
      And no orphan file is left in `player_photos`
      ''',
      () async {
        // Given
        final failing = GwentRepository(
          playerDao: _ThrowingPlayerDao(),
          photoStore: photoStore,
        );

        // When
        final call = failing.createPlayer(
          name: 'Geralt',
          photoTempPath: source.path,
        );

        // Then
        await expectLater(call, throwsStateError);
        expect(photosDir.listSync(), isEmpty);
      },
    );

    test(
      '''
      Given a stored player with a photo and a `PlayerDao` whose `update` throws
      When `updatePlayer` is called with a new photo
      Then the error is rethrown
      And the previous photo is kept and the new copy is removed
      ''',
      () async {
        // Given
        final created = await repository.createPlayer(
          name: 'Geralt',
          photoTempPath: source.path,
        );
        final failing = GwentRepository(
          playerDao: _ThrowingPlayerDao(),
          photoStore: photoStore,
        );

        // When
        final call = failing.updatePlayer(created, photoTempPath: source.path);

        // Then
        await expectLater(call, throwsStateError);
        final files = photosDir.listSync().map((f) => basename(f.path));
        expect(files, [created.photoFile]);
      },
    );
  });
}
