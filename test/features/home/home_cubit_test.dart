import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_cubit.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_side_effect.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_side_effect_handler.dart';

void main() {
  late MockSideEffectHandler<HomeSideEffect> sideEffectHandler;

  setUp(() => sideEffectHandler = MockSideEffectHandler<HomeSideEffect>());

  HomeCubit buildCubitWithHandler() {
    final cubit = HomeCubit();
    final subscription = attachSideEffectHandler(cubit, sideEffectHandler);
    addTearDown(() async {
      await subscription.cancel();
      await cubit.close();
    });
    return cubit;
  }

  group('HomeCubit', () {
    group('initial state', () {
      test(
        '''
      Given a new `HomeCubit`
      When no method is called
      Then state is an empty `HomeState`
      ''',
        () async {
          // Given
          final cubit = HomeCubit();

          // Then
          expect(cubit.state, const HomeState());
          await cubit.close();
        },
      );
    });

    group('`onPlayer1NameChanged`', () {
      blocTest<HomeCubit, HomeState>(
        '''
      Given a new cubit
      When `onPlayer1NameChanged` is called
      Then `player1Name` is updated
      ''',
        build: HomeCubit.new,
        act: (c) => c.onPlayer1NameChanged('Alice'),
        expect: () => [const HomeState(player1Name: 'Alice')],
      );
    });

    group('`onPlayer2NameChanged`', () {
      blocTest<HomeCubit, HomeState>(
        '''
      Given a new cubit
      When `onPlayer2NameChanged` is called
      Then `player2Name` is updated
      ''',
        build: HomeCubit.new,
        act: (c) => c.onPlayer2NameChanged('Bob'),
        expect: () => [const HomeState(player2Name: 'Bob')],
      );
    });

    group('`onPlayer1PhotoPicked` and `onPlayer2PhotoPicked`', () {
      blocTest<HomeCubit, HomeState>(
        '''
      Given a new cubit
      When photos are picked for both players
      Then `player1PhotoPath` and `player2PhotoPath` are updated
      ''',
        build: HomeCubit.new,
        act: (c) => c
          ..onPlayer1PhotoPicked('/p1.jpg')
          ..onPlayer2PhotoPicked('/p2.jpg'),
        expect: () => [
          const HomeState(player1PhotoPath: '/p1.jpg'),
          const HomeState(
            player1PhotoPath: '/p1.jpg',
            player2PhotoPath: '/p2.jpg',
          ),
        ],
      );
    });

    group('`onPlayTapped`', () {
      test(
        '''
      Given empty player names
      When `onPlayTapped` is called
      Then `NavigateToGame` is emitted with default names
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler();

          // When
          cubit.onPlayTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Player 1',
                player2Name: 'Player 2',
              ),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given entered names and photos
      When `onPlayTapped` is called
      Then `NavigateToGame` carries them through
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler()
            ..onPlayer1NameChanged('Alice')
            ..onPlayer2NameChanged('Bob')
            ..onPlayer1PhotoPicked('/p1.jpg')
            ..onPlayer2PhotoPicked('/p2.jpg');

          // When
          cubit.onPlayTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Alice',
                player2Name: 'Bob',
                player1PhotoPath: '/p1.jpg',
                player2PhotoPath: '/p2.jpg',
              ),
            ),
          ).called(1);
        },
      );
    });

    group('`onScoresTapped`', () {
      test(
        '''
      Given a new cubit
      When `onScoresTapped` is called
      Then `NavigateToScores` is emitted
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler();

          // When
          cubit.onScoresTapped();
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(const NavigateToScores()),
          ).called(1);
        },
      );
    });
  });
}
