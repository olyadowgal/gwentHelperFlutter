import 'player_data.dart';
import 'winner.dart';

class GameData {
  final PlayerData firstPlayerData;
  final PlayerData secondPlayerData;

  const GameData({
    required this.firstPlayerData,
    required this.secondPlayerData,
  });

  Winner get winner {
    if (firstPlayerData.totalPoints > secondPlayerData.totalPoints) {
      return Winner.first;
    } else if (firstPlayerData.totalPoints < secondPlayerData.totalPoints) {
      return Winner.second;
    }
    return Winner.tie;
  }

  GameData copyWith({
    PlayerData? firstPlayerData,
    PlayerData? secondPlayerData,
  }) {
    return GameData(
      firstPlayerData: firstPlayerData ?? this.firstPlayerData,
      secondPlayerData: secondPlayerData ?? this.secondPlayerData,
    );
  }
}
