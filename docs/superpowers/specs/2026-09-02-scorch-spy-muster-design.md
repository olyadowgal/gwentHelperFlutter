# Scorch, Spy and Muster — Design Spec

**Date:** 2026-09-02
**Goal:** Add the four abilities requested by a user email — special Scorch, unit/row Scorch, Spy and Muster — to the game screen, following the rules of the Witcher 3 tavern Gwent minigame (not the standalone *GWENT: The Witcher Card Game*).

---

## Rules Reference

All four requests are valid Witcher 3 Gwent, quoted from the official
[CDPR Gwent manual](https://cdn-l-thewitcher.cdprojektred.com/media/TW3/Pdf/GwentManuals/en-Manual-Gwent-ONLINE.pdf):

| Ability | Manual text |
|---|---|
| Scorch (special card) | "Discard after playing. Kills the strongest card(s) on the battlefield for both players — so if there's a tie, this kills all cards of that strength on both sides." |
| Scorch (unit card) | "Affects this card's row on the opponent's side of the battlefield only. If the opponent has a total strength of 10 or higher on that row, kill that row's strongest card(s)." |
| Muster | "Go through your deck, find any cards with the same name or unit type as this card and play them all immediately." |
| Spy | "Place on your opponent's battlefield (counts towards your opponent's total) and draw 2 cards from your deck." |

Heroes are immune to all special cards and abilities, so they are never Scorch targets.

The standalone game reuses these names with different rules. We implement the Witcher 3 text only.

---

## Decisions Summary

| Area | Decision |
|---|---|
| Scorch behaviour | The app highlights legal targets; the user taps chips to remove them. Never auto-deletes. |
| Special Scorch | A sidebar board action, not a card on a row. |
| Unit/row Scorch | An ability on a normal unit card, resolved when the card is added. |
| Spy | An ability; the chip is added to the **other** player's row of the same type. |
| Muster | An ability plus a "how many extra copies" prompt. No scoring change. |
| Draw 2 (Spy) / deck search (Muster) | Out of scope — the app tracks no deck or hand. |
| Target strength | Current strength from `CardsRow.pointsOf`, after weather, Tight Bond, Morale and Horn. |
| Resolution | Targets are computed once, from a snapshot, and do not recompute as chips are removed. |
| Persistence | None needed. `GameScore` stores only round points, so there is no DB migration. |

---

## Section 1: Domain — New Abilities

Add three values to `Ability` (`lib/domain/models/ability.dart`), keeping the existing
`displayName` / `shortName` pattern:

| Value | `displayName` | `shortName` |
|---|---|---|
| `spy` | `Spy` | `Sp` |
| `muster` | `Muster` | `Mu` |
| `scorchRow` | `Scorch (Row)` | `Sc` |

Special Scorch is deliberately **not** an `Ability`. It is a one-shot board action, like the
weather toggles, because the card never stays on the battlefield.

`CardsRow.pointsOf` is **unchanged**. None of the three abilities modifies strength:

- `spy` — the chip sits on the opponent's row, so their `totalPoints` already includes it.
- `muster` — only adds more cards, each scored normally.
- `scorchRow` — removes cards; it does not change the value of surviving ones.

A regression test must assert that adding these abilities to a card leaves `pointsOf` untouched.

### `PlayerSide` (preparatory refactor)

Scorch targets live on either player, so the domain now needs the concept of a side. Today the
only such enum is `SelectedPlayer`, declared in the feature layer (`game_state.dart`), which the
domain must not import.

Introduce `enum PlayerSide { first, second }` in `lib/domain/models/player_side.dart` and rename
`SelectedPlayer` to it everywhere (`game_state.dart`, `game_cubit.dart`, `game_view.dart` and their
tests). This is a mechanical rename, not a behaviour change, and it avoids two enums for one
concept.

---

## Section 2: Domain — Scorch Target Resolution

New pure file `lib/domain/scorch.dart` — no Flutter imports, fully unit testable.

```dart
class ScorchTarget extends Equatable {
  final PlayerSide side;
  final CardsRowType rowType;
  final String cardId;
}
```

Two resolvers:

```dart
/// Special Scorch: strongest non-hero unit(s) across both players and all rows.
Iterable<ScorchTarget> specialScorchTargets(GameData data);

/// Unit Scorch: the opponent's row of the same type, and only if that row's
/// current total strength is 10 or more.
Iterable<ScorchTarget> rowScorchTargets(
  GameData data, {
  required PlayerSide owner,
  required CardsRowType rowType,
});
```

Rules both resolvers share:

1. **Strength is current strength** — `CardsRow.pointsOf(card)`, so weather, Tight Bond, Morale
   Boost and Commander's Horn are already applied. A frost-flattened melee row makes every
   non-hero unit a 1, which is exactly why Villentretenmerth can wipe a whole row.
2. **Heroes are never targets** — a card with `Ability.hero` is skipped when looking for the
   strongest, and skipped when collecting targets.
3. **Ties kill all** — every non-hero unit whose current strength equals the maximum is returned.
4. **Strength must be at least 1** — a board of only 0-strength chips (for example Decoys, which
   `pointsOf` scores as 0) yields no targets, rather than "scorching" nothing of value.

Rules specific to `rowScorchTargets`:

5. **Opponent's side, same row type.** `owner` is the side that played the card; targets come from
   the other side's row of the same `rowType`.
6. **The 10-point gate uses the row total** — `CardsRow.totalPoints` of that enemy row, which
   includes hero strength. Heroes count toward reaching 10 but still cannot be killed. Below 10,
   the result is empty.

---

## Section 3: State and Cubit

### State

`GameState` gains one nullable field:

```dart
final ScorchPrompt? scorchPrompt;
```

```dart
class ScorchPrompt extends Equatable {
  final List<ScorchTarget> targets;
}
```

`scorchPrompt == null` means normal play. Non-null means pick mode: the listed chips are the only
legal taps. A prompt is never created with an empty target list — an empty resolution produces a
side effect instead. `copyWith` needs a `clearScorchPrompt` flag, matching the existing
`clearGameOver` pattern.

### Cubit methods

Named per `docs/ai-instructions.md` (`onSomethingHappened`):

| Method | Behaviour |
|---|---|
| `onScorchTapped()` | Resolves `specialScorchTargets`. Empty → `ShowNoScorchTargets` side effect. Otherwise emits a prompt. |
| `onScorchTargetTapped(ScorchTarget)` | Removes that card from its side and row, then drops it from the prompt's target list. When the list empties, the prompt clears. |
| `onScorchPickCancelled()` | Clears the prompt, leaving remaining targets on the board. |

`onCardAdded` grows two branches:

- **Spy** — if the new card has `Ability.spy`, it is added to the **other** side's row of the same
  type instead of the selected player's.
- **Row Scorch** — after a card with `Ability.scorchRow` is added, resolve `rowScorchTargets` for
  the enemy row and either emit a prompt or `ShowNoScorchTargets`.
- **Muster** — after a card with `Ability.muster` is added, emit `ShowMusterCountDialog`.

New method `onMusterCountChosen(CardsRowType, Card, int extraCopies)` appends that many copies of
the card to the same row. Each copy is a new `Card` with a fresh `cardId` and the same points and
abilities, so a mustered Tight Bond group multiplies correctly. The dialog offers 1 to 4 extra
copies, which covers every Witcher 3 muster group, and can be dismissed to add none.

Guards: `onScorchTapped` and the add-time triggers do nothing once `gameOver != null`, consistent
with `onEndRoundTapped`.

### Side effects

Added to `GameSideEffect`:

- `ShowMusterCountDialog(CardsRowType rowType, Card card)`
- `ShowNoScorchTargets(ScorchNoTargetReason reason)` — a snackbar. The two reasons need different
  copy: `nothingToScorch` (no non-hero unit of strength 1 or more) and `rowBelowTen` (the enemy
  row totals less than 10).

---

## Section 4: UI

### Sidebar

A Scorch action joins the sidebar, between the weather toggles and Pass. The sidebar already
shrinks to fit via `FittedBox`, so one more control is safe, but the icon sizes should be
re-checked on a small screen after the change.

### Card chips

`CardChip` gains:

- `isScorchTarget` — draws a highlight (error-colored border) when this chip is a legal target.
- `onTap` — in pick mode, taps remove; long-press keeps opening the edit dialog. Outside pick
  mode `onTap` is null, so current behaviour is unchanged.

The chip's `_abilityIcon` only maps four abilities to SVG assets, and we have no SVGs for the new
ones. Extend it to fall back to standard Material vector icons (`Icons.visibility` for Spy,
`Icons.groups` for Muster, `Icons.local_fire_department` for Scorch), which satisfies the
"vector icons, no PNG" rule in `docs/ai-instructions.md`.

### Pick mode banner

While `scorchPrompt != null`, the board shows a banner with the number of remaining targets, a
note when targets sit on the other player's side, and a Cancel action. No Done action is needed:
removing the last target clears the prompt on its own. Because the board renders one player at a
time, the user switches sides with the existing player widgets; highlights persist across the
switch since they are keyed by `ScorchTarget.side`.

### Strings

All new copy goes in `GameStrings`: `scorch`, `scorchHint`, `nothingToScorch`, `rowBelowTen`,
`musterTitle`, `musterCount`, `scorchRemaining`, `scorchOtherSide`. `cancel` already exists.

---

## Section 5: Testing

TDD throughout, following the existing conventions: Given/When/Then in the description, AAA body
comments, groups named after the class under test, member names in backticks.

**`test/domain/scorch_test.dart`** (new)

1. Special Scorch picks the single strongest non-hero unit across both sides.
2. Ties return every unit of that strength, on both sides.
3. A hero stronger than every unit is not a target; the strongest non-hero is.
4. Weather-flattened rows make all non-hero units equal, so all are targets.
5. Horn / Tight Bond / Morale change which unit is strongest.
6. An all-zero or empty board returns no targets.
7. Row Scorch with an enemy row totalling 9 returns nothing.
8. Row Scorch at exactly 10 returns that row's strongest non-hero unit(s).
9. Row Scorch ignores the owner's own row and every other row type.
10. Row Scorch reaches 10 partly through hero strength, but only kills non-heroes.

**`test/domain/cards_row_test.dart`** (extend)

11. `spy`, `muster` and `scorchRow` do not change `pointsOf`.

**`test/features/game/game_cubit_test.dart`** (extend)

12. Adding a Spy card puts it on the other player's row of the same type, and their `totalPoints`
    grows while the selected player's does not.
13. Adding a Muster card emits `ShowMusterCountDialog`.
14. `onMusterCountChosen` appends the requested number of identical copies.
15. Adding a Scorch-row card with a qualifying enemy row emits a prompt with the right targets.
16. The same with a sub-10 enemy row emits `ShowNoScorchTargets` and no prompt.
17. `onScorchTapped` with targets emits a prompt; with none, `ShowNoScorchTargets`.
18. `onScorchTargetTapped` removes exactly that card and shrinks the target list.
19. Removing the last target clears the prompt.
20. `onScorchPickCancelled` clears the prompt and removes nothing.
21. Scorch actions are no-ops after game over.

**`test/features/game/game_view_test.dart`** (extend)

22. In pick mode, targeted chips are highlighted and a tap removes one.
23. Outside pick mode, a chip tap does nothing and long-press still opens the edit dialog.

---

## Out of Scope

- Spy's "draw 2 cards" and Muster's real deck search — the app models no deck or hand.
- Moving a card across sides when Spy is toggled in the **edit** dialog. Spy placement is decided
  when the card is added; to change it, delete and re-add. Worth revisiting if users ask.
- Medic, Agile, Clear Weather, Skellige Storm, Summon Avenger and leader abilities. All are real
  Witcher 3 Gwent and reasonable follow-ups, but they are not in this email.
- Any standalone *GWENT: The Witcher Card Game* rules.
- Persisting abilities or scorch history into `GameScore`.

---

## Verification

- `flutter analyze` — no issues.
- `flutter test` — existing 75 tests plus roughly 23 new ones pass.
- Manual check on a phone in landscape: the sidebar still fits with the Scorch action added, and
  pick-mode highlights survive switching players.
