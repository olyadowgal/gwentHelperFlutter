import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';
import 'package:gwent_helper_flutter/features/scores/cubit/score_player.dart';
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

  setUp(() {
    repository = MockGwentRepository();
    when(() => repository.getPlayers()).thenAnswer((_) async => []);
  });

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
      Given games and saved players, one with a photo and one without
      When the cubit is constructed
      Then `players` maps each player id to its name and resolved photo path
      ''',
        () async {
          // Given
          final annie = Player(id: 'p1', name: 'Annie', photoFile: 'a.jpg');
          final bea = Player(id: 'p2', name: 'Bea');
          when(() => repository.getGames()).thenAnswer((_) async => [score]);
          when(
            () => repository.getPlayers(),
          ).thenAnswer((_) async => [annie, bea]);
          when(
            () => repository.photoPathOf(annie),
          ).thenAnswer((_) async => '/photos/a.jpg');
          when(() => repository.photoPathOf(bea)).thenAnswer((_) async => null);

          // When
          final cubit = await buildCubitWithHandler();

          // Then
          expect(cubit.state.players, {
            'p1': const ScorePlayer(name: 'Annie', photoPath: '/photos/a.jpg'),
            'p2': const ScorePlayer(name: 'Bea'),
          });
        },
      );

      test(
        '''
      Given loading the saved players throws
      When the cubit is constructed
      Then the scores still load, `players` is empty and there is no error
      ''',
        () async {
          // Given
          when(() => repository.getGames()).thenAnswer((_) async => [score]);
          when(() => repository.getPlayers()).thenThrow(Exception('db fail'));

          // When
          final cubit = await buildCubitWithHandler();

          // Then
          expect(cubit.state.scores, [score]);
          expect(cubit.state.players, isEmpty);
          expect(cubit.state.errorMessage, isNull);
        },
      );

      test(
        '''
      Given resolving one player's photo throws
      When the cubit is constructed
      Then that player has no photo and the other player keeps theirs
      ''',
        () async {
          // Given
          final annie = Player(id: 'p1', name: 'Annie', photoFile: 'a.jpg');
          final bea = Player(id: 'p2', name: 'Bea', photoFile: 'b.jpg');
          when(() => repository.getGames()).thenAnswer((_) async => [score]);
          when(
            () => repository.getPlayers(),
          ).thenAnswer((_) async => [annie, bea]);
          when(
            () => repository.photoPathOf(annie),
          ).thenThrow(Exception('io fail'));
          when(
            () => repository.photoPathOf(bea),
          ).thenAnswer((_) async => '/photos/b.jpg');

          // When
          final cubit = await buildCubitWithHandler();

          // Then
          expect(cubit.state.players, {
            'p1': const ScorePlayer(name: 'Annie'),
            'p2': const ScorePlayer(name: 'Bea', photoPath: '/photos/b.jpg'),
          });
        },
      );

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
