# Bloc Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the Gwent Helper app from Riverpod + custom GameNotifier to Flutter Bloc (Cubit + SideEffects) following the architecture defined in `docs/ai-instructions.md`, `docs/architecture.md`, and `docs/state-management.md`.

**Architecture:** Each screen becomes a feature folder with `cubit/`, `view/`, `widgets/`, and `resources/` subfolders. State is managed by Cubits; one-time events (navigation, dialogs) are emitted as SideEffects and handled in the View via `BlocSideEffectHandler`. The repository is provided at app level via `RepositoryProvider` and injected into Cubits via constructor DI — no service locators.

**Tech Stack:** `flutter_bloc ^9.1.1` (already present), `equatable` (to add), `go_router ^13.2.1` (keep), `image_picker`, `image_cropper` (keep). Remove `flutter_riverpod`.

---

## File Map

### Files to DELETE
- `lib/state/game_notifier.dart`
- `lib/state/game_provider.dart`
- `lib/state/main_provider.dart`
- `lib/state/score_provider.dart`
- `lib/ui/screens/home_screen.dart`
- `lib/ui/screens/game_screen.dart`
- `lib/ui/screens/scores_screen.dart`
- `lib/ui/widgets/user_widget.dart`
- `lib/ui/widgets/weather_widget.dart`
- `lib/ui/widgets/cards_row_widget.dart`
- `lib/ui/widgets/card_chip.dart`
- `lib/ui/dialogs/add_card_dialog.dart`
- `lib/ui/dialogs/edit_card_dialog.dart`

### Files to KEEP (unchanged)
- `lib/arch/side_effect.dart`
- `lib/arch/bloc_side_effect_handler.dart`
- `lib/arch/list_extensions.dart`
- `lib/arch/json_extensions.dart`
- `lib/arch/typedefs.dart`
- `lib/arch/side_effect_consumed_aware.dart`
- `lib/data/database.dart`
- `lib/data/game_score_dao.dart`
- `lib/data/gwent_repository.dart`
- `lib/domain/models/` (all files)

### Files to CREATE

```
lib/
├── main.dart                   MODIFY — swap ProviderScope → MultiRepositoryProvider
├── router.dart                 MODIFY — point routes to Page widgets, use Navigator push for /game
│
├── features/
│   ├── home/
│   │   ├── cubit/
│   │   │   ├── home_cubit.dart
│   │   │   ├── home_state.dart
│   │   │   └── home_side_effect.dart
│   │   ├── resources/
│   │   │   └── home_strings.dart
│   │   ├── view/
│   │   │   ├── home_page.dart   ← BlocProvider only, no UI
│   │   │   └── home_view.dart   ← UI only
│   │   └── widgets/
│   │       └── player_input_widget.dart
│   │
│   ├── game/
│   │   ├── cubit/
│   │   │   ├── game_cubit.dart
│   │   │   ├── game_state.dart
│   │   │   └── game_side_effect.dart
│   │   ├── resources/
│   │   │   └── game_strings.dart
│   │   ├── view/
│   │   │   ├── game_page.dart
│   │   │   └── game_view.dart
│   │   └── widgets/
│   │       ├── user_widget.dart
│   │       ├── weather_widget.dart
│   │       ├── cards_row_widget.dart
│   │       ├── card_chip.dart
│   │       ├── add_card_dialog.dart
│   │       └── edit_card_dialog.dart
│   │
│   └── scores/
│       ├── cubit/
│       │   ├── scores_cubit.dart
│       │   ├── scores_state.dart
│       │   └── scores_side_effect.dart
│       ├── resources/
│       │   └── scores_strings.dart
│       ├── view/
│       │   ├── scores_page.dart
│       │   └── scores_view.dart
│       └── widgets/
│           └── score_card_widget.dart
```

---

## Task 1: Add `equatable`, remove `flutter_riverpod`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Update pubspec.yaml**

  Change dependencies block so it has `equatable: ^2.0.5` and does NOT have `flutter_riverpod`:

  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    flutter_bloc: ^9.1.1
    equatable: ^2.0.5
    go_router: ^13.2.1
    sqflite: ^2.3.3+1
    path: ^1.9.0
    path_provider: ^2.1.3
    image_picker: ^1.1.2
    image_cropper: ^12.2.1
    uuid: ^4.4.0
    intl: ^0.19.0
  ```

- [ ] **Step 2: Run pub get**

  ```bash
  flutter pub get
  ```

  Expected: resolves successfully, no Riverpod packages in output.

- [ ] **Step 3: Commit**

  ```bash
  git add pubspec.yaml pubspec.lock
  git commit -m "chore: swap flutter_riverpod for equatable"
  ```

---

## Task 2: Home feature — cubit layer

**Files:**
- Create: `lib/features/home/cubit/home_side_effect.dart`
- Create: `lib/features/home/cubit/home_state.dart`
- Create: `lib/features/home/cubit/home_cubit.dart`

- [ ] **Step 1: Create `home_side_effect.dart`**

  ```dart
  // lib/features/home/cubit/home_side_effect.dart
  import 'package:equatable/equatable.dart';
  import '../../../arch/side_effect.dart';

  sealed class HomeSideEffect extends Equatable implements SideEffect {
    const HomeSideEffect();

    @override
    List<Object?> get props => [];
  }

  class NavigateToGame extends HomeSideEffect {
    final String player1Name;
    final String player2Name;
    final String? player1PhotoPath;
    final String? player2PhotoPath;

    const NavigateToGame({
      required this.player1Name,
      required this.player2Name,
      this.player1PhotoPath,
      this.player2PhotoPath,
    });

    @override
    List<Object?> get props => [player1Name, player2Name, player1PhotoPath, player2PhotoPath];
  }

  class NavigateToScores extends HomeSideEffect {}
  ```

- [ ] **Step 2: Create `home_state.dart`**

  ```dart
  // lib/features/home/cubit/home_state.dart
  import 'package:equatable/equatable.dart';
  import '../../../arch/side_effect.dart';
  import 'home_side_effect.dart';

  final class HomeState extends Equatable
      with WithSideEffects<HomeState, HomeSideEffect> {
    final String player1Name;
    final String player2Name;
    final String? player1PhotoPath;
    final String? player2PhotoPath;

    @override
    final List<HomeSideEffect> sideEffects;

    const HomeState({
      this.player1Name = '',
      this.player2Name = '',
      this.player1PhotoPath,
      this.player2PhotoPath,
      this.sideEffects = const [],
    });

    HomeState copyWith({
      String? player1Name,
      String? player2Name,
      String? player1PhotoPath,
      String? player2PhotoPath,
      List<HomeSideEffect>? sideEffects,
    }) =>
        HomeState(
          player1Name: player1Name ?? this.player1Name,
          player2Name: player2Name ?? this.player2Name,
          player1PhotoPath: player1PhotoPath ?? this.player1PhotoPath,
          player2PhotoPath: player2PhotoPath ?? this.player2PhotoPath,
          sideEffects: sideEffects ?? this.sideEffects,
        );

    @override
    HomeState withSideEffects(List<HomeSideEffect> sideEffects) =>
        copyWith(sideEffects: sideEffects);

    @override
    List<Object?> get props => [
          player1Name,
          player2Name,
          player1PhotoPath,
          player2PhotoPath,
          sideEffects,
        ];
  }
  ```

- [ ] **Step 3: Create `home_cubit.dart`**

  ```dart
  // lib/features/home/cubit/home_cubit.dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'home_side_effect.dart';
  import 'home_state.dart';

  class HomeCubit extends Cubit<HomeState> {
    HomeCubit() : super(const HomeState());

    void onPlayer1NameChanged(String name) =>
        emit(state.copyWith(player1Name: name));

    void onPlayer2NameChanged(String name) =>
        emit(state.copyWith(player2Name: name));

    void onPlayer1PhotoPicked(String path) =>
        emit(state.copyWith(player1PhotoPath: path));

    void onPlayer2PhotoPicked(String path) =>
        emit(state.copyWith(player2PhotoPath: path));

    void onPlayTapped() {
      emit(
        state +
            NavigateToGame(
              player1Name:
                  state.player1Name.isEmpty ? 'Player 1' : state.player1Name,
              player2Name:
                  state.player2Name.isEmpty ? 'Player 2' : state.player2Name,
              player1PhotoPath: state.player1PhotoPath,
              player2PhotoPath: state.player2PhotoPath,
            ),
      );
    }

    void onScoresTapped() => emit(state + NavigateToScores());
  }
  ```

- [ ] **Step 4: Run analyze — expect errors only about missing imports (Riverpod files still exist)**

  ```bash
  flutter analyze lib/features/home/
  ```

  Expected: No issues in the new files.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/home/cubit/
  git commit -m "feat(home): add HomeCubit, HomeState, HomeSideEffect"
  ```

