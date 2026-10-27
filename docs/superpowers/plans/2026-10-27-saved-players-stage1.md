# Saved Players — Stage 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Players can be saved with a name and a permanent photo and picked again from the home screen, and the home screen keeps the same players after a finished game.

**Architecture:** A new `player` table (schema v3) plus two optional player links on `game_score`; a `PlayerPhotoStore` copies cropped photos into permanent app storage; `GwentRepository` owns all player and photo I/O so cubits never touch `sqflite` or files. `HomeCubit` saves/links players when Play is tapped and writes the resulting ids back into its state; game over returns with `context.pop()` so the existing `HomeCubit` survives.

**Tech Stack:** Flutter, `flutter_bloc` (Cubit + side-effect pattern in `lib/arch/`), `sqflite` (+ `sqflite_common_ffi` in tests), `path_provider`, `uuid`, `equatable`, `go_router`, `bloc_test` + `mocktail`.

**Spec:** `docs/superpowers/specs/2026-10-27-saved-players-design.md` (this plan covers its Stage 1 only; Stage 2 — users page, stats, scoreboard photos — is a separate plan).

## Global Constraints

- Schema `version: 3`. `player(id TEXT PRIMARY KEY, name TEXT NOT NULL, photo_file TEXT, created_at INTEGER NOT NULL)`. `game_score` gains nullable `first_player_id TEXT` and `second_player_id TEXT`. No foreign-key constraints. Upgrade is `CREATE TABLE player` + two `ALTER TABLE game_score ADD COLUMN`; `onCreate` must produce the same final schema.
- `first_player` / `second_player` keep being written on game over as the name snapshot.
- Persist the photo **file name only**, never an absolute path. A new file name (uuid) on every photo change; the previous file is deleted after the swap.
- Name matching is trimmed and case-insensitive **in Dart** (`toLowerCase()`), not SQL — SQLite `LOWER`/`NOCASE` only fold ASCII and would miss Ukrainian/Polish names.
- A blank name (after trim) is a guest: nothing saved, both ids null, existing "Player 1/2" fallback applies.
- Cubits never use `BuildContext`, `sqflite` or the file system. Fallback names are passed in from the view.
- The home screen is blank only on a cold start; nothing is remembered across launches.
- New strings go in all 9 `lib/l10n/app_*.arb` files (en, de, fr, es, it, pt, pl, nl, uk); no Russian.
- Tests: Given/When/Then in the description (multi-line `'''` string with `// Given` `// When` `// Then` comments), member names in backticks, bloc_test + mocktail for cubits, `sqflite_common_ffi` for DB tests. Match existing files in `test/`.
- Do not commit unless the user explicitly asks; each task ends with a suggested commit message only.
- Out of scope here: users page, stats, delete, score-card photos, build-number bump.

## Review Focus

Inputs the spec implies but its feature list doesn't spell out; each has a test in the named task.

1. **Non-ASCII names:** typing `олег` or `łukasz` when `Олег` / `Łukasz` is saved reuses that player, and `  Anna ` matches `anna` — no duplicate player (Task 3, Task 5).
2. **Same name typed on both sides:** both resolve to one player; the second side stays an unlinked guest so one person isn't counted as both players (Task 5).
3. **Saved player selected, then name cleared:** that side plays as a guest and the saved player is left unchanged (Task 5).
4. **Storage failure:** if saving a player or photo throws, Play still starts the match, with null ids for the failed side (Task 5).
5. **Missing photo file** (deleted outside the app, or photo_file set but file gone): selecting the player yields no photo and no crash (Task 1, Task 5).

---

### Task 1: `Player` model and `PlayerPhotoStore`

**Files:**
- Create: `lib/domain/models/player.dart`, `lib/data/player_photo_store.dart`
- Test: `test/domain/player_test.dart`, `test/data/player_photo_store_test.dart`

**Interfaces:**
- Produces:
  - `class Player extends Equatable { Player({String? id, required String name, String? photoFile, DateTime? createdAt}); final String id; final String name; final String? photoFile; final DateTime createdAt; Player copyWith({String? name, String? photoFile}); Map<String, dynamic> toMap(); factory Player.fromMap(Map<String, dynamic> map); }` — `id` defaults to `Uuid().v4()`, `createdAt` to `DateTime.now()`; map keys are `id`, `name`, `photo_file`, `created_at` (epoch millis), matching the schema.
  - `class PlayerPhotoStore { PlayerPhotoStore({Future<Directory> Function()? documentsDirectory}); Future<String> save(String sourcePath); Future<String?> resolve(String fileName); Future<void> delete(String fileName); }` — default directory provider is `getApplicationDocumentsDirectory`; files live in `<documents>/player_photos/`.

