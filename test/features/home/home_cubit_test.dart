import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_cubit.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_side_effect.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_state.dart';

void main() {
  test('initial state is empty', () {
    final cubit = HomeCubit();
    expect(cubit.state, const HomeState());
    cubit.close();
  });

  blocTest<HomeCubit, HomeState>(
    'onPlayer1NameChanged updates player1Name',
    build: HomeCubit.new,
    act: (c) => c.onPlayer1NameChanged('Alice'),
    expect: () => [const HomeState(player1Name: 'Alice')],
  );

  blocTest<HomeCubit, HomeState>(
    'onPlayer2NameChanged updates player2Name',
    build: HomeCubit.new,
    act: (c) => c.onPlayer2NameChanged('Bob'),
    expect: () => [const HomeState(player2Name: 'Bob')],
  );

  blocTest<HomeCubit, HomeState>(
    'photo picks update photo paths',
    build: HomeCubit.new,
    act: (c) => c
      ..onPlayer1PhotoPicked('/p1.jpg')
      ..onPlayer2PhotoPicked('/p2.jpg'),
    expect: () => [
      const HomeState(player1PhotoPath: '/p1.jpg'),
      const HomeState(player1PhotoPath: '/p1.jpg', player2PhotoPath: '/p2.jpg'),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'onPlayTapped with empty names emits NavigateToGame with defaults',
    build: HomeCubit.new,
    act: (c) => c.onPlayTapped(),
    expect: () => [
      const HomeState(
        sideEffects: [
          NavigateToGame(player1Name: 'Player 1', player2Name: 'Player 2'),
        ],
      ),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'onPlayTapped carries entered names and photos through',
    build: HomeCubit.new,
    seed: () => const HomeState(
      player1Name: 'Alice',
      player2Name: 'Bob',
      player1PhotoPath: '/p1.jpg',
      player2PhotoPath: '/p2.jpg',
    ),
    act: (c) => c.onPlayTapped(),
    expect: () => [
      const HomeState(
        player1Name: 'Alice',
        player2Name: 'Bob',
        player1PhotoPath: '/p1.jpg',
        player2PhotoPath: '/p2.jpg',
        sideEffects: [
          NavigateToGame(
            player1Name: 'Alice',
            player2Name: 'Bob',
            player1PhotoPath: '/p1.jpg',
            player2PhotoPath: '/p2.jpg',
          ),
        ],
      ),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'onScoresTapped emits NavigateToScores',
    build: HomeCubit.new,
    act: (c) => c.onScoresTapped(),
    expect: () => [
      const HomeState(sideEffects: [NavigateToScores()]),
    ],
  );
}