---

## Task 3: Home feature — view layer

**Files:**
- Create: `lib/features/home/resources/home_strings.dart`
- Create: `lib/features/home/widgets/player_input_widget.dart`
- Create: `lib/features/home/view/home_page.dart`
- Create: `lib/features/home/view/home_view.dart`

- [ ] **Step 1: Create `home_strings.dart`**

  ```dart
  // lib/features/home/resources/home_strings.dart
  abstract class HomeStrings {
    static const appTitle = 'GwentHelper';
    static const vs = 'VS';
    static const play = 'PLAY';
    static const player1 = 'Player 1';
    static const player2 = 'Player 2';
    static const scoresTooltip = 'Leaderboard';
  }
  ```

- [ ] **Step 2: Create `player_input_widget.dart`**

  ```dart
  // lib/features/home/widgets/player_input_widget.dart
  import 'dart:io';
  import 'package:flutter/material.dart';

  class PlayerInputWidget extends StatelessWidget {
    final String label;
    final TextEditingController controller;
    final String? photoPath;
    final VoidCallback onPhotoTap;
    final ValueChanged<String> onNameChanged;

    const PlayerInputWidget({
      super.key,
      required this.label,
      required this.controller,
      required this.photoPath,
      required this.onPhotoTap,
      required this.onNameChanged,
    });

    @override
    Widget build(BuildContext context) => Column(
          children: [
            GestureDetector(
              onTap: onPhotoTap,
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    photoPath != null ? FileImage(File(photoPath!)) : null,
                child: photoPath == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: label),
                onChanged: onNameChanged,
              ),
            ),
          ],
        );
  }
  ```

- [ ] **Step 3: Create `home_page.dart`**

  ```dart
  // lib/features/home/view/home_page.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../cubit/home_cubit.dart';
  import 'home_view.dart';

  class HomePage extends StatelessWidget {
    const HomePage({super.key});

    @override
    Widget build(BuildContext context) => BlocProvider(
          create: (_) => HomeCubit(),
          child: const HomeView(),
        );
  }
  ```

- [ ] **Step 4: Create `home_view.dart`**

  ```dart
  // lib/features/home/view/home_view.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';
  import 'package:image_cropper/image_cropper.dart';
  import 'package:image_picker/image_picker.dart';
  import '../../../arch/bloc_side_effect_handler.dart';
  import '../cubit/home_cubit.dart';
  import '../cubit/home_side_effect.dart';
  import '../cubit/home_state.dart';
  import '../resources/home_strings.dart';
  import '../widgets/player_input_widget.dart';

  class HomeView extends StatefulWidget {
    const HomeView({super.key});

    @override
    State<HomeView> createState() => _HomeViewState();
  }

  class _HomeViewState extends State<HomeView> {
    final _p1Controller = TextEditingController();
    final _p2Controller = TextEditingController();

    @override
    void dispose() {
      _p1Controller.dispose();
      _p2Controller.dispose();
      super.dispose();
    }

    Future<void> _pickPhoto(BuildContext context, bool isPlayer1) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
              aspectRatioPresets: [CropAspectRatioPreset.square]),
          IOSUiSettings(aspectRatioPresets: [CropAspectRatioPreset.square]),
        ],
      );
      if (cropped == null) return;
      if (!context.mounted) return;

      final cubit = context.read<HomeCubit>();
      if (isPlayer1) {
        cubit.onPlayer1PhotoPicked(cropped.path);
      } else {
        cubit.onPlayer2PhotoPicked(cropped.path);
      }
    }

    @override
    Widget build(BuildContext context) =>
        BlocSideEffectHandler<HomeCubit, HomeState, HomeSideEffect>(
          listener: (context, sideEffect) {
            switch (sideEffect) {
              case NavigateToGame(
                  :final player1Name,
                  :final player2Name,
                  :final player1PhotoPath,
                  :final player2PhotoPath,
                ):
                context.push('/game', extra: {
                  'player1Name': player1Name,
                  'player2Name': player2Name,
                  'player1PhotoPath': player1PhotoPath,
                  'player2PhotoPath': player2PhotoPath,
                });
              case NavigateToScores():
                context.push('/scores');
            }
          },
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text(HomeStrings.appTitle)),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        PlayerInputWidget(
                          label: HomeStrings.player1,
                          controller: _p1Controller,
                          photoPath: state.player1PhotoPath,
                          onPhotoTap: () => _pickPhoto(context, true),
                          onNameChanged:
                              context.read<HomeCubit>().onPlayer1NameChanged,
                        ),
                        const Text(
                          HomeStrings.vs,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        PlayerInputWidget(
                          label: HomeStrings.player2,
                          controller: _p2Controller,
                          photoPath: state.player2PhotoPath,
                          onPhotoTap: () => _pickPhoto(context, false),
                          onNameChanged:
                              context.read<HomeCubit>().onPlayer2NameChanged,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: context.read<HomeCubit>().onPlayTapped,
                      child: const Text(HomeStrings.play),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.leaderboard),
                      tooltip: HomeStrings.scoresTooltip,
                      onPressed: context.read<HomeCubit>().onScoresTapped,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
  ```

