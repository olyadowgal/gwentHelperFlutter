import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/database.dart';
import 'package:gwent_helper_flutter/data/game_score_dao.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The pre-migration schema: the original `game_score` table had no `id`
/// column, so `AppDatabase`'s v1 -> v2 upgrade derives one from `date`.
const _v1Columns = '''
    date INTEGER NOT NULL,
    first_player TEXT NOT NULL,
    second_player TEXT NOT NULL,
    winner TEXT NOT NULL,
    first_round_first_player INTEGER,
    second_round_first_player INTEGER,
    third_round_first_player INTEGER,
    first_round_second_player INTEGER,
    second_round_second_player INTEGER,
    third_round_second_player INTEGER
''';

/// The v2 schema: `game_score` has an `id` but no player-link columns and
/// there is no `player` table.
const _v2Columns =
    '''
    id TEXT PRIMARY KEY,
    $_v1Columns
''';

Future<Set<Object?>> _columnNames(Database db, String table) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  return columns.map((c) => c['name']).toSet();
}

/// Column name and declared type of every column, in table order.
Future<List<(Object?, Object?)>> _columnShape(Database db, String table) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  return columns.map((c) => (c['name'], c['type'])).toList();
}

/// The v3 `player` table: no `deleted_at` yet.
const _v3PlayerColumns = '''
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    photo_file TEXT,
    created_at INTEGER NOT NULL
''';

