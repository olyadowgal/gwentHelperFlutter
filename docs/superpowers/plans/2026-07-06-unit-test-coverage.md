# Unit Test Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cover cubits, remaining domain models, and arch helpers of gwent_helper_flutter with unit tests (~45 new tests).

**Architecture:** Tests mirror `lib/` structure under `test/`. `mocktail` mocks `GwentRepository` for cubit tests. `bloc_test` is used only where states are fully value-comparable (HomeCubit); GameCubit and ScoresCubit use plain `test()` with direct state assertions because their states hold non-Equatable domain objects (identity equality) and ScoresCubit emits from its constructor.

**Tech Stack:** flutter_test, bloc_test, mocktail.

**Spec:** `docs/superpowers/specs/2026-07-06-unit-test-coverage-design.md`

---

## Important context for all tasks

- These are tests for EXISTING code. Tests should pass on first run. If a test fails, first re-check the test against the actual source; if the source genuinely misbehaves, report it as a concern — do NOT silently change production code.
- `Card`, `CardsRow`, `PlayerData`, `GameData`, `GameScore` do NOT override `==` (identity equality). `GameState`/`ScoresState` are Equatable but their props contain these identity-equal objects. Assert on individual fields, not whole-state equality, except for `HomeState` (all value props).
- All side effect classes ARE Equatable (`NavigateToGame`, `ShowAddCardDialog(rowType)`, etc. compare by value; `ShowEditCardDialog` compares `row`/`card` by identity — pass the same instances).
- Existing tests (`test/domain/cards_row_test.dart`, `test/domain/game_data_test.dart`, `test/widget_test.dart`) stay unchanged.

## File Map

### Modified
- `pubspec.yaml` (dev_dependencies)

### Created
- `test/arch/json_extensions_test.dart`
- `test/arch/list_extensions_test.dart`
- `test/arch/side_effects_test.dart`
- `test/domain/player_data_test.dart`
- `test/domain/rounds_data_test.dart`
- `test/domain/game_score_test.dart`
- `test/features/home/home_cubit_test.dart`
- `test/features/scores/scores_cubit_test.dart`
- `test/features/game/game_cubit_test.dart`

---

### Task 1: Dev dependencies + arch helper tests

**Files:**
- Modify: `pubspec.yaml`
- Create: `test/arch/json_extensions_test.dart`
- Create: `test/arch/list_extensions_test.dart`
- Create: `test/arch/side_effects_test.dart`

- [ ] **Step 1: Add dev dependencies**

In `pubspec.yaml` under `dev_dependencies:`, add:

```yaml
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

Run:
```bash
cd /Users/olhadovgal/Projects/gwent_helper_flutter && flutter pub get
```
Expected: resolves cleanly. If version solving fails, relax to the latest versions `flutter pub add` picks: `flutter pub add dev:bloc_test dev:mocktail`.

- [ ] **Step 2: Create test/arch/json_extensions_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/arch/json_extensions.dart';

void main() {
  group('parseObject', () {
    test('parses present key', () {
      final map = <String, dynamic>{
        'user': <String, dynamic>{'name': 'Bob'},
      };
      final name = map.parseObject('user', (m) => m['name'] as String);
      expect(name, 'Bob');
    });

    test('returns null for absent key', () {
      final map = <String, dynamic>{};
      expect(map.parseObject('user', (m) => m), isNull);
    });
  });

  group('parseEnum', () {
    test('parses present string value', () {
      final map = <String, dynamic>{'kind': 'two'};
      final value = map.parseEnum('kind', (v) => v == 'two' ? 2 : null);
      expect(value, 2);
    });

    test('returns null for absent key', () {
      final map = <String, dynamic>{};
      expect(map.parseEnum('kind', (v) => v), isNull);
    });
  });

  group('parseObjectsList', () {
    test('parses list and skips entries where parser returns null', () {
      final map = <String, dynamic>{
        'items': [
          <String, dynamic>{'v': 1},
          <String, dynamic>{'v': null},
          <String, dynamic>{'v': 3},
        ],
      };
      final list = map.parseObjectsList('items', (m) => m['v'] as int?);
      expect(list, [1, 3]);
    });

    test('returns null for absent key', () {
      final map = <String, dynamic>{};
      expect(map.parseObjectsList('items', (m) => m), isNull);
    });
  });

  group('parseStringsList', () {
    test('parses list of strings', () {
      final map = <String, dynamic>{
        'tags': ['a', 'b'],
      };
      expect(map.parseStringsList('tags'), ['a', 'b']);
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.parseStringsList('tags'), isNull);
    });
  });

  group('parseBoolInt', () {
    test('passes through booleans', () {
      expect(<String, dynamic>{'f': true}.parseBoolInt('f'), isTrue);
      expect(<String, dynamic>{'f': false}.parseBoolInt('f'), isFalse);
    });

    test('parses 1 as true and 0 as false', () {
      expect(<String, dynamic>{'f': 1}.parseBoolInt('f'), isTrue);
      expect(<String, dynamic>{'f': 0}.parseBoolInt('f'), isFalse);
    });

    test('returns false for absent key', () {
      expect(<String, dynamic>{}.parseBoolInt('f'), isFalse);
    });
  });

  group('parseNum', () {
    test('passes through num', () {
      expect(<String, dynamic>{'n': 5}.parseNum('n'), 5);
      expect(<String, dynamic>{'n': 4.5}.parseNum('n'), 4.5);
    });

    test('parses numeric string', () {
      expect(<String, dynamic>{'n': '4.5'}.parseNum('n'), 4.5);
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.parseNum('n'), isNull);
    });
  });

  group('getFirstKeyExists', () {
    test('returns first present key', () {
      final map = <String, dynamic>{'b': 1, 'c': 2};
      expect(map.getFirstKeyExists(['a', 'b', 'c']), 'b');
    });

    test('throws when no key is present', () {
      expect(
        () => <String, dynamic>{}.getFirstKeyExists(['a', 'b']),
        throwsException,
      );
    });
  });
}
```