- [ ] **Step 5: Run analyze on the new home feature files**

  ```bash
  flutter analyze lib/features/home/
  ```

  Expected: No issues.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/features/home/
  git commit -m "feat(home): add HomePage, HomeView, PlayerInputWidget, HomeStrings"
  ```

---

## Task 4: Scores feature — cubit + view

**Files:**
- Create: `lib/features/scores/cubit/scores_side_effect.dart`
- Create: `lib/features/scores/cubit/scores_state.dart`
- Create: `lib/features/scores/cubit/scores_cubit.dart`
- Create: `lib/features/scores/resources/scores_strings.dart`
- Create: `lib/features/scores/widgets/score_card_widget.dart`
- Create: `lib/features/scores/view/scores_page.dart`
- Create: `lib/features/scores/view/scores_view.dart`

- [ ] **Step 1: Create `scores_side_effect.dart`**

  ```dart
  // lib/features/scores/cubit/scores_side_effect.dart
  import 'package:equatable/equatable.dart';
  import '../../../arch/side_effect.dart';

  sealed class ScoresSideEffect extends Equatable implements SideEffect {
    const ScoresSideEffect();

    @override
    List<Object?> get props => [];
  }

  class ShowClearConfirmDialog extends ScoresSideEffect {
    const ShowClearConfirmDialog();
  }
  ```

- [ ] **Step 2: Create `scores_state.dart`**

  ```dart
  // lib/features/scores/cubit/scores_state.dart
  import 'package:equatable/equatable.dart';
  import '../../../arch/side_effect.dart';
  import '../../../domain/models/game_score.dart';
  import 'scores_side_effect.dart';

  final class ScoresState extends Equatable
      with WithSideEffects<ScoresState, ScoresSideEffect> {
    final bool isLoading;
    final List<GameScore> scores;
    final String? errorMessage;

    @override
    final List<ScoresSideEffect> sideEffects;

    const ScoresState({
      this.isLoading = false,
      this.scores = const [],
      this.errorMessage,
      this.sideEffects = const [],
    });

    ScoresState copyWith({
      bool? isLoading,
      List<GameScore>? scores,
      String? errorMessage,
      bool clearError = false,
      List<ScoresSideEffect>? sideEffects,
    }) =>
        ScoresState(
          isLoading: isLoading ?? this.isLoading,
          scores: scores ?? this.scores,
          errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
          sideEffects: sideEffects ?? this.sideEffects,
        );

    @override
    ScoresState withSideEffects(List<ScoresSideEffect> sideEffects) =>
        copyWith(sideEffects: sideEffects);

    @override
    List<Object?> get props => [isLoading, scores, errorMessage, sideEffects];
  }
  ```

- [ ] **Step 3: Create `scores_cubit.dart`**

  ```dart
  // lib/features/scores/cubit/scores_cubit.dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../../data/gwent_repository.dart';
  import 'scores_side_effect.dart';
  import 'scores_state.dart';

  class ScoresCubit extends Cubit<ScoresState> {
    final GwentRepository _repository;

    ScoresCubit({required GwentRepository repository})
        : _repository = repository,
          super(const ScoresState()) {
      onScreenOpened();
    }

    Future<void> onScreenOpened() async {
      emit(state.copyWith(isLoading: true, clearError: true));
      try {
        final scores = await _repository.getGames();
        emit(state.copyWith(isLoading: false, scores: scores));
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    }

    void onClearAllTapped() => emit(state + const ShowClearConfirmDialog());

    Future<void> onClearConfirmed() async {
      await _repository.clearGames();
      emit(state.copyWith(scores: []));
    }
  }
  ```

- [ ] **Step 4: Create `scores_strings.dart`**

  ```dart
  // lib/features/scores/resources/scores_strings.dart
  abstract class ScoresStrings {
    static const title = 'Scores';
    static const clearAll = 'Clear All';
    static const clearConfirmTitle = 'Clear All Scores';
    static const clearConfirmContent =
        'This will delete all game history. Continue?';
    static const cancel = 'Cancel';
    static const clear = 'Clear';
    static const empty = 'No games recorded yet.';
    static const round = 'Round';
  }
  ```

- [ ] **Step 5: Create `score_card_widget.dart`**

  ```dart
  // lib/features/scores/widgets/score_card_widget.dart
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import '../../../domain/models/game_score.dart';
  import '../resources/scores_strings.dart';

  class ScoreCardWidget extends StatelessWidget {
    final GameScore score;

    const ScoreCardWidget({super.key, required this.score});

    String _pts(int? v) => v?.toString() ?? '—';

    @override
    Widget build(BuildContext context) {
      final dateStr =
          DateFormat('MMM d, yyyy  HH:mm').format(score.date);
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      score.firstPlayer,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Text('vs'),
                  Expanded(
                    child: Text(
                      score.secondPlayer,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Winner: ${score.winner}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Table(
                children: [
                  TableRow(children: [
                    _HeaderCell(ScoresStrings.round),
                    _HeaderCell(score.firstPlayer),
                    _HeaderCell(score.secondPlayer),
                  ]),
                  TableRow(children: [
                    const _Cell('1'),
                    _Cell(_pts(score.firstRoundFirstPlayerPoints)),
                    _Cell(_pts(score.firstRoundSecondPlayerPoints)),
                  ]),
                  TableRow(children: [
                    const _Cell('2'),
                    _Cell(_pts(score.secondRoundFirstPlayerPoints)),
                    _Cell(_pts(score.secondRoundSecondPlayerPoints)),
                  ]),
                  TableRow(children: [
                    const _Cell('3'),
                    _Cell(_pts(score.thirdRoundFirstPlayerPoints)),
                    _Cell(_pts(score.thirdRoundSecondPlayerPoints)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  class _HeaderCell extends StatelessWidget {
    final String text;

    const _HeaderCell(this.text);

    @override
    Widget build(BuildContext context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        );
  }

  class _Cell extends StatelessWidget {
    final String text;

    const _Cell(this.text);

    @override
    Widget build(BuildContext context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(text,
              style: Theme.of(context).textTheme.bodyMedium),
        );
  }
  ```

- [ ] **Step 6: Create `scores_page.dart`**

  ```dart
  // lib/features/scores/view/scores_page.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../../data/gwent_repository.dart';
  import '../cubit/scores_cubit.dart';
  import 'scores_view.dart';

  class ScoresPage extends StatelessWidget {
    const ScoresPage({super.key});

    @override
    Widget build(BuildContext context) => BlocProvider(
          create: (_) => ScoresCubit(repository: context.read<GwentRepository>()),
          child: const ScoresView(),
        );
  }
  ```

- [ ] **Step 7: Create `scores_view.dart`**

  ```dart
  // lib/features/scores/view/scores_view.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../../arch/bloc_side_effect_handler.dart';
  import '../cubit/scores_cubit.dart';
  import '../cubit/scores_side_effect.dart';
  import '../cubit/scores_state.dart';
  import '../resources/scores_strings.dart';
  import '../widgets/score_card_widget.dart';

  class ScoresView extends StatelessWidget {
    const ScoresView({super.key});

    @override
    Widget build(BuildContext context) =>
        BlocSideEffectHandler<ScoresCubit, ScoresState, ScoresSideEffect>(
          listener: (context, sideEffect) {
            switch (sideEffect) {
              case ShowClearConfirmDialog():
                showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title:
                        const Text(ScoresStrings.clearConfirmTitle),
                    content: const Text(
                        ScoresStrings.clearConfirmContent),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false),
                        child: const Text(ScoresStrings.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true),
                        child: const Text(ScoresStrings.clear),
                      ),
                    ],
                  ),
                ).then((confirmed) {
                  if (confirmed == true) {
                    context.read<ScoresCubit>().onClearConfirmed();
                  }
                });
            }
          },
          child: BlocBuilder<ScoresCubit, ScoresState>(
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: const Text(ScoresStrings.title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: ScoresStrings.clearAll,
                    onPressed:
                        context.read<ScoresCubit>().onClearAllTapped,
                  ),
                ],
              ),
              body: switch (state) {
                ScoresState(isLoading: true) =>
                  const Center(child: CircularProgressIndicator()),
                ScoresState(errorMessage: final msg)
                    when msg != null =>
                  Center(child: Text('Error: $msg')),
                ScoresState(scores: final scores)
                    when scores.isEmpty =>
                  const Center(
                      child: Text(ScoresStrings.empty)),
                ScoresState(scores: final scores) =>
                  ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, index) =>
                        ScoreCardWidget(score: scores[index]),
                  ),
              },
            ),
          ),
        );
  }
  ```

- [ ] **Step 8: Run analyze on scores feature**

  ```bash
  flutter analyze lib/features/scores/
  ```

  Expected: No issues.

- [ ] **Step 9: Commit**

  ```bash
  git add lib/features/scores/
  git commit -m "feat(scores): add ScoresCubit, ScoresState, ScoresPage, ScoresView, ScoreCardWidget"
  ```

---

## Task 5: Game feature — cubit layer

The game cubit replaces both `GameNotifier` and `GameState`. The `_saved` flag and all mutation logic move here. Dialogs are triggered via side effects.

**Files:**
- Create: `lib/features/game/cubit/game_side_effect.dart`
- Create: `lib/features/game/cubit/game_state.dart`
- Create: `lib/features/game/cubit/game_cubit.dart`

- [ ] **Step 1: Create `game_side_effect.dart`**

  ```dart
  // lib/features/game/cubit/game_side_effect.dart
  import 'package:equatable/equatable.dart';
  import '../../../arch/side_effect.dart';
  import '../../../domain/models/card.dart';
  import '../../../domain/models/cards_row.dart';
  import '../../../domain/models/cards_row_type.dart';
  import '../../../domain/models/winner.dart';

  sealed class GameSideEffect extends Equatable implements SideEffect {
    const GameSideEffect();

    @override
    List<Object?> get props => [];
  }

  class ShowAddCardDialog extends GameSideEffect {
    final CardsRowType rowType;

    const ShowAddCardDialog(this.rowType);

    @override
    List<Object?> get props => [rowType];
  }

  class ShowEditCardDialog extends GameSideEffect {
    final CardsRow row;
    final Card card;

    const ShowEditCardDialog(this.row, this.card);

    @override
    List<Object?> get props => [row, card];
  }

  class ShowGameOverDialog extends GameSideEffect {
    final Winner winner;

    const ShowGameOverDialog(this.winner);

    @override
    List<Object?> get props => [winner];
  }

  class NavigateBack extends GameSideEffect {
    const NavigateBack();
  }
  ```

- [ ] **Step 2: Create `game_state.dart`**

  ```dart
  // lib/features/game/cubit/game_state.dart
  import 'package:equatable/equatable.dart';
  import '../../../arch/side_effect.dart';
  import '../../../domain/models/game_data.dart';
  import '../../../domain/models/player_data.dart';
  import '../../../domain/models/rounds_data.dart';
  import '../../../domain/models/winner.dart';
  import 'game_side_effect.dart';

  enum SelectedPlayer { first, second }

  final class GameState extends Equatable
      with WithSideEffects<GameState, GameSideEffect> {
    final GameData gameData;
    final SelectedPlayer selectedPlayer;
    final Winner? gameOver;
    final int roundCounter;
    final RoundsData roundsData;

    @override
    final List<GameSideEffect> sideEffects;

    const GameState({
      required this.gameData,
      this.selectedPlayer = SelectedPlayer.first,
      this.gameOver,
      this.roundCounter = 0,
      this.roundsData = const RoundsData(),
      this.sideEffects = const [],
    });

    PlayerData get selectedPlayerData =>
        selectedPlayer == SelectedPlayer.first
            ? gameData.firstPlayerData
            : gameData.secondPlayerData;

    GameState copyWith({
      GameData? gameData,
      SelectedPlayer? selectedPlayer,
      Winner? gameOver,
      bool clearGameOver = false,
      int? roundCounter,
      RoundsData? roundsData,
      List<GameSideEffect>? sideEffects,
    }) =>
        GameState(
          gameData: gameData ?? this.gameData,
          selectedPlayer: selectedPlayer ?? this.selectedPlayer,
          gameOver:
              clearGameOver ? null : (gameOver ?? this.gameOver),
          roundCounter: roundCounter ?? this.roundCounter,
          roundsData: roundsData ?? this.roundsData,
          sideEffects: sideEffects ?? this.sideEffects,
        );

    @override
    GameState withSideEffects(List<GameSideEffect> sideEffects) =>
        copyWith(sideEffects: sideEffects);

    @override
    List<Object?> get props => [
          gameData,
          selectedPlayer,
          gameOver,
          roundCounter,
          roundsData,
          sideEffects,
        ];
  }
  ```

- [ ] **Step 3: Create `game_cubit.dart`**

  ```dart
  // lib/features/game/cubit/game_cubit.dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../../data/gwent_repository.dart';
  import '../../../domain/models/card.dart';
  import '../../../domain/models/cards_row.dart';
  import '../../../domain/models/cards_row_type.dart';
  import '../../../domain/models/game_data.dart';
  import '../../../domain/models/game_score.dart';
  import '../../../domain/models/player_data.dart';
  import '../../../domain/models/winner.dart';
  import 'game_side_effect.dart';
  import 'game_state.dart';

  class GameCubit extends Cubit<GameState> {
    final GwentRepository _repository;
    bool _saved = false;

    GameCubit({
      required String player1Name,
      required String player2Name,
      required GwentRepository repository,
    })  : _repository = repository,
          super(
            GameState(
              gameData: GameData(
                firstPlayerData: PlayerData(name: player1Name),
                secondPlayerData: PlayerData(name: player2Name),
              ),
            ),
          );

    void onPlayerSelected(SelectedPlayer player) =>
        emit(state.copyWith(selectedPlayer: player));

    void onAddCardRequested(CardsRowType rowType) =>
        emit(state + ShowAddCardDialog(rowType));

    void onCardAdded(CardsRowType rowType, Card card) {
      final updated = _updateSelectedPlayer((p) {
        final row = p.cardsRows[rowType]!;
        return p.copyWith(
          cardsRows: {
            ...p.cardsRows,
            rowType: row.copyWith(cards: [...row.cards, card]),
          },
        );
      });
      emit(state.copyWith(gameData: updated));
    }

    void onEditCardRequested(CardsRow row, Card card) =>
        emit(state + ShowEditCardDialog(row, card));

    void onCardEdited(CardsRowType rowType, Card card) {
      final updated = _updateSelectedPlayer((p) {
        final row = p.cardsRows[rowType]!;
        final newCards = row.cards
            .map((c) => c.cardId == card.cardId ? card : c)
            .toList();
        return p.copyWith(
          cardsRows: {
            ...p.cardsRows,
            rowType: row.copyWith(cards: newCards),
          },
        );
      });
      emit(state.copyWith(gameData: updated));
    }

    void onCardDeleted(CardsRowType rowType, Card card) {
      final updated = _updateSelectedPlayer((p) {
        final row = p.cardsRows[rowType]!;
        return p.copyWith(
          cardsRows: {
            ...p.cardsRows,
            rowType: row.copyWith(
              cards: row.cards
                  .where((c) => c.cardId != card.cardId)
                  .toList(),
            ),
          },
        );
      });
      emit(state.copyWith(gameData: updated));
    }

    void onHornChanged(CardsRowType rowType, bool value) {
      final updated = _updateSelectedPlayer((p) {
        final row = p.cardsRows[rowType]!;
        return p.copyWith(
          cardsRows: {
            ...p.cardsRows,
            rowType: row.copyWith(horn: value),
          },
        );
      });
      emit(state.copyWith(gameData: updated));
    }

    void onWeatherChanged(CardsRowType rowType, bool value) {
      var data = state.gameData;
      for (final player in SelectedPlayer.values) {
        final p = player == SelectedPlayer.first
            ? data.firstPlayerData
            : data.secondPlayerData;
        final row = p.cardsRows[rowType]!;
        final updated = p.copyWith(
          cardsRows: {
            ...p.cardsRows,
            rowType: row.copyWith(badWeather: value),
          },
        );
        data = player == SelectedPlayer.first
            ? data.copyWith(firstPlayerData: updated)
            : data.copyWith(secondPlayerData: updated);
      }
      emit(state.copyWith(gameData: data));
    }

    void onEndRoundTapped() {
      if (state.gameOver != null) return;
      var data = state.gameData;
      final roundCounter = state.roundCounter + 1;
      final roundsData = state.roundsData.withRound(
        roundCounter,
        data.firstPlayerData.totalPoints,
        data.secondPlayerData.totalPoints,
      );

      switch (data.winner) {
        case Winner.first:
          data =
              data.copyWith(secondPlayerData: data.secondPlayerData.minusLife());
        case Winner.second:
          data =
              data.copyWith(firstPlayerData: data.firstPlayerData.minusLife());
        case Winner.tie:
          data = data.copyWith(
            firstPlayerData: data.firstPlayerData.minusLife(),
            secondPlayerData: data.secondPlayerData.minusLife(),
          );
      }

      final p1Dead = data.firstPlayerData.lives == 0;
      final p2Dead = data.secondPlayerData.lives == 0;

      if (p1Dead || p2Dead) {
        final gameOver = (p1Dead && p2Dead)
            ? Winner.tie
            : p1Dead
                ? Winner.second
                : Winner.first;
        emit(state.copyWith(
          gameData: data,
          roundCounter: roundCounter,
          roundsData: roundsData,
          gameOver: gameOver,
        ) + ShowGameOverDialog(gameOver));
      } else {
        data = data.copyWith(
          firstPlayerData: data.firstPlayerData.clearCards(),
          secondPlayerData: data.secondPlayerData.clearCards(),
        );
        emit(state.copyWith(
          gameData: data,
          roundCounter: roundCounter,
          roundsData: roundsData,
        ));
      }
    }

    Future<void> onGameOverConfirmed() async {
      final data = state.gameData;
      final rounds = state.roundsData;
      final gameOver = state.gameOver;
      if (gameOver == null || _saved) return;
      _saved = true;

      final score = GameScore(
        date: DateTime.now(),
        firstPlayer: data.firstPlayerData.name,
        secondPlayer: data.secondPlayerData.name,
        winner: gameOver.name,
        firstRoundFirstPlayerPoints: rounds.firstRoundFirst,
        secondRoundFirstPlayerPoints: rounds.secondRoundFirst,
        thirdRoundFirstPlayerPoints: rounds.thirdRoundFirst,
        firstRoundSecondPlayerPoints: rounds.firstRoundSecond,
        secondRoundSecondPlayerPoints: rounds.secondRoundSecond,
        thirdRoundSecondPlayerPoints: rounds.thirdRoundSecond,
      );
      await _repository.addGame(score);
      emit(state + const NavigateBack());
    }

    GameData _updateSelectedPlayer(
        PlayerData Function(PlayerData) update) {
      final data = state.gameData;
      return state.selectedPlayer == SelectedPlayer.first
          ? data.copyWith(
              firstPlayerData: update(data.firstPlayerData))
          : data.copyWith(
              secondPlayerData: update(data.secondPlayerData));
    }
  }
  ```

- [ ] **Step 4: Run analyze on game cubit**

  ```bash
  flutter analyze lib/features/game/cubit/
  ```

  Expected: No issues.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/game/cubit/
  git commit -m "feat(game): add GameCubit, GameState, GameSideEffect"
  ```