- [ ] **Step 1: Write failing tests.** `player_test.dart`: `toMap`/`fromMap` round-trip equals the original (including null `photoFile`); `copyWith(name:)` keeps id and createdAt. `player_photo_store_test.dart` (inject a temp directory): `save` copies the file, returns a name with no path separators that ends `.jpg`, and the copy's bytes equal the source's; two `save` calls of the same source return different names; `resolve` returns `<dir>/player_photos/<name>` for a saved file and `null` for an unknown name (Review Focus 5); `delete` removes the file and does not throw for an unknown name.
- [ ] **Step 2: Run** `flutter test test/domain/player_test.dart test/data/player_photo_store_test.dart` — expect FAIL (files missing).
- [ ] **Step 3: Implement** both classes per the signatures above. `save` creates `player_photos/` if missing and copies (does not move) the source, so the cropper's temp file is untouched.
- [ ] **Step 4: Run** the same command — expect PASS.
- [ ] **Step 5: Suggested commit:** `Add Player model and PlayerPhotoStore`

### Task 2: Schema v3, `PlayerDao`, `GameScore` player links

**Files:**
- Modify: `lib/data/database.dart` (version 3, `onCreate`, `onUpgrade`), `lib/domain/models/game_score.dart`, `docs/architecture.md` (schema v3 + new data classes)
- Create: `lib/data/player_dao.dart`
- Test: `test/data/database_migration_test.dart` (extend), `test/data/player_dao_test.dart`, `test/domain/game_score_test.dart` (extend)

**Interfaces:**
- Consumes: `Player` (Task 1).
- Produces:
  - `GameScore({..., String? firstPlayerId, String? secondPlayerId})` with fields `firstPlayerId` / `secondPlayerId`; `toMap` writes `first_player_id` / `second_player_id`; `fromMap` reads them as `String?` (absent key → null).
  - `class PlayerDao { Future<void> insert(Player p); Future<void> update(Player p); Future<List<Player>> getAll(); Future<Player?> findByName(String name); }` — `getAll` sorts by `name.toLowerCase()` in Dart; `findByName` compares `trim().toLowerCase()` of both sides in Dart and returns the first match.

- [ ] **Step 1: Write failing tests.**
  - Migration (follow the existing v1→v2 test pattern, seeding a **v2** database with `game_score` rows, then opening via `AppDatabase.instance`): the `player` table exists and is empty; the seeded games survive with `first_player_id` and `second_player_id` null; a game inserted afterwards with ids round-trips through `GameScoreDao`. Also a fresh database (no file) has both the `player` table and the two columns (`onCreate`).
  - A **v1** database (no `id`, no player tables) opened via `AppDatabase.instance` upgrades through v2 to v3 in one step: rows survive with legacy ids, the `player` table exists, and `first_player_id` / `second_player_id` exist and are null. (Guards against adding the new columns twice.)
  - `PlayerDao`: insert then `getAll` returns it; `update` changes name and `photoFile`; `getAll` order is case-insensitive for `Łukasz`, `anna`, `Олег`; `findByName('олег')` finds `Олег`, `findByName('  łukasz ')` finds `Łukasz`, and an unknown name returns null (Review Focus 1).
  - `GameScore`: `toMap`/`fromMap` round-trip keeps both ids, and `fromMap` of a map without the id keys gives null ids.
- [ ] **Step 2: Run** `flutter test test/data test/domain/game_score_test.dart` — expect FAIL.
- [ ] **Step 3: Implement.** `database.dart`: bump to 3. Leave `_tableColumns` as the v2 column list, because the v1→v2 step rebuilds `game_score` from it and must not already contain the new columns (a later `ALTER` would then fail as a duplicate). `onCreate` creates `game_score` from `_tableColumns` plus `first_player_id TEXT, second_player_id TEXT`, and creates `player`. Add an `if (oldVersion < 3)` block after the v2 block doing `CREATE TABLE player (...)` and two `ALTER TABLE game_score ADD COLUMN`. Implement `PlayerDao` and the `GameScore` fields. Update `docs/architecture.md`'s schema paragraph.
- [ ] **Step 4: Run** `flutter test test/data test/domain` — expect PASS (existing v1→v2 migration test still green).
- [ ] **Step 5: Suggested commit:** `Add player table (schema v3) and player links on game_score`

### Task 3: `GwentRepository` player API

**Files:**
- Modify: `lib/data/gwent_repository.dart`
- Test: `test/data/gwent_repository_players_test.dart`

