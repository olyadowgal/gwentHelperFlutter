# Android UI Migration — Design Spec

**Date:** 2026-06-30  
**Goal:** Reproduce the Android gwentHelper app's visual design faithfully in the Flutter project.

---

## Decisions Summary

| Area | Decision |
|---|---|
| Theme | Oxford blue background, teal primary, sunglow secondary, dark scheme |
| Font | Vollkorn serif for VS label, chevron button text, and headline styles |
| Icons | 17 Android vector XMLs converted to SVG, bundled in `assets/icons/` |
| Home screen | Landscape layout, triangular ClipPath chevron buttons |
| Game screen | Landscape-locked, 4-zone horizontal layout with sidebar |
| Card chips | Portrait rectangles (28×44dp), white/gold backgrounds, ability icon |
| Scores screen | Crown icons per player, grey-tinted back/trash buttons |

---

## Implementation Approach

**A — Theme & assets layer first, then screens in order.**

Rationale: the `ThemeData`, fonts, and SVG assets are shared dependencies for all three screens. Getting them right first means each screen task is purely about layout, not debugging color loading or font registration.

Order: Theme + assets → Home → Game → Scores.

---

## Section 1: Theme & Assets

### New dependency
```yaml
flutter_svg: ^2.x
```

### Fonts
- Source: `gwentHelper/app/src/main/res/font/vollkorn_*.ttf`
- Destination: `assets/fonts/Vollkorn-Regular.ttf`, `assets/fonts/Vollkorn-Bold.ttf`
- Register in `pubspec.yaml` under `flutter.fonts`
- Apply in `ThemeData.textTheme` to `displayLarge`, `headlineLarge`, `headlineMedium`

### Color Palette

| Token | Name | Hex |
|---|---|---|
| `scaffoldBackgroundColor` | Oxford Blue | `#263238` |
| `colorScheme.primary` | Mountain Meadow | `#1FAA83` |
| `colorScheme.primaryContainer` | Medium Aquamarine | `#5FDCB3` |
| `colorScheme.secondary` | Sunglow | `#FFCA28` |
| `colorScheme.secondaryContainer` | Dark Goldenrod | `#C79A00` |
| `colorScheme.surface` | Blue Grey | `#37474F` |
| `colorScheme.outline` | Mid Grey | `#6C6E6F` |
| Card background | White | `#FFFFFF` |

`ThemeData` uses `brightness: Brightness.dark`. Replace the current `ColorScheme.fromSeed` with an explicit `ColorScheme` built from the palette above.

### SVG Icons

Convert these 17 Android vector drawables from XML → SVG format and place in `assets/icons/`:

| Filename | Usage |
|---|---|
| `ic_frost.svg` | Weather toggle — frost |
| `ic_fog.svg` | Weather toggle — fog |
| `ic_rain.svg` | Weather toggle — rain |
| `ic_jewel_activated.svg` | Player life (active) |
| `ic_jewel_deactivated.svg` | Player life (lost) |
| `ic_horn.svg` | Horn checkbox in stats column |
| `ic_crown.svg` | Winner indicator on scores screen |
| `ic_ring.svg` | Avatar ring overlay on UserWidget |
| `ic_exit.svg` | Exit button in game sidebar |
| `ic_reset.svg` | Pass/reset button in game sidebar |
| `ic_plus_in_circle.svg` | Add card button |
| `ic_trash.svg` | Clear scores button |
| `ic_baseline_arrow_back.svg` | Back button on scores screen |
| `ic_decoy.svg` | Card ability icon |
| `ic_morale_boost.svg` | Card ability icon |
| `ic_tight_bond.svg` | Card ability icon |
| `ic_male_avatar.svg` | Default avatar placeholder |

Register all under `assets/icons/` in `pubspec.yaml`.

---

## Section 2: Home Screen

**File:** `lib/features/home/view/home_view.dart`  
**Orientation:** Landscape only — lock in `initState`, restore in `dispose` (wrap `HomeView` in `StatefulWidget` if currently `StatelessWidget`).

### Layout: full-screen `Row`

```
[ Scores chevron | Player 1 card | VS | Player 2 card | Play chevron ]
```

**Scores chevron** (`BackgroundTouchButton` widget, new file `lib/features/home/widgets/background_touch_button.dart`):
- `ClipPath` with right-pointing `TriangleClipper` (custom `CustomClipper<Path>`)
- Width: ~100dp, full screen height
- Fill color: `#FFCA28` (sunglow)
- Child: rotated "Scores" text, Vollkorn bold, `#263238`, `writing-mode` equivalent via `RotatedBox`
- `onTap` → `cubit.onScoresTapped()`

**Center (`Expanded`):**
- `Row` with `PlayerInputWidget` + VS label + `PlayerInputWidget`
- VS: `Text('VS')`, Vollkorn bold, 48sp, `#5FDCB3`
- `PlayerInputWidget`: white `Card` (elevation 6, no corner radius), `CircleAvatar` radius 64 (tap → pick photo), `TextField` below (hint "Player 1"/"Player 2", oxford blue text, max 15 chars, no border)

**Play chevron** (mirror of Scores):
- `ClipPath` with left-pointing `TriangleClipper`
- Fill: `#5FDCB3`
- "Play" text, Vollkorn bold, `#263238`
- `onTap` → `cubit.onPlayTapped()`

**Removed:** `AppBar`, `ElevatedButton("PLAY")`, `IconButton` (leaderboard). Navigation lives entirely in the chevrons.

---

## Section 3: Game Screen

