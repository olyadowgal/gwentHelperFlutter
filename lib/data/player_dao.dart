import 'package:sqflite/sqflite.dart';
import '../domain/models/player.dart';
import 'database.dart';

class PlayerDao {
  Future<Database> get _db => AppDatabase.instance;

  Future<void> insert(Player player) async {
    final db = await _db;
    await db.insert(
      'player',
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<void> update(Player player) async {
    final db = await _db;
    await db.update(
      'player',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  /// Soft-deletes a player: sets `deleted_at` and touches nothing else. An
  /// unknown [id] matches no row and is a no-op.
  Future<void> markDeleted(String id, DateTime deletedAt) async {
    final db = await _db;
    await db.update(
      'player',
      {'deleted_at': deletedAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Excludes soft-deleted players unless [includeDeleted] is set. Sorted
  /// case-insensitively in Dart: SQLite's `LOWER`/`NOCASE` only fold ASCII, so
  /// they would misorder Ukrainian and Polish names.
  Future<List<Player>> getAll({bool includeDeleted = false}) async {
    final db = await _db;
    final maps = await db.query(
      'player',
      where: includeDeleted ? null : 'deleted_at IS NULL',
    );
    final players = maps.map(Player.fromMap).toList();
    players.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return players;
  }

  /// Matches ignoring case and surrounding spaces, done in Dart for the same
  /// reason as [getAll]. Ignores deleted players. Returns the first match, or
  /// null.
  Future<Player?> findByName(String name) async {
    final wanted = _normalize(name);
    final players = await getAll();
    for (final player in players) {
      if (_normalize(player.name) == wanted) return player;
    }
    return null;
  }

  static String _normalize(String name) => name.trim().toLowerCase();
}