**Interfaces:**
- Consumes: `PlayerDao`, `PlayerPhotoStore`, `Player`.
- Produces on `GwentRepository` (constructor becomes `GwentRepository({GameScoreDao? dao, PlayerDao? playerDao, PlayerPhotoStore? photoStore})`, all defaulting to real instances):
  - `Future<List<Player>> getPlayers()`
  - `Future<Player?> findPlayerByName(String name)`
  - `Future<Player> createPlayer({required String name, String? photoTempPath})` — stores `name.trim()`; copies the photo (if given) before inserting; if the insert fails, deletes the copied file and rethrows.
  - `Future<Player> updatePlayer(Player player, {String? name, String? photoTempPath})` — saves the new photo (if given), updates the row, then deletes the previous photo file only after the update succeeded; returns the updated `Player`.
  - `Future<String?> photoPathOf(Player player)` — absolute path via `PlayerPhotoStore.resolve`, null when `photoFile` is null or the file is missing.

- [ ] **Step 1: Write failing tests** (ffi database + temp-directory `PlayerPhotoStore`, like the migration test setup): `createPlayer` trims the name and a created player appears in `getPlayers` with a `photoFile` whose file exists; `createPlayer` with no photo leaves `photoFile` null; `updatePlayer(name:)` renames and keeps the photo; `updatePlayer(photoTempPath:)` gives a new `photoFile`, the new file exists and the old file is gone; `photoPathOf` returns null after the file is deleted on disk (Review Focus 5); `findPlayerByName('ŁUKASZ')` finds `Łukasz` (Review Focus 1); a failing `PlayerDao.insert` (stub dao throwing) leaves no orphan file in `player_photos/`.
- [ ] **Step 2: Run** `flutter test test/data/gwent_repository_players_test.dart` — expect FAIL.
- [ ] **Step 3: Implement** the methods above. Existing `addGame`/`getGames`/`clearGames` unchanged.
- [ ] **Step 4: Run** `flutter test test/data` — expect PASS.
- [ ] **Step 5: Suggested commit:** `Add player create/update/lookup to GwentRepository`

### Task 4: Game flow carries player ids; game over returns to the same home screen

**Files:**
- Modify: `lib/features/game/cubit/game_cubit.dart`, `lib/features/game/view/game_page.dart`, `lib/features/game/view/game_view.dart` (the `NavigateBack` case, currently `context.go('/')`), `lib/router.dart`
- Test: `test/features/game/game_cubit_test.dart` (extend), `test/features/home/rematch_flow_test.dart` (new)

**Interfaces:**
- Consumes: `GameScore.firstPlayerId/secondPlayerId` (Task 2).
- Produces:
  - `GameCubit({required String player1Name, required String player2Name, String? player1Id, String? player2Id, required GwentRepository repository})`; `onGameOverConfirmed` writes the ids into the saved `GameScore` next to the name snapshot.
  - `GamePage({..., String? player1Id, String? player2Id})`; the `/game` route reads `extra['player1Id'] as String?` and `extra['player2Id'] as String?` (missing key → null).
  - On `NavigateBack`, `GameView` calls `context.pop()`.