Future<bool> _tableExists(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    [table],
  );
  return rows.isNotEmpty;
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

  late String path;

  setUp(() async {
    path = join(await databaseFactory.getDatabasesPath(), 'gwent_helper.db');
    await databaseFactory.deleteDatabase(path);
  });

  tearDown(() async {
    AppDatabase.resetForTest();
    await databaseFactory.deleteDatabase(path);
  });

  group('AppDatabase v1 -> v2 migration', () {
    test(
      '''
      Given a v1 database with rows saved before `id` existed
      When `AppDatabase.instance` opens it
      Then rows survive with a legacy id derived from `date`
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v1Columns)');
            },
          ),
        );
        const date = 1700000000000;
        await legacyDb.insert('game_score', {
          'date': date,
          'first_player': 'Alice',
          'second_player': 'Bob',
          'winner': 'first',
          'first_round_first_player': 10,
          'second_round_first_player': 20,
          'third_round_first_player': 30,
          'first_round_second_player': 5,
          'second_round_second_player': 15,
          'third_round_second_player': 25,
        });
        await legacyDb.close();

        // When
        final db = await AppDatabase.instance;

        // Then
        expect(db.isOpen, isTrue);
        final rows = await db.query('game_score');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'legacy-$date');
        expect(rows.single['first_player'], 'Alice');
        expect(rows.single['second_player'], 'Bob');
      },
    );

    test(
      '''
      Given a v1 database with a saved game
      When it's read through `GameScoreDao.getAll` after migration
      Then the game is returned as a fully-formed `GameScore`
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v1Columns)');
            },
          ),
        );
        const date = 1650000000000;
        await legacyDb.insert('game_score', {
          'date': date,
          'first_player': 'Geralt',
          'second_player': 'Yennefer',
          'winner': 'second',
          'first_round_first_player': null,
          'second_round_first_player': null,
          'third_round_first_player': null,
          'first_round_second_player': null,
          'second_round_second_player': null,
          'third_round_second_player': null,
        });
        await legacyDb.close();
        AppDatabase.resetForTest();

        // When
        final scores = await GameScoreDao().getAll();

        // Then
        expect(scores, hasLength(1));
        final score = scores.single;
        expect(score.id, 'legacy-$date');
        expect(score.firstPlayer, 'Geralt');
        expect(score.secondPlayer, 'Yennefer');
        expect(score.secondPlayerWon, isTrue);
      },
    );

    test(
      '''
      Given no existing database file
      When `AppDatabase.instance` opens it for the first time
      Then it is created directly at v2 with an `id` column, skipping migration
      ''',
      () async {
        // When
        final db = await AppDatabase.instance;

        // Then
        final columns = await db.rawQuery('PRAGMA table_info(game_score)');
        final columnNames = columns.map((c) => c['name']).toSet();
        expect(columnNames, contains('id'));
      },
    );
  });

  group('AppDatabase v2 -> v3 migration', () {
    test(
      '''
      Given a v2 database with saved games
      When `AppDatabase.instance` opens it
      Then the empty `player` table exists and the games survive with null player ids
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v2Columns)');
            },
          ),
        );
        await legacyDb.insert('game_score', {
          'id': 'game-1',
          'date': 1700000000000,
          'first_player': 'Alice',
          'second_player': 'Bob',
          'winner': 'first',
        });
        await legacyDb.close();

        // When
        final db = await AppDatabase.instance;

        // Then
        expect(await _tableExists(db, 'player'), isTrue);
        expect(await db.query('player'), isEmpty);
        final rows = await db.query('game_score');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'game-1');
        expect(rows.single['first_player_id'], isNull);
        expect(rows.single['second_player_id'], isNull);
      },
    );

    test(
      '''
      Given a v2 database migrated to v3
      When a `GameScore` with player ids is inserted through `GameScoreDao`
      Then it round-trips with both ids
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v2Columns)');
            },
          ),
        );
        await legacyDb.close();
        final dao = GameScoreDao();
        final score = GameScore(
          date: DateTime(2026, 7, 6),
          firstPlayer: 'Alice',
          secondPlayer: 'Bob',
          winner: 'first',
          firstPlayerId: 'player-1',
          secondPlayerId: 'player-2',
        );

        // When
        await dao.insert(score);
        final scores = await dao.getAll();

        // Then
        expect(scores, hasLength(1));
        expect(scores.single.firstPlayerId, 'player-1');
        expect(scores.single.secondPlayerId, 'player-2');
      },
    );

    test(
      '''
      Given a v1 database with a saved game
      When `AppDatabase.instance` opens it
      Then it upgrades through v2 to v3 in one step with the player table and null player ids
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v1Columns)');
            },
          ),
        );
        const date = 1700000000000;
        await legacyDb.insert('game_score', {
          'date': date,
          'first_player': 'Alice',
          'second_player': 'Bob',
          'winner': 'first',
        });
        await legacyDb.close();

        // When
        final db = await AppDatabase.instance;

        // Then
        expect(await _tableExists(db, 'player'), isTrue);
        final columnNames = await _columnNames(db, 'game_score');
        expect(
          columnNames,
          containsAll(['first_player_id', 'second_player_id']),
        );
        final rows = await db.query('game_score');
        expect(rows, hasLength(1));
        expect(rows.single['id'], 'legacy-$date');
        expect(rows.single['first_player_id'], isNull);
        expect(rows.single['second_player_id'], isNull);
      },
    );

    test(
      '''
      Given no existing database file
      When `AppDatabase.instance` opens it for the first time
      Then the `player` table and both player-link columns exist
      ''',
      () async {
        // When
        final db = await AppDatabase.instance;

        // Then
        expect(await _tableExists(db, 'player'), isTrue);
        expect(
          await _columnNames(db, 'player'),
          unorderedEquals([
            'id',
            'name',
            'photo_file',
            'created_at',
            'deleted_at',
          ]),
        );
        expect(
          await _columnNames(db, 'game_score'),
          containsAll(['first_player_id', 'second_player_id']),
        );
      },
    );
  });

  group('AppDatabase v3 -> v4 migration', () {
    test(
      '''
      Given a v3 database with a saved player and games linked to it
      When `AppDatabase.instance` opens it
      Then every row survives, `deleted_at` exists and is null, and the links are unchanged
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE game_score (
                  $_v2Columns,
                  first_player_id TEXT,
                  second_player_id TEXT
                )
              ''');
              await db.execute('CREATE TABLE player ($_v3PlayerColumns)');
            },
          ),
        );
        await legacyDb.insert('player', {
          'id': 'player-1',
          'name': 'Alice',
          'photo_file': 'alice.jpg',
          'created_at': 1700000000000,
        });
        for (final gameId in ['game-1', 'game-2']) {
          await legacyDb.insert('game_score', {
            'id': gameId,
            'date': 1700000000000,
            'first_player': 'Alice',
            'second_player': 'Bob',
            'winner': 'first',
            'first_player_id': 'player-1',
          });
        }
        await legacyDb.close();

        // When
        final db = await AppDatabase.instance;

        // Then
        expect(await _columnNames(db, 'player'), contains('deleted_at'));
        final players = await db.query('player');
        expect(players, hasLength(1));
        expect(players.single['id'], 'player-1');
        expect(players.single['name'], 'Alice');
        expect(players.single['photo_file'], 'alice.jpg');
        expect(players.single['created_at'], 1700000000000);
        expect(players.single['deleted_at'], isNull);
        final games = await db.query('game_score', orderBy: 'id');
        expect(games.map((g) => g['id']), ['game-1', 'game-2']);
        expect(games.map((g) => g['first_player_id']), [
          'player-1',
          'player-1',
        ]);
        expect(games.map((g) => g['second_player_id']), [null, null]);
      },
    );

    test(
      '''
      Given a v2 database
      When `AppDatabase.instance` opens it
      Then it upgrades to v4 with `deleted_at` added once on the new `player` table
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v2Columns)');
            },
          ),
        );
        await legacyDb.close();

        // When
        final db = await AppDatabase.instance;

        // Then
        expect(
          await _columnNames(db, 'player'),
          unorderedEquals([
            'id',
            'name',
            'photo_file',
            'created_at',
            'deleted_at',
          ]),
        );
      },
    );

    test(
      '''
      Given a v1 database
      When `AppDatabase.instance` opens it
      Then it upgrades to v4 with `deleted_at` added once on the new `player` table
      ''',
      () async {
        // Given
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE game_score ($_v1Columns)');
            },
          ),
        );
        await legacyDb.close();

        // When
        final db = await AppDatabase.instance;

        // Then
        expect(
          await _columnNames(db, 'player'),
          unorderedEquals([
            'id',
            'name',
            'photo_file',
            'created_at',
            'deleted_at',
          ]),
        );
      },
    );

    test(
      '''
      Given no existing database file
      When `AppDatabase.instance` opens it for the first time
      Then `player` has a `deleted_at` column
      ''',
      () async {
        // When
        final db = await AppDatabase.instance;

        // Then
        expect(await _columnNames(db, 'player'), contains('deleted_at'));
      },
    );

    test(
      '''
      Given a fresh install and a database upgraded from v3
      When their `player` and `game_score` tables are inspected with `PRAGMA table_info`
      Then column names and types are identical
      ''',
      () async {
        // Given
        final fresh = await AppDatabase.instance;
        final freshPlayer = await _columnShape(fresh, 'player');
        final freshGames = await _columnShape(fresh, 'game_score');
        AppDatabase.resetForTest();
        await fresh.close();
        await databaseFactory.deleteDatabase(path);
        final legacyDb = await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE game_score (
                  $_v2Columns,
                  first_player_id TEXT,
                  second_player_id TEXT
                )
              ''');
              await db.execute('CREATE TABLE player ($_v3PlayerColumns)');
            },
          ),
        );
        await legacyDb.close();

        // When
        final upgraded = await AppDatabase.instance;

        // Then
        expect(await _columnShape(upgraded, 'player'), freshPlayer);
        expect(await _columnShape(upgraded, 'game_score'), freshGames);
        expect(freshPlayer.last, ('deleted_at', 'INTEGER'));
      },
    );
  });
}
