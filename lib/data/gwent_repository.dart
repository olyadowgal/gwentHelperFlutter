import '../domain/models/game_score.dart';
import '../domain/models/player.dart';
import 'game_score_dao.dart';
import 'player_dao.dart';
import 'player_photo_store.dart';

class GwentRepository {
  final GameScoreDao _dao;
  final PlayerDao _playerDao;
  final PlayerPhotoStore _photoStore;

  GwentRepository({
    GameScoreDao? dao,
    PlayerDao? playerDao,
    PlayerPhotoStore? photoStore,
  }) : _dao = dao ?? GameScoreDao(),
       _playerDao = playerDao ?? PlayerDao(),
       _photoStore = photoStore ?? PlayerPhotoStore();

  Future<void> addGame(GameScore score) => _dao.insert(score);
  Future<List<GameScore>> getGames() => _dao.getAll();
  Future<void> clearGames() => _dao.deleteAll();

  Future<List<Player>> getPlayers() => _playerDao.getAll();

  Future<Player?> findPlayerByName(String name) => _playerDao.findByName(name);

  /// Saves a player with the trimmed [name]. The photo is copied into
  /// permanent storage first; if the insert fails, that copy is removed again.
  Future<Player> createPlayer({
    required String name,
    String? photoTempPath,
  }) async {
    final photoFile = photoTempPath == null
        ? null
        : await _photoStore.save(photoTempPath);
    // Stored in whole milliseconds, so the returned player equals the stored one.
    final player = Player(
      name: name.trim(),
      photoFile: photoFile,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      ),
    );
    try {
      await _playerDao.insert(player);
    } catch (_) {
      if (photoFile != null) await _photoStore.delete(photoFile);
      rethrow;
    }
    return player;
  }

  /// Changes the name and/or photo of [player]. The previous photo file is
  /// deleted only after the row was updated, so a failure never loses it.
  Future<Player> updatePlayer(
    Player player, {
    String? name,
    String? photoTempPath,
  }) async {
    final newPhotoFile = photoTempPath == null
        ? null
        : await _photoStore.save(photoTempPath);
    final updated = player.copyWith(
      name: name?.trim(),
      photoFile: newPhotoFile,
    );
    try {
      await _playerDao.update(updated);
    } catch (_) {
      if (newPhotoFile != null) await _photoStore.delete(newPhotoFile);
      rethrow;
    }
    final oldPhotoFile = player.photoFile;
    if (newPhotoFile != null && oldPhotoFile != null) {
      await _photoStore.delete(oldPhotoFile);
    }
    return updated;
  }

  /// Absolute path of the player's photo, or null if there is none or the
  /// file is missing.
  Future<String?> photoPathOf(Player player) async {
    final photoFile = player.photoFile;
    if (photoFile == null) return null;
    return _photoStore.resolve(photoFile);
  }
}
