class RoundsData {
  final int? firstRoundFirst;
  final int? firstRoundSecond;
  final int? secondRoundFirst;
  final int? secondRoundSecond;
  final int? thirdRoundFirst;
  final int? thirdRoundSecond;

  const RoundsData({
    this.firstRoundFirst,
    this.firstRoundSecond,
    this.secondRoundFirst,
    this.secondRoundSecond,
    this.thirdRoundFirst,
    this.thirdRoundSecond,
  });

  RoundsData withRound(int roundNumber, int firstPoints, int secondPoints) {
    return switch (roundNumber) {
      1 => RoundsData(
          firstRoundFirst: firstPoints,
          firstRoundSecond: secondPoints,
          secondRoundFirst: secondRoundFirst,
          secondRoundSecond: secondRoundSecond,
          thirdRoundFirst: thirdRoundFirst,
          thirdRoundSecond: thirdRoundSecond,
        ),
      2 => RoundsData(
          firstRoundFirst: firstRoundFirst,
          firstRoundSecond: firstRoundSecond,
          secondRoundFirst: firstPoints,
          secondRoundSecond: secondPoints,
          thirdRoundFirst: thirdRoundFirst,
          thirdRoundSecond: thirdRoundSecond,
        ),
      3 => RoundsData(
          firstRoundFirst: firstRoundFirst,
          firstRoundSecond: firstRoundSecond,
          secondRoundFirst: secondRoundFirst,
          secondRoundSecond: secondRoundSecond,
          thirdRoundFirst: firstPoints,
          thirdRoundSecond: secondPoints,
        ),
      _ => throw ArgumentError('Invalid round number: $roundNumber. Must be 1, 2, or 3.'),
    };
  }
}
