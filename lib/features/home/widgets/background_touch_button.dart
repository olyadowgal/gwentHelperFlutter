import 'package:flutter/material.dart';

enum ChevronSide { left, right }

/// How deep the arrow bites into the chevron.
const _notch = 24.0;

/// The chevron outline, shared by the clip and the painted border so the two
/// always describe the same shape.
Path chevronPath(Size size, ChevronSide side) {
  final path = Path();
  if (side == ChevronSide.right) {
    path.moveTo(0, 0);
    path.lineTo(size.width - _notch, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - _notch, size.height);
    path.lineTo(0, size.height);
  } else {
    path.moveTo(_notch, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(_notch, size.height);
    path.lineTo(0, size.height / 2);
  }
  path.close();
  return path;
}

class ChevronClipper extends CustomClipper<Path> {
  final ChevronSide side;

  const ChevronClipper(this.side);

  @override
  Path getClip(Size size) => chevronPath(size, side);

  @override
  bool shouldReclip(ChevronClipper oldClipper) => oldClipper.side != side;
}

/// Strokes the chevron edge for the outlined variant.
class ChevronOutlinePainter extends CustomPainter {
  final ChevronSide side;
  final Color color;
  final double strokeWidth;

  const ChevronOutlinePainter({
    required this.side,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = chevronPath(size, side);
    // Clipping to the same path keeps the inner half of a double-width stroke,
    // so the border cannot spill past the chevron on the diagonal edges.
    canvas
      ..save()
      ..clipPath(path)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(ChevronOutlinePainter oldDelegate) =>
      oldDelegate.side != side ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;

  /// The outline never takes taps; the chevron underneath owns the hit area.
  @override
  bool hitTest(Offset position) => false;
}

/// The full-height chevron that starts a match or opens the scores.
///
/// [filled] paints the primary gold action; the outlined variant is a dark
/// panel with a gold edge for secondary navigation.
class BackgroundTouchButton extends StatelessWidget {
  static const _width = 100.0;
  static const _strokeWidth = 2.0;

  final String label;
  final ChevronSide side;
  final bool filled;
  final VoidCallback onTap;

  /// Overrides the default fill ([filled] ? primary : surface). Used to give
  /// a filled chevron its own identity (e.g. walnut for Scores) without
  /// reaching for the primary gold that PLAY owns.
  final Color? fillColor;

  /// Overrides the default label color ([filled] ? onPrimary : onSurface),
  /// paired with [fillColor] when the default wouldn't stay readable on it.
  final Color? textColor;

  const BackgroundTouchButton({
    super.key,
    required this.label,
    required this.side,
    required this.onTap,
    this.filled = false,
    this.fillColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedFill =
        fillColor ?? (filled ? colorScheme.primary : colorScheme.surface);
    final resolvedTextColor =
        textColor ?? (filled ? colorScheme.onPrimary : colorScheme.onSurface);
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      // The rotated label would otherwise be announced as a second node
      // alongside the button itself.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: ChevronClipper(side),
                child: ColoredBox(
                  color: resolvedFill,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: side == ChevronSide.left ? 1 : 3,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 20,
                              color: resolvedTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!filled)
                CustomPaint(
                  painter: ChevronOutlinePainter(
                    side: side,
                    color: colorScheme.primary,
                    strokeWidth: _strokeWidth,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