---

## Task 6: Game feature — widgets and dialogs

Move and update the game-specific widgets and dialogs to `lib/features/game/widgets/`. Imports change from `../../domain/` to `../../../domain/` etc.

**Files:**
- Create: `lib/features/game/widgets/card_chip.dart`
- Create: `lib/features/game/widgets/user_widget.dart`
- Create: `lib/features/game/widgets/weather_widget.dart`
- Create: `lib/features/game/widgets/cards_row_widget.dart`
- Create: `lib/features/game/widgets/add_card_dialog.dart`
- Create: `lib/features/game/widgets/edit_card_dialog.dart`
- Create: `lib/features/game/resources/game_strings.dart`

- [ ] **Step 1: Create `game_strings.dart`**

  ```dart
  // lib/features/game/resources/game_strings.dart
  abstract class GameStrings {
    static const endRound = 'END ROUND';
    static const gameOverTitle = 'Game Over';
    static const ok = 'OK';
    static const addCardTitle = 'Add Card';
    static const editCardTitle = 'Edit Card';
    static const points = 'Points:';
    static const abilities = 'Abilities:';
    static const cancel = 'CANCEL';
    static const add = 'ADD';
    static const save = 'SAVE';
    static const delete = 'DELETE';
    static const horn = 'Horn';
  }
  ```

