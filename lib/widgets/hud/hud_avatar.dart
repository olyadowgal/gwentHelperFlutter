import 'package:flutter/material.dart';

import '../../app_theme.dart';

/// How far down the sides the top and bottom points reach, as a fraction of
/// the frame height.
const _shoulderRatio = 0.25;

/// The six-sided HUD outline that fits [size].
///
/// The clip and the painted border both come from here, so the edge can never
/// drift away from the photo it frames. [inset] shrinks the path by half a
/// stroke width so a border stays inside the avatar box.
Path hudFramePath(Size size, {double inset = 0}) {
  final rect = Offset.zero & size;
  final frame = inset == 0 ? rect : rect.deflate(inset);
  final shoulder = frame.height * _shoulderRatio;
  return Path()
    ..moveTo(frame.center.dx, frame.top)
    ..lineTo(frame.right, frame.top + shoulder)
    ..lineTo(frame.right, frame.bottom - shoulder)
    ..lineTo(frame.center.dx, frame.bottom)
    ..lineTo(frame.left, frame.bottom - shoulder)
    ..lineTo(frame.left, frame.top + shoulder)
    ..close();
}

/// Clips a photo or placeholder to the HUD frame.
class HudFrameClipper extends CustomClipper<Path> {
  const HudFrameClipper();

  @override
  Path getClip(Size size) => hudFramePath(size);

  @override
  bool shouldReclip(HudFrameClipper oldClipper) => false;
}

/// Strokes the HUD frame around whatever it covers.
class HudHexFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const HudHexFramePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      hudFramePath(size, inset: strokeWidth / 2),
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(HudHexFramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// A player portrait inside the HUD frame.
///
/// Shows [image] when there is one and the person placeholder otherwise. The
/// border is gold while [selected] and olive the rest of the time.
class HudAvatar extends StatelessWidget {
  /// Names the painted border so tests can target it.
  static const frameKey = Key('hud-avatar-frame');

  static const _borderWidth = 2.0;

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

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: const HudFrameClipper(),
          child: ColoredBox(
            color: AppTheme.panel,
            child: image == null
                ? Center(
                    child: Icon(
                      Icons.person,
                      size: iconSize,
                      color: AppTheme.cream,
                    ),
                  )
                : Image(image: image!, fit: BoxFit.cover),
          ),
        ),
        CustomPaint(
          key: frameKey,
          painter: HudHexFramePainter(
            color: selected ? AppTheme.gold : AppTheme.olive,
            strokeWidth: _borderWidth,
          ),
        ),
      ],
    ),
  );
}
