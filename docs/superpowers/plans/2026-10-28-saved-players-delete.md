# Common Saved-Players List and Swipe-to-Delete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Both home-screen sides pick from the same full list of saved players, and a saved player can be removed from that list by swiping its row, without touching past games or their scoreboard cards.

**Architecture:** "Delete" is a soft delete: a nullable `player.deleted_at` column (schema v4). Deleted players disappear from the picker and are ignored when a typed name is matched, but stay readable for the scoreboard so past cards keep their name and photo. Photo files and game links are never touched.

**Tech Stack:** Flutter, `flutter_bloc`, `sqflite` (+ `sqflite_common_ffi` in tests), `flutter_slidable` (new dependency, swipe-to-reveal actions), `mocktail`/`bloc_test`.

**Spec:** `docs/superpowers/specs/2026-10-27-saved-players-design.md` (original saved-players design). This plan changes two of its decisions, agreed with the user on 2026-10-28:
1. The picker no longer hides the player chosen on the other side; picking someone already on the other side empties that other side.
2. Delete is a soft delete from the picker sheet (no separate users page); the spec's "set links to NULL and delete the photo file" is replaced by "keep links and photo, hide the player".

## Global Constraints

- Schema `version: 4`. `player` gains `deleted_at INTEGER` (nullable, epoch millis). The upgrade is one additive `ALTER TABLE player ADD COLUMN deleted_at INTEGER`; `onCreate` must produce the same final schema; v1→v4, v2→v4, v3→v4 and fresh install must all end identical. No foreign keys. No existing row is rewritten.
- Deleting a player NEVER deletes games, never changes `game_score` links, and never deletes the photo file.
- Name matching stays trimmed and case-insensitive in Dart. A deleted player is never matched: typing a deleted player's name creates a NEW player and old games stay linked to the old one.
- The home picker lists every non-deleted player on both sides.
- Deleting a player who is currently chosen on a home side clears that side completely (id, name, photo, photo-changed flag).
- Swipe flow: swipe a row left → red Delete button appears → tap it → confirmation dialog → only its Delete button deletes. A swipe alone or Cancel deletes nothing. The sheet stays open and the row disappears.
- Cubits never use `BuildContext`, `sqflite` or the file system. Repository owns all player I/O.
- New strings go in all 9 `lib/l10n/app_*.arb` files (en, de, fr, es, it, pt, pl, nl, uk), no Russian. Reuse the existing `delete` ("DELETE") and `gameCancel` ("CANCEL") keys.
- Tests: Given/When/Then in the description (multi-line `'''` string with `// Given` `// When` `// Then` comments), member names in backticks, bloc_test + mocktail for cubits, `sqflite_common_ffi` for DB tests with each DB test file using its OWN temporary databases directory.
- Commits go on the feature branch only; no push, no merge.
- Out of scope: users page, per-player stats, un-delete, freeing photo storage, build-number bump.

## Review Focus

