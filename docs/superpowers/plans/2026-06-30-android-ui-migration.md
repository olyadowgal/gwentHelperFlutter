# Android UI Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reproduce the Android gwentHelper app's visual design faithfully in Flutter — oxford-blue dark theme, Vollkorn font, triangular home-screen chevrons, landscape game screen with sidebar, portrait card chips, and SVG icon set.

**Architecture:** Approach A — shared foundation first (theme, fonts, SVG assets), then screens in order: Home → Game → Scores. All colors flow through `ThemeData`/`colorScheme`; no hardcoded `Colors.*` in widget code. The 17 Android XML vector drawables are converted to SVG via a Python script and rendered with `flutter_svg`.

**Tech Stack:** `flutter_svg ^2.x`, `flutter_bloc`, `go_router`, Vollkorn TTF, SVG assets in `assets/icons/`.

---

## File Map

### Created
- `assets/fonts/Vollkorn.ttf`
- `assets/icons/ic_frost.svg` … (17 SVG files — full list in Task 1)
- `lib/features/home/widgets/background_touch_button.dart`
- `lib/features/game/widgets/stats_column_widget.dart`

### Modified
- `pubspec.yaml`
- `lib/main.dart`
- `lib/features/home/view/home_view.dart`
- `lib/features/home/widgets/player_input_widget.dart`
- `lib/features/game/view/game_view.dart`
- `lib/features/game/widgets/user_widget.dart`
- `lib/features/game/widgets/weather_widget.dart`
- `lib/features/game/widgets/cards_row_widget.dart`
- `lib/features/game/widgets/card_chip.dart`
- `lib/features/game/resources/game_strings.dart`
- `lib/features/scores/view/scores_view.dart`
- `lib/features/scores/widgets/score_card_widget.dart`

---

