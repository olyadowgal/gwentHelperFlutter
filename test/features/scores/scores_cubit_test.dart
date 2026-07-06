import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_cubit.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/scores_side_effect.dart';
import 'package:mocktail/mocktail.dart';

class MockGwentRepository extends Mock implements GwentRepository {}

void main() {
  late MockGwentRepository repository;

  final score = GameScore(
    date: DateTime(2026, 7, 6),
    firstPlayer: 'Alice',
    secondPlayer: 'Bob',
    winner: 'first',
  );

  setUp(() {
    repository = MockGwentRepository();
  });

  test('loads scores on construction', () async {
    when(() => repository.getGames()).thenAnswer((_) async => [score]);
    final cubit = ScoresCubit(repository: repository);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.scores, [score]);
    expect(cubit.state.errorMessage, isNull);
    await cubit.close();
  });

  test('repository error surfaces as errorMessage', () async {
    when(() => repository.getGames()).thenThrow(Exception('db fail'));
    final cubit = ScoresCubit(repository: repository);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, contains('db fail'));
    await cubit.close();
  });

  test('onClearAllTapped emits ShowClearConfirmDialog side effect', () async {
    when(() => repository.getGames()).thenAnswer((_) async => [score]);
    final cubit = ScoresCubit(repository: repository);
    await Future<void>.delayed(Duration.zero);
    cubit.onClearAllTapped();
    expect(cubit.state.sideEffects, [const ShowClearConfirmDialog()]);
    await cubit.close();
  });

  test('onClearConfirmed clears repository and empties scores', () async {
    when(() => repository.getGames()).thenAnswer((_) async => [score]);
    when(() => repository.clearGames()).thenAnswer((_) async {});
    final cubit = ScoresCubit(repository: repository);
    await Future<void>.delayed(Duration.zero);
    await cubit.onClearConfirmed();
    verify(() => repository.clearGames()).called(1);
    expect(cubit.state.scores, isEmpty);
    await cubit.close();
  });
}
