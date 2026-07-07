import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_cubit.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_side_effect.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_side_effect_handler.dart';

// region Mocks
class MockGwentRepository extends Mock implements GwentRepository {}
// endregion

void main() {
  late MockGwentRepository repository;
  late MockSideEffectHandler<ScoresSideEffect> sideEffectHandler;

  final score = GameScore(
    date: DateTime(2026, 7, 6),
    firstPlayer: 'Alice',
    secondPlayer: 'Bob',
    winner: 'first',
  );

  setUp(() => repository = MockGwentRepository());

  setUp(() => sideEffectHandler = MockSideEffectHandler<ScoresSideEffect>());

  Future<ScoresCubit> buildCubitWithHandler() async {
    final cubit = ScoresCubit(repository: repository);
    final subscription = attachSideEffectHandler(cubit, sideEffectHandler);
    addTearDown(() async {
      await subscription.cancel();
      await cubit.close();
    });
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  group('ScoresCubit', () {
    group('`onScreenOpened`', () {
      test(
        '''
      Given the repository returns scores
      When the cubit is constructed
      Then scores are loaded into state
      ''',
        () async {
          // Given
          when(() => repository.getGames()).thenAnswer((_) async => [score]);

          // When
          final cubit = await buildCubitWithHandler();

          // Then
          expect(cubit.state.isLoading, isFalse);
          expect(cubit.state.scores, [score]);
          expect(cubit.state.errorMessage, isNull);
        },
      );

      test(
        '''
      Given the repository throws
      When the cubit is constructed
      Then the error surfaces as `errorMessage`
      ''',
        () async {
          // Given
          when(() => repository.getGames()).thenThrow(Exception('db fail'));

          // When
          final cubit = await buildCubitWithHandler();

          // Then
          expect(cubit.state.isLoading, isFalse);
          expect(cubit.state.errorMessage, contains('db fail'));
        },
      );
    });

    group('`onClearAllTapped`', () {
      test(
        '''
      Given loaded scores
      When `onClearAllTapped` is called
      Then `ShowClearConfirmDialog` is emitted
      ''',
        () async {
          // Given
          when(() => repository.getGames()).thenAnswer((_) async => [score]);
          final cubit = await buildCubitWithHandler();

          // When
          cubit.onClearAllTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(const ShowClearConfirmDialog()),
          ).called(1);
        },
      );
    });

    group('`onClearConfirmed`', () {
      test(
        '''
      Given loaded scores
      When `onClearConfirmed` is called
      Then the repository is cleared and `scores` is empty
      ''',
        () async {
          // Given
          when(() => repository.getGames()).thenAnswer((_) async => [score]);
          when(() => repository.clearGames()).thenAnswer((_) async {});
          final cubit = await buildCubitWithHandler();

          // When
          await cubit.onClearConfirmed();

          // Then
          verify(() => repository.clearGames()).called(1);
          expect(cubit.state.scores, isEmpty);
        },
      );
    });
  });
}
