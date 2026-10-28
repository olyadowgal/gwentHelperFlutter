# Saved Players — Design

## Problem

Players are re-created from scratch every match. The home screen holds a name and a photo per player only in memory (`HomeState`); a game stores just two name strings (`game_score.first_player` / `second_player`). Consequences:

- **Current bug:** after a finished game the home screen comes back blank, when it should come back pre-filled with the players who just played. Game over emits `NavigateBack`, which calls `context.go('/')` (`game_view.dart`), rebuilding `HomePage` with a new `HomeCubit`. Leaving a game early uses `context.pop()` and does keep the entered players, so the two exits behave differently. The fix is described under "Keeping players after a game".
- Nothing identifies "the same person" across matches, so there are no per-player results.
- A picked photo is a temporary crop file (`ImageCropper` output) that is never copied to permanent storage. It is lost on app restart, and nothing in the DB, `GameScore` or `PlayerData` can hold it.
- The Scores screen shows names only; it cannot show a photo.

## Goal

Players who play regularly can be saved once and reused:

- A saved player has a name and an optional photo that persist across app restarts.
- On the home screen you can choose a saved player for each side, or enter a new one.
- Saved players' names and photos show in the game sidebar and on the Scores screen.
- A users page lists saved players with games played, wins and losses, and lets you rename, re-photo or delete them.

## Decisions (from design discussion)

- **Data model:** a new `player` table; `game_score` gains two optional player links. Name columns stay as a snapshot (approach A). Replacing the name columns was rejected because it breaks existing games.
- **Per-player scores:** games are linked to the player, and the users page shows games played, wins and losses. No cumulative-points leaderboard.
- **Existing games:** left as-is (no auto-created players, no merge tool). They stay readable by name, are unlinked, and do not count in per-player stats.
- **Same players after a game:** when a game finishes, the home screen keeps the same two players (names, photos, saved-player links) so a rematch is one tap. The home screen is blank only when the app starts; the selection is not remembered across app launches.
- **Home picker:** tapping a player card opens a list of saved players plus "New player".
- **Delivery:** two stages, each shippable on its own.

## Design

### Storage (schema v3)

`lib/data/database.dart` bumps `version` to 3 and adds an `if (oldVersion < 3)` block. `onCreate` must create the same final schema.

```
player(
  id          TEXT PRIMARY KEY,   -- uuid v4
  name        TEXT NOT NULL,
  photo_file  TEXT,               -- file NAME only, nullable
  created_at  INTEGER NOT NULL
)
game_score + first_player_id  TEXT   -- nullable
game_score + second_player_id TEXT   -- nullable
```

- The upgrade is `CREATE TABLE player` plus two `ALTER TABLE game_score ADD COLUMN`. Existing rows are untouched (both ids NULL).
- No foreign-key constraints: sqflite has them off by default, and SQLite cannot add one via `ALTER`. Integrity is handled in code (players are soft-deleted, so game links never dangle).
- `first_player` / `second_player` keep being written when a game ends, as the player's name at that moment.

### Photo storage

New `PlayerPhotoStore` (in `lib/data/`):

- `save(String croppedTempPath) -> Future<String>` copies the file into `<documents>/player_photos/<uuid>.jpg` and returns the **file name** only. Absolute paths are never persisted, because the iOS app container path can change between app updates.
- A new file name is generated on every change, so `FileImage` never serves a stale cached image. The previous file is deleted after the swap.
- `resolve(String fileName)` returns the absolute path (asynchronously; the documents directory is looked up on first use and cached), or null if the file is missing. Cubits resolve paths when they load a player and hand widgets plain absolute paths, so widgets build a `FileImage` synchronously and `main()` is unchanged. `path_provider` is already a dependency but unused.
- A missing file (e.g. deleted outside the app) renders the placeholder avatar, never an error.

### Domain and data layer

- New `Player` model (`id`, `name`, `photoFile`, `createdAt`) with `toMap`/`fromMap`, in `lib/domain/models/`.
- New `PlayerDao`: insert, update, getAll (ordered by name, case-insensitive), findByName, markDeleted.
- `GameScore` gains `firstPlayerId` / `secondPlayerId` (nullable), included in `toMap`/`fromMap`. `GameScoreDao` gains per-player queries for stats. Deleting a player never touches game links (see Users page).
- `GwentRepository` exposes players: `getPlayers`, `savePlayer`, `updatePlayer`, `deletePlayer`, `getPlayerStats`. Cubits never touch `sqflite` or the file system directly (existing architecture rule).

### Player stats

`PlayerStats { played, wins, losses, draws }`, computed by SQL over `game_score` where the player's id is in either slot:

- win: the player is `first` and `winner = 'first'`, or `second` and `winner = 'second'`.
- draw: `winner = 'tie'`.
- loss: the rest of the games that player took part in.

Stats are always computed, never stored, so there are no counters to drift.

### Home screen

