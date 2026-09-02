# Scorch, Spy and Muster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Witcher 3-compliant special Scorch, row Scorch, Spy, and Muster interactions to the game helper.

**Architecture:** Pure domain resolvers compute legal Scorch targets from immutable game data. `GameCubit` coordinates card placement and a temporary target-picking state, while the game view renders actions, prompts, and target highlights without embedding rules.

**Tech Stack:** Dart, Flutter Material, Cubit/Equatable, flutter_test, mocktail.

---

### Task 1: Move player-side identity into the domain

**Files:**
- Create: `lib/domain/models/player_side.dart`
- Modify: `lib/features/game/cubit/game_state.dart`
- Modify: `lib/features/game/cubit/game_cubit.dart`
- Modify: `lib/features/game/view/game_view.dart`
- Modify: `test/features/game/game_cubit_test.dart`
- Modify: `test/features/game/game_view_test.dart`

- [ ] **Step 1: Add the domain enum**

```dart
enum PlayerSide { first, second }
```

- [ ] **Step 2: Replace `SelectedPlayer` with `PlayerSide`**

Import `player_side.dart`, delete the feature-local enum, and mechanically replace:

```dart
final PlayerSide selectedPlayer;

PlayerData get selectedPlayerData =>
    selectedPlayer == PlayerSide.first
        ? gameData.firstPlayerData
        : gameData.secondPlayerData;
```

Update all Cubit, view, and test references from `SelectedPlayer.first/second` to
`PlayerSide.first/second`. Do not change behavior.

- [ ] **Step 3: Run focused tests**

Run:

```bash
flutter test test/features/game/game_cubit_test.dart test/features/game/game_view_test.dart
```

Expected: all tests pass.

### Task 2: Add ability metadata without changing scoring

**Files:**
- Modify: `lib/domain/models/ability.dart`
- Modify: `test/domain/cards_row_test.dart`

- [ ] **Step 1: Write failing scoring tests**

Add parameterized cases proving that each new ability preserves printed strength:

```dart
for (final ability in [
  Ability.spy,
  Ability.muster,
  Ability.scorchRow,
]) {
  test(
    '''
    Given a card with `$ability`
    When `pointsOf` is called
    Then the ability does not change its strength
    ''',
    () {
      // Given
      final card = Card(points: 6, abilities: [ability]);
      final row = CardsRow(
        type: CardsRowType.closeCombat,
        cards: [card],
      );

      // When
      final points = row.pointsOf(card);

      // Then
      expect(points, 6);
    },
  );
}
```

- [ ] **Step 2: Run the test and confirm compilation fails**

Run:

```bash
flutter test test/domain/cards_row_test.dart
```

Expected: FAIL because the enum values do not exist.

- [ ] **Step 3: Add enum values and labels**

Add:

```dart
spy,
muster,
scorchRow;
```

Extend both switches:

```dart
Ability.spy => 'Spy',
Ability.muster => 'Muster',
Ability.scorchRow => 'Scorch (Row)',
```

```dart
Ability.spy => 'Sp',
Ability.muster => 'Mu',
Ability.scorchRow => 'Sc',
```

- [ ] **Step 4: Run the focused test**

Run:

```bash
flutter test test/domain/cards_row_test.dart
```

Expected: all tests pass without changing `CardsRow.pointsOf`.

### Task 3: Implement pure Scorch target resolution

**Files:**
- Create: `lib/domain/scorch.dart`
- Create: `test/domain/scorch_test.dart`

- [ ] **Step 1: Write failing resolver tests**

Cover:

```dart
group('`specialScorchTargets`', () {
  test('''
  Given non-hero units on both sides with a strongest tie
  When `specialScorchTargets` is called
  Then every tied strongest unit is returned and heroes are excluded
  ''', () {
    // Build GameData with two strength-8 regular units and one strength-10 hero.
    // Expect only the two strength-8 card IDs.
  });

  test('''
  Given weather and row modifiers
  When `specialScorchTargets` is called
  Then current calculated strength determines the targets
  ''', () {
    // Build weather, horn, morale, and tight-bond rows.
    // Assert targets from CardsRow.pointsOf values, not printed values.
  });

  test('''
  Given an empty or zero-strength battlefield
  When `specialScorchTargets` is called
  Then no targets are returned
  ''', () {
    // Assert empty output for no cards and Decoy-only rows.
  });
});

group('`rowScorchTargets`', () {
  test('''
  Given an enemy row totaling less than 10
  When `rowScorchTargets` is called
  Then no targets are returned
  ''', () {});

  test('''
  Given an enemy row totaling exactly 10
  When `rowScorchTargets` is called
  Then all strongest non-hero units in that same row are returned
  ''', () {});

  test('''
  Given hero strength makes the enemy row reach 10
  When `rowScorchTargets` is called
  Then regular units can be targeted but heroes cannot
  ''', () {});
});
```

Use small test helpers to construct cards, rows, players, and game data. Assert full
`ScorchTarget` values so side and row mistakes are caught.

- [ ] **Step 2: Run and verify failure**

Run:

```bash
flutter test test/domain/scorch_test.dart
```

Expected: FAIL because `scorch.dart` does not exist.

- [ ] **Step 3: Implement target types and resolvers**

Implement:

```dart
final class ScorchTarget extends Equatable {
  final PlayerSide side;
  final CardsRowType rowType;
  final String cardId;

  const ScorchTarget({
    required this.side,
    required this.rowType,
    required this.cardId,
  });

  @override
  List<Object?> get props => [side, rowType, cardId];
}
```

Create a private candidate record:

```dart
typedef _Candidate = ({
  ScorchTarget target,
  int strength,
});
```

For special Scorch, iterate both players and every row, skip Heroes, calculate
`row.pointsOf(card)`, reject strengths below 1, find the maximum, and return every
candidate at that strength.

For row Scorch, choose the side opposite `owner`, get only `rowType`, return empty when
`row.totalPoints < 10`, then apply the same strongest-non-hero selection.

- [ ] **Step 4: Run domain tests**

Run:

```bash
flutter test test/domain/scorch_test.dart test/domain/cards_row_test.dart
```

Expected: all tests pass.

### Task 4: Add Scorch prompt state and Cubit actions

**Files:**
- Modify: `lib/features/game/cubit/game_state.dart`
- Modify: `lib/features/game/cubit/game_side_effect.dart`
- Modify: `lib/features/game/cubit/game_cubit.dart`
- Modify: `test/features/game/game_cubit_test.dart`

- [ ] **Step 1: Write failing Cubit tests**

Add tests for:

```dart
// `onScorchTapped`: prompt with exact special-Scorch target snapshot.
// No targets: ShowNoScorchTargets(ScorchNoTargetReason.nothingToScorch).
// `onScorchTargetTapped`: removes only the selected card and shrinks the prompt.
// Last removal clears the prompt.
// `onScorchPickCancelled`: clears prompt without removing cards.
// Every Scorch action is a no-op after game over.
```

Use `attachSideEffectHandler` for side-effect assertions and verify both players' rows after
removal.

- [ ] **Step 2: Run focused tests and verify failure**

Run:

```bash
flutter test test/features/game/game_cubit_test.dart
```

Expected: compilation fails because prompt types and Cubit methods do not exist.

- [ ] **Step 3: Add state and side-effect types**

Add:

```dart
final class ScorchPrompt extends Equatable {
  final List<ScorchTarget> targets;

  const ScorchPrompt(this.targets) : assert(targets.length > 0);

  @override
  List<Object?> get props => [targets];
}

enum ScorchNoTargetReason { nothingToScorch, rowBelowTen }
```

Add `ScorchPrompt? scorchPrompt` to `GameState`, include it in `props`, and extend
`copyWith`:

```dart
ScorchPrompt? scorchPrompt,
bool clearScorchPrompt = false,
```

Add:

```dart
final class ShowNoScorchTargets extends GameSideEffect {
  final ScorchNoTargetReason reason;
  const ShowNoScorchTargets(this.reason);
  @override
  List<Object?> get props => [reason];
}
```

- [ ] **Step 4: Implement Scorch Cubit actions**

Implement `onScorchTapped`, `onScorchTargetTapped`, and `onScorchPickCancelled`.
Use a private helper that locates the target side, row, and card ID and returns copied
`GameData`. Ignore stale or non-prompt targets rather than throwing.

- [ ] **Step 5: Run focused tests**

Run:

```bash
flutter test test/features/game/game_cubit_test.dart
```

Expected: all tests pass.

### Task 5: Implement Spy, Muster, and row Scorch placement

**Files:**
- Modify: `lib/features/game/cubit/game_side_effect.dart`
- Modify: `lib/features/game/cubit/game_cubit.dart`
- Modify: `test/features/game/game_cubit_test.dart`

- [ ] **Step 1: Write failing card-placement tests**

Add tests proving:

```dart
// Spy is inserted into the opposite player's same row.
// A regular card remains on the selected player's row.
// Muster emits ShowMusterCountDialog(rowType, card).
// Choosing N adds exactly N copies with unique IDs and equal points/abilities.
// Dismissing Muster adds no copies.
// Row Scorch resolves after its unit is inserted.
// A row below 10 emits rowBelowTen; a qualifying row creates ScorchPrompt.
```

- [ ] **Step 2: Run and verify failure**

Run:

```bash
flutter test test/features/game/game_cubit_test.dart
```

Expected: compilation failures for the new side effect and method.

- [ ] **Step 3: Add the Muster side effect**

```dart
final class ShowMusterCountDialog extends GameSideEffect {
  final CardsRowType rowType;
  final Card card;

  const ShowMusterCountDialog(this.rowType, this.card);

  @override
  List<Object?> get props => [rowType, card];
}
```

- [ ] **Step 4: Extend `onCardAdded`**

Select the insertion side first:

```dart
final owner = state.selectedPlayer;
final destination = card.abilities.contains(Ability.spy)
    ? owner.opposite
    : owner;
```

Add an `opposite` extension on `PlayerSide` in `player_side.dart`. Insert the card by copying
the chosen player's row. Then:

```dart
if (card.abilities.contains(Ability.muster)) {
  emit(nextState + ShowMusterCountDialog(rowType, card));
} else if (card.abilities.contains(Ability.scorchRow)) {
  // Resolve targets using `owner` and `rowType`, then prompt or explain.
} else {
  emit(nextState);
}
```

For a Spy with row Scorch, `owner` still means the player who played it; placement side does not
change who the enemy is.

- [ ] **Step 5: Implement Muster copies**

```dart
void onMusterCountChosen(
  CardsRowType rowType,
  Card card,
  int extraCopies,
) {
  if (extraCopies < 1 || extraCopies > 4 || state.gameOver != null) return;
  final side = card.abilities.contains(Ability.spy)
      ? state.selectedPlayer.opposite
      : state.selectedPlayer;
  // Append List.generate(extraCopies, (_) => Card(...)).
}
```

Because the dialog returns while selection cannot change behind a modal, the selected side remains
the owner for this first version.

- [ ] **Step 6: Run focused tests**

Run:

```bash
flutter test test/features/game/game_cubit_test.dart
```

Expected: all tests pass.

### Task 6: Add dialogs, Scorch action, highlights, and pick banner

**Files:**
- Modify: `lib/features/game/resources/game_strings.dart`
- Modify: `lib/features/game/widgets/card_chip.dart`
- Modify: `lib/features/game/widgets/cards_row_widget.dart`
- Modify: `lib/features/game/view/game_view.dart`
- Modify: `test/features/game/game_view_test.dart`

