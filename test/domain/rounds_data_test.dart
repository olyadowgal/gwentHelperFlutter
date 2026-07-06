import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/rounds_data.dart';

void main() {
  group('withRound', () {
    test('round 1 sets first-round slots, others stay null', () {
      final data = const RoundsData().withRound(1, 10, 20);
      expect(data.firstRoundFirst, 10);
      expect(data.firstRoundSecond, 20);
      expect(data.secondRoundFirst, isNull);
      expect(data.secondRoundSecond, isNull);
      expect(data.thirdRoundFirst, isNull);
      expect(data.thirdRoundSecond, isNull);
    });

    test('rounds accumulate without overwriting earlier rounds', () {
      final data = const RoundsData()
          .withRound(1, 10, 20)
          .withRound(2, 30, 40)
          .withRound(3, 50, 60);
      expect(data.firstRoundFirst, 10);
      expect(data.firstRoundSecond, 20);
      expect(data.secondRoundFirst, 30);
      expect(data.secondRoundSecond, 40);
      expect(data.thirdRoundFirst, 50);
      expect(data.thirdRoundSecond, 60);
    });

    test('invalid round number throws ArgumentError', () {
      expect(
        () => const RoundsData().withRound(4, 1, 2),
        throwsArgumentError,
      );
      expect(
        () => const RoundsData().withRound(0, 1, 2),
        throwsArgumentError,
      );
    });
  });
}