- [ ] **Step 3: Create test/arch/list_extensions_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/arch/list_extensions.dart';

void main() {
  group('operator -', () {
    test('removes matching elements and returns a new list', () {
      final original = [1, 2, 3, 2];
      final result = original - [2];
      expect(result, [1, 3]);
      expect(original, [1, 2, 3, 2]);
    });

    test('removing nothing returns equal list', () {
      expect([1, 2] - <int>[], [1, 2]);
    });
  });

  group('sorted', () {
    test('returns sorted copy without mutating original', () {
      final original = [3, 1, 2];
      final result = original.sorted;
      expect(result, [1, 2, 3]);
      expect(original, [3, 1, 2]);
    });
  });
}
```

- [ ] **Step 4: Create test/arch/side_effects_test.dart**

Uses `HomeState`/`HomeSideEffect` as a concrete `WithSideEffects` implementation, plus a minimal test cubit for the consumed-aware mixin.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/arch/side_effect_consumed_aware.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_side_effect.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_state.dart';

class _ConsumedAwareCubit extends Cubit<HomeState>
    with SideEffectConsumedAware<HomeState> {
  _ConsumedAwareCubit() : super(const HomeState());

  final consumed = <SideEffect>[];

  void addEffect(HomeSideEffect effect) => emit(state + effect);

  void consumeEffect(HomeSideEffect effect) => emit(state - effect);

  @override
  void onSideEffectConsumed(SideEffect sideEffect) => consumed.add(sideEffect);
}

void main() {
  group('WithSideEffects', () {
    test('+ appends the effect and produces an unequal state', () {
      const initial = HomeState();
      final withEffect = initial + const NavigateToScores();
      expect(withEffect.sideEffects, [const NavigateToScores()]);
      expect(withEffect, isNot(equals(initial)));
    });

    test('- removes the effect', () {
      final withEffect = const HomeState() + const NavigateToScores();
      final consumed = withEffect - const NavigateToScores();
      expect(consumed.sideEffects, isEmpty);
    });

    test('+ preserves existing effects', () {
      const gameEffect = NavigateToGame(
        player1Name: 'A',
        player2Name: 'B',
      );
      final state =
          (const HomeState() + const NavigateToScores()) + gameEffect;
      expect(
        state.sideEffects,
        [const NavigateToScores(), gameEffect],
      );
    });
  });

  group('SideEffectConsumedAware', () {
    test('fires onSideEffectConsumed when one effect is consumed', () {
      final cubit = _ConsumedAwareCubit();
      cubit.addEffect(const NavigateToScores());
      cubit.consumeEffect(const NavigateToScores());
      expect(cubit.consumed, [const NavigateToScores()]);
      cubit.close();
    });

    test('does not fire when an effect is added', () {
      final cubit = _ConsumedAwareCubit();
      cubit.addEffect(const NavigateToScores());
      expect(cubit.consumed, isEmpty);
      cubit.close();
    });
  });
}
```

