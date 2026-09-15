# Witcher HUD chrome — Design Spec

**Date:** 2026-09-03
**Goal:** Restyle the whole app so it reads as an original Witcher-like overlay (near-black, olive, gold) without using CDPR art, fonts, or HUD assets, and without changing game rules or the current landscape helper layout.

---

## Decisions Summary

| Area | Decision |
|---|---|
| Mood | Witcher HUD: near-black, muted olive, gold chrome |
| Depth | Chrome only — keep today’s structure (sidebar, one player’s three rows, Pass/Scorch) |
| Screens | Home, game, scores, and dialogs in one pass |
| Type | Keep **Vollkorn** for display; no new font files |
| Implementation | Theme tokens in `AppTheme` plus a small set of HUD primitives |
| Art | Original geometry and recolored existing SVGs only |

---

## Legal / originality

Allowed: original color tokens, `RoundedRectangleBorder` / hex / slight shear shapes, gradients we define, recoloring `assets/icons/*`, new original SVGs we draw.

Not allowed: TW3 HUD rips, Gwent card faces/backs, character portraits, copying the in-game Trajan-like font file, tracing CDPR ornaments.

If a control would only look “right” by copying a TW3 asset, we simplify it (hex ring, olive hairline, gold fill) instead.

---

## Approach

**Theme tokens + HUD parts**, not a global `CustomPainter` skin and not a color-only `ThemeData` swap.

1. **`AppTheme`** owns colors, card/dialog/button defaults, Vollkorn mapping, and `onLightCard` replacement (light cards go away).
2. **Primitives** in `lib/widgets/hud/`: hex avatar frame, angular chip shape, outlined vs filled gold control, dark dialog shell. Screens compose these; they do not each invent borders.
3. **Layout and cubits stay.** No change to `GameCubit` scoring, Scorch/Spy/Muster, or navigation.

---

## Tokens

| Token | Hex | Use |
|---|---|---|
| Background | `#0D0F0C` | Scaffold |
| Panel | `#141811` | Sidebar, score rows, dialog surface |
| Line | `#6B7C3A` | Hairlines, idle borders |
| Gold | `#C8A84B` | Titles, selected player, primary actions, hero chip edge |
| Cream | `#D4C48A` | Body text and icons on dark |
| Scorch / error | keep a strong red (current error family is fine) | Scorch highlight and destructive actions |

Contrast is a requirement, not a nice-to-have: cream on background and gold on background must stay readable; chip point numerals stay **bold** and **≥ 13px**. Widget tests can assert token use on key widgets the same way score-card contrast is tested today.

`ColorScheme.primary` / `secondary` / `surface` / `onSurface` / `error` are remapped to these tokens so existing `Theme.of(context).colorScheme.*` call sites pick up the HUD without a rewrite. Hardcoded `Colors.white` chips and player cards are removed.

---

## Primitives

| Part | Behavior |
|---|---|
| Hex avatar | Same photo/placeholder; clip or overlay to a hex; selected = gold ring; idle = olive |
| Chip | Dark fill, slight shear (not a square Material card), olive border; hero = gold border; Scorch border uses the **same** radius/shear as the chip (fixes the squared highlight class of bugs) |
| Controls | Outlined gold/olive for secondary (Exit, Scores, Cancel); filled gold for primary (Play, Add, OK) |
| Gems / weather / horn | Existing SVGs, gold when active, muted olive/charcoal when not |

Sidebar hit targets and Pass long-press stay as they are; chrome must not shrink the 90px sidebar or cover Pass.

---

## Screens

**Home.** Same landscape: Scores chevron, VS + two player editors, Play chevron. White `Card` player editors become dark panels; avatars use the hex frame; VS stays Vollkorn at `displayLarge`, colored gold instead of teal.

**Game.** Same three zones. Sidebar `surface` becomes panel + olive edge. Selected player is the hex ring, not a full teal rectangle. Rows stay one-player-at-a-time. `_ScorchBanner` uses error colors on the dark panel. Dialogs (add/edit card, exit, game over, muster) use the dark dialog shell.

**Scores.** No white Material cards and no `onLightCard` workaround. Each match is a dark row: cream names (existing blank-name fallbacks), gold crown for the winner, muted date. App bar icons use cream/gold, not grey-on-slate leftovers.

---

## Out of scope

- Two-sided board or showing both players’ rows at once
- New fonts
- New abilities or scoring changes
- CDPR-like card illustrations
- Motion beyond light press / selected states
- Replacing the custom chevron Play/Scores control with a different navigation model

---

## Files (expected)

- `lib/app_theme.dart` — tokens and component themes
- New HUD widgets under `lib/` (keep them out of `domain/`)
- `lib/features/home/...`, `lib/features/game/widgets/...`, `lib/features/game/view/game_view.dart`, `lib/features/scores/...`
- Tests: theme/contrast (extend or replace `score_card_widget_test` light-card assumptions), `card_chip_test` (shape still rounded/sheared when Scorch is on), existing game/home overflow tests still pass

---

## Verification

- `flutter test` and `flutter analyze` stay green
- Visual check on landscape phone: Home VS, in-match Pass reachable, Scorch chip highlight follows chip shape, Scores names readable on dark rows
- No new binary art from CDPR; asset diff is original SVG and/or recolors only