1. **Migration safety:** a v3 database with existing players and games upgrades with every row intact and `deleted_at` null; v1/v2/fresh end in the same schema (Task 1).
2. **Past games survive a delete:** after a delete, the player is gone from the picker list but the scoreboard still resolves their name and photo (Tasks 2).
3. **Re-typing a deleted name:** creates a new player, never relinks to the deleted one (Tasks 1, 3).
4. **Deleting a selected player** (from the same sheet or from the other side's sheet) clears that side fully; picking a player already on the other side clears the other side (Task 3).
5. **No accidental delete:** swipe alone, Cancel, and a failed repository delete leave the row and the data unchanged and do not crash (Task 4).

---

### Task 1: Schema v4, `Player.deletedAt`, `PlayerDao`

**Files:**
- Modify: `lib/data/database.dart`, `lib/domain/models/player.dart`, `lib/data/player_dao.dart`, `docs/architecture.md` (schema v4 note)
- Test: `test/data/database_migration_test.dart` (extend), `test/data/player_dao_test.dart` (extend), `test/domain/player_test.dart` (extend)

**Interfaces:**
- Produces:
  - `Player({String? id, required String name, String? photoFile, DateTime? createdAt, DateTime? deletedAt})`; field `final DateTime? deletedAt`; `bool get isDeleted => deletedAt != null`; `toMap` writes `deleted_at` (epoch millis or null); `Player.fromMap` reads `deleted_at as int?`; `copyWith({String? name, String? photoFile, DateTime? deletedAt})`; `props` include `deletedAt`.
  - `PlayerDao.getAll({bool includeDeleted = false})` (default excludes deleted players; still sorted by lowercased name); `PlayerDao.findByName(String name)` ignores deleted players; `Future<void> markDeleted(String id, DateTime deletedAt)` (sets `deleted_at` for that id; unknown id is a no-op).

- [ ] **Step 1: Write failing tests.** Migration (follow the existing pattern; own temp databases directory): a **v3** database seeded with a `player` row and `game_score` rows linked to it upgrades through `AppDatabase.instance` with all rows intact, `deleted_at` null and the column present; a **v1** and a **v2** database also end at v4 with the `deleted_at` column (and the earlier v2/v3 expectations still hold); a fresh database has `deleted_at`; `PRAGMA table_info(player)` of a fresh install equals that of an upgraded v3 install (column names and types). `PlayerDao`: `markDeleted` hides the player from `getAll()` but `getAll(includeDeleted: true)` returns it with `deletedAt` set; `findByName` does not return a deleted player and DOES return an active player with the same name added afterwards; `markDeleted` of an unknown id does not throw. `Player`: `toMap`/`fromMap` round-trip with and without `deletedAt`; `isDeleted`.
- [ ] **Step 2: Run** `flutter test test/data test/domain` — expect FAIL.
- [ ] **Step 3: Implement.** `database.dart`: bump to 4; keep `_tableColumns` and the existing `player` DDL shared constant semantics so v1→v2→v3→v4 never adds a column twice (the `player` table is created by the v3 step WITHOUT `deleted_at`, then the v4 step `ALTER`s it; `onCreate` creates `player` WITH `deleted_at`). Add `if (oldVersion < 4)` after the v3 block. Implement the model and DAO changes.
- [ ] **Step 4: Run** `flutter test test/data test/domain` — expect PASS.
- [ ] **Step 5: Suggested commit:** `Add soft-delete column to player (schema v4)`

### Task 2: Repository delete and scoreboard keeps deleted players

**Files:**
- Modify: `lib/data/gwent_repository.dart`, `lib/features/scores/cubit/scores_cubit.dart`
- Test: `test/data/gwent_repository_players_test.dart` (extend), `test/features/scores/scores_cubit_test.dart` (update stubs + one new test)

**Interfaces:**
- Consumes: `PlayerDao.getAll({includeDeleted})`, `markDeleted`, `Player.deletedAt` (Task 1).
- Produces on `GwentRepository`:
  - `Future<List<Player>> getPlayers()` — unchanged signature, now excludes deleted players.
  - `Future<List<Player>> getPlayersIncludingDeleted()`.
  - `Future<void> deletePlayer(Player player)` — soft-deletes via `markDeleted(player.id, DateTime.now())`; does NOT touch the photo file or any game row.
  - `findPlayerByName` unchanged signature (ignores deleted via the DAO).
- `ScoresCubit` loads players with `getPlayersIncludingDeleted()` instead of `getPlayers()`.

- [ ] **Step 1: Write failing tests.** Repository (real ffi DB + temp photo dir): `deletePlayer` removes the player from `getPlayers()` but `getPlayersIncludingDeleted()` still returns it; the player's photo file still exists and `photoPathOf` still resolves; a game row linked to the player is unchanged; `createPlayer` with the deleted player's exact name creates a different id, and `findPlayerByName` then returns the new one (Review Focus 3). `ScoresCubit` test: the cubit calls `getPlayersIncludingDeleted()` (stub it; a deleted player still appears in `state.players` with name and photo path) (Review Focus 2); update the existing stubs from `getPlayers` to `getPlayersIncludingDeleted` in `scores_cubit_test.dart` and `scores_view_test.dart`.
- [ ] **Step 2: Run** `flutter test test/data test/features/scores` — expect FAIL.
- [ ] **Step 3: Implement** the repository methods and the cubit switch.
- [ ] **Step 4: Run** `flutter test test/data test/features/scores` — expect PASS.
- [ ] **Step 5: Suggested commit:** `Soft-delete players in the repository; keep them on the scoreboard`

### Task 3: `HomeCubit` — common list, clear-the-other-side, delete

**Files:**
- Modify: `lib/features/home/cubit/home_cubit.dart`
- Test: `test/features/home/home_cubit_test.dart` (update + extend)

**Interfaces:**
- Consumes: `GwentRepository.deletePlayer(Player)`, `getPlayers()` (Task 2).
- Produces:
  - `onSavedPlayersRequested({required bool isPlayer1})` now lists every player returned by `getPlayers()` (no exclusion of the other side's selection); still emits `ShowSavedPlayers` and still falls back to an empty list when the repository throws.
  - `onSavedPlayerSelected({required bool isPlayer1, required Player player})`: if the OTHER side currently has the same player id, that other side is cleared completely (id, name `''`, photo path, photo-changed flag) in the same emit.
  - `Future<bool> onSavedPlayerDeleted({required Player player})`: calls `repository.deletePlayer(player)`; on success removes the player from the cubit's known players, clears completely every side whose id equals `player.id`, and returns true; if the repository throws it changes nothing and returns false.

- [ ] **Step 1: Write failing tests.** Update the existing test that asserted exclusion of the other side's player so it now expects the full list. New tests: selecting a player who is on the other side empties that side and fills this one (Review Focus 4); selecting a player not on the other side leaves the other side untouched; `onSavedPlayerDeleted` success returns true, calls `deletePlayer` once, and clears a side that had that player selected (name, photo, id, flag) while leaving the other side alone; deleting a player not selected anywhere changes no side; both sides cleared if the same id were somehow on both; repository throws → returns false and state is unchanged (Review Focus 5); after deleting a selected player and typing the same name, Play calls `createPlayer` (stub `findPlayerByName` to return null), not an update (Review Focus 3).
- [ ] **Step 2: Run** `flutter test test/features/home/home_cubit_test.dart` — expect FAIL.
- [ ] **Step 3: Implement** the three cubit changes per the interfaces.
- [ ] **Step 4: Run** `flutter test test/features/home` — expect PASS.
- [ ] **Step 5: Suggested commit:** `Share one saved-players list between both sides; support deleting`

### Task 4: Swipe-to-delete UI, strings, dependency

**Files:**
- Modify: `pubspec.yaml` (add `flutter_slidable`, latest stable compatible version), `lib/features/home/view/home_view.dart` (the saved-players sheet), `lib/l10n/app_*.arb` (9 files)
- Test: `test/features/home/home_view_test.dart` (extend)

**Interfaces:**
- Consumes: `HomeCubit.onSavedPlayerDeleted({required Player player}) -> Future<bool>` and `SavedPlayerOption` (`player`, `photoPath`) (Task 3).
- Produces:
  - In the saved-players bottom sheet each saved-player row is wrapped in a `Slidable` whose `endActionPane` holds one red delete action labelled with the existing `l10n.delete` (icon `Icons.delete`); tapping the row still selects the player.
  - Tapping the delete action shows an `AlertDialog` with title `l10n.deleteSavedPlayerTitle(player.name)`, content `l10n.deleteSavedPlayerMessage`, a Cancel button (`l10n.gameCancel`) and a Delete button (`l10n.delete`). Only Delete calls `cubit.onSavedPlayerDeleted(player: ...)`; if it returns true the row is removed from the open sheet (the sheet becomes stateful with a local list); if false the row stays. Cancel/dismiss does nothing.
  - New l10n keys in all 9 ARBs: `deleteSavedPlayerTitle(name)` and `deleteSavedPlayerMessage` — en `"Delete {name}?"` (with `@deleteSavedPlayerTitle` placeholder `name` of type String, same style as `playerWins`) / `"This removes the player from your saved players. Past games and scores stay as they are."`; de `"{name} löschen?"` / `"Der Spieler wird aus den gespeicherten Spielern entfernt. Bisherige Spiele und Ergebnisse bleiben erhalten."`; fr `"Supprimer {name} ?"` / `"Le joueur sera retiré des joueurs enregistrés. Les parties et scores passés restent inchangés."`; es `"¿Eliminar a {name}?"` / `"Se quitará al jugador de los jugadores guardados. Las partidas y puntuaciones anteriores se conservan."`; it `"Eliminare {name}?"` / `"Il giocatore verrà rimosso dai giocatori salvati. Le partite e i punteggi passati restano invariati."`; pt `"Eliminar {name}?"` / `"O jogador será removido dos jogadores guardados. Os jogos e as pontuações anteriores mantêm-se."`; pl `"Usunąć {name}?"` / `"Gracz zostanie usunięty z zapisanych graczy. Dotychczasowe gry i wyniki pozostaną bez zmian."`; nl `"{name} verwijderen?"` / `"De speler wordt uit de opgeslagen spelers verwijderd. Eerdere partijen en scores blijven bewaard."`; uk `"Видалити {name}?"` / `"Гравця буде видалено зі збережених гравців. Попередні ігри та результати залишаться."`

- [ ] **Step 1: Write failing tests** (mock repository; open the sheet via the chip): both sides' sheets list the same players, including one already chosen on the other side; swiping a row left reveals a Delete action and does NOT delete or show a dialog by itself (Review Focus 5); tapping Delete shows the dialog with the player's name; Cancel closes the dialog and `deletePlayer` is never called and the row stays; confirming calls `deletePlayer` once and the row disappears while the sheet stays open and "New player" is still there; when `deletePlayer` throws the row stays and nothing crashes; deleting the player who is selected on a side empties that side's text field.
- [ ] **Step 2: Run** `flutter test test/features/home` — expect FAIL.
- [ ] **Step 3: Implement.** Add the dependency (`flutter pub add flutter_slidable`), the sheet changes and the strings; regenerate localizations (generated `lib/l10n/app_localizations*.dart` are git-ignored — run `flutter gen-l10n` or any build and verify the new getters exist for all 9 locales). Keep `home_view.dart` readable: extract the sheet into its own private widget in the same file or a new file under `lib/features/home/widgets/` if that file grows unwieldy.
- [ ] **Step 4: Run** `flutter test` (whole suite) and `flutter analyze` — expect all PASS and no issues.
- [ ] **Step 5: Suggested commit:** `Add swipe-to-delete for saved players in the picker`