- [ ] **Step 1: Write failing tests.**
  - `game_cubit_test.dart`: given a cubit built with ids `'p1'`/`'p2'`, when game over is confirmed, the `GameScore` passed to `repository.addGame` has `firstPlayerId == 'p1'` and `secondPlayerId == 'p2'`; with no ids both are null (reuse the file's existing game-over setup and `MockGwentRepository`).
  - `rematch_flow_test.dart`: build a `GoRouter` with `/` → `HomePage` and `/game` → `BlocProvider<GameCubit>.value(value: cubit, child: const GameView())`, where `cubit` is a `GameCubit` created in the test (as `game_view_test.dart` does) with a `MockGwentRepository` whose `addGame` completes; wrap in `RepositoryProvider<GwentRepository>.value(repository)` and `MaterialApp.router` with `AppTheme.data` and the localization delegates, 2400×1080 view. Given names `Anna` and `Bea` typed on the home screen and Play tapped, when the test drives `cubit` to game over (`onCardAdded` / `onEndRoundTapped` calls as in `playToGameOver` in `game_cubit_test.dart`) and taps the game-over dialog's `OK`, then the home screen is shown again and both text fields still contain `Anna` and `Bea`. No existing widget test reaches game over, so confirm the dialog appears before relying on it.
- [ ] **Step 2: Run** `flutter test test/features/game/game_cubit_test.dart test/features/home/rematch_flow_test.dart` — expect FAIL.
- [ ] **Step 3: Implement** the interface changes. This also fixes the current bug that a finished game wipes the home screen: with `pop()` the original `HomePage` (and its `HomeCubit` and text controllers) is still in the stack beneath `/game`.
- [ ] **Step 4: Run** `flutter test test/features/game test/features/home/rematch_flow_test.dart` — expect PASS.
- [ ] **Step 5: Suggested commit:** `Return to the same home screen after a finished game; pass player ids to games`

### Task 5: `HomeCubit` — saved-player selection and save-on-Play

**Files:**
- Modify: `lib/features/home/cubit/home_cubit.dart`, `home_state.dart`, `home_side_effect.dart`
- Test: `test/features/home/home_cubit_test.dart` (rewrite the setup and the `onPlayTapped` group)

**Interfaces:**
- Consumes: `GwentRepository` player API (Task 3), `Player`.
- Produces:
  - `HomeCubit({required GwentRepository repository})`.
  - `HomeState` gains `String? player1Id`, `String? player2Id`, `bool player1PhotoChanged`, `bool player2PhotoChanged` (default false). `copyWith` gains `bool clearPlayer1 = false` / `bool clearPlayer2 = false`, which reset that side's id, photo path and changed flag (the existing `??` copyWith cannot clear nullable fields). `onPlayerNPhotoPicked(path)` also sets that side's `PhotoChanged` to true.
  - `class SavedPlayerOption extends Equatable { final Player player; final String? photoPath; }` and side effect `ShowSavedPlayers(bool isPlayer1, List<SavedPlayerOption> options)` (in `home_side_effect.dart`). `NavigateToGame` gains `String? player1Id, String? player2Id` (included in `props`).
  - `Future<void> onSavedPlayersRequested({required bool isPlayer1})` — loads players, resolves each `photoPathOf`, excludes the player currently selected on the *other* side, emits `ShowSavedPlayers`; on a repository failure emits `ShowSavedPlayers` with an empty list.
  - `Future<void> onSavedPlayerSelected({required bool isPlayer1, required Player player})` — sets that side's id, name and resolved photo path, `PhotoChanged` false.
  - `void onNewPlayerSelected({required bool isPlayer1})` — clears that side (id, name `''`, photo, flag).
  - `Future<void> onPlayTapped({required String player1Fallback, required String player2Fallback})` — resolves each side as below, then emits the resolved state plus `NavigateToGame`.

  **Per-side resolution on Play** (name = typed name trimmed):
  - blank name → guest: id null, nothing saved (Review Focus 3: a previously selected saved player is left untouched).
  - id selected → if the name differs or `PhotoChanged`, `repository.updatePlayer(...)`; id kept.
  - no id → `findPlayerByName`; if found, link it (and `updatePlayer` with the new photo if `PhotoChanged`), else `createPlayer(name, photoTempPath if PhotoChanged)`.
  - if side 2 resolves to the same id as side 1, side 2 stays a guest (id null, nothing saved) (Review Focus 2).
  - after a successful save, that side's state gets its id, its permanent photo path (`photoPathOf`) and `PhotoChanged` false, so a rematch creates nothing new.
  - any repository exception on a side → that side proceeds as a guest with null id; the match still starts (Review Focus 4).
  - `NavigateToGame` names use the existing fallback rule (`_nameOr`).

- [ ] **Step 1: Write failing tests** (blocTest + a `MockGwentRepository`; stub `photoPathOf` to return a path or null as needed). Cover, each as a Given/When/Then test:
  - initial state has null ids and false flags;
  - `onPlayer1PhotoPicked` sets path and `player1PhotoChanged`;
  - `onSavedPlayersRequested(isPlayer1: true)` emits `ShowSavedPlayers` with options from `getPlayers`, excluding the id selected on side 2;
  - `onSavedPlayerSelected` fills id, name and path from `photoPathOf`, flag false; with `photoPathOf` returning null (missing file) the path is null and nothing throws (Review Focus 5);
  - `onNewPlayerSelected` clears the side;
  - Play with a typed name and no match → `createPlayer` called once, `NavigateToGame` carries the new id, state holds id and permanent photo path with flag false;
  - Play with typed `олег`, saved `Олег` exists → no `createPlayer`, linked to the saved id (stub `findPlayerByName`) (Review Focus 1);
  - Play with a selected saved player whose name was edited → `updatePlayer` called with the new name, id unchanged;
  - Play with a selected saved player and a newly picked photo → `updatePlayer(photoTempPath: ...)`;
  - Play with a selected saved player and nothing changed → neither `createPlayer` nor `updatePlayer` called;
  - Play with blank names → no repository save calls, ids null, fallback names used;
  - selected saved player with name cleared → guest, `updatePlayer` never called (Review Focus 3);
  - both names `Anna` → both sides resolve to the same player; side 2 id is null (Review Focus 2);
  - `createPlayer` throws → `NavigateToGame` still emitted with null id for that side (Review Focus 4);
  - rematch: after a successful Play, a second `onPlayTapped` makes no `createPlayer` / `updatePlayer` calls.
- [ ] **Step 2: Run** `flutter test test/features/home/home_cubit_test.dart` — expect FAIL (compile errors first: constructor signature).
- [ ] **Step 3: Implement** the cubit, state and side-effect changes per the interfaces above.
- [ ] **Step 4: Run** `flutter test test/features/home/home_cubit_test.dart` — expect PASS.
- [ ] **Step 5: Suggested commit:** `Save and reuse players from the home screen cubit`

### Task 6: Home UI — "Saved players" chip, picker sheet, wiring, localization

**Files:**
- Modify: `lib/features/home/widgets/player_input_widget.dart`, `lib/features/home/view/home_view.dart`, `lib/features/home/view/home_page.dart`, `lib/l10n/app_*.arb` (9 files), regenerate with `flutter gen-l10n`
- Test: `test/features/home/home_view_test.dart` (extend; `setUp` builds `HomeCubit(repository: MockGwentRepository())`), `test/widget_test.dart` (update `PlayerInputWidget` constructor calls)

**Interfaces:**
- Consumes: `HomeCubit` methods and `ShowSavedPlayers` (Task 5).
- Produces:
  - `PlayerInputWidget({..., required String savedPlayersLabel, required VoidCallback onChooseSaved})` — a chip in the card header showing `savedPlayersLabel`; tapping it calls `onChooseSaved`. The avatar tap and name field behave as today.
  - `HomeView` handles `ShowSavedPlayers` by showing a modal bottom sheet: one row per option (`HudAvatar` size 44 with `FileImage(File(photoPath))` or placeholder, plus the name) and a final "New player" row. Choosing a row calls `onSavedPlayerSelected` / `onNewPlayerSelected` and sets that side's `TextEditingController.text` to the player's name (or `''`). Dismissing the sheet does nothing. `NavigateToGame` handling adds `'player1Id'` / `'player2Id'` to the `/game` route `extra`.
  - `HomePage` creates `HomeCubit(repository: context.read<GwentRepository>())`.
  - New l10n keys in all 9 ARBs, mirroring how `player1` / `play` entries are written: `savedPlayers` and `newPlayer` — en "Saved players" / "New player"; de "Gespeicherte Spieler" / "Neuer Spieler"; fr "Joueurs enregistrés" / "Nouveau joueur"; es "Jugadores guardados" / "Nuevo jugador"; it "Giocatori salvati" / "Nuovo giocatore"; pt "Jogadores guardados" / "Novo jogador"; pl "Zapisani gracze" / "Nowy gracz"; nl "Opgeslagen spelers" / "Nieuwe speler"; uk "Збережені гравці" / "Новий гравець".

- [ ] **Step 1: Write failing tests** in `home_view_test.dart` (mock repository stubbed with two saved players, one with a photo path that does not exist on disk): tapping a card's "Saved players" chip shows the sheet listing both names and "New player"; tapping a saved player closes the sheet and that side's text field shows the name; tapping "New player" after selecting clears the field; with an empty saved list the sheet shows only "New player"; the missing-photo player renders without throwing (Review Focus 5). Existing avatar-dialog tests keep passing.
- [ ] **Step 2: Run** `flutter test test/features/home test/widget_test.dart test/l10n_test.dart` — expect FAIL.
- [ ] **Step 3: Implement** the widget, view, page and ARB changes; run `flutter gen-l10n`; update the `PlayerInputWidget` calls in `test/widget_test.dart`.
- [ ] **Step 4: Run** `flutter test` (whole suite) and `flutter analyze` — expect all PASS and no analyzer issues.
- [ ] **Step 5: Manual check on an Android emulator** (platform channels don't run in `flutter test`): pick a photo, type a name, Play, finish a game → home shows the same names and photos; fully restart the app → home is blank, the chip's sheet lists the saved player with its photo; select it on a side, rename it, Play → the sheet later shows the new name; blank both names → Play still works and saves nothing. Repeat the restart check on an iOS simulator if available, and test installing over a previous build once with a device build (path stability across updates).
- [ ] **Step 6: Suggested commit:** `Add saved-player picker to the home screen`