- [ ] **Step 2: Create `card_chip.dart`** (read `lib/ui/widgets/card_chip.dart` first, then copy with updated imports)

  Read the existing file:
  ```
  lib/ui/widgets/card_chip.dart
  ```

  Create `lib/features/game/widgets/card_chip.dart` with the same content but fix the import path:
  - Change `'../../domain/models/card.dart'` → `'../../../domain/models/card.dart'`
  - Change `'../../domain/models/ability.dart'` → `'../../../domain/models/ability.dart'`

- [ ] **Step 3: Create `user_widget.dart`**

  Same content as `lib/ui/widgets/user_widget.dart` — no import path changes needed (no domain imports).

  ```dart
  // lib/features/game/widgets/user_widget.dart
  import 'dart:io';
  import 'package:flutter/material.dart';

  class UserWidget extends StatelessWidget {
    final String name;
    final int totalPoints;
    final int lives;
    final String? photoPath;
    final bool isSelected;
    final bool isWinning;
    final VoidCallback onTap;

    const UserWidget({
      super.key,
      required this.name,
      required this.totalPoints,
      required this.lives,
      required this.isSelected,
      required this.isWinning,
      required this.onTap,
      this.photoPath,
    });

    @override
    Widget build(BuildContext context) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: photoPath != null
                      ? FileImage(File(photoPath!))
                      : null,
                  child: photoPath == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(name,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '$totalPoints',
                  style: TextStyle(
                    fontSize: 20,
                    color: isWinning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    2,
                    (i) => Icon(
                      Icons.favorite,
                      size: 16,
                      color: i < lives ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
  ```

