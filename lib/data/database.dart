import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  /// Drops the cached instance so the next [instance] access reopens the
  /// database file from disk, re-running `onCreate`/`onUpgrade`. Tests use
  /// this to exercise migrations against a db file they seeded themselves.
  @visibleForTesting
  static void resetForTest() => _db = null;

  /// The v2 `game_score` columns. Deliberately without the v3 player-link
  /// columns: the v1 -> v2 step rebuilds the table from this list, and the
  /// v3 step then adds those columns with `ALTER TABLE`.
  static const _tableColumns = '''
            id TEXT PRIMARY KEY,
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

  static const _playerColumns = '''
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            photo_file TEXT,
            created_at INTEGER NOT NULL
  ''';

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gwent_helper.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE game_score (
            $_tableColumns,
            first_player_id TEXT,
            second_player_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE player (
            $_playerColumns
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE game_score_v2 (
              $_tableColumns
            )
          ''');
          await db.execute('''
            INSERT INTO game_score_v2 (
              id, date, first_player, second_player, winner,
              first_round_first_player, second_round_first_player,
              third_round_first_player, first_round_second_player,
              second_round_second_player, third_round_second_player
            )
            SELECT
              'legacy-' || date, date, first_player, second_player, winner,
              first_round_first_player, second_round_first_player,
              third_round_first_player, first_round_second_player,
              second_round_second_player, third_round_second_player
            FROM game_score
          ''');
          await db.execute('DROP TABLE game_score');
          await db.execute('ALTER TABLE game_score_v2 RENAME TO game_score');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE player (
              $_playerColumns
            )
          ''');
          await db.execute(
            'ALTER TABLE game_score ADD COLUMN first_player_id TEXT',
          );
          await db.execute(
            'ALTER TABLE game_score ADD COLUMN second_player_id TEXT',
          );
        }
      },
    );
  }
}
