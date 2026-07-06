import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_cubit.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_side_effect.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_side_effect_handler.dart';

class MockGwentRepository extends Mock implements GwentRepository {}

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

  group('`onScreenOpened`', () {
    test('loads scores on construction', () async {
      when(() => repository.getGames()).thenAnswer((_) async => [score]);
      final cubit = await buildCubitWithHandler();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.scores, [score]);
      expect(cubit.state.errorMessage, isNull);
    });

    test('repository error surfaces as `errorMessage`', () async {
      when(() => repository.getGames()).thenThrow(Exception('db fail'));
      final cubit = await buildCubitWithHandler();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, contains('db fail'));
    });
  });

  group('`onClearAllTapped`', () {
    test('emits `ShowClearConfirmDialog`', () async {
      when(() => repository.getGames()).thenAnswer((_) async => [score]);
      final cubit = await buildCubitWithHandler();
      cubit.onClearAllTapped();
      await Future<void>.delayed(Duration.zero);
      verify(
        () => sideEffectHandler.call(const ShowClearConfirmDialog()),
      ).called(1);
    });
  });

  group('`onClearConfirmed`', () {
    test('clears repository and empties `scores`', () async {
      when(() => repository.getGames()).thenAnswer((_) async => [score]);
      when(() => repository.clearGames()).thenAnswer((_) async {});
      final cubit = await buildCubitWithHandler();
      await cubit.onClearConfirmed();
      verify(() => repository.clearGames()).called(1);
      expect(cubit.state.scores, isEmpty);
    });
  });
}
