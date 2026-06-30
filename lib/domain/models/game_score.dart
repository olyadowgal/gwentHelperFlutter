class GameScore {
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

  const GameScore({
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
  });

  Map<String, dynamic> toMap() => {
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

  factory GameScore.fromMap(Map<String, dynamic> map) => GameScore(
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
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