- [ ] **Step 4: Create `weather_widget.dart`** (read `lib/ui/widgets/weather_widget.dart`, copy with corrected import path if any)

  Read existing: `lib/ui/widgets/weather_widget.dart`

  Create `lib/features/game/widgets/weather_widget.dart` with same content, updating any import from `../../domain/` to `../../../domain/`.

- [ ] **Step 5: Create `cards_row_widget.dart`**

  ```dart
  // lib/features/game/widgets/cards_row_widget.dart
  import 'package:flutter/material.dart' hide Card;
  import '../../../domain/models/card.dart';
  import '../../../domain/models/cards_row.dart';
  import '../../../domain/models/cards_row_type.dart';
  import 'card_chip.dart';
  import '../resources/game_strings.dart';

  class CardsRowWidget extends StatelessWidget {
    final CardsRow row;
    final void Function(CardsRowType) onAddCard;
    final void Function(CardsRow, Card) onCardLongPress;
    final void Function(CardsRowType, bool) onHornChanged;

    const CardsRowWidget({
      super.key,
      required this.row,
      required this.onAddCard,
      required this.onCardLongPress,
      required this.onHornChanged,
    });

    @override
    Widget build(BuildContext context) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  children: [
                    Text(row.type.displayName,
                        style: const TextStyle(fontSize: 10)),
                    Text(
                      '${row.totalPoints}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(GameStrings.horn,
                            style: TextStyle(fontSize: 10)),
                        Checkbox(
                          value: row.horn,
                          onChanged: (v) =>
                              onHornChanged(row.type, v ?? false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...row.cards.map(
                        (card) => CardChip(
                          card: card,
                          displayPoints: row.pointsOf(card),
                          onLongPress: () => onCardLongPress(row, card),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => onAddCard(row.type),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }
  ```

- [ ] **Step 6: Create `add_card_dialog.dart`**

  ```dart
  // lib/features/game/widgets/add_card_dialog.dart
  import 'package:flutter/material.dart' hide Card;
  import '../../../domain/models/ability.dart';
  import '../../../domain/models/card.dart';
  import '../../../domain/models/cards_row_type.dart';
  import '../resources/game_strings.dart';

  class AddCardDialog extends StatefulWidget {
    final CardsRowType rowType;

    const AddCardDialog({super.key, required this.rowType});

    @override
    State<AddCardDialog> createState() => _AddCardDialogState();
  }

  class _AddCardDialogState extends State<AddCardDialog> {
    int _points = 0;
    final List<Ability> _selectedAbilities = [];

    @override
    Widget build(BuildContext context) => AlertDialog(
          title: Text(
              '${GameStrings.addCardTitle} (${widget.rowType.displayName})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(GameStrings.points),
                    Expanded(
                      child: Slider(
                        value: _points.toDouble(),
                        min: 0,
                        max: 15,
                        divisions: 15,
                        label: '$_points',
                        onChanged: (v) =>
                            setState(() => _points = v.round()),
                      ),
                    ),
                    Text('$_points'),
                  ],
                ),
                const Divider(),
                const Text(GameStrings.abilities),
                ...Ability.values.map(
                  (ability) => CheckboxListTile(
                    title: Text(ability.displayName),
                    value: _selectedAbilities.contains(ability),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedAbilities.add(ability);
                      } else {
                        _selectedAbilities.remove(ability);
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(GameStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                Card(
                  points: _points,
                  abilities: List.from(_selectedAbilities),
                ),
              ),
              child: const Text(GameStrings.add),
            ),
          ],
        );
  }
  ```

