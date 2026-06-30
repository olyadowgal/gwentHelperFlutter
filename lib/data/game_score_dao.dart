import 'package:sqflite/sqflite.dart';
import '../domain/models/game_score.dart';
import 'database.dart';

class GameScoreDao {
  Future<Database> get _db => AppDatabase.instance;

  Future<void> insert(GameScore score) async {
    final db = await _db;
    await db.insert(
      'game_score',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<List<GameScore>> getAll() async {
    final db = await _db;
    final maps = await db.query('game_score', orderBy: 'date DESC');
    return maps.map(GameScore.fromMap).toList();
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('game_score');
  }
}
