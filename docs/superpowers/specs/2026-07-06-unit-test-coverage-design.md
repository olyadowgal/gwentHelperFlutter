# Unit Test Coverage — Design Spec

**Date:** 2026-07-06
**Goal:** Cover the gwent_helper_flutter business logic with unit tests: all 3 cubits, remaining domain models, and arch helpers. Widget tests and DAO/sqflite tests are explicitly out of scope.

---

## Decisions Summary

| Area | Decision |
|---|---|
| Scope | Cubits + domain models + arch helpers (no widget tests, no DAO tests) |
| Tooling | `bloc_test` + `mocktail` dev dependencies |
| Repository mocking | `MockGwentRepository` via mocktail |
| Existing tests | `cards_row_test.dart`, `game_data_test.dart`, `widget_test.dart` stay unchanged |

---

## Dependencies

Add to `pubspec.yaml` under `dev_dependencies:`

```yaml
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

(Use latest compatible versions at implementation time; these are indicative.)

---

## Test File Structure

Mirrors `lib/`:

```
test/
  arch/
    json_extensions_test.dart
    list_extensions_test.dart
    side_effects_test.dart
  domain/
    cards_row_test.dart        (existing, unchanged)
    game_data_test.dart        (existing, unchanged)
    player_data_test.dart      (new)
    rounds_data_test.dart      (new)
    game_score_test.dart       (new)
  features/
    home/home_cubit_test.dart
    scores/scores_cubit_test.dart
    game/game_cubit_test.dart
  widget_test.dart             (existing, unchanged)
```

---

## Section 1: Cubit Tests

### GameCubit (`test/features/game/game_cubit_test.dart`) — ~20 cases

Setup: `MockGwentRepository extends Mock implements GwentRepository`. Cubit constructed with `player1Name: 'Alice'`, `player2Name: 'Bob'`.

Behaviors to cover:

1. **Initial state** — both players with given names, 2 lives, empty rows, `SelectedPlayer.first`, round 0, no side effects.
2. **onPlayerSelected** — switches `selectedPlayer`; `selectedPlayerData` getter follows.
3. **onAddCardRequested** — emits state with `ShowAddCardDialog(rowType)` side effect.
4. **onCardAdded** — card appended to the selected player's row only; other player untouched. Verify for both selected players.
5. **onEditCardRequested** — emits `ShowEditCardDialog(row, card)` side effect.
6. **onCardEdited** — card with matching `cardId` replaced; other cards untouched.
7. **onCardDeleted** — card with matching `cardId` removed.
8. **onHornChanged** — sets `horn` on the selected player's specified row only.
9. **onWeatherChanged** — sets `badWeather` on the *same row for both players*.
10. **onEndRoundTapped — winner loses no life**: p1 has more points → p2 loses a life, p1 keeps 2.
11. **onEndRoundTapped — tie**: both lose a life.
12. **onEndRoundTapped — cards cleared between rounds**: after a non-fatal round, both players' rows are empty, horn/weather reset, round counter incremented, `RoundsData` records the pre-clear totals.
13. **onEndRoundTapped — game over p1 wins**: p2 at 1 life and loses → `gameOver == Winner.first`, `ShowGameOverDialog(Winner.first)` side effect, cards NOT cleared.
14. **onEndRoundTapped — game over tie**: both at 1 life, tie round → `gameOver == Winner.tie`.
15. **onEndRoundTapped — no-op after game over**: calling again emits nothing.
16. **onGameOverConfirmed — saves and navigates**: `repository.addGame` called once with a `GameScore` whose players/winner/round points match state (date ignored via `any`/captured matcher); emits `NavigateBack` side effect.
17. **onGameOverConfirmed — double-call guard**: second call does not call `addGame` again and emits nothing.
18. **onGameOverConfirmed — no-op when gameOver is null**.

### HomeCubit (`test/features/home/home_cubit_test.dart`) — ~6 cases

1. Initial state — empty names, null photo paths.
2. `onPlayer1NameChanged` / `onPlayer2NameChanged` update state.
3. `onPlayer1PhotoPicked` / `onPlayer2PhotoPicked` update state.
4. `onPlayTapped` with empty names → `NavigateToGame` with defaults `'Player 1'` / `'Player 2'`.
5. `onPlayTapped` with set names/photos → `NavigateToGame` carries them through.
6. `onScoresTapped` → `NavigateToScores` side effect.

### ScoresCubit (`test/features/scores/scores_cubit_test.dart`) — ~4 cases

Note: the constructor calls `onScreenOpened()`, so stub `getGames()` before construction.

1. Construction loads scores: emits loading state then loaded state with repository's scores.
2. `getGames` throws → emits state with `errorMessage`, `isLoading` false.
3. `onClearAllTapped` → `ShowClearConfirmDialog` side effect.
4. `onClearConfirmed` → `repository.clearGames()` called, state's `scores` emptied.

---

## Section 2: Domain Model Tests

### PlayerData (`test/domain/player_data_test.dart`)

1. Default constructor: 2 lives, all three `CardsRowType` rows present and empty.
2. `totalPoints` sums points across all rows.
3. `minusLife` decrements; clamps at 0 (calling on 0 lives stays 0).
4. `clearCards` empties cards and resets horn/badWeather on every row; keeps `name` and `lives`.

### RoundsData (`test/domain/rounds_data_test.dart`)

1. `withRound(1, a, b)` sets first-round slots, others null.
2. `withRound(2, ...)` and `withRound(3, ...)` fill their slots while preserving previously set rounds.
3. `withRound(4, ...)` throws `ArgumentError`.

### GameScore (`test/domain/game_score_test.dart`)

`GameScore` has `toMap()` / `GameScore.fromMap()` (snake_case keys, date as `millisecondsSinceEpoch`).

1. `toMap → fromMap` round-trip: all fields survive with all round points set.
2. Round-trip with null round points: nulls preserved.
3. `toMap` stores date as `millisecondsSinceEpoch` int.

---

## Section 3: Arch Helper Tests

### json_extensions (`test/arch/json_extensions_test.dart`)

1. `parseObject` — parses present key, returns null for absent key.
2. `parseEnum` — parses string value, null for absent.
3. `parseObjectsList` — parses list, skips entries where parser returns null, returns null for absent key.
4. `parseStringsList` — parses, null for absent.
5. `parseBoolInt` — true/false passthrough, 1 → true, 0 → false, absent → false.
6. `parseNum` — int passthrough, numeric string parsed, absent → null.
7. `getFirstKeyExists` — returns first present key; throws when none present.

### list_extensions (`test/arch/list_extensions_test.dart`)

1. `-` operator removes matching elements, returns new list.
2. `sorted` returns sorted copy without mutating the original.

### Side effects (`test/arch/side_effects_test.dart`)

Uses `GameState`/`HomeState` (or a minimal test-local state class) to verify the generic machinery:

1. `state + effect` appends the effect to `sideEffects` and produces a state that is not equal to the original (Equatable includes `sideEffects` in props).
2. Consuming one side effect (emitting state with one fewer effect) triggers `SideEffectConsumedAware.onSideEffectConsumed` with the consumed effect — testable with a minimal test cubit mixing in `SideEffectConsumedAware`.

---

## Out of Scope

- Widget tests for the restyled UI (CardChip, UserWidget, chevrons, etc.)
- `GameScoreDao` / `AppDatabase` sqflite tests (would need `sqflite_common_ffi`)
- `GwentRepository` itself — a 3-line passthrough; covered implicitly via cubit tests
- Golden/screenshot tests

---

## Verification

- `flutter analyze` — no issues
- `flutter test` — all tests pass (existing 11 + ~45 new)
