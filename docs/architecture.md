# Architecture

## Entry Point

`lib/main.dart` bootstraps the app in this order:

1. Initialize Firebase (Crashlytics, Analytics)
2. Set up `FlutterError` and `PlatformDispatcher` to forward uncaught errors to Crashlytics
3. Initialize Mapbox with the `MAPBOX_API_TOKEN` dart-define
4. Initialize `NotificationService` (local push notifications)
5. Initialize `DatabaseService` (Drift SQLite database)
6. Run `App` wrapped in `MultiRepositoryProvider` with the three shared services

`APP_NAME`, `BASE_URL`, and `MAPBOX_API_TOKEN` are injected at build time via `--dart-define-from-file`. See [ci-and-flavors.md](ci-and-flavors.md).

## Folder Structure

```
lib/
├── main.dart                  # App entry point
├── theme.dart                 # Global MaterialTheme
├── firebase_options.dart      # Generated Firebase config (do not edit)
│
├── app/                       # Root app widget and top-level BLoC
│   ├── bloc/                  # AppCubit (auth state, global navigation)
│   ├── model/                 # App-level models
│   └── view/                  # App widget, router
│
├── features/                  # One folder per screen or flow
│   └── <feature>/
│       ├── cubit/             # State management (Cubit + State + SideEffects)
│       ├── model/             # Feature-local data models
│       ├── resources/         # Strings, constants local to this feature
│       ├── services/          # Feature-local business logic
│       ├── view/              # Screen widget(s)
│       └── widgets/           # Private widgets used by this feature
│
├── data/                      # Shared data layer
│   ├── api/                   # Dio HTTP client + interceptors
│   ├── database/              # Drift DB definition and tables
│   ├── datasources/           # Raw data access (API calls, DB queries)
│   ├── entities/              # Shared data models (API response shapes)
│   ├── providers/             # Combine datasources, return domain objects
│   └── services/              # Cross-feature shared services
│
├── arch/                      # Custom architecture base classes
│   ├── side_effect.dart       # SideEffect mixin and WithSideEffects mixin
│   ├── bloc_side_effect_handler.dart  # BlocListener wrapper for side effects
│   └── ...                    # JSON extensions, list extensions, typedefs
│
├── services/                  # App-wide singleton services
│   └── talker_service.dart    # Logging (Talker)
│
└── widgets/                   # Shared UI widgets used across features
```

## Layer Diagram

```
┌─────────────────────────────────────┐
│              UI (View)              │  BlocBuilder / BlocConsumer
└───────────────────┬─────────────────┘
                    │ events / state
┌───────────────────▼─────────────────┐
│              Cubit                  │  lib/features/<name>/cubit/
└───────────┬───────────┬─────────────┘
            │           │
┌───────────▼──┐  ┌─────▼──────────────┐
│   Services   │  │     Providers      │  lib/data/providers/
│ (lib/data/   │  │ (combine sources,  │
│  services/)  │  │  return models)    │
└──────────────┘  └─────┬──────────────┘
                        │
           ┌────────────▼────────────┐
           │       Datasources       │  lib/data/datasources/
           └───────┬─────────┬───────┘
                   │         │
          ┌────────▼──┐  ┌───▼──────┐
          │  Dio API  │  │  Drift   │
          │  Client   │  │   (DB)   │
          └───────────┘  └──────────┘
```

## State Management: Bloc + SideEffects

The app uses [Cubit](https://bloclibrary.dev/) (a simplified form of Bloc from the `flutter_bloc` package) for all state management. Each feature has its own Cubit that holds the screen state and exposes methods the UI calls in response to user actions.

**Cubit** holds the current state and emits new states via `emit()`. The View rebuilds automatically whenever state changes.

**SideEffects** are one-time events that should not be part of persistent state — showing a snackbar, opening a dialog, or navigating away. They are implemented via a custom `WithSideEffects` mixin on the state class and handled in the View using `BlocSideEffectHandler`. A side effect is emitted with the `+` operator:

```dart
emit(state + ShowErrorMessage('Something went wrong'));
```

SideEffects are optional, but should be added to any non-trivial screen even if not immediately needed — they make future additions (error handling, navigation) much easier without refactoring the state layer.

See [state-management.md](state-management.md) for a full walkthrough with code examples, and [adding-a-feature.md](adding-a-feature.md) for the step-by-step pattern. For deeper Bloc/Cubit background: [bloclibrary.dev](https://bloclibrary.dev/).

## Key Shared Services

| Service | File | Purpose |
|---|---|---|
| `DatabaseService` | `lib/data/database/database_service.dart` | Drift SQLite — local persistence |
| `NotificationService` | `lib/data/services/notification_service.dart` | Local push notifications |
| `talker` | `lib/services/talker_service.dart` | App-wide logging, also exposed in debug UI |

All three are created in `main.dart` and injected via `RepositoryProvider`. Cubits receive them through constructor injection — never via service locator.

## Naming Conventions

- Files and folders: `snake_case`
- Classes and enums: `UpperCamelCase`
- Variables and parameters: `lowerCamelCase`
- Cubit public methods: `onSomethingHappened` (e.g. `onLoginClicked`, `onEmailChanged`)
- Service/provider methods: describe the action, no `on` prefix (e.g. `login`, `fetchData`)

See `.github/copilot-instructions.md` for the full coding style guide.
