import '../domain/models/game_score.dart';
import 'game_score_dao.dart';

class GwentRepository {
  final GameScoreDao _dao;

  GwentRepository({GameScoreDao? dao}) : _dao = dao ?? GameScoreDao();

  Future<void> addGame(GameScore score) => _dao.insert(score);
  Future<List<GameScore>> getGames() => _dao.getAll();
  Future<void> clearGames() => _dao.deleteAll();
}