- [ ] **Step 5: Run the new tests**

```bash
flutter test test/arch/
```
Expected: all pass. If any fail, re-read the corresponding source in `lib/arch/` and fix the TEST, not the source (unless the source has a real bug — then stop and report).

- [ ] **Step 6: Full analyze + test**

```bash
flutter analyze && flutter test
```
Expected: no issues, all tests pass.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock test/arch/
git commit -m "test(arch): json/list extensions and side-effect machinery tests, add bloc_test+mocktail"
```

---

### Task 2: Domain model tests

**Files:**
- Create: `test/domain/player_data_test.dart`
- Create: `test/domain/rounds_data_test.dart`
- Create: `test/domain/game_score_test.dart`

- [ ] **Step 1: Create test/domain/player_data_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_data.dart';

void main() {
  group('PlayerData defaults', () {
    test('starts with 2 lives and all row types present and empty', () {
      final player = PlayerData(name: 'Alice');
      expect(player.lives, 2);
      expect(player.cardsRows.keys.toSet(), CardsRowType.values.toSet());
      for (final row in player.cardsRows.values) {
        expect(row.cards, isEmpty);
        expect(row.horn, isFalse);
        expect(row.badWeather, isFalse);
      }
    });
  });

  group('totalPoints', () {
    test('sums points across all rows', () {
      final player = PlayerData(
        cardsRows: {
          CardsRowType.closeCombat: CardsRow(
            type: CardsRowType.closeCombat,
            cards: [Card(points: 5, abilities: const [])],
          ),
          CardsRowType.longRange: CardsRow(
            type: CardsRowType.longRange,
            cards: [Card(points: 3, abilities: const [])],
          ),
          CardsRowType.siege: const CardsRow(type: CardsRowType.siege),
        },
      );
      expect(player.totalPoints, 8);
    });
  });

  group('minusLife', () {
    test('decrements lives', () {
      expect(PlayerData().minusLife().lives, 1);
    });

    test('clamps at 0', () {
      final dead = PlayerData(lives: 0).minusLife();
      expect(dead.lives, 0);
    });
  });

  group('clearCards', () {
    test('empties cards and resets horn/badWeather, keeps name and lives',
        () {
      final player = PlayerData(
        name: 'Alice',
        lives: 1,
        cardsRows: {
          for (final t in CardsRowType.values)
            t: CardsRow(
              type: t,
              cards: [Card(points: 4, abilities: const [])],
              horn: true,
              badWeather: true,
            ),
        },
      );
      final cleared = player.clearCards();
      expect(cleared.name, 'Alice');
      expect(cleared.lives, 1);
      for (final row in cleared.cardsRows.values) {
        expect(row.cards, isEmpty);
        expect(row.horn, isFalse);
        expect(row.badWeather, isFalse);
      }
    });
  });
}
```

- [ ] **Step 2: Create test/domain/rounds_data_test.dart**

```dart
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
```

- [ ] **Step 3: Create test/domain/game_score_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';

