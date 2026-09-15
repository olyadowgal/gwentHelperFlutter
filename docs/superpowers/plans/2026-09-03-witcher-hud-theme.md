# Witcher HUD Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle Home, Game, Scores, and dialogs as an original near-black/olive/gold Witcher-like HUD without changing layout or game behavior.

**Architecture:** `AppTheme` is the source of truth for palette and Material component defaults. Small reusable HUD primitives provide the original hex avatar frame and panel chrome; feature widgets compose those primitives while retaining existing callbacks and state flow.

**Tech Stack:** Flutter Material 3, `flutter_svg`, widget tests, existing Vollkorn font.

---

### Task 1: HUD theme tokens and component defaults

**Files:**
- Modify: `lib/app_theme.dart`
- Create: `test/app_theme_test.dart`

- [ ] **Step 1: Write failing token and contrast tests**

Create tests which assert the approved colors and readable pairings:

```dart
expect(AppTheme.background, const Color(0xFF0D0F0C));
expect(AppTheme.panel, const Color(0xFF141811));
expect(AppTheme.olive, const Color(0xFF6B7C3A));
expect(AppTheme.gold, const Color(0xFFC8A84B));
expect(AppTheme.cream, const Color(0xFFD4C48A));
expect(AppTheme.data.scaffoldBackgroundColor, AppTheme.background);
expect(AppTheme.data.cardTheme.color, AppTheme.panel);
expect(contrastRatio(AppTheme.cream, AppTheme.background), greaterThanOrEqualTo(4.5));
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test test/app_theme_test.dart`

Expected: compile failure because the public HUD tokens do not exist.

- [ ] **Step 3: Implement the approved theme**

Expose the five design tokens from `AppTheme`, remap `ColorScheme.dark`, keep `error` strongly red, and define:

```dart
cardTheme: const CardThemeData(
  color: panel,
  elevation: 0,
  shape: RoundedRectangleBorder(
    side: BorderSide(color: olive),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  ),
),
dialogTheme: const DialogThemeData(
  backgroundColor: panel,
  titleTextStyle: TextStyle(
    fontFamily: 'Vollkorn',
    color: gold,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  ),
),
```

Add filled gold `ElevatedButtonThemeData`, outlined cream/gold `TextButtonThemeData`, gold checkbox/slider defaults, and cream body text. Keep `Vollkorn` on the existing display styles only.

- [ ] **Step 4: Run theme tests**

Run: `flutter test test/app_theme_test.dart`

Expected: all pass.

---

### Task 2: Reusable HUD frame and Home screen

**Files:**
- Create: `lib/widgets/hud/hud_avatar.dart`
- Modify: `lib/features/home/widgets/player_input_widget.dart`
- Modify: `lib/features/home/widgets/background_touch_button.dart`
- Modify: `lib/features/home/view/home_view.dart`
- Create: `test/widgets/hud_avatar_test.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing avatar and Home styling tests**

Test that `HudAvatar` keeps the supplied image/placeholder and paints either the idle olive or selected gold border. Extend the app test to assert the player editor cards use `AppTheme.panel` and no widget overflows at the existing portrait bootstrap size.

```dart
expect(
  tester.widget<CustomPaint>(find.byKey(const Key('hud-avatar-frame'))).painter,
  isA<HudHexFramePainter>(),
);
expect(
  tester.widget<Card>(find.byKey(const Key('player-input-Player 1'))).color,
  AppTheme.panel,
);
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/widgets/hud_avatar_test.dart test/widget_test.dart`

Expected: compile/test failure because `HudAvatar` and keys do not exist.

- [ ] **Step 3: Implement `HudAvatar`**

Create a focused widget that clips its child to an original six-sided path and paints a matching border:

```dart
class HudAvatar extends StatelessWidget {
  final double size;
  final ImageProvider? image;
  final bool selected;
  final double iconSize;

  const HudAvatar({
    super.key,
    required this.size,
    this.image,
    this.selected = false,
    required this.iconSize,
  });
}
```

Use one shared path helper for both `CustomClipper<Path>` and `CustomPainter`; border color is `AppTheme.gold` when selected and `AppTheme.olive` otherwise. Render the existing person icon when `image == null`.

- [ ] **Step 4: Apply Home chrome**

Replace `CircleAvatar` in `PlayerInputWidget` with `HudAvatar`, set the player card to `AppTheme.panel`, olive border and 4px radius, and use `onSurface`/`outline` text colors. Add stable keys `player-input-$hint`.

Keep `BackgroundTouchButton` geometry and hit area; apply gold fill to Play and an olive/gold outlined dark panel to Scores through parameters or a new `filled` flag. Change Home’s callers to use `AppTheme` tokens and retain the existing `FittedBox` overflow protection.

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/widgets/hud_avatar_test.dart test/widget_test.dart`

