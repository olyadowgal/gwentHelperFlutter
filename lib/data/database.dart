import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gwent_helper.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE game_score (
            date INTEGER PRIMARY KEY,
            first_player TEXT NOT NULL,
            second_player TEXT NOT NULL,
            winner TEXT NOT NULL,
            first_round_first_player INTEGER,
            second_round_first_player INTEGER,
            third_round_first_player INTEGER,
            first_round_second_player INTEGER,
            second_round_second_player INTEGER,
            third_round_second_player INTEGER
          )
        ''');
      },
    );
  }
}