- [ ] **Step 7: Create `edit_card_dialog.dart`**

  `EditCardResult` sealed class stays here — it's only used by game feature.

  ```dart
  // lib/features/game/widgets/edit_card_dialog.dart
  import 'package:flutter/material.dart' hide Card;
  import '../../../domain/models/ability.dart';
  import '../../../domain/models/card.dart';
  import '../resources/game_strings.dart';

  sealed class EditCardResult {}

  class EditCardSave extends EditCardResult {
    final Card card;
    EditCardSave(this.card);
  }

  class EditCardDelete extends EditCardResult {}

  class EditCardDialog extends StatefulWidget {
    final Card card;

    const EditCardDialog({super.key, required this.card});

    @override
    State<EditCardDialog> createState() => _EditCardDialogState();
  }

  class _EditCardDialogState extends State<EditCardDialog> {
    late int _points;
    late List<Ability> _selectedAbilities;

    @override
    void initState() {
      super.initState();
      _points = widget.card.points;
      _selectedAbilities = List.from(widget.card.abilities);
    }

    @override
    Widget build(BuildContext context) => AlertDialog(
          title: const Text(GameStrings.editCardTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(GameStrings.points),
                    Expanded(
                      child: Slider(
                        value: _points.toDouble(),
                        min: 0,
                        max: 15,
                        divisions: 15,
                        label: '$_points',
                        onChanged: (v) =>
                            setState(() => _points = v.round()),
                      ),
                    ),
                    Text('$_points'),
                  ],
                ),
                const Divider(),
                const Text(GameStrings.abilities),
                ...Ability.values.map(
                  (ability) => CheckboxListTile(
                    title: Text(ability.displayName),
                    value: _selectedAbilities.contains(ability),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedAbilities.add(ability);
                      } else {
                        _selectedAbilities.remove(ability);
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(EditCardDelete()),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red),
              child: const Text(GameStrings.delete),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(GameStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                EditCardSave(
                  widget.card.copyWith(
                    points: _points,
                    abilities: List.from(_selectedAbilities),
                  ),
                ),
              ),
              child: const Text(GameStrings.save),
            ),
          ],
        );
  }
  ```

- [ ] **Step 8: Run analyze on game widgets**

  ```bash
  flutter analyze lib/features/game/widgets/ lib/features/game/resources/
  ```

  Expected: No issues.

- [ ] **Step 9: Commit**

  ```bash
  git add lib/features/game/widgets/ lib/features/game/resources/
  git commit -m "feat(game): add game widgets, dialogs, GameStrings"
  ```

---

## Task 7: Game feature — view layer

**Files:**
- Create: `lib/features/game/view/game_page.dart`
- Create: `lib/features/game/view/game_view.dart`

- [ ] **Step 1: Create `game_page.dart`**

  ```dart
  // lib/features/game/view/game_page.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import '../../../data/gwent_repository.dart';
  import '../cubit/game_cubit.dart';
  import 'game_view.dart';

  class GamePage extends StatelessWidget {
    final String player1Name;
    final String player2Name;
    final String? player1PhotoPath;
    final String? player2PhotoPath;

    const GamePage({
      super.key,
      required this.player1Name,
      required this.player2Name,
      this.player1PhotoPath,
      this.player2PhotoPath,
    });

    @override
    Widget build(BuildContext context) => BlocProvider(
          create: (_) => GameCubit(
            player1Name: player1Name,
            player2Name: player2Name,
            repository: context.read<GwentRepository>(),
          ),
          child: GameView(
            player1PhotoPath: player1PhotoPath,
            player2PhotoPath: player2PhotoPath,
          ),
        );
  }
  ```

- [ ] **Step 2: Create `game_view.dart`**

  ```dart
  // lib/features/game/view/game_view.dart
  import 'package:flutter/material.dart' hide Card;
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';
  import '../../../arch/bloc_side_effect_handler.dart';
  import '../../../domain/models/card.dart';
  import '../../../domain/models/cards_row_type.dart';
  import '../../../domain/models/winner.dart';
  import '../cubit/game_cubit.dart';
  import '../cubit/game_side_effect.dart';
  import '../cubit/game_state.dart';
  import '../resources/game_strings.dart';
  import '../widgets/add_card_dialog.dart';
  import '../widgets/cards_row_widget.dart';
  import '../widgets/edit_card_dialog.dart';
  import '../widgets/user_widget.dart';
  import '../widgets/weather_widget.dart';

  class GameView extends StatelessWidget {
    final String? player1PhotoPath;
    final String? player2PhotoPath;

    const GameView({
      super.key,
      this.player1PhotoPath,
      this.player2PhotoPath,
    });

    String _winnerMessage(BuildContext context, Winner winner) {
      final state = context.read<GameCubit>().state;
      return switch (winner) {
        Winner.first => '${state.gameData.firstPlayerData.name} wins!',
        Winner.second => '${state.gameData.secondPlayerData.name} wins!',
        Winner.tie => "It's a tie!",
      };
    }

    @override
    Widget build(BuildContext context) =>
        BlocSideEffectHandler<GameCubit, GameState, GameSideEffect>(
          listener: (context, sideEffect) {
            switch (sideEffect) {
              case ShowAddCardDialog(:final rowType):
                showDialog<Card>(
                  context: context,
                  builder: (_) => AddCardDialog(rowType: rowType),
                ).then((card) {
                  if (card != null) {
                    context
                        .read<GameCubit>()
                        .onCardAdded(rowType, card);
                  }
                });

              case ShowEditCardDialog(:final row, :final card):
                showDialog<EditCardResult>(
                  context: context,
                  builder: (_) => EditCardDialog(card: card),
                ).then((result) {
                  if (result == null) return;
                  switch (result) {
                    case EditCardSave(:final card):
                      context
                          .read<GameCubit>()
                          .onCardEdited(row.type, card);
                    case EditCardDelete():
                      context
                          .read<GameCubit>()
                          .onCardDeleted(row.type, card);
                  }
                });

              case ShowGameOverDialog(:final winner):
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text(GameStrings.gameOverTitle),
                    content:
                        Text(_winnerMessage(context, winner)),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context
                              .read<GameCubit>()
                              .onGameOverConfirmed();
                        },
                        child: const Text(GameStrings.ok),
                      ),
                    ],
                  ),
                );

              case NavigateBack():
                context.pop();
            }
          },
          child: BlocBuilder<GameCubit, GameState>(
            builder: (context, state) {
              final p1 = state.gameData.firstPlayerData;
              final p2 = state.gameData.secondPlayerData;
              final selectedData = state.selectedPlayerData;
              final cubit = context.read<GameCubit>();

              return Scaffold(
                appBar: AppBar(
                  title: Text('Round ${state.roundCounter + 1}'),
                  actions: [
                    TextButton(
                      onPressed: cubit.onEndRoundTapped,
                      child: const Text(
                        GameStrings.endRound,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: UserWidget(
                            name: p1.name,
                            totalPoints: p1.totalPoints,
                            lives: p1.lives,
                            photoPath: player1PhotoPath,
                            isSelected: state.selectedPlayer ==
                                SelectedPlayer.first,
                            isWinning: p1.totalPoints > p2.totalPoints,
                            onTap: () => cubit.onPlayerSelected(
                                SelectedPlayer.first),
                          ),
                        ),
                        Expanded(
                          child: UserWidget(
                            name: p2.name,
                            totalPoints: p2.totalPoints,
                            lives: p2.lives,
                            photoPath: player2PhotoPath,
                            isSelected: state.selectedPlayer ==
                                SelectedPlayer.second,
                            isWinning: p2.totalPoints > p1.totalPoints,
                            onTap: () => cubit.onPlayerSelected(
                                SelectedPlayer.second),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    WeatherWidget(
                      frostActive: selectedData
                              .cardsRows[CardsRowType.closeCombat]
                              ?.badWeather ??
                          false,
                      fogActive: selectedData
                              .cardsRows[CardsRowType.longRange]
                              ?.badWeather ??
                          false,
                      rainActive: selectedData
                              .cardsRows[CardsRowType.siege]
                              ?.badWeather ??
                          false,
                      onChanged: cubit.onWeatherChanged,
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: CardsRowType.values.map((rowType) {
                          final row =
                              selectedData.cardsRows[rowType]!;
                          return CardsRowWidget(
                            row: row,
                            onAddCard: cubit.onAddCardRequested,
                            onCardLongPress:
                                cubit.onEditCardRequested,
                            onHornChanged: cubit.onHornChanged,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
  }
  ```

