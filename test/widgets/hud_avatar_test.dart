import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/widgets/hud/hud_avatar.dart';

/// A 1x1 transparent PNG, so tests can supply a real decodable image.
final _transparentPng = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]),
);

void main() {
  const size = 96.0;

  Future<void> pumpAvatar(
    WidgetTester tester, {
    bool selected = false,
    ImageProvider? image,
    double iconSize = 48,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: Scaffold(
          body: Center(
            child: HudAvatar(
              size: size,
              image: image,
              selected: selected,
              iconSize: iconSize,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('HudAvatar', () {
    testWidgets(
      '''
      Given an unselected avatar
      When it is rendered
      Then its frame is stroked in the idle olive
      ''',
      (tester) async {
        // When
        await pumpAvatar(tester);

        // Then
        expect(
          find.byKey(HudAvatar.frameKey),
          paints..path(color: AppTheme.olive, style: PaintingStyle.stroke),
        );
      },
    );

    testWidgets(
      '''
      Given a selected avatar
      When it is rendered
      Then its frame is stroked in gold
      ''',
      (tester) async {
        // When
        await pumpAvatar(tester, selected: true);

        // Then
        expect(
          find.byKey(HudAvatar.frameKey),
          paints..path(color: AppTheme.gold, style: PaintingStyle.stroke),
        );
      },
    );

    testWidgets(
      '''
      Given an avatar without a photo
      When it is rendered
      Then the person placeholder is shown at the requested icon size
      ''',
      (tester) async {
        // When
        await pumpAvatar(tester, iconSize: 40);

        // Then
        expect(find.byType(Image), findsNothing);
        expect(tester.widget<Icon>(find.byIcon(Icons.person)).size, 40);
      },
    );

    testWidgets(
      '''
      Given an avatar with a photo
      When it is rendered
      Then the photo replaces the placeholder and fills the frame
      ''',
      (tester) async {
        // When
        await pumpAvatar(tester, image: _transparentPng);

        // Then
        expect(find.byIcon(Icons.person), findsNothing);
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, _transparentPng);
        expect(image.fit, BoxFit.cover);
      },
    );

    testWidgets(
      '''
      Given an avatar with a size
      When it is rendered
      Then it lays out as a square of that size and clips its content
      ''',
      (tester) async {
        // When
        await pumpAvatar(tester);

        // Then
        expect(tester.getSize(find.byType(HudAvatar)), const Size(size, size));
        expect(find.byType(ClipPath), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given a rendered avatar
      When its clip is read
      Then it is the same six-sided frame the border is painted from
      ''',
      (tester) async {
        // When
        await pumpAvatar(tester);

        // Then
        final clipper = tester.widget<ClipPath>(find.byType(ClipPath)).clipper!;
        expect(clipper, isA<HudFrameClipper>());
        expect(
          clipper.getClip(const Size(size, size)).getBounds(),
          hudFramePath(const Size(size, size)).getBounds(),
        );
      },
    );
  });

  group('hudFramePath', () {
    test(
      '''
      Given the shared frame path
      When points around it are probed
      Then it fills its box but cuts the corners off
      ''',
      () {
        // Given
        final path = hudFramePath(const Size(size, size));

        // Then
        expect(path.getBounds(), const Rect.fromLTWH(0, 0, size, size));
        expect(path.contains(const Offset(2, 2)), isFalse);
        expect(path.contains(const Offset(size - 2, size - 2)), isFalse);
        expect(path.contains(const Offset(size / 2, size / 2)), isTrue);
        expect(path.contains(const Offset(size / 2, 2)), isTrue);
        expect(path.contains(const Offset(2, size / 2)), isTrue);
      },
    );

    test(
      '''
      Given a border stroke width
      When the frame path is inset by half of it
      Then the stroke stays inside the avatar box
      ''',
      () {
        // Given
        const stroke = 2.0;

        // When
        final path = hudFramePath(const Size(size, size), inset: stroke / 2);

        // Then
        expect(
          path.getBounds(),
          const Rect.fromLTWH(0, 0, size, size).deflate(stroke / 2),
        );
      },
    );
  });
}
