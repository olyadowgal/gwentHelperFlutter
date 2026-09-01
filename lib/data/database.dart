import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

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

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gwent_helper.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE game_score (
            $_tableColumns
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
      },
    );
  }
}
