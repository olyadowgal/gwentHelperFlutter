# Architecture

## Entry Point

`lib/main.dart` bootstraps the app:

1. Create a single `GwentRepository` and expose it app-wide via `RepositoryProvider`.
2. Run `MaterialApp.router`, configured with `appRouter` (`lib/router.dart`, `go_router`) and the app's `MaterialTheme` (`lib/app_theme.dart`).

There is no Firebase, no remote API, no build flavors, and no dart-define configuration — this is a fully offline, single-build app.

## Folder Structure

```
lib/
├── main.dart                  # App entry point
├── router.dart                # go_router route table
├── app_theme.dart             # Global MaterialTheme (Witcher HUD styling)
│
├── features/                  # One folder per screen
│   └── <feature>/              (home, game, scores)
│       ├── cubit/              # Cubit + State + SideEffect for this screen
│       ├── resources/          # Strings local to this feature (<Feature>Strings)
│       ├── view/                # Page (route target) + View (screen body) widgets
│       └── widgets/             # Private widgets used only by this feature
│
├── domain/models/              # Plain Dart entities and scoring logic
│   ├── card.dart, ability.dart, cards_row.dart, cards_row_type.dart
│   ├── game_data.dart, player_data.dart, rounds_data.dart, winner.dart
│   └── game_score.dart         # DB-facing DTO (toMap/fromMap)
│
├── data/                       # Persistence
│   ├── database.dart           # AppDatabase — sqflite singleton, schema + migrations
│   ├── game_score_dao.dart     # GameScoreDao — CRUD against the `game_score` table
│   └── gwent_repository.dart   # GwentRepository — the one dependency Cubits see
│
├── arch/                       # Side-effect plumbing shared by every Cubit
│   ├── side_effect.dart               # SideEffect mixin, WithSideEffects mixin
│   ├── bloc_side_effect_handler.dart  # BlocListener wrapper that consumes side effects
│   ├── side_effect_consumed_aware.dart
│   ├── json_extensions.dart / list_extensions.dart / typedefs.dart
│
└── widgets/hud/                # Shared UI widgets used across features (e.g. HudAvatar)
```

## Layer Diagram

```
┌─────────────────────────────────────┐
│              UI (View)              │  BlocBuilder / BlocConsumer
└───────────────────┬─────────────────┘
                    │ method calls / state
┌───────────────────▼─────────────────┐
│              Cubit                  │  lib/features/<name>/cubit/
└───────────────────┬─────────────────┘
                    │
┌───────────────────▼─────────────────┐
│           GwentRepository           │  lib/data/gwent_repository.dart
└───────────────────┬─────────────────┘
                    │
┌───────────────────▼─────────────────┐
│    GameScoreDao  →  AppDatabase     │  lib/data/
│                       (sqflite)     │
└──────────────────────────────────────┘
```

`domain/models/` sits beside this stack, not inside it — Cubits and the repository both depend on it, but it has no Flutter or sqflite imports of its own.

## State Management: Bloc + SideEffects

The app uses [Cubit](https://bloclibrary.dev/) (via `flutter_bloc`) for all state management. Each feature has its own Cubit that holds the screen state and exposes methods the UI calls in response to user actions.

**Cubit** holds the current state and emits new states via `emit()`. The View rebuilds automatically whenever state changes.

**SideEffects** are one-time events that should not be part of persistent state — showing a snackbar, opening a dialog, or navigating away. They are implemented via a custom `WithSideEffects` mixin on the state class and handled in the View using `BlocSideEffectHandler`. A side effect is emitted with the `+` operator:

```dart
emit(state + ShowErrorMessage('Something went wrong'));
```

SideEffects are optional, but should be added to any non-trivial screen even if not immediately needed — they make future additions (error handling, navigation) much easier without refactoring the state layer.

See [state-management.md](state-management.md) for a full walkthrough with code examples, and [adding-a-feature.md](adding-a-feature.md) for the step-by-step pattern. For deeper Bloc/Cubit background: [bloclibrary.dev](https://bloclibrary.dev/).

## Persistence

`AppDatabase` (`lib/data/database.dart`) is a static singleton wrapping a single `sqflite` database (`gwent_helper.db`) with one table, `game_score`. It owns schema creation (`onCreate`) and upgrades (`onUpgrade`); the current schema is version 2, adding a primary-key `id` column that earlier installs didn't have — see the `onUpgrade` block and `test/data/database_migration_test.dart` for how that migration is verified.

`GameScoreDao` is the only class that talks to `AppDatabase` directly. `GwentRepository` wraps the DAO and is the only dependency Cubits are constructed with — no Cubit imports `sqflite` or `AppDatabase` directly.

## Key Shared Dependency

| Class | File | Purpose |
|---|---|---|
| `GwentRepository` | `lib/data/gwent_repository.dart` | The single data-access dependency injected into every Cubit |

It's created once in `main.dart` and provided via `RepositoryProvider`. Cubits receive it through constructor injection — never via service locator.

## Naming Conventions

- Files and folders: `snake_case`
- Classes and enums: `UpperCamelCase`
- Variables and parameters: `lowerCamelCase`
- Cubit public methods: `onSomethingHappened` (e.g. `onCardTapped`, `onNameChanged`)
- Service/provider methods: describe the action, no `on` prefix (e.g. `insert`, `getAll`)

See `docs/ai-instructions.md` for the full coding style guide.
