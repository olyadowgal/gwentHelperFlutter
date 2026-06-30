# Flutter Rewrite — Continuation Notes

This file exists so a new Claude Code session (started from THIS directory) can pick up where the previous session left off.

## What This Project Is

A Flutter rewrite of an Android Gwent card-game score tracker. Original Android app is at `/Users/olhadovgal/Projects/gwentHelper`. This Flutter project is a full rewrite using Flutter 3.x + Dart 3.x.

## Tech Stack

- Flutter 3.x / Dart 3.x
- `flutter_riverpod ^2.5.1` — state management
- `go_router ^13.2.1` — navigation
- `sqflite ^2.3.3+1` — local SQLite persistence
- `image_picker` + `image_cropper` — avatar photos
- `uuid ^4.4.0` — card IDs
- `intl ^0.19.0` — date formatting

## Execution Method

We are using **Subagent-Driven Development** (the `superpowers:subagent-driven-development` skill): one fresh subagent per task, with spec review + quality review after each. All subagents should work on this directory.

## Task Status

| # | Task | Status |
|---|------|--------|
| 1 | Flutter project scaffold (deps, main.dart, router) | ✅ Done |
| 2 | Domain models + scoring logic + tests | ✅ Done |
| 3 | Database layer (sqflite) | ✅ Done |
| 4 | State management (Riverpod providers) | ✅ Done |
| 5 | Home screen UI | ✅ Done |
| 6 | Game screen widgets | ✅ Done |
| 7 | Add/Edit card dialogs | ✅ Done |
| 8 | Full game screen implementation | ✅ Done |
| 9 | Scores screen | ✅ Done |
| 10 | Final polish and verification | 🔲 Not started |

## Task 8 — Pending Fixes

The game screen was implemented (commit `e4c954c`) and reviewed. Three fixes are needed before marking Task 8 done:

### Fix 1: `mounted` check after `await showDialog` (Critical)

In `lib/ui/screens/game_screen.dart`, add `if (!mounted) return;` after each `await showDialog` call:

- In `_showAddCardDialog`: after `final card = await showDialog<Card>(...);`, before `if (card != null)`
- In `_showEditCardDialog`: after `final result = await showDialog<EditCardResult>(...);`, before `if (result == null) return;`

### Fix 2: Replace `Navigator.of(context).pop()` with `context.pop()` (Critical)

In `_showGameOverDialog`, the OK button's `onPressed` currently calls:
```dart
Navigator.of(context).pop();
context.pop();
```
Replace both with:
```dart
context.pop(); // dismisses dialog
context.pop(); // returns to home screen
```

### Fix 3: Fix `isWinning` tie case (Important)

Two `UserWidget` calls currently use `>=` for `isWinning`, causing both players to appear as "winning" when tied. Change to `>`:
- `isWinning: p1.totalPoints > p2.totalPoints`
- `isWinning: p2.totalPoints > p1.totalPoints`

After applying, run:
```bash
flutter analyze
git add lib/ui/screens/game_screen.dart
git commit -m "fix: mounted guards after dialogs, single-navigator pop, tie isWinning fix"
```

Then mark Task 8 ✅ done and move on to Task 9.

## Task 9 — Scores Screen

Replace stub `lib/ui/screens/scores_screen.dart` with full implementation:

- `ConsumerWidget` watching `scoresProvider` (from `lib/state/score_provider.dart`)
- `scoresProvider` is a `FutureProvider<List<GameScore>>`
- `GameScore` is in `lib/domain/models/game_score.dart`: fields `date`, `firstPlayer`, `secondPlayer`, `winner` (String), plus 6 nullable round point fields
- Show a `ListView` of score cards (date, players, winner, round scores)
- "Clear All" button calls `ref.read(gwentRepositoryProvider).clearAll()` then `ref.invalidate(scoresProvider)` to refresh
- `gwentRepositoryProvider` is in `lib/state/game_provider.dart`
- Use `intl` package for date formatting

## Task 10 — Final Polish

- `flutter test` — all existing tests pass
- `flutter analyze` — no issues
- Manual checklist: home → play game → add cards → end rounds → see game over → check scores screen

## Key Architecture Notes

- `GameNotifier` (`lib/state/game_notifier.dart`) is a **plain Dart class**, NOT a Riverpod StateNotifier. It uses an `onStateChanged` callback. Its lifetime is tied to `GameScreen`'s `StatefulWidget`.
- `SelectedPlayer` is an enum (not int) used in `GameNotifier.selectPlayer()`
- `EditCardResult` is a **sealed class** in `lib/ui/dialogs/edit_card_dialog.dart`: `EditCardSave(card)` and `EditCardDelete()`
- `import 'package:flutter/material.dart' hide Card;` is used in files that import the domain `Card` class to avoid name conflict with Flutter's `Card` widget
- Scoring behavior (weather→tight-bond ordering, exponential horn stacking) intentionally matches the original Android app, not "correct" Gwent rules

## File Layout

```
lib/
  main.dart
  router.dart
  domain/models/
    ability.dart       — Ability enum with displayName + shortName
    card.dart          — Card (UUID, points, abilities, copyWith)
    cards_row.dart     — CardsRow + full Gwent scoring logic
    cards_row_type.dart
    game_data.dart
    game_score.dart    — DB DTO
    player_data.dart
    rounds_data.dart
    winner.dart
  data/
    database.dart
    game_score_dao.dart
    gwent_repository.dart
  state/
    game_notifier.dart  — GameNotifier + GameState
    game_provider.dart  — gwentRepositoryProvider
    main_provider.dart  — homeProvider, HomeNotifier, HomeState
    score_provider.dart — scoresProvider
  ui/
    screens/
      home_screen.dart   ✅ full
      game_screen.dart   ⚠️ full but needs 3 fixes above
      scores_screen.dart 🔲 stub
    widgets/
      user_widget.dart
      weather_widget.dart
      card_chip.dart
      cards_row_widget.dart
    dialogs/
      add_card_dialog.dart
      edit_card_dialog.dart
test/
  domain/
    cards_row_test.dart
    game_data_test.dart
```
