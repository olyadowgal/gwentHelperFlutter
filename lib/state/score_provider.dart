import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/game_score.dart';
import 'game_provider.dart';

final scoresProvider = FutureProvider<List<GameScore>>((ref) async {
  final repo = ref.read(gwentRepositoryProvider);
  return repo.getGames();
});
