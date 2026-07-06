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

  test('Given a new `HomeCubit`\n'
      'When no method is called\n'
      'Then state is an empty `HomeState`', () async {
    final cubit = HomeCubit();
    expect(cubit.state, const HomeState());
    await cubit.close();
  });

  group('`onPlayer1NameChanged`', () {
    blocTest<HomeCubit, HomeState>(
      'Given a new cubit\n'
      'When `onPlayer1NameChanged` is called\n'
      'Then `player1Name` is updated',
      build: HomeCubit.new,
      act: (c) => c.onPlayer1NameChanged('Alice'),
      expect: () => [const HomeState(player1Name: 'Alice')],
    );
  });

  group('`onPlayer2NameChanged`', () {
    blocTest<HomeCubit, HomeState>(
      'Given a new cubit\n'
      'When `onPlayer2NameChanged` is called\n'
      'Then `player2Name` is updated',
      build: HomeCubit.new,
      act: (c) => c.onPlayer2NameChanged('Bob'),
      expect: () => [const HomeState(player2Name: 'Bob')],
    );
  });

  group('`onPlayer1PhotoPicked` and `onPlayer2PhotoPicked`', () {
    blocTest<HomeCubit, HomeState>(
      'Given a new cubit\n'
      'When photos are picked for both players\n'
      'Then `player1PhotoPath` and `player2PhotoPath` are updated',
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
    test('Given empty player names\n'
        'When `onPlayTapped` is called\n'
        'Then `NavigateToGame` is emitted with default names', () async {
      final cubit = buildCubitWithHandler();
      cubit.onPlayTapped();
      await Future<void>.delayed(Duration.zero);
      verify(
        () => sideEffectHandler.call(
          const NavigateToGame(
            player1Name: 'Player 1',
            player2Name: 'Player 2',
          ),
        ),
      ).called(1);
    });

    test('Given entered names and photos\n'
        'When `onPlayTapped` is called\n'
        'Then `NavigateToGame` carries them through', () async {
      final cubit = buildCubitWithHandler();
      cubit
        ..onPlayer1NameChanged('Alice')
        ..onPlayer2NameChanged('Bob')
        ..onPlayer1PhotoPicked('/p1.jpg')
        ..onPlayer2PhotoPicked('/p2.jpg')
        ..onPlayTapped();
      await Future<void>.delayed(Duration.zero);
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
    });
  });

  group('`onScoresTapped`', () {
    test('Given a new cubit\n'
        'When `onScoresTapped` is called\n'
        'Then `NavigateToScores` is emitted', () async {
      final cubit = buildCubitWithHandler();
      cubit.onScoresTapped();
      await Future<void>.delayed(Duration.zero);
      verify(() => sideEffectHandler.call(const NavigateToScores())).called(1);
    });
  });
}