- `HomeState` gains `player1Id` / `player2Id` (nullable). Name and photo remain in state as today; photo is now a `photoFile` for saved players or a temp crop path for an unsaved pick.
- Each player card gets a dedicated "Saved players" tap target (a chip in the card header). This is a deliberate reading of "tap the player card": the avatar tap already opens the Camera/Gallery dialog and the name is a text field, so a whole-card tap would collide with both.
- The chip opens a bottom sheet listing saved players (photo + name) plus a "New player" entry. Choosing a saved player fills id, name and photo. Choosing "New player" clears the id, name and photo for that side. A player already chosen on the other side is not offered, so one person cannot play themselves.
- Editing name or photo while a saved player is selected updates that saved player when Play is tapped. This keeps one source of truth and gives you rename without a separate screen in Stage 1.
- On Play, with no saved player selected and a non-blank name: if a saved player with the same name (trimmed, case-insensitive) exists, link to it and apply a newly picked photo, otherwise create a new saved player. This prevents a duplicate person being created every match.
- A blank name stays a guest: nothing is saved, both ids are null, and the existing "Player 1/2" fallback applies.
- The route `extra` gains `player1Id` / `player2Id` alongside the existing name and photo values.
- **Keeping players after a game:** when Play creates or links a saved player, the resulting id is written back into `HomeState`, so the home screen shows that player as selected and a rematch does not create anything new. Game over returns with `context.pop()` instead of `context.go('/')`, so the existing `HomeCubit` (pushed-over, not replaced) keeps its state, the same as leaving a game early already does. Nothing is persisted across app launches: a cold start creates a fresh `HomeCubit` with blank players.

### Game

- `GameCubit` receives the two optional ids and writes them into `GameScore` in `onGameOverConfirmed`, together with the name snapshot.
- The game sidebar keeps using `HudAvatar` (size 44) fed from the saved photo.

### Scores screen

- `ScoresCubit` loads games plus a `Map<String, Player>` once.
- `ScoreCardWidget` shows a small `HudAvatar` next to each name. For a linked game it shows the **live** name and photo, so a rename also updates past games; this includes deleted players, so a deleted player's past games keep their name and photo. For a guest or an unknown id it shows the snapshot name and the placeholder avatar.

### Users page (Stage 2)

- New route `/players`, opened from the home screen.
- A list of saved players: photo, name, and games played / wins / losses.
- Per player: rename, change photo (reusing the existing camera/gallery + crop flow), delete with a confirmation dialog.
- **Delete is a soft delete:** schema v4 adds a nullable `player.deleted_at`, and `PlayerDao.markDeleted` is its only writer (`update` never touches it). A deleted player disappears from the saved list and from name lookup, but the row, the photo file and the game links stay, so past games keep the name and photo on the scoreboard. Retyping the name creates a new player. Stage-2 stats must group by player id, not name, and must decide whether deleted players are listed.

## Stages

1. **Stage 1 — foundation and picker.** Schema v3 + migration, `Player`/`PlayerDao`/`PlayerPhotoStore`, repository methods, home picker and save-on-Play behaviour, home keeps the same players after a finished game, ids written into saved games, game sidebar photo from permanent storage.
2. **Stage 2 — users page and scoreboard photos.** Stats query, `/players` page (rename / re-photo / delete), photos and live names on score cards.

## Localization and docs

- New strings go in all 9 `lib/l10n/app_*.arb` files (en, de, fr, es, it, pt, pl, nl, uk). Russian stays excluded. Dutch and Ukrainian wording is flagged as best-effort.
- `docs/architecture.md` is updated for schema v3 and the new data classes.
- Each release bumps the `+N` build number in `pubspec.yaml`.

## Out of scope

- Merging duplicate players, or auto-creating players from old games.
- Cumulative-points leaderboards or per-player history screens/filters.
- Remembering the last-used players across app launches (the home screen starts blank on every cold start).
- Cloud sync and backup of players or photos.
- Changes to `image_picker` / `image_cropper` versions or crop UI settings.

## Testing

Follows the project test conventions (Given/When/Then in descriptions; bloc_test + mocktail for cubits; `sqflite_common_ffi` for DB).

- **Migration** (`database_migration_test.dart` pattern): seed a v2 DB with games, open at v3; the `player` table exists, old games are intact with NULL ids, and new games round-trip with ids.
- **`PlayerDao` / repository:** insert, update, name lookup (case-insensitive), markDeleted hides a player from getAll and name lookup but keeps the row and game links; update never un-deletes.
- **Stats:** wins, losses and draws for the first and second slot; a player with no games shows zeros.
- **`PlayerPhotoStore`:** save copies the file and returns a file name only; replacing deletes the old file; a missing file degrades to the placeholder.
- **`HomeCubit`:** select a saved player; "New player" clears the side; the other side's player is excluded; Play creates, reuses by name, or treats a blank name as a guest.
- **`GameCubit`:** ids and the name snapshot are written on game over.
- **Rematch flow:** after game over the home screen still shows both players' names, photos and saved-player selection, and pressing Play again does not create duplicate players.
- **Widget tests:** the home picker sheet; the score card shows avatar and live name for a linked game, and a deleted player's games keep the name and photo, and snapshot name plus placeholder show for a guest or unknown id; the users page lists stats and deletes with confirmation.
- **Manual device check** (picker, camera and file storage are platform concerns not covered by `flutter test`): photos survive an app restart; behaviour after an app update on both platforms.