- [ ] **Step 1: Write failing widget tests**

Add tests proving:

```dart
// The Scorch action is visible and fully on-screen at Pixel 8 landscape geometry.
// Tapping Scorch with legal targets enters pick mode.
// Only listed target chips use an error-colored border.
// Tapping a highlighted chip removes it.
// The banner shows remaining count and Cancel clears pick mode.
// A normal chip tap outside pick mode does nothing.
// Long-press still emits ShowEditCardDialog.
```

- [ ] **Step 2: Run and verify failure**

Run:

```bash
flutter test test/features/game/game_view_test.dart
```

Expected: compilation or finder failures because the new controls do not exist.

- [ ] **Step 3: Add strings**

Add:

```dart
static const scorch = 'Scorch';
static const scorchHint = 'Highlight strongest units';
static const nothingToScorch = 'There are no units Scorch can destroy.';
static const rowBelowTen = 'The enemy row must total at least 10.';
static const musterTitle = 'Muster';
static const musterCount = 'How many matching cards should be added?';
static const scorchRemaining = 'Scorch targets remaining: ';
static const scorchOtherSide = 'Targets also remain on the other player’s side.';
```

- [ ] **Step 4: Extend card chip rendering**

Add optional `onTap` and `isScorchTarget` parameters. Wrap the existing card shape in:

```dart
shape: isScorchTarget
    ? RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 3,
        ),
      )
    : null,
```

Replace `_abilityIcon()` with a small widget builder that keeps existing SVG icons and renders
Material vector icons for Spy (`Icons.visibility`), Muster (`Icons.groups`), and row Scorch
(`Icons.local_fire_department`).

- [ ] **Step 5: Pass target state through rows**

Add to `CardsRowWidget`:

```dart
final Set<String> scorchTargetIds;
final void Function(CardsRowType, Card) onScorchTargetTap;
```

Set each chip's `isScorchTarget`, and only provide `onTap` when its ID is in the target set.

- [ ] **Step 6: Add game-screen interactions**

In `GameView`, derive visible target IDs by filtering `state.scorchPrompt?.targets` by
`state.selectedPlayer` and row type. Add a sidebar `_SidebarButton` using
`Icons.local_fire_department` or a dedicated Material-icon variant, wired to
`cubit.onScorchTapped`.

When a prompt exists, overlay or reserve a compact banner above the card rows. It must show the
remaining target count, show `scorchOtherSide` when any target belongs to the non-selected side,
and include a `TextButton` wired to `onScorchPickCancelled`.

Handle `ShowNoScorchTargets` with a reason-specific snackbar.

Handle `ShowMusterCountDialog` with a modal containing choices 1–4 and Cancel; a choice calls
`onMusterCountChosen(rowType, card, count)`.

- [ ] **Step 7: Run widget tests**

Run:

```bash
flutter test test/features/game/game_view_test.dart
```

Expected: all tests pass with no layout exceptions.

### Task 7: Complete verification

**Files:**
- Modify only files implicated by verification failures.

- [ ] **Step 1: Format changed Dart files only**

Run `dart format` with the explicit list of modified `.dart` paths. Do not run it over `lib` or
`test`, because that creates unrelated formatter churn in this repository.

- [ ] **Step 2: Run the entire test suite**

Run:

```bash
flutter test
```

Expected: all existing and new tests pass.

- [ ] **Step 3: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Inspect the final diff**

Run:

```bash
git status --short
git diff --stat
git diff --check
```

Expected: only the approved feature, tests, spec, and plan are changed; no whitespace errors.

- [ ] **Step 5: Manual acceptance check**

On a landscape phone:

1. Add a Spy and confirm its points appear for the other player.
2. Add a Muster card and choose extra copies.
3. Trigger row Scorch below and at the 10-point threshold.
4. Trigger special Scorch with tied targets on both sides.
5. Switch players and remove every highlighted target.
6. Confirm Heroes never highlight and the sidebar does not overflow.
