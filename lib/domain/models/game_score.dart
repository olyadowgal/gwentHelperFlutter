import 'package:uuid/uuid.dart';
import 'winner.dart';

class GameScore {
  final String id;
  final DateTime date;
  final String firstPlayer;
  final String secondPlayer;
  final String winner;
  final int? firstRoundFirstPlayerPoints;
  final int? secondRoundFirstPlayerPoints;
  final int? thirdRoundFirstPlayerPoints;
  final int? firstRoundSecondPlayerPoints;
  final int? secondRoundSecondPlayerPoints;
  final int? thirdRoundSecondPlayerPoints;

  GameScore({
    String? id,
    required this.date,
    required this.firstPlayer,
    required this.secondPlayer,
    required this.winner,
    this.firstRoundFirstPlayerPoints,
    this.secondRoundFirstPlayerPoints,
    this.thirdRoundFirstPlayerPoints,
    this.firstRoundSecondPlayerPoints,
    this.secondRoundSecondPlayerPoints,
    this.thirdRoundSecondPlayerPoints,
  }) : id = id ?? const Uuid().v4();

  Winner? get _parsedWinner {
    for (final value in Winner.values) {
      if (value.name == winner) return value;
    }
    return null;
  }

  bool get firstPlayerWon =>
      _parsedWinner == Winner.first ||
      (_parsedWinner == null && winner == firstPlayer);

  bool get secondPlayerWon =>
      _parsedWinner == Winner.second ||
      (_parsedWinner == null && winner == secondPlayer);

  /// Games can be saved before a name was ever typed in, so displaying a name
  /// always falls back to a placeholder.
  String displayedFirstPlayer({required String fallback}) =>
      _nameOr(firstPlayer, fallback);

  String displayedSecondPlayer({required String fallback}) =>
      _nameOr(secondPlayer, fallback);

  String displayedWinner({
    required String tieLabel,
    required String firstPlayerFallback,
    required String secondPlayerFallback,
  }) {
    if (firstPlayerWon) {
      return displayedFirstPlayer(fallback: firstPlayerFallback);
    }
    if (secondPlayerWon) {
      return displayedSecondPlayer(fallback: secondPlayerFallback);
    }
    return tieLabel;
  }

  static String _nameOr(String name, String fallback) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'first_player': firstPlayer,
    'second_player': secondPlayer,
    'winner': winner,
    'first_round_first_player': firstRoundFirstPlayerPoints,
    'second_round_first_player': secondRoundFirstPlayerPoints,
    'third_round_first_player': thirdRoundFirstPlayerPoints,
    'first_round_second_player': firstRoundSecondPlayerPoints,
    'second_round_second_player': secondRoundSecondPlayerPoints,
    'third_round_second_player': thirdRoundSecondPlayerPoints,
  };

  factory GameScore.fromMap(Map<String, dynamic> map) {
    final dateMillis = map['date'] as int;
    return GameScore(
      id: map['id'] as String? ?? 'legacy-$dateMillis',
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      firstPlayer: map['first_player'] as String,
      secondPlayer: map['second_player'] as String,
      winner: map['winner'] as String,
      firstRoundFirstPlayerPoints: map['first_round_first_player'] as int?,
      secondRoundFirstPlayerPoints: map['second_round_first_player'] as int?,
      thirdRoundFirstPlayerPoints: map['third_round_first_player'] as int?,
      firstRoundSecondPlayerPoints: map['first_round_second_player'] as int?,
      secondRoundSecondPlayerPoints: map['second_round_second_player'] as int?,
      thirdRoundSecondPlayerPoints: map['third_round_second_player'] as int?,
    );
  }
}