void main() {
  final date = DateTime(2026, 7, 6, 12, 30);

  group('toMap / fromMap round-trip', () {
    test('all fields survive with all round points set', () {
      final score = GameScore(
        date: date,
        firstPlayer: 'Alice',
        secondPlayer: 'Bob',
        winner: 'first',
        firstRoundFirstPlayerPoints: 10,
        secondRoundFirstPlayerPoints: 20,
        thirdRoundFirstPlayerPoints: 30,
        firstRoundSecondPlayerPoints: 11,
        secondRoundSecondPlayerPoints: 21,
        thirdRoundSecondPlayerPoints: 31,
      );
      final restored = GameScore.fromMap(score.toMap());
      expect(restored.date, date);
      expect(restored.firstPlayer, 'Alice');
      expect(restored.secondPlayer, 'Bob');
      expect(restored.winner, 'first');
      expect(restored.firstRoundFirstPlayerPoints, 10);
      expect(restored.secondRoundFirstPlayerPoints, 20);
      expect(restored.thirdRoundFirstPlayerPoints, 30);
      expect(restored.firstRoundSecondPlayerPoints, 11);
      expect(restored.secondRoundSecondPlayerPoints, 21);
      expect(restored.thirdRoundSecondPlayerPoints, 31);
    });

    test('null round points are preserved', () {
      final score = GameScore(
        date: date,
        firstPlayer: 'Alice',
        secondPlayer: 'Bob',
        winner: 'tie',
      );
      final restored = GameScore.fromMap(score.toMap());
      expect(restored.firstRoundFirstPlayerPoints, isNull);
      expect(restored.thirdRoundSecondPlayerPoints, isNull);
    });

    test('toMap stores date as millisecondsSinceEpoch', () {
      final score = GameScore(
        date: date,
        firstPlayer: 'A',
        secondPlayer: 'B',
        winner: 'first',
      );
      expect(score.toMap()['date'], date.millisecondsSinceEpoch);
    });
  });
}
```

- [ ] **Step 4: Run + commit**

```bash
flutter test test/domain/ && flutter analyze
git add test/domain/
git commit -m "test(domain): PlayerData, RoundsData, GameScore tests"
```
Expected: all tests pass (including the 2 pre-existing domain test files), no analyzer issues.

---

### Task 3: HomeCubit + ScoresCubit tests

**Files:**
- Create: `test/features/home/home_cubit_test.dart`
- Create: `test/features/scores/scores_cubit_test.dart`

- [ ] **Step 1: Create test/features/home/home_cubit_test.dart**

`HomeState` is fully value-comparable, so `blocTest` with `expect:` lists works.

```dart
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
```

- [ ] **Step 2: Create test/features/scores/scores_cubit_test.dart**

NOTE: `ScoresCubit`'s constructor calls `onScreenOpened()` — the `isLoading: true` emission happens synchronously during construction, so `blocTest` (which attaches its listener after `build`) would miss it. Use plain tests: stub first, construct, await a microtask, assert final state.

```dart
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
```

- [ ] **Step 3: Run + commit**

```bash
flutter test test/features/ && flutter analyze
git add test/features/
git commit -m "test(features): HomeCubit and ScoresCubit tests"
```
Expected: all pass, no analyzer issues.

---

### Task 4: GameCubit tests

**Files:**
- Create: `test/features/game/game_cubit_test.dart`

- [ ] **Step 1: Create test/features/game/game_cubit_test.dart**

Plain `test()` style throughout — `GameState.props` contains non-Equatable `GameData`, so state-list expectations would compare by identity and fail. Assert on fields of `cubit.state`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_cubit.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_side_effect.dart';
import 'package:gwent_helper_flutter/features/game/cubit/game_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGwentRepository extends Mock implements GwentRepository {}

Card card(int points, {String? id, List<Ability> abilities = const []}) =>
    Card(cardId: id, points: points, abilities: abilities);

void main() {
  late MockGwentRepository repository;
  late GameCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      GameScore(
        date: DateTime(2026),
        firstPlayer: '',
        secondPlayer: '',
        winner: '',
      ),
    );
  });

  setUp(() {
    repository = MockGwentRepository();
    when(() => repository.addGame(any())).thenAnswer((_) async {});
    cubit = GameCubit(
      player1Name: 'Alice',
      player2Name: 'Bob',
      repository: repository,
    );
  });

  tearDown(() => cubit.close());

  group('initial state', () {
    test('players named, 2 lives, empty rows, first selected, round 0', () {
      final state = cubit.state;
      expect(state.gameData.firstPlayerData.name, 'Alice');
      expect(state.gameData.secondPlayerData.name, 'Bob');
      expect(state.gameData.firstPlayerData.lives, 2);
      expect(state.gameData.secondPlayerData.lives, 2);
      expect(state.gameData.firstPlayerData.totalPoints, 0);
      expect(state.selectedPlayer, SelectedPlayer.first);
      expect(state.roundCounter, 0);
      expect(state.gameOver, isNull);
      expect(state.sideEffects, isEmpty);
    });
  });

  group('onPlayerSelected', () {
    test('switches selected player and selectedPlayerData follows', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      expect(cubit.state.selectedPlayer, SelectedPlayer.second);
      expect(cubit.state.selectedPlayerData.name, 'Bob');
    });
  });

  group('card dialogs', () {
    test('onAddCardRequested emits ShowAddCardDialog side effect', () {
      cubit.onAddCardRequested(CardsRowType.siege);
      expect(
        cubit.state.sideEffects,
        [const ShowAddCardDialog(CardsRowType.siege)],
      );
    });

    test('onEditCardRequested emits ShowEditCardDialog side effect', () {
      final c = card(5);
      cubit.onCardAdded(CardsRowType.closeCombat, c);
      final row = cubit
          .state.gameData.firstPlayerData.cardsRows[CardsRowType.closeCombat]!;
      cubit.onEditCardRequested(row, c);
      expect(cubit.state.sideEffects, [ShowEditCardDialog(row, c)]);
    });
  });

  group('onCardAdded', () {
    test('appends to selected player row only', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      final p1Row = cubit
          .state.gameData.firstPlayerData.cardsRows[CardsRowType.closeCombat]!;
      final p2Row = cubit
          .state.gameData.secondPlayerData.cardsRows[CardsRowType.closeCombat]!;
      expect(p1Row.cards, hasLength(1));
      expect(p2Row.cards, isEmpty);
    });

    test('adds to second player when selected', () {
      cubit.onPlayerSelected(SelectedPlayer.second);
      cubit.onCardAdded(CardsRowType.longRange, card(3));
      final p1Row = cubit
          .state.gameData.firstPlayerData.cardsRows[CardsRowType.longRange]!;
      final p2Row = cubit
          .state.gameData.secondPlayerData.cardsRows[CardsRowType.longRange]!;
      expect(p1Row.cards, isEmpty);
      expect(p2Row.cards, hasLength(1));
    });
  });

  group('onCardEdited', () {
    test('replaces card with matching cardId, leaves others', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5, id: 'c1'));
      cubit.onCardAdded(CardsRowType.closeCombat, card(3, id: 'c2'));
      cubit.onCardEdited(CardsRowType.closeCombat, card(9, id: 'c1'));
      final cards = cubit.state.gameData.firstPlayerData
          .cardsRows[CardsRowType.closeCombat]!.cards;
      expect(cards.firstWhere((c) => c.cardId == 'c1').points, 9);
      expect(cards.firstWhere((c) => c.cardId == 'c2').points, 3);
    });
  });

  group('onCardDeleted', () {
    test('removes card with matching cardId', () {
      cubit.onCardAdded(CardsRowType.siege, card(5, id: 'c1'));
      cubit.onCardAdded(CardsRowType.siege, card(3, id: 'c2'));
      cubit.onCardDeleted(CardsRowType.siege, card(5, id: 'c1'));
      final cards = cubit
          .state.gameData.firstPlayerData.cardsRows[CardsRowType.siege]!.cards;
      expect(cards.map((c) => c.cardId), ['c2']);
    });
  });

  group('onHornChanged', () {
    test('sets horn on the selected player specified row only', () {
      cubit.onHornChanged(CardsRowType.longRange, true);
      final p1 = cubit.state.gameData.firstPlayerData;
      final p2 = cubit.state.gameData.secondPlayerData;
      expect(p1.cardsRows[CardsRowType.longRange]!.horn, isTrue);
      expect(p1.cardsRows[CardsRowType.closeCombat]!.horn, isFalse);
      expect(p2.cardsRows[CardsRowType.longRange]!.horn, isFalse);
    });
  });

  group('onWeatherChanged', () {
    test('sets badWeather on the same row for BOTH players', () {
      cubit.onWeatherChanged(CardsRowType.closeCombat, true);
      final p1 = cubit.state.gameData.firstPlayerData;
      final p2 = cubit.state.gameData.secondPlayerData;
      expect(p1.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
      expect(p2.cardsRows[CardsRowType.closeCombat]!.badWeather, isTrue);
      expect(p1.cardsRows[CardsRowType.siege]!.badWeather, isFalse);
    });
  });

  group('onEndRoundTapped', () {
    test('loser loses a life, winner keeps lives', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5)); // Alice 5, Bob 0
      cubit.onEndRoundTapped();
      expect(cubit.state.gameData.firstPlayerData.lives, 2);
      expect(cubit.state.gameData.secondPlayerData.lives, 1);
    });

    test('tie: both players lose a life', () {
      cubit.onEndRoundTapped(); // 0 : 0 → tie
      expect(cubit.state.gameData.firstPlayerData.lives, 1);
      expect(cubit.state.gameData.secondPlayerData.lives, 1);
    });

    test('cards cleared and round recorded after non-fatal round', () {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onPlayerSelected(SelectedPlayer.second);
      cubit.onCardAdded(CardsRowType.siege, card(2));
      cubit.onEndRoundTapped();

      final state = cubit.state;
      expect(state.roundCounter, 1);
      expect(state.roundsData.firstRoundFirst, 5);
      expect(state.roundsData.firstRoundSecond, 2);
      expect(state.gameData.firstPlayerData.totalPoints, 0);
      expect(state.gameData.secondPlayerData.totalPoints, 0);
      expect(state.gameOver, isNull);
    });

    test('game over when a player runs out of lives; cards NOT cleared', () {
      // Round 1: Alice wins, Bob 2→1
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onEndRoundTapped();
      // Round 2: Alice wins again, Bob 1→0 → game over
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onEndRoundTapped();

      final state = cubit.state;
      expect(state.gameOver, Winner.first);
      expect(state.sideEffects, [const ShowGameOverDialog(Winner.first)]);
      // On game over the final board is preserved (not cleared).
      expect(state.gameData.firstPlayerData.totalPoints, 5);
    });

    test('double game over (both at 0) is a tie', () {
      cubit.onEndRoundTapped(); // tie: both 2→1
      cubit.onEndRoundTapped(); // tie: both 1→0 → game over tie
      expect(cubit.state.gameOver, Winner.tie);
      expect(cubit.state.sideEffects, [const ShowGameOverDialog(Winner.tie)]);
    });

    test('is a no-op after game over', () {
      cubit.onEndRoundTapped();
      cubit.onEndRoundTapped(); // game over (tie)
      final roundsBefore = cubit.state.roundCounter;
      cubit.onEndRoundTapped(); // must do nothing
      expect(cubit.state.roundCounter, roundsBefore);
    });
  });

  group('onGameOverConfirmed', () {
    Future<void> playToGameOver() async {
      cubit.onCardAdded(CardsRowType.closeCombat, card(5));
      cubit.onEndRoundTapped(); // Bob 2→1
      cubit.onCardAdded(CardsRowType.closeCombat, card(7));
      cubit.onEndRoundTapped(); // Bob 1→0 → game over Winner.first
    }

    test('saves the score once and emits NavigateBack', () async {
      await playToGameOver();
      await cubit.onGameOverConfirmed();

      final captured =
          verify(() => repository.addGame(captureAny())).captured;
      expect(captured, hasLength(1));
      final score = captured.single as GameScore;
      expect(score.firstPlayer, 'Alice');
      expect(score.secondPlayer, 'Bob');
      expect(score.winner, 'first');
      expect(score.firstRoundFirstPlayerPoints, 5);
      expect(score.secondRoundFirstPlayerPoints, 7);
      expect(score.thirdRoundFirstPlayerPoints, isNull);
      expect(score.firstRoundSecondPlayerPoints, 0);

      expect(cubit.state.sideEffects, contains(const NavigateBack()));
    });

    test('second call does not save again', () async {
      await playToGameOver();
      await cubit.onGameOverConfirmed();
      await cubit.onGameOverConfirmed();
      verify(() => repository.addGame(any())).called(1);
    });

    test('is a no-op when game is not over', () async {
      await cubit.onGameOverConfirmed();
      verifyNever(() => repository.addGame(any()));
      expect(cubit.state.sideEffects, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the GameCubit tests**

```bash
flutter test test/features/game/
```
Expected: all pass. Two spots most likely to need attention if reality differs from this plan:
- The `ShowEditCardDialog(row, c)` equality check relies on passing the exact same `row`/`card` instances — read the emitted side effect from `cubit.state.sideEffects.single` and compare fields instead if the equality assert fails.
- `sideEffects` accumulation: side effects persist in state until the UI consumes them (`BlocSideEffectHandler` does the `-` removal at runtime; in unit tests nothing consumes them). Where a test performs several side-effect-emitting calls, use `contains(...)` rather than exact list equality.

- [ ] **Step 3: Full suite + analyze**

```bash
flutter analyze && flutter test
```
Expected: no issues; all tests (old + new, ~56 total) pass.

- [ ] **Step 4: Commit**

```bash
git add test/features/game/
git commit -m "test(game): GameCubit tests — card CRUD, horn/weather, rounds, game over, save guard"
```
