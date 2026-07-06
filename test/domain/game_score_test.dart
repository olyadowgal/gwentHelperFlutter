import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';

void main() {
  final date = DateTime(2026, 7, 6, 12, 30);

  group('toMap / fromMap round-trip', () {
    test('all fields survive with all round points set', () {
      final score = GameScore(
        date: date,
        firstPlayer: 'Alice',
        secondPlayer: 'Bob',
        winner: 'first',
        firstRoundFirstPlayerPoints: 10,
        secondRoundFirstPlayerPoints: 20,
        thirdRoundFirstPlayerPoints: 30,
        firstRoundSecondPlayerPoints: 11,
        secondRoundSecondPlayerPoints: 21,
        thirdRoundSecondPlayerPoints: 31,
      );
      final restored = GameScore.fromMap(score.toMap());
      expect(restored.date, date);
      expect(restored.firstPlayer, 'Alice');
      expect(restored.secondPlayer, 'Bob');
      expect(restored.winner, 'first');
      expect(restored.firstRoundFirstPlayerPoints, 10);
      expect(restored.secondRoundFirstPlayerPoints, 20);
      expect(restored.thirdRoundFirstPlayerPoints, 30);
      expect(restored.firstRoundSecondPlayerPoints, 11);
      expect(restored.secondRoundSecondPlayerPoints, 21);
      expect(restored.thirdRoundSecondPlayerPoints, 31);
    });

    test('null round points are preserved', () {
      final score = GameScore(
        date: date,
        firstPlayer: 'Alice',
        secondPlayer: 'Bob',
        winner: 'tie',
      );
      final restored = GameScore.fromMap(score.toMap());
      expect(restored.firstRoundFirstPlayerPoints, isNull);
      expect(restored.thirdRoundSecondPlayerPoints, isNull);
    });

    test('toMap stores date as millisecondsSinceEpoch', () {
      final score = GameScore(
        date: date,
        firstPlayer: 'A',
        secondPlayer: 'B',
        winner: 'first',
      );
      expect(score.toMap()['date'], date.millisecondsSinceEpoch);
    });
  });
}
