import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/features/home/widgets/background_touch_button.dart';
import 'package:gwent_helper_flutter/features/home/widgets/player_input_widget.dart';
import 'package:gwent_helper_flutter/main.dart';
import 'package:gwent_helper_flutter/widgets/hud/hud_avatar.dart';

void main() {
  /// The chevron button that carries [label].
  Finder chevron(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(BackgroundTouchButton),
  );

  /// The color filling a chevron, which is what separates the filled primary
  /// action from the outlined secondary one.
  Color chevronFill(WidgetTester tester, String label) => tester
      .widget<ColoredBox>(
        find
            .descendant(of: chevron(label), matching: find.byType(ColoredBox))
            .first,
      )
      .color;

  /// The outline painted along a chevron, or `null` when it has none.
  ChevronOutlinePainter? chevronOutline(WidgetTester tester, String label) {
    final painters = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: chevron(label),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((paint) => paint.painter)
        .whereType<ChevronOutlinePainter>();
    return painters.isEmpty ? null : painters.first;
  }

  group('GwentHelperApp', () {
    testWidgets(
      '''
      Given the app
      When it is launched
      Then player name inputs are shown
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given a portrait phone screen
      When the app is launched before the orientation lock applies
      Then nothing overflows
      ''',
      (WidgetTester tester) async {
        // Given
        tester.view
          ..physicalSize = const Size(1080, 2400)
          ..devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given a landscape phone screen
      When the app is launched
      Then the HUD home screen fits without overflowing
      ''',
      (WidgetTester tester) async {
        // Given
        tester.view
          ..physicalSize = const Size(2400, 1080)
          ..devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(tester.takeException(), isNull);
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given the home screen
      When the player editors are rendered
      Then each one is a dark panel with an olive hairline and 4px corners
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        for (final hint in ['Player 1', 'Player 2']) {
          final material = tester.widget<Material>(
            find
                .descendant(
                  of: find.byKey(Key('player-input-$hint')),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(material.color, AppTheme.panel);
          final shape = material.shape! as RoundedRectangleBorder;
          expect(shape.side.color, AppTheme.olive);
          expect(shape.side.width, 1);
          expect(
            shape.borderRadius,
            const BorderRadius.all(Radius.circular(4)),
          );
        }
      },
    );

    testWidgets(
      '''
      Given the home screen without player photos
      When the avatars are rendered
      Then both are idle olive HUD frames around the person placeholder
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(find.byType(HudAvatar), findsNWidgets(2));
        expect(find.byIcon(Icons.person), findsNWidgets(2));
        final painters = tester
            .widgetList<CustomPaint>(find.byKey(HudAvatar.frameKey))
            .map((paint) => paint.painter)
            .cast<HudHexFramePainter>();
        expect(
          painters.map((painter) => painter.color),
          everyElement(AppTheme.olive),
        );
      },
    );

    testWidgets(
      '''
      Given the home screen
      When the player name fields are rendered
      Then their text is cream and their hint stays readable on the panel
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(field.style!.color, AppTheme.cream);
        final hint = field.decoration!.hintStyle!.color!;
        expect(
          _contrastRatio(
            Color.alphaBlend(hint, AppTheme.panel),
            AppTheme.panel,
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    testWidgets(
      '''
      Given the home screen
      When the Play and Scores chevrons are rendered
      Then Play is filled gold and Scores is an outlined dark panel
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(chevronFill(tester, 'PLAY'), AppTheme.gold);
        expect(
          tester.widget<Text>(find.text('PLAY')).style!.color,
          AppTheme.background,
        );
        expect(chevronOutline(tester, 'PLAY'), isNull);

        expect(chevronFill(tester, 'Scores'), AppTheme.panel);
        expect(
          tester.widget<Text>(find.text('Scores')).style!.color,
          AppTheme.cream,
        );
        expect(chevronOutline(tester, 'Scores')!.color, AppTheme.gold);
      },
    );

    testWidgets(
      '''
      Given the home screen
      When the VS separator is rendered
      Then it uses the gold display style from the theme
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(
          tester.widget<Text>(find.text('VS')).style!.color,
          AppTheme.gold,
        );
      },
    );
  });

  group('BackgroundTouchButton', () {
    testWidgets(
      '''
      Given a chevron beside the rest of the screen
      When its top, middle and bottom are tapped
      Then the whole column still reacts
      ''',
      (WidgetTester tester) async {
        // Given
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.data,
            home: Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BackgroundTouchButton(
                    label: 'Scores',
                    side: ChevronSide.right,
                    onTap: () => taps++,
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        );

        // When
        final chevron = tester.getRect(find.byType(BackgroundTouchButton));
        await tester.tapAt(Offset(chevron.left + 8, chevron.top + 8));
        await tester.tapAt(chevron.center);
        await tester.tapAt(Offset(chevron.left + 8, chevron.bottom - 8));

        // Then
        expect(taps, 3);
      },
    );

    testWidgets(
      '''
      Given a chevron control
      When its semantics are read
      Then it is one tappable button carrying its label
      ''',
      (WidgetTester tester) async {
        // Given
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.data,
            home: Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BackgroundTouchButton(
                    label: 'Scores',
                    side: ChevronSide.right,
                    onTap: () {},
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        );

        // Then
        expect(
          tester.getSemantics(find.byType(BackgroundTouchButton)),
          isSemantics(label: 'Scores', isButton: true, hasTapAction: true),
        );
        expect(find.bySemanticsLabel('Scores'), findsOneWidget);
        semantics.dispose();
      },
    );
  });

  group('PlayerInputWidget', () {
    Future<void> pumpEditor(
      WidgetTester tester, {
      required VoidCallback onPhotoTap,
    }) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.data,
          home: Scaffold(
            body: Center(
              child: PlayerInputWidget(
                hint: 'Player 1',
                controller: controller,
                onPhotoTap: onPhotoTap,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '''
      Given the six-sided avatar
      When a transparent corner outside its shape is tapped
      Then the photo picker stays shut, while a tap on the avatar opens it
      ''',
      (WidgetTester tester) async {
        // Given
        var photoTaps = 0;
        await pumpEditor(tester, onPhotoTap: () => photoTaps++);
        final avatar = tester.getRect(find.byType(HudAvatar));

        // When
        await tester.tapAt(avatar.topLeft + const Offset(4, 4));

        // Then
        expect(photoTaps, 0);

        // When
        await tester.tapAt(avatar.center);

        // Then
        expect(photoTaps, 1);
      },
    );

    testWidgets(
      '''
      Given the avatar photo picker
      When its semantics are read
      Then it is one tappable button that names the player it belongs to
      ''',
      (WidgetTester tester) async {
        // Given
        final semantics = tester.ensureSemantics();

        // When
        await pumpEditor(tester, onPhotoTap: () {});

        // Then
        expect(
          tester.getSemantics(find.byType(HudAvatar)),
          isSemantics(
            label: 'Change photo for Player 1',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          find.bySemanticsLabel('Change photo for Player 1'),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );
  });
}

/// WCAG contrast ratio between two opaque colors.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
