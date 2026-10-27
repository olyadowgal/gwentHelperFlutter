import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/player.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_cubit.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_side_effect.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_side_effect_handler.dart';

class MockGwentRepository extends Mock implements GwentRepository {}

class FakePlayer extends Fake implements Player {}

void main() {
  late MockSideEffectHandler<HomeSideEffect> sideEffectHandler;
  late MockGwentRepository repository;

  setUpAll(() => registerFallbackValue(FakePlayer()));

  setUp(() {
    sideEffectHandler = MockSideEffectHandler<HomeSideEffect>();
    repository = MockGwentRepository();
    when(() => repository.photoPathOf(any())).thenAnswer((_) async => null);
  });

  final anna = Player(
    id: 'a1',
    name: 'Anna',
    photoFile: 'anna.jpg',
    createdAt: DateTime(2026),
  );
  final oleh = Player(id: 'o1', name: 'Олег', createdAt: DateTime(2026));

  HomeCubit buildCubit() => HomeCubit(repository: repository);

  HomeCubit buildCubitWithHandler() {
    final cubit = buildCubit();
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
      Then state is an empty `HomeState` with null ids and unchanged photos
      ''',
        () async {
          // Given
          final cubit = buildCubit();

          // Then
          expect(cubit.state, const HomeState());
          expect(cubit.state.player1Id, isNull);
          expect(cubit.state.player2Id, isNull);
          expect(cubit.state.player1PhotoChanged, isFalse);
          expect(cubit.state.player2PhotoChanged, isFalse);
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
        build: buildCubit,
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
        build: buildCubit,
        act: (c) => c.onPlayer2NameChanged('Bob'),
        expect: () => [const HomeState(player2Name: 'Bob')],
      );
    });

    group('`onPlayer1PhotoPicked` and `onPlayer2PhotoPicked`', () {
      blocTest<HomeCubit, HomeState>(
        '''
      Given a new cubit
      When photos are picked for both players
      Then the photo paths are updated and the photos are flagged as changed
      ''',
        build: buildCubit,
        act: (c) => c
          ..onPlayer1PhotoPicked('/p1.jpg')
          ..onPlayer2PhotoPicked('/p2.jpg'),
        expect: () => [
          const HomeState(
            player1PhotoPath: '/p1.jpg',
            player1PhotoChanged: true,
          ),
          const HomeState(
            player1PhotoPath: '/p1.jpg',
            player1PhotoChanged: true,
            player2PhotoPath: '/p2.jpg',
            player2PhotoChanged: true,
          ),
        ],
      );
    });

    group('`onSavedPlayersRequested`', () {
      test(
        '''
      Given saved players and none selected
      When `onSavedPlayersRequested` is called for player 1
      Then `ShowSavedPlayers` lists every saved player with its photo path
      ''',
        () async {
          // Given
          when(
            () => repository.getPlayers(),
          ).thenAnswer((_) async => [anna, oleh]);
          when(
            () => repository.photoPathOf(anna),
          ).thenAnswer((_) async => '/photos/anna.jpg');
          final cubit = buildCubitWithHandler();

          // When
          await cubit.onSavedPlayersRequested(isPlayer1: true);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              ShowSavedPlayers(true, [
                SavedPlayerOption(player: anna, photoPath: '/photos/anna.jpg'),
                SavedPlayerOption(player: oleh),
              ]),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given a saved player is selected for player 2
      When `onSavedPlayersRequested` is called for player 1
      Then that player is excluded from the options
      ''',
        () async {
          // Given
          when(
            () => repository.getPlayers(),
          ).thenAnswer((_) async => [anna, oleh]);
          final cubit = buildCubitWithHandler();
          await cubit.onSavedPlayerSelected(isPlayer1: false, player: anna);

          // When
          await cubit.onSavedPlayersRequested(isPlayer1: true);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              ShowSavedPlayers(true, [SavedPlayerOption(player: oleh)]),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given loading the saved players fails
      When `onSavedPlayersRequested` is called
      Then `ShowSavedPlayers` is emitted with an empty list
      ''',
        () async {
          // Given
          when(() => repository.getPlayers()).thenThrow(Exception('db'));
          final cubit = buildCubitWithHandler();

          // When
          await cubit.onSavedPlayersRequested(isPlayer1: false);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(const ShowSavedPlayers(false, [])),
          ).called(1);
        },
      );
    });

    group('`onSavedPlayerSelected`', () {
      test(
        '''
      Given a saved player with a photo
      When `onSavedPlayerSelected` is called for player 1
      Then id, name and resolved photo path are set and the photo is not changed
      ''',
        () async {
          // Given
          when(
            () => repository.photoPathOf(anna),
          ).thenAnswer((_) async => '/photos/anna.jpg');
          final cubit = buildCubit();

          // When
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);

          // Then
          expect(
            cubit.state,
            const HomeState(
              player1Id: 'a1',
              player1Name: 'Anna',
              player1PhotoPath: '/photos/anna.jpg',
            ),
          );
        },
      );

      test(
        '''
      Given a saved player whose photo file is missing
      When `onSavedPlayerSelected` is called for player 2
      Then the photo path is null and nothing throws
      ''',
        () async {
          // Given
          when(
            () => repository.photoPathOf(anna),
          ).thenAnswer((_) async => null);
          final cubit = buildCubit();

          // When
          await cubit.onSavedPlayerSelected(isPlayer1: false, player: anna);

          // Then
          expect(
            cubit.state,
            const HomeState(player2Id: 'a1', player2Name: 'Anna'),
          );
        },
      );
    });

    group('`onNewPlayerSelected`', () {
      test(
        '''
      Given player 1 has a selected saved player and a picked photo
      When `onNewPlayerSelected` is called for player 1
      Then id, name, photo and changed flag of player 1 are cleared
      ''',
        () async {
          // Given
          final cubit = buildCubit();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);
          cubit.onPlayer1PhotoPicked('/p1.jpg');

          // When
          cubit.onNewPlayerSelected(isPlayer1: true);

          // Then
          expect(cubit.state, const HomeState());
        },
      );

      test(
        '''
      Given both players have a selected saved player
      When `onNewPlayerSelected` is called for player 2
      Then player 1 is left untouched
      ''',
        () async {
          // Given
          final cubit = buildCubit();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);
          await cubit.onSavedPlayerSelected(isPlayer1: false, player: oleh);

          // When
          cubit.onNewPlayerSelected(isPlayer1: false);

          // Then
          expect(
            cubit.state,
            const HomeState(player1Id: 'a1', player1Name: 'Anna'),
          );
        },
      );
    });

    group('`onPlayTapped`', () {
      Future<void> play(HomeCubit cubit) => cubit.onPlayTapped(
        player1Fallback: 'Player 1',
        player2Fallback: 'Player 2',
      );

      void verifyNothingSaved() {
        verifyNever(
          () => repository.createPlayer(
            name: any(named: 'name'),
            photoTempPath: any(named: 'photoTempPath'),
          ),
        );
        verifyNever(
          () => repository.updatePlayer(
            any(),
            name: any(named: 'name'),
            photoTempPath: any(named: 'photoTempPath'),
          ),
        );
      }

      test(
        '''
      Given empty player names
      When `onPlayTapped` is called
      Then `NavigateToGame` is emitted with default names and no ids
      And the repository is not used
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler();

          // When
          await play(cubit);
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
          verifyZeroInteractions(repository);
        },
      );

      test(
        '''
      Given blank (whitespace) names
      When `onPlayTapped` is called
      Then both sides are guests and the repository is never called
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler()
            ..onPlayer1NameChanged('   ')
            ..onPlayer2NameChanged(' ');

          // When
          await play(cubit);
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
          verifyZeroInteractions(repository);
        },
      );

      test(
        '''
      Given entered names and photos that match no saved player
      When `onPlayTapped` is called
      Then `createPlayer` is called once per side with the picked photo
      And `NavigateToGame` carries the new ids and permanent photo paths
      And the state holds ids and permanent paths with photo not changed
      ''',
        () async {
          // Given
          final newAnna = Player(id: 'n1', name: 'Anna', photoFile: 'n1.jpg');
          final newBob = Player(id: 'n2', name: 'Bob', photoFile: 'n2.jpg');
          when(
            () => repository.findPlayerByName(any()),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(
              name: 'Anna',
              photoTempPath: '/tmp/p1.jpg',
            ),
          ).thenAnswer((_) async => newAnna);
          when(
            () => repository.createPlayer(
              name: 'Bob',
              photoTempPath: '/tmp/p2.jpg',
            ),
          ).thenAnswer((_) async => newBob);
          when(
            () => repository.photoPathOf(newAnna),
          ).thenAnswer((_) async => '/photos/n1.jpg');
          when(
            () => repository.photoPathOf(newBob),
          ).thenAnswer((_) async => '/photos/n2.jpg');
          final cubit = buildCubitWithHandler()
            ..onPlayer1NameChanged('  Anna ')
            ..onPlayer2NameChanged('Bob')
            ..onPlayer1PhotoPicked('/tmp/p1.jpg')
            ..onPlayer2PhotoPicked('/tmp/p2.jpg');

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => repository.createPlayer(
              name: 'Anna',
              photoTempPath: '/tmp/p1.jpg',
            ),
          ).called(1);
          verify(
            () => repository.createPlayer(
              name: 'Bob',
              photoTempPath: '/tmp/p2.jpg',
            ),
          ).called(1);
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Anna',
                player2Name: 'Bob',
                player1PhotoPath: '/photos/n1.jpg',
                player2PhotoPath: '/photos/n2.jpg',
                player1Id: 'n1',
                player2Id: 'n2',
              ),
            ),
          ).called(1);
          expect(cubit.state.player1Id, 'n1');
          expect(cubit.state.player1PhotoPath, '/photos/n1.jpg');
          expect(cubit.state.player1PhotoChanged, isFalse);
          expect(cubit.state.player2Id, 'n2');
          expect(cubit.state.player2PhotoPath, '/photos/n2.jpg');
          expect(cubit.state.player2PhotoChanged, isFalse);
        },
      );

      test(
        '''
      Given a typed name without a photo that matches no saved player
      When `onPlayTapped` is called
      Then `createPlayer` is called without a photo
      ''',
        () async {
          // Given
          final newBob = Player(id: 'n2', name: 'Bob');
          when(
            () => repository.findPlayerByName(any()),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(name: 'Bob'),
          ).thenAnswer((_) async => newBob);
          final cubit = buildCubit()..onPlayer2NameChanged('Bob');

          // When
          await play(cubit);

          // Then
          verify(() => repository.createPlayer(name: 'Bob')).called(1);
          expect(cubit.state.player2Id, 'n2');
          expect(cubit.state.player2PhotoPath, isNull);
        },
      );

      test(
        '''
      Given typed `олег` and a saved player `Олег`
      When `onPlayTapped` is called
      Then no player is created or updated and the side is linked to the saved id
      And the saved player's exact name is written to the state
      ''',
        () async {
          // Given
          when(
            () => repository.findPlayerByName('олег'),
          ).thenAnswer((_) async => oleh);
          final cubit = buildCubitWithHandler()..onPlayer1NameChanged('олег');

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verifyNothingSaved();
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Олег',
                player2Name: 'Player 2',
                player1Id: 'o1',
              ),
            ),
          ).called(1);
          expect(cubit.state.player1Id, 'o1');
          expect(cubit.state.player1Name, 'Олег');
        },
      );

      test(
        '''
      Given typed `олег` matching a saved player and a newly picked photo
      When `onPlayTapped` is called
      Then the saved player is updated with the new photo and linked
      ''',
        () async {
          // Given
          final updated = oleh.copyWith(photoFile: 'o.jpg');
          when(
            () => repository.findPlayerByName('олег'),
          ).thenAnswer((_) async => oleh);
          when(
            () => repository.updatePlayer(oleh, photoTempPath: '/tmp/o.jpg'),
          ).thenAnswer((_) async => updated);
          when(
            () => repository.photoPathOf(updated),
          ).thenAnswer((_) async => '/photos/o.jpg');
          final cubit = buildCubit()
            ..onPlayer1NameChanged('олег')
            ..onPlayer1PhotoPicked('/tmp/o.jpg');

          // When
          await play(cubit);

          // Then
          verify(
            () => repository.updatePlayer(oleh, photoTempPath: '/tmp/o.jpg'),
          ).called(1);
          verifyNever(
            () => repository.createPlayer(
              name: any(named: 'name'),
              photoTempPath: any(named: 'photoTempPath'),
            ),
          );
          expect(cubit.state.player1Id, 'o1');
          expect(cubit.state.player1PhotoPath, '/photos/o.jpg');
          expect(cubit.state.player1PhotoChanged, isFalse);
        },
      );

      test(
        '''
      Given a selected saved player whose name was edited
      When `onPlayTapped` is called
      Then `updatePlayer` is called with the new name and the id is unchanged
      ''',
        () async {
          // Given
          when(
            () => repository.updatePlayer(anna, name: 'Annie'),
          ).thenAnswer((_) async => anna.copyWith(name: 'Annie'));
          final cubit = buildCubitWithHandler();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);
          cubit.onPlayer1NameChanged('Annie');

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(() => repository.updatePlayer(anna, name: 'Annie')).called(1);
          verifyNever(() => repository.findPlayerByName(any()));
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Annie',
                player2Name: 'Player 2',
                player1Id: 'a1',
              ),
            ),
          ).called(1);
          expect(cubit.state.player1Id, 'a1');
        },
      );

      test(
        '''
      Given a selected saved player and a newly picked photo
      When `onPlayTapped` is called
      Then `updatePlayer` is called with the photo only
      And the state holds the permanent photo path with photo not changed
      ''',
        () async {
          // Given
          final updated = anna.copyWith(photoFile: 'new.jpg');
          when(
            () => repository.updatePlayer(anna, photoTempPath: '/tmp/new.jpg'),
          ).thenAnswer((_) async => updated);
          when(
            () => repository.photoPathOf(updated),
          ).thenAnswer((_) async => '/photos/new.jpg');
          final cubit = buildCubit();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);
          cubit.onPlayer1PhotoPicked('/tmp/new.jpg');

          // When
          await play(cubit);

          // Then
          verify(
            () => repository.updatePlayer(anna, photoTempPath: '/tmp/new.jpg'),
          ).called(1);
          expect(cubit.state.player1PhotoPath, '/photos/new.jpg');
          expect(cubit.state.player1PhotoChanged, isFalse);
        },
      );

      test(
        '''
      Given a selected saved player with nothing changed
      When `onPlayTapped` is called
      Then neither `createPlayer` nor `updatePlayer` is called
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verifyNothingSaved();
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Anna',
                player2Name: 'Player 2',
                player1Id: 'a1',
              ),
            ),
          ).called(1);
        },
      );

      test(
        '''
      Given a selected saved player whose name was cleared
      When `onPlayTapped` is called
      Then the side is a guest and `updatePlayer` is never called
      ''',
        () async {
          // Given
          final cubit = buildCubitWithHandler();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);
          cubit.onPlayer1NameChanged('');

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verifyNothingSaved();
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
      Given both players are typed as `Anna` and a saved `Anna` exists
      When `onPlayTapped` is called
      Then player 1 is linked and player 2 stays a guest with a null id
      ''',
        () async {
          // Given
          when(
            () => repository.findPlayerByName('Anna'),
          ).thenAnswer((_) async => anna);
          final cubit = buildCubitWithHandler()
            ..onPlayer1NameChanged('Anna')
            ..onPlayer2NameChanged('Anna');

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Anna',
                player2Name: 'Anna',
                player1Id: 'a1',
              ),
            ),
          ).called(1);
          verifyNothingSaved();
          expect(cubit.state.player2Id, isNull);
        },
      );

      test(
        '''
      Given `createPlayer` throws for player 1
      When `onPlayTapped` is called
      Then `NavigateToGame` is still emitted with a null id for player 1
      And player 2 is still saved
      ''',
        () async {
          // Given
          final newBob = Player(id: 'n2', name: 'Bob');
          when(
            () => repository.findPlayerByName(any()),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(name: 'Anna'),
          ).thenThrow(Exception('db'));
          when(
            () => repository.createPlayer(name: 'Bob'),
          ).thenAnswer((_) async => newBob);
          final cubit = buildCubitWithHandler()
            ..onPlayer1NameChanged('Anna')
            ..onPlayer2NameChanged('Bob');

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Anna',
                player2Name: 'Bob',
                player2Id: 'n2',
              ),
            ),
          ).called(1);
          expect(cubit.state.player1Id, isNull);
        },
      );

      test(
        '''
      Given a successful first `onPlayTapped` that created a player
      When `onPlayTapped` is called again for a rematch
      Then no `createPlayer` or `updatePlayer` call is made
      And `NavigateToGame` carries the same id
      ''',
        () async {
          // Given
          final newAnna = Player(id: 'n1', name: 'Anna', photoFile: 'n1.jpg');
          when(
            () => repository.findPlayerByName(any()),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(
              name: 'Anna',
              photoTempPath: '/tmp/p1.jpg',
            ),
          ).thenAnswer((_) async => newAnna);
          when(
            () => repository.photoPathOf(newAnna),
          ).thenAnswer((_) async => '/photos/n1.jpg');
          final cubit = buildCubitWithHandler()
            ..onPlayer1NameChanged('Anna')
            ..onPlayer1PhotoPicked('/tmp/p1.jpg');
          await play(cubit);
          clearInteractions(repository);

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then
          verifyNothingSaved();
          verify(
            () => sideEffectHandler.call(
              const NavigateToGame(
                player1Name: 'Anna',
                player2Name: 'Player 2',
                player1PhotoPath: '/photos/n1.jpg',
                player1Id: 'n1',
              ),
            ),
          ).called(2);
        },
      );

      test(
        '''
      Given a linked `олег` / `Олег` side after the first `onPlayTapped`
      When `onPlayTapped` is called again for a rematch
      Then no `createPlayer` or `updatePlayer` call is made
      ''',
        () async {
          // Given
          when(
            () => repository.findPlayerByName('олег'),
          ).thenAnswer((_) async => oleh);
          final cubit = buildCubit()..onPlayer1NameChanged('олег');
          await play(cubit);
          clearInteractions(repository);

          // When
          await play(cubit);

          // Then
          verifyNothingSaved();
          expect(cubit.state.player1Id, 'o1');
        },
      );

      test(
        '''
      Given a selected saved player `олег` whose name is edited case-only to `Олег`
      When `onPlayTapped` is called
      Then `updatePlayer` is called with the new name
      ''',
        () async {
          // Given
          final lower = Player(
            id: 'l1',
            name: 'олег',
            createdAt: DateTime(2026),
          );
          when(
            () => repository.updatePlayer(lower, name: 'Олег'),
          ).thenAnswer((_) async => lower.copyWith(name: 'Олег'));
          final cubit = buildCubit();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: lower);
          cubit.onPlayer1NameChanged('Олег');

          // When
          await play(cubit);

          // Then
          verify(() => repository.updatePlayer(lower, name: 'Олег')).called(1);
          expect(cubit.state.player1Id, 'l1');
          expect(cubit.state.player1Name, 'Олег');
        },
      );

      test(
        '''
      Given a selected saved player whose name was cleared and a first `onPlayTapped`
      When a new name `Bob` is typed and `onPlayTapped` is called again
      Then `updatePlayer` is never called and `createPlayer` is called for `Bob`
      And after the first Play the side showed as a guest with its other fields kept
      ''',
        () async {
          // Given
          final newBob = Player(id: 'n2', name: 'Bob');
          when(
            () => repository.photoPathOf(anna),
          ).thenAnswer((_) async => '/photos/anna.jpg');
          when(
            () => repository.findPlayerByName('Bob'),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(name: 'Bob'),
          ).thenAnswer((_) async => newBob);
          final cubit = buildCubit();
          await cubit.onSavedPlayerSelected(isPlayer1: true, player: anna);
          cubit.onPlayer1NameChanged('');
          await play(cubit);

          // Then (after first Play)
          expect(cubit.state.player1Id, isNull);
          expect(cubit.state.player1Name, '');
          expect(cubit.state.player1PhotoPath, '/photos/anna.jpg');
          expect(cubit.state.player1PhotoChanged, isFalse);

          // When
          cubit.onPlayer1NameChanged('Bob');
          await play(cubit);

          // Then
          verifyNever(
            () => repository.updatePlayer(
              any(),
              name: any(named: 'name'),
              photoTempPath: any(named: 'photoTempPath'),
            ),
          );
          verify(() => repository.createPlayer(name: 'Bob')).called(1);
          expect(cubit.state.player1Id, 'n2');
        },
      );

      test(
        '''
      Given player 1 links to saved `Anna` while player 2 had `Anna` selected
      When `onPlayTapped` is called
      Then player 2 shows as a guest with a null id and its name kept
      And later editing player 2 to `Bob` creates `Bob` instead of renaming `Anna`
      ''',
        () async {
          // Given
          final newBob = Player(id: 'n2', name: 'Bob');
          when(
            () => repository.findPlayerByName('Anna'),
          ).thenAnswer((_) async => anna);
          when(
            () => repository.findPlayerByName('Bob'),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(name: 'Bob'),
          ).thenAnswer((_) async => newBob);
          final cubit = buildCubit()..onPlayer1NameChanged('Anna');
          await cubit.onSavedPlayerSelected(isPlayer1: false, player: anna);

          // When
          await play(cubit);

          // Then (after first Play)
          expect(cubit.state.player1Id, 'a1');
          expect(cubit.state.player2Id, isNull);
          expect(cubit.state.player2Name, 'Anna');

          // When
          cubit
            ..onPlayer1NameChanged('')
            ..onPlayer2NameChanged('Bob');
          await play(cubit);

          // Then
          verifyNever(
            () => repository.updatePlayer(
              any(),
              name: any(named: 'name'),
              photoTempPath: any(named: 'photoTempPath'),
            ),
          );
          verify(() => repository.createPlayer(name: 'Bob')).called(1);
          expect(cubit.state.player2Id, 'n2');
        },
      );

      test(
        '''
      Given `createPlayer` is still running from a first `onPlayTapped`
      When `onPlayTapped` is called a second time without awaiting
      Then `createPlayer` is called once and one `NavigateToGame` is emitted
      And a later `onPlayTapped` works normally
      ''',
        () async {
          // Given
          final completer = Completer<Player>();
          final newAnna = Player(id: 'n1', name: 'Anna');
          when(
            () => repository.findPlayerByName(any()),
          ).thenAnswer((_) async => null);
          when(
            () => repository.createPlayer(name: 'Anna'),
          ).thenAnswer((_) => completer.future);
          final cubit = buildCubitWithHandler()..onPlayer1NameChanged('Anna');

          // When
          final first = play(cubit);
          final second = play(cubit);
          await Future<void>.delayed(Duration.zero);
          completer.complete(newAnna);
          await Future.wait([first, second]);
          await Future<void>.delayed(Duration.zero);

          // Then
          verify(() => repository.createPlayer(name: 'Anna')).called(1);
          const expected = NavigateToGame(
            player1Name: 'Anna',
            player2Name: 'Player 2',
            player1Id: 'n1',
          );
          verify(() => sideEffectHandler.call(expected)).called(1);

          // When
          await play(cubit);
          await Future<void>.delayed(Duration.zero);

          // Then (verified calls are not counted again)
          verifyNever(
            () => repository.createPlayer(
              name: any(named: 'name'),
              photoTempPath: any(named: 'photoTempPath'),
            ),
          );
          verify(() => sideEffectHandler.call(expected)).called(1);
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