Expected: all pass.

---

### Task 3: Game board chrome

**Files:**
- Modify: `lib/features/game/widgets/user_widget.dart`
- Modify: `lib/features/game/widgets/card_chip.dart`
- Modify: `lib/features/game/widgets/cards_row_widget.dart`
- Modify: `lib/features/game/widgets/weather_widget.dart`
- Modify: `lib/features/game/widgets/stats_column_widget.dart`
- Modify: `lib/features/game/view/game_view.dart`
- Modify: `test/features/game/card_chip_test.dart`
- Modify: `test/features/game/game_view_test.dart`

- [ ] **Step 1: Write failing game chrome tests**

Extend `card_chip_test.dart` to assert normal chips are dark with olive borders, hero chips use gold borders, and Scorch uses the same shape with an error border:

```dart
expect(card.color, AppTheme.panel);
expect(shape.side.color, AppTheme.olive);
expect(heroShape.side.color, AppTheme.gold);
expect(scorchShape.borderRadius, normalShape.borderRadius);
```

Extend `game_view_test.dart` to assert selected user frame is gold, sidebar is `AppTheme.panel`, and the existing landscape test still keeps Pass visible.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter test test/features/game/card_chip_test.dart test/features/game/game_view_test.dart`

Expected: styling assertions fail against white chips and old selection rectangle.

- [ ] **Step 3: Restyle game widgets**

Use `HudAvatar` in `UserWidget`; remove the rectangular selected border. Style:

- card chips: panel fill, 4px radius, olive idle border, gold hero border, error Scorch border (Scorch has precedence);
- plus/weather/horn/sidebar icons: gold active, olive idle;
- stats and sidebar text: cream with gold winning totals;
- row separators: olive at low opacity;
- sidebar: panel background with olive right edge.

Preserve chip width/height, sidebar width, callbacks, long-press Pass, Scorch target behavior, and all keys used by tests.

- [ ] **Step 4: Restyle prompts without changing behavior**

Use the global dialog/button themes for add/edit/exit/game-over/muster dialogs. Replace the hardcoded red delete button with `colorScheme.error`; keep `_ScorchBanner` on error container colors.

- [ ] **Step 5: Run focused game tests**

Run: `flutter test test/features/game/card_chip_test.dart test/features/game/game_view_test.dart test/features/game/game_cubit_test.dart`

Expected: all pass.

---

### Task 4: Scores chrome and final verification

**Files:**
- Modify: `lib/features/scores/widgets/score_card_widget.dart`
- Modify: `lib/features/scores/view/scores_view.dart`
- Modify: `test/features/scores/score_card_widget_test.dart`

- [ ] **Step 1: Rewrite the failing score contrast test for dark cards**

Remove the light-card-specific theme assumption. Assert all paragraphs meet 4.5:1 against `AppTheme.panel`, the card itself is panel colored, winner crown is gold, and existing placeholder-name tests remain:

```dart
final card = tester.widget<Card>(find.byType(Card));
expect(card.color ?? AppTheme.data.cardTheme.color, AppTheme.panel);
expect(
  contrastRatio(paragraph.text.style!.color!, AppTheme.panel),
  greaterThanOrEqualTo(4.5),
);
```

- [ ] **Step 2: Run score tests and verify failure**

Run: `flutter test test/features/scores/score_card_widget_test.dart`

Expected: old `onLightCard` override and crown color assertions do not match the HUD.

- [ ] **Step 3: Implement score and app-bar chrome**

Remove the nested light `Theme` and `AppTheme.onLightCard` dependency from `ScoreCardWidget`. Use the global dark card theme, cream text, gold winning crown and olive idle crown. In `ScoresView`, use panel app bar, cream back icon, error-colored destructive icon, and keep loading/error/empty states unchanged.

- [ ] **Step 4: Run score tests**

Run: `flutter test test/features/scores/score_card_widget_test.dart test/features/scores/scores_cubit_test.dart`

Expected: all pass.

- [ ] **Step 5: Format, lint, and run the complete suite**

Run:

```bash
dart format lib test
flutter analyze
flutter test
```

Expected: no analyzer issues and all tests pass. Verify manually at a landscape phone size that Home fits, Pass remains visible, chip/Scorch outlines match, dialogs are readable, and score placeholders remain visible.

