import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/database.dart';
import 'package:gwent_helper_flutter/data/game_score_dao.dart';
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

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
}