### Task 1: SVG assets, Vollkorn font, flutter_svg

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/fonts/Vollkorn.ttf`
- Create: `assets/icons/*.svg` (17 files)

- [ ] **Step 1: Add flutter_svg to pubspec.yaml**

In `pubspec.yaml` under `dependencies:`, add:
```yaml
  flutter_svg: ^2.0.10+1
```

- [ ] **Step 2: Copy Vollkorn font**

```bash
mkdir -p /Users/olhadovgal/Projects/gwent_helper_flutter/assets/fonts
cp /Users/olhadovgal/Projects/gwentHelper/app/src/main/res/font/vollkorn.ttf \
   /Users/olhadovgal/Projects/gwent_helper_flutter/assets/fonts/Vollkorn.ttf
```

- [ ] **Step 3: Convert Android XML vector drawables to SVG**

Create `/tmp/convert_icons.py`:

```python
import xml.etree.ElementTree as ET
import os

ANDROID_NS = 'http://schemas.android.com/apk/res/android'

def clean_color(color):
    if not color or color in ('none', '@null', '@color/transparent'):
        return 'none'
    c = color.lstrip('#')
    if len(c) == 8:      # AARRGGBB -> #RRGGBB
        return '#' + c[2:]
    if len(c) == 6:
        return '#' + c
    return color

def convert(xml_path, svg_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    vw = root.get(f'{{{ANDROID_NS}}}viewportWidth', '24')
    vh = root.get(f'{{{ANDROID_NS}}}viewportHeight', '24')

    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {vh}">']
    open_groups = 0
    for elem in root:
        tag = elem.tag.split('}')[-1]
        if tag == 'group':
            parts = []
            tx = elem.get(f'{{{ANDROID_NS}}}translateX', '0')
            ty = elem.get(f'{{{ANDROID_NS}}}translateY', '0')
            rot = elem.get(f'{{{ANDROID_NS}}}rotation', '0')
            px = elem.get(f'{{{ANDROID_NS}}}pivotX', '0')
            py = elem.get(f'{{{ANDROID_NS}}}pivotY', '0')
            if tx != '0' or ty != '0':
                parts.append(f'translate({tx},{ty})')
            if rot != '0':
                parts.append(f'rotate({rot},{px},{py})')
            transform = ' '.join(parts)
            lines.append(f'  <g{f" transform=\"{transform}\"" if transform else ""}>')
            open_groups += 1
            for child in elem:
                ctag = child.tag.split('}')[-1]
                if ctag == 'path':
                    _append_path(lines, child, '    ')
        elif tag == 'path':
            _append_path(lines, elem, '  ')
    for _ in range(open_groups):
        lines.append('  </g>')
    lines.append('</svg>')
    with open(svg_path, 'w') as f:
        f.write('\n'.join(lines))
    print(f'  ✓ {os.path.basename(svg_path)}')

def _append_path(lines, elem, indent):
    d = elem.get(f'{{{ANDROID_NS}}}pathData', '')
    fill = clean_color(elem.get(f'{{{ANDROID_NS}}}fillColor', '#000000'))
    stroke = clean_color(elem.get(f'{{{ANDROID_NS}}}strokeColor', 'none'))
    sw = elem.get(f'{{{ANDROID_NS}}}strokeWidth', '0')
    attr = f'd="{d}" fill="{fill}"'
    if stroke != 'none':
        attr += f' stroke="{stroke}" stroke-width="{sw}"'
    lines.append(f'{indent}<path {attr}/>')

android_dir = '/Users/olhadovgal/Projects/gwentHelper/app/src/main/res/drawable'
flutter_dir = '/Users/olhadovgal/Projects/gwent_helper_flutter/assets/icons'
os.makedirs(flutter_dir, exist_ok=True)

icons = [
    'ic_frost', 'ic_fog', 'ic_rain',
    'ic_jewel_activated', 'ic_jewel_deactivated',
    'ic_horn', 'ic_crown', 'ic_ring',
    'ic_exit', 'ic_reset', 'ic_plus_in_circle',
    'ic_trash', 'ic_baseline_arrow_back',
    'ic_decoy', 'ic_morale_boost', 'ic_tight_bond',
    'ic_male_avatar',
]

for icon in icons:
    src = os.path.join(android_dir, f'{icon}.xml')
    dst = os.path.join(flutter_dir, f'{icon}.svg')
    if os.path.exists(src):
        convert(src, dst)
    else:
        print(f'  ✗ NOT FOUND: {icon}')
```

Run it:
```bash
python3 /tmp/convert_icons.py
```

Expected: 17 lines starting with `✓`, no `✗` lines.

- [ ] **Step 4: Register fonts and assets in pubspec.yaml**

Under `flutter:` in `pubspec.yaml`, add (merge with any existing `assets:` block):
```yaml
  fonts:
    - family: Vollkorn
      fonts:
        - asset: assets/fonts/Vollkorn.ttf

  assets:
    - assets/icons/
    - assets/fonts/
```

- [ ] **Step 5: flutter pub get**

```bash
cd /Users/olhadovgal/Projects/gwent_helper_flutter && flutter pub get
```

Expected: Resolving dependencies... (no errors).

- [ ] **Step 6: flutter analyze**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/
git commit -m "feat(assets): flutter_svg, Vollkorn font, 17 SVG icons converted from Android"
```

---

### Task 2: ThemeData — oxford blue dark scheme + Vollkorn

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Read current main.dart**

Read `lib/main.dart`.

- [ ] **Step 2: Replace ThemeData**

Replace the entire `GwentHelperApp` class (keep imports, `main()`, and `RepositoryProvider` wrapper unchanged):

```dart
class GwentHelperApp extends StatelessWidget {
  const GwentHelperApp({super.key});

  @override
  Widget build(BuildContext context) => RepositoryProvider(
        create: (_) => GwentRepository(),
        child: MaterialApp.router(
          routerConfig: appRouter,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF263238),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1FAA83),
              onPrimary: Color(0xFF263238),
              primaryContainer: Color(0xFF5FDCB3),
              onPrimaryContainer: Color(0xFF263238),
              secondary: Color(0xFFFFCA28),
              onSecondary: Color(0xFF263238),
              secondaryContainer: Color(0xFFC79A00),
              onSecondaryContainer: Color(0xFF263238),
              surface: Color(0xFF37474F),
              onSurface: Colors.white,
              outline: Color(0xFF6C6E6F),
              error: Color(0xFFE31829),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontFamily: 'Vollkorn',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5FDCB3),
                fontSize: 48,
              ),
              headlineLarge: TextStyle(
                fontFamily: 'Vollkorn',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5FDCB3),
                fontSize: 32,
              ),
              headlineMedium: TextStyle(
                fontFamily: 'Vollkorn',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5FDCB3),
                fontSize: 24,
              ),
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 6,
            ),
            useMaterial3: true,
          ),
        ),
      );
}
```

- [ ] **Step 3: flutter analyze**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 4: flutter test**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "feat(theme): oxford blue dark theme, Vollkorn font, Gwent color scheme"
```

---

### Task 3: Home screen — landscape layout + triangular chevrons

**Files:**
- Create: `lib/features/home/widgets/background_touch_button.dart`
- Modify: `lib/features/home/widgets/player_input_widget.dart`
- Modify: `lib/features/home/view/home_view.dart`

- [ ] **Step 1: Read existing home files**

Read `lib/features/home/view/home_view.dart`, `lib/features/home/widgets/player_input_widget.dart`, `lib/features/home/cubit/home_cubit.dart`, `lib/features/home/resources/home_strings.dart`.

Verify `HomeStrings` has: `vs`, `play`, `player1`, `player2`, `scoresTooltip`. Add any missing constants.

- [ ] **Step 2: Create BackgroundTouchButton**

Create `lib/features/home/widgets/background_touch_button.dart`:

```dart
import 'package:flutter/material.dart';

enum ChevronSide { left, right }

class BackgroundTouchButton extends StatelessWidget {
  final String label;
  final Color color;
  final ChevronSide side;
  final VoidCallback onTap;

  const BackgroundTouchButton({
    super.key,
    required this.label,
    required this.color,
    required this.side,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipPath(
          clipper: _ChevronClipper(side),
          child: Container(
            width: 100,
            color: color,
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: side == ChevronSide.left ? 1 : 3,
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      );
}

class _ChevronClipper extends CustomClipper<Path> {
  final ChevronSide side;
  const _ChevronClipper(this.side);

  @override
  Path getClip(Size size) {
    const notch = 24.0;
    final path = Path();
    if (side == ChevronSide.right) {
      path.moveTo(0, 0);
      path.lineTo(size.width - notch, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - notch, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(notch, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(notch, size.height);
      path.lineTo(0, size.height / 2);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ChevronClipper old) => old.side != side;
}
```

- [ ] **Step 3: Restyle PlayerInputWidget**

Replace `lib/features/home/widgets/player_input_widget.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';

class PlayerInputWidget extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final String? photoPath;
  final VoidCallback onPhotoTap;

  const PlayerInputWidget({
    super.key,
    required this.hint,
    required this.controller,
    this.photoPath,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        elevation: 6,
        shape: const RoundedRectangleBorder(),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onPhotoTap,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFE0E0E0),
                  backgroundImage: photoPath != null
                      ? FileImage(File(photoPath!)) as ImageProvider
                      : null,
                  child: photoPath == null
                      ? const Icon(
                          Icons.person,
                          size: 48,
                          color: Color(0xFF263238),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  maxLength: 15,
                  style: const TextStyle(color: Color(0xFF263238)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFF6C6E6F)),
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
}
```

- [ ] **Step 4: Rewrite HomeView**

Replace `lib/features/home/view/home_view.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gwent_helper_flutter/arch/bloc_side_effect_handler.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_side_effect.dart';
import '../cubit/home_state.dart';
import '../resources/home_strings.dart';
import '../widgets/background_touch_button.dart';
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
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _p1Controller.addListener(
      () => context.read<HomeCubit>().onPlayer1NameChanged(_p1Controller.text),
    );
    _p2Controller.addListener(
      () => context.read<HomeCubit>().onPlayer2NameChanged(_p2Controller.text),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(bool isPlayer1) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;
    if (isPlayer1) {
      context.read<HomeCubit>().onPlayer1PhotoPicked(cropped.path);
    } else {
      context.read<HomeCubit>().onPlayer2PhotoPicked(cropped.path);
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
            body: Row(
              children: [
                BackgroundTouchButton(
                  label: HomeStrings.scoresTooltip,
                  color: Theme.of(context).colorScheme.secondary,
                  side: ChevronSide.right,
                  onTap: context.read<HomeCubit>().onScoresTapped,
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PlayerInputWidget(
                          hint: HomeStrings.player1,
                          controller: _p1Controller,
                          photoPath: state.player1PhotoPath,
                          onPhotoTap: () => _pickPhoto(true),
                        ),
                        const SizedBox(width: 32),
                        Text(
                          HomeStrings.vs,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(width: 32),
                        PlayerInputWidget(
                          hint: HomeStrings.player2,
                          controller: _p2Controller,
                          photoPath: state.player2PhotoPath,
                          onPhotoTap: () => _pickPhoto(false),
                        ),
                      ],
                    ),
                  ),
                ),
                BackgroundTouchButton(
                  label: HomeStrings.play,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  side: ChevronSide.left,
                  onTap: context.read<HomeCubit>().onPlayTapped,
                ),
              ],
            ),
          ),
        ),
      );
}
```

- [ ] **Step 5: flutter analyze**

```bash
flutter analyze lib/features/home/
```

Expected: No issues found.

- [ ] **Step 6: flutter test**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/home/
git commit -m "feat(home): landscape layout, triangular chevron buttons, Vollkorn VS label"
```

---

### Task 4: UserWidget — SVG jewels + ring overlay + sunglow points

**Files:**
- Modify: `lib/features/game/widgets/user_widget.dart`

- [ ] **Step 1: Read current user_widget.dart**

Read `lib/features/game/widgets/user_widget.dart`.

- [ ] **Step 2: Rewrite UserWidget**

Replace the file content:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    this.photoPath,
    required this.isSelected,
    required this.isWinning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: colorScheme.primaryContainer,
                  width: 2,
                ),
              )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: photoPath != null
                        ? FileImage(File(photoPath!)) as ImageProvider
                        : null,
                    child: photoPath == null
                        ? const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  SvgPicture.asset(
                    'assets/icons/ic_ring.svg',
                    width: 56,
                    height: 56,
                    colorFilter: ColorFilter.mode(
                      colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$totalPoints',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isWinning
                    ? colorScheme.secondary
                    : colorScheme.onSurface,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(2, (i) {
                final active = i < lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SvgPicture.asset(
                    active
                        ? 'assets/icons/ic_jewel_activated.svg'
                        : 'assets/icons/ic_jewel_deactivated.svg',
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      active
                          ? colorScheme.secondaryContainer
                          : const Color(0xFF263238),
                      BlendMode.srcIn,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: flutter analyze**

```bash
flutter analyze lib/features/game/widgets/user_widget.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/game/widgets/user_widget.dart
git commit -m "feat(game): restyle UserWidget — SVG jewels, ring overlay, sunglow winning points"
```

---

### Task 5: WeatherWidget (vertical) + CardChip (portrait rectangle)

**Files:**
- Modify: `lib/features/game/widgets/weather_widget.dart`
- Modify: `lib/features/game/widgets/card_chip.dart`

- [ ] **Step 1: Read current files**

Read `lib/features/game/widgets/weather_widget.dart`, `lib/features/game/widgets/card_chip.dart`, `lib/features/game/resources/game_strings.dart`, `lib/domain/models/ability.dart`.

- [ ] **Step 2: Rewrite WeatherWidget as vertical column**

Replace `lib/features/game/widgets/weather_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import '../resources/game_strings.dart';

class WeatherWidget extends StatelessWidget {
  final bool frostActive;
  final bool fogActive;
  final bool rainActive;
  final void Function(CardsRowType, bool) onChanged;

  const WeatherWidget({
    super.key,
    required this.frostActive,
    required this.fogActive,
    required this.rainActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WeatherToggle(
            icon: 'assets/icons/ic_frost.svg',
            label: GameStrings.frost,
            active: frostActive,
            onTap: () => onChanged(CardsRowType.closeCombat, !frostActive),
          ),
          _WeatherToggle(
            icon: 'assets/icons/ic_fog.svg',
            label: GameStrings.fog,
            active: fogActive,
            onTap: () => onChanged(CardsRowType.longRange, !fogActive),
          ),
          _WeatherToggle(
            icon: 'assets/icons/ic_rain.svg',
            label: GameStrings.rain,
            active: rainActive,
            onTap: () => onChanged(CardsRowType.siege, !rainActive),
          ),
        ],
      );
}

class _WeatherToggle extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _WeatherToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.outline;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SvgPicture.asset(
          icon,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Rewrite CardChip as portrait rectangle**

Replace `lib/features/game/widgets/card_chip.dart`:

```dart
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';

class CardChip extends StatelessWidget {
  final Card card;
  final int displayPoints;
  final VoidCallback onLongPress;

  const CardChip({
    super.key,
    required this.card,
    required this.displayPoints,
    required this.onLongPress,
  });

  String? _abilityIcon() {
    for (final ability in card.abilities) {
      final icon = switch (ability) {
        Ability.decoy => 'assets/icons/ic_decoy.svg',
        Ability.moraleBoost => 'assets/icons/ic_morale_boost.svg',
        Ability.tightBond => 'assets/icons/ic_tight_bond.svg',
        Ability.horn => 'assets/icons/ic_horn.svg',
        _ => null,
      };
      if (icon != null) return icon;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isHero = card.abilities.contains(Ability.hero);
    final iconPath = _abilityIcon();
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        color: isHero
            ? Theme.of(context).colorScheme.secondary
            : Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: SizedBox(
          width: 28,
          height: 44,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$displayPoints',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                if (iconPath != null)
                  SvgPicture.asset(
                    iconPath,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF263238),
                      BlendMode.srcIn,
                    ),
                  )
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: flutter analyze**

```bash
flutter analyze lib/features/game/widgets/
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/features/game/widgets/weather_widget.dart lib/features/game/widgets/card_chip.dart
git commit -m "feat(game): vertical WeatherWidget with SVG icons, portrait CardChip rectangles"
```

---

### Task 6: StatsColumnWidget + simplified CardsRowWidget

**Files:**
- Create: `lib/features/game/widgets/stats_column_widget.dart`
- Modify: `lib/features/game/widgets/cards_row_widget.dart`

- [ ] **Step 1: Read current CardsRowWidget and game_cubit.dart**

Read `lib/features/game/widgets/cards_row_widget.dart` and `lib/features/game/cubit/game_cubit.dart` to confirm `onHornChanged(CardsRowType, bool)` signature.

- [ ] **Step 2: Create StatsColumnWidget**

Create `lib/features/game/widgets/stats_column_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';

class StatsColumnWidget extends StatelessWidget {
  final Map<CardsRowType, CardsRow> cardsRows;
  final void Function(CardsRowType, bool) onHornChanged;

  const StatsColumnWidget({
    super.key,
    required this.cardsRows,
    required this.onHornChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: CardsRowType.values.map((rowType) {
          final row = cardsRows[rowType]!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${row.cards.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => onHornChanged(rowType, !row.horn),
                child: SvgPicture.asset(
                  'assets/icons/ic_horn.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    row.horn
                        ? colorScheme.primaryContainer
                        : Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 3: Simplify CardsRowWidget — remove stats column, make onHornChanged optional**

Replace `lib/features/game/widgets/cards_row_widget.dart`:

```dart
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'card_chip.dart';

class CardsRowWidget extends StatelessWidget {
  final CardsRow row;
  final void Function(CardsRowType) onAddCard;
  final void Function(CardsRow, Card) onCardLongPress;
  // Horn moved to StatsColumnWidget; kept optional so old GameView compiles until Task 7
  final void Function(CardsRowType, bool)? onHornChanged;

  const CardsRowWidget({
    super.key,
    required this.row,
    required this.onAddCard,
    required this.onCardLongPress,
    this.onHornChanged,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
              icon: SvgPicture.asset(
                'assets/icons/ic_plus_in_circle.svg',
                width: 32,
                height: 32,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primaryContainer,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => onAddCard(row.type),
            ),
          ],
        ),
      );
}
```

Note: `onHornChanged` is now optional and not used in the widget body — horn is handled by `StatsColumnWidget`. The existing `GameView` can still pass it without analyzer errors; Task 7 removes it cleanly when rewriting `GameView`.

- [ ] **Step 4: flutter analyze**

```bash
flutter analyze lib/features/game/
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/features/game/widgets/stats_column_widget.dart lib/features/game/widgets/cards_row_widget.dart
git commit -m "feat(game): add StatsColumnWidget, remove stats column from CardsRowWidget"
```

---

### Task 7: GameView — 4-zone landscape layout

**Files:**
- Modify: `lib/features/game/view/game_view.dart`
- Modify: `lib/features/game/resources/game_strings.dart`

- [ ] **Step 1: Read current game_view.dart and game_strings.dart**

Read both files.

- [ ] **Step 2: Add all missing GameStrings constants**

Read `lib/features/game/resources/game_strings.dart`. Add these constants if not already present:
```dart
static const exit = 'Exit';
static const pass = 'Pass';
static const exitTitle = 'Exit game?';
static const exitContent = 'Progress will not be saved.';
```

Verify `cancel` already exists (used in the exit dialog). If missing, add `static const cancel = 'Cancel';`.

- [ ] **Step 3: Rewrite GameView**

Replace `lib/features/game/view/game_view.dart`:

```dart
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/arch/bloc_side_effect_handler.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_side_effect.dart';
import '../cubit/game_state.dart';
import '../resources/game_strings.dart';
import '../widgets/add_card_dialog.dart';
import '../widgets/cards_row_widget.dart';
import '../widgets/edit_card_dialog.dart';
import '../widgets/stats_column_widget.dart';
import '../widgets/user_widget.dart';
import '../widgets/weather_widget.dart';

class GameView extends StatefulWidget {
  final String? player1PhotoPath;
  final String? player2PhotoPath;

  const GameView({
    super.key,
    this.player1PhotoPath,
    this.player2PhotoPath,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _winnerMessage(Winner winner, String p1, String p2) =>
      switch (winner) {
        Winner.first => '$p1 ${GameStrings.wins}',
        Winner.second => '$p2 ${GameStrings.wins}',
        Winner.tie => GameStrings.tie,
      };

  void _showExitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(GameStrings.exitTitle),
        content: const Text(GameStrings.exitContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(GameStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            child: const Text(GameStrings.exit),
          ),
        ],
      ),
    );
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
                if (card != null && context.mounted) {
                  context.read<GameCubit>().onCardAdded(rowType, card);
                }
              });

            case ShowEditCardDialog(:final row, :final card):
              showDialog<EditCardResult>(
                context: context,
                builder: (_) => EditCardDialog(card: card),
              ).then((result) {
                if (result == null || !context.mounted) return;
                switch (result) {
                  case EditCardSave(:final card):
                    context.read<GameCubit>().onCardEdited(row.type, card);
                  case EditCardDelete():
                    context.read<GameCubit>().onCardDeleted(row.type, card);
                }
              });

            case ShowGameOverDialog(:final winner):
              final state = context.read<GameCubit>().state;
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text(GameStrings.gameOverTitle),
                  content: Text(_winnerMessage(
                    winner,
                    state.gameData.firstPlayerData.name,
                    state.gameData.secondPlayerData.name,
                  )),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<GameCubit>().onGameOverConfirmed();
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
            final colorScheme = Theme.of(context).colorScheme;

            return Scaffold(
              body: Row(
                children: [
                  // Zone 1: Sidebar
                  Container(
                    width: 90,
                    color: colorScheme.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Exit button
                        GestureDetector(
                          onTap: () => _showExitDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/ic_exit.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    colorScheme.outline,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                Text(
                                  GameStrings.exit,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Player 1
                        UserWidget(
                          name: p1.name,
                          totalPoints: p1.totalPoints,
                          lives: p1.lives,
                          photoPath: widget.player1PhotoPath,
                          isSelected:
                              state.selectedPlayer == SelectedPlayer.first,
                          isWinning: p1.totalPoints > p2.totalPoints,
                          onTap: () =>
                              cubit.onPlayerSelected(SelectedPlayer.first),
                        ),
                        // Weather
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
                        // Player 2
                        UserWidget(
                          name: p2.name,
                          totalPoints: p2.totalPoints,
                          lives: p2.lives,
                          photoPath: widget.player2PhotoPath,
                          isSelected:
                              state.selectedPlayer == SelectedPlayer.second,
                          isWinning: p2.totalPoints > p1.totalPoints,
                          onTap: () =>
                              cubit.onPlayerSelected(SelectedPlayer.second),
                        ),
                        // Pass button (long-press to end round)
                        GestureDetector(
                          onLongPress: cubit.onEndRoundTapped,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/ic_reset.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    colorScheme.outline,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                Text(
                                  GameStrings.pass,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Zone 2: Stats column
                  StatsColumnWidget(
                    cardsRows: selectedData.cardsRows,
                    onHornChanged: cubit.onHornChanged,
                  ),
                  // Zone 3: Divider
                  Container(
                    width: 1,
                    color: Colors.white24,
                  ),
                  // Zone 4: Card rows
                  Expanded(
                    child: Column(
                      children: CardsRowType.values.map((rowType) {
                        final row = selectedData.cardsRows[rowType]!;
                        return Expanded(
                          child: CardsRowWidget(
                            row: row,
                            onAddCard: cubit.onAddCardRequested,
                            onCardLongPress: cubit.onEditCardRequested,
                          ),
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

- [ ] **Step 4: flutter analyze**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 6: flutter test**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/game/
git commit -m "feat(game): 4-zone landscape GameView — sidebar, stats column, portrait card rows"
```

---

### Task 8: Scores — crown icons + SVG AppBar buttons

**Files:**
- Modify: `lib/features/scores/widgets/score_card_widget.dart`
- Modify: `lib/features/scores/view/scores_view.dart`

- [ ] **Step 1: Read current files**

Read `lib/features/scores/widgets/score_card_widget.dart`, `lib/features/scores/view/scores_view.dart`, and `lib/domain/models/game_score.dart`.

`GameScore` has: `firstPlayer` (String), `secondPlayer` (String), `winner` (String — contains the winning player's name).

- [ ] **Step 2: Add crown icons to ScoreCardWidget**

Read the current `ScoreCardWidget` carefully. Find where `score.firstPlayer` and `score.secondPlayer` are displayed. Wrap each in a `Row` with a crown `SvgPicture` beside the name:

```dart
// Player 1 name + crown
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SvgPicture.asset(
      'assets/icons/ic_crown.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        score.winner == score.firstPlayer
            ? Theme.of(context).colorScheme.secondaryContainer
            : const Color(0xFF263238),
        BlendMode.srcIn,
      ),
    ),
    const SizedBox(width: 4),
    // existing firstPlayer Text widget here
  ],
),

// Player 2 name + crown
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SvgPicture.asset(
      'assets/icons/ic_crown.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        score.winner == score.secondPlayer
            ? Theme.of(context).colorScheme.secondaryContainer
            : const Color(0xFF263238),
        BlendMode.srcIn,
      ),
    ),
    const SizedBox(width: 4),
    // existing secondPlayer Text widget here
  ],
),
```

Add import: `import 'package:flutter_svg/flutter_svg.dart';`

Preserve all existing structure — only wrap the name Text widgets, don't restructure the card layout.

- [ ] **Step 3: Update ScoresView AppBar**

In `lib/features/scores/view/scores_view.dart`, find the `AppBar` widget. Replace it with:

```dart
AppBar(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  leading: IconButton(
    icon: SvgPicture.asset(
      'assets/icons/ic_baseline_arrow_back.svg',
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(
        Color(0xFFC4C5C5),
        BlendMode.srcIn,
      ),
    ),
    onPressed: () => context.pop(),
  ),
  actions: [
    GestureDetector(
      onLongPress: () => context.read<ScoresCubit>().onClearAllTapped(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SvgPicture.asset(
          'assets/icons/ic_trash.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFFC4C5C5),
            BlendMode.srcIn,
          ),
        ),
      ),
    ),
  ],
),
```

Add `import 'package:flutter_svg/flutter_svg.dart';` if not already present.
Add `import 'package:flutter_bloc/flutter_bloc.dart';` and the `ScoresCubit` import if not already present.

- [ ] **Step 4: flutter analyze**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 5: flutter test**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scores/
git commit -m "feat(scores): SVG crown icons per player, SVG back/trash AppBar buttons"
```