**File:** `lib/features/game/view/game_view.dart`  
**Orientation:** Landscape-locked on entry, restored on exit.

### Layout: `Row` with 4 zones

#### Zone 1 — Sidebar (`~90dp`, `colorScheme.surface` `#37474F`, elevation 6)

Top to bottom:
1. **Exit button**: `ic_exit.svg` + "Exit" label (`#6C6E6F`), tap → show exit confirmation `AlertDialog` directly in `GameView` via `showDialog` (no new cubit method — on confirm, call `context.pop()` without saving)
2. **`UserWidget` (Player 1)** — see UserWidget spec below
3. **`WeatherWidget`** (vertical) — see WeatherWidget spec below
4. **`UserWidget` (Player 2)**
5. **Pass button**: `ic_reset.svg` + "Pass" label (`#6C6E6F`), long-press → `cubit.onEndRoundTapped()`

#### Zone 2 — Stats column (`~40dp`, `#263238`)

3 rows, one per `CardsRowType`, each containing:
- Card count `Text` (24sp white, bold)
- `ic_horn.svg` toggle: tinted `#5FDCB3` when `row.horn == true` / white when false; tap → `cubit.onHornChanged(rowType, !row.horn)`

#### Zone 3 — Divider
1dp wide, white, full height.

#### Zone 4 — Card rows (`Expanded`)

`Column` of 3× `CardsRowWidget` (horizontal scroll, weight 1 each).  
No sidebar info here — stats moved to Zone 2.

### Widget: `UserWidget`

Restyled completely:
- 48dp `Stack`: `CircleAvatar` (photo or `ic_male_avatar.svg` placeholder) with `ic_ring.svg` overlay tinted `colorScheme.primary`
- Player name: 14sp white
- Total points: 24sp bold — sunglow `#FFCA28` if winning, white if losing
- Lives: 2× `SvgPicture.asset('assets/icons/ic_jewel_activated.svg')` (16dp, tinted `#C79A00`) or `ic_jewel_deactivated.svg` (tinted `#263238`) based on `lives` count

### Widget: `WeatherWidget`

Change from horizontal `Row` to vertical `Column` of 3 `_WeatherToggle`s inside the sidebar.  
Each toggle: `SvgPicture.asset(icon, colorFilter: ...)` 32dp — tinted `#5FDCB3` when active, `#6C6E6F` when inactive. Tap to toggle.

### Widget: `CardsRowWidget`

Remove the 80dp stats column (moved to Zone 2). Keep only the horizontal-scroll row of `CardChip`s + add button.

### Widget: `CardChip`

Redesigned as portrait rectangle:
- Size: 28×44dp `Card`, elevation 2
- Background: white (`#FFFFFF`) for normal cards, sunglow `#FFCA28` for hero cards
- Points: top-aligned `Text`, 14sp bold, `#263238`
- Ability icon: bottom-aligned `SvgPicture.asset(...)` 16dp, tinted `#263238` (or empty `SizedBox` if no ability)
- Long-press → `onCardLongPress(row, card)`

---

## Section 4: Scores Screen

**File:** `lib/features/scores/view/scores_view.dart`  
**Widget:** `lib/features/scores/widgets/score_card_widget.dart`

### AppBar changes
- Remove title text
- Back button: `IconButton` with `SvgPicture.asset('assets/icons/ic_baseline_arrow_back.svg')`, tinted `#C4C5C5`
- Trash button: `IconButton` with `SvgPicture.asset('assets/icons/ic_trash.svg')`, tinted `#C4C5C5`, long-press → `cubit.onClearAllTapped()`

### `ScoreCardWidget` changes
- Add `ic_crown.svg` (32dp) beside each player name
- Crown tint: `#C79A00` (dark goldenrod) if player won, `#263238` (oxford blue) if they lost
- Winner determined by `GameScore.winner` (a `String`): compare `score.winner == score.firstPlayer` and `score.winner == score.secondPlayer`; tie if neither matches

### No structural changes
`ScoresView`, `ScoresCubit`, `ScoresState`, `ScoresPage` are unchanged. Only `ScoreCardWidget` and `ScoresView`'s AppBar are touched.

---

## Files Changed / Created

| File | Action |
|---|---|
| `pubspec.yaml` | Add `flutter_svg`, register fonts + assets |
| `lib/main.dart` | Replace `ThemeData` with full dark oxford-blue theme |
| `assets/fonts/Vollkorn-Regular.ttf` | Copy from Android project |
| `assets/fonts/Vollkorn-Bold.ttf` | Copy from Android project |
| `assets/icons/*.svg` | 17 converted SVGs |
| `lib/features/home/view/home_view.dart` | Full rewrite — chevron layout |
| `lib/features/home/widgets/background_touch_button.dart` | New — ClipPath chevron widget |
| `lib/features/home/widgets/player_input_widget.dart` | Restyle — white card, oxford blue text |
| `lib/features/game/view/game_view.dart` | Full rewrite — 4-zone landscape layout |
| `lib/features/game/widgets/user_widget.dart` | Restyle — SVG jewels, ring overlay |
| `lib/features/game/widgets/weather_widget.dart` | Restyle — vertical, SVG icons |
| `lib/features/game/widgets/cards_row_widget.dart` | Remove stats column |
| `lib/features/game/widgets/card_chip.dart` | Restyle — portrait rectangle |
| `lib/features/scores/view/scores_view.dart` | AppBar icon swap |
| `lib/features/scores/widgets/score_card_widget.dart` | Add crown icons |