- [ ] **Step 3: Run analyze on game view files**

  ```bash
  flutter analyze lib/features/game/view/
  ```

  Expected: No issues.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/game/view/
  git commit -m "feat(game): add GamePage, GameView"
  ```

---

## Task 8: Wire up main.dart and router.dart, delete old files

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/router.dart`
- Modify: `test/widget_test.dart`
- Delete: `lib/state/` (entire directory)
- Delete: `lib/ui/` (entire directory)

- [ ] **Step 1: Rewrite `lib/main.dart`**

  ```dart
  // lib/main.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'data/gwent_repository.dart';
  import 'router.dart';

  void main() {
    runApp(const GwentHelperApp());
  }

  class GwentHelperApp extends StatelessWidget {
    const GwentHelperApp({super.key});

    @override
    Widget build(BuildContext context) => RepositoryProvider(
          create: (_) => GwentRepository(),
          child: MaterialApp.router(
            title: 'GwentHelper',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1B2A4A)),
              useMaterial3: true,
            ),
            routerConfig: router,
          ),
        );
  }
  ```

- [ ] **Step 2: Rewrite `lib/router.dart`**

  ```dart
  // lib/router.dart
  import 'package:go_router/go_router.dart';
  import 'features/home/view/home_page.dart';
  import 'features/game/view/game_page.dart';
  import 'features/scores/view/scores_page.dart';

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final extra =
              (state.extra as Map<String, String?>?) ?? {};
          return GamePage(
            player1Name: extra['player1Name'] ?? 'Player 1',
            player2Name: extra['player2Name'] ?? 'Player 2',
            player1PhotoPath: extra['player1PhotoPath'],
            player2PhotoPath: extra['player2PhotoPath'],
          );
        },
      ),
      GoRoute(
        path: '/scores',
        builder: (context, state) => const ScoresPage(),
      ),
    ],
  );
  ```

- [ ] **Step 3: Update `test/widget_test.dart`**

  The test previously wrapped with `ProviderScope`. Now wrap with `RepositoryProvider`:

  ```dart
  // test/widget_test.dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:gwent_helper_flutter/data/gwent_repository.dart';
  import 'package:gwent_helper_flutter/main.dart';

  void main() {
    testWidgets('App smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(
        RepositoryProvider(
          create: (_) => GwentRepository(),
          child: const GwentHelperApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('GwentHelper'), findsOneWidget);
    });
  }
  ```

  Note: `GwentHelperApp` already creates a `RepositoryProvider` internally now (in step 1), so you can also just do:
  ```dart
  await tester.pumpWidget(const GwentHelperApp());
  ```

  Use whichever compiles without error.

- [ ] **Step 4: Run analyze to verify everything wires together**

  ```bash
  flutter analyze
  ```

  Expected: No issues (old files still exist — they will be deleted next).

  If there are errors about unused imports in old files, proceed anyway — deleting them is next.

- [ ] **Step 5: Delete old files**

  ```bash
  git rm -r lib/state/ lib/ui/
  ```

- [ ] **Step 6: Run analyze again — must be clean**

  ```bash
  flutter analyze
  ```

  Expected: No issues.

- [ ] **Step 7: Run tests**

  ```bash
  flutter test
  ```

  Expected: All 11 tests pass (domain tests unchanged, smoke test updated).

- [ ] **Step 8: Commit**

  ```bash
  git add -A
  git commit -m "feat: wire BLoC architecture — update main/router, delete Riverpod state layer"
  ```

---

## Self-Review

### Spec coverage

| Requirement | Covered by |
|---|---|
| Use Cubit for state management | Tasks 2, 4, 5 |
| State + SideEffect per feature | Tasks 2, 4, 5 |
| Sealed SideEffect classes extending Equatable + SideEffect | Tasks 2, 4, 5 |
| `onSomethingHappened` method naming | Tasks 2, 4, 5 |
| No BuildContext in Cubits | Tasks 2, 4, 5 — cubit files have no Flutter imports |
| BlocProvider only in Page widgets | Tasks 3, 4, 7 |
| BlocSideEffectHandler for navigation/dialogs | Tasks 3, 4, 7 |
| Strings in resources/ not hardcoded | Tasks 3, 4, 6 |
| Relative imports within feature, absolute across | All tasks — checked |
| `final` properties, `const` constructors | All state/side-effect classes |
| Remove flutter_riverpod | Task 1 |
| One public widget per file | All widget files |
| Repository provided via RepositoryProvider | Task 8 main.dart |
| Constructor DI into Cubits | Tasks 3 (HomeCubit has none), 4 (ScoresCubit takes repository), 5 (GameCubit takes repository) |

### Placeholder scan

No TBDs, TODOs, or vague steps found.

### Type consistency

- `SelectedPlayer` enum defined in `game_state.dart` and used in `game_view.dart` ✓
- `EditCardResult` / `EditCardSave` / `EditCardDelete` defined in `edit_card_dialog.dart` and used in `game_view.dart` ✓
- `GwentRepository` used consistently as `context.read<GwentRepository>()` in pages ✓
- `BlocSideEffectHandler` generic types match the Cubit/State/SideEffect triple in each view ✓
