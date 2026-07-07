import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/rounds_data.dart';

void main() {
  group('RoundsData', () {
    group('`withRound`', () {
      test(
        '''
      Given empty `RoundsData`
      When `withRound` is called for round 1
      Then first-round slots are set and others stay null
      ''',
        () {
          // When
          final data = const RoundsData().withRound(1, 10, 20);

          // Then
          expect(data.firstRoundFirst, 10);
          expect(data.firstRoundSecond, 20);
          expect(data.secondRoundFirst, isNull);
          expect(data.secondRoundSecond, isNull);
          expect(data.thirdRoundFirst, isNull);
          expect(data.thirdRoundSecond, isNull);
        },
      );

      test(
        '''
      Given recorded earlier rounds
      When `withRound` is called for later rounds
      Then earlier rounds are not overwritten
      ''',
        () {
          // When
          final data = const RoundsData()
              .withRound(1, 10, 20)
              .withRound(2, 30, 40)
              .withRound(3, 50, 60);

          // Then
          expect(data.firstRoundFirst, 10);
          expect(data.firstRoundSecond, 20);
          expect(data.secondRoundFirst, 30);
          expect(data.secondRoundSecond, 40);
          expect(data.thirdRoundFirst, 50);
          expect(data.thirdRoundSecond, 60);
        },
      );

      test(
        '''
      Given an invalid round number
      When `withRound` is called
      Then it throws `ArgumentError`
      ''',
        () {
          // When / Then
          expect(
            () => const RoundsData().withRound(4, 1, 2),
            throwsArgumentError,
          );
          expect(
            () => const RoundsData().withRound(0, 1, 2),
            throwsArgumentError,
          );
        },
      );
    });
  });
}
