import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';

/// How far the banner's peak rises above its flat sides.
const _peakHeight = 10.0;

/// A small pennant, pointed at the top like the home screen's PLAY/SCORES
/// chevrons, flat everywhere else. Shared by the clip and the painted
/// border so the two can never drift apart.
Path _bannerPath(Size size) => Path()
  ..moveTo(size.width / 2, 0)
  ..lineTo(size.width, _peakHeight)
  ..lineTo(size.width, size.height)
  ..lineTo(0, size.height)
  ..lineTo(0, _peakHeight)
  ..close();

class _BannerClipper extends CustomClipper<Path> {
  const _BannerClipper();

  @override
  Path getClip(Size size) => _bannerPath(size);

  @override
  bool shouldReclip(_BannerClipper oldClipper) => false;
}

/// Strokes the banner's pennant edge, clipped to itself so a double-width
/// stroke can't spill past the point on the diagonal sides.
class _BannerOutlinePainter extends CustomPainter {
  final Color color;

  const _BannerOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _bannerPath(size);
    canvas
      ..save()
      ..clipPath(path)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _BannerOutlinePainter oldDelegate) =>
      oldDelegate.color != color;

  /// The outline never takes taps; the banner underneath owns the hit area.
  @override
  bool hitTest(Offset position) => false;
}

class _HeartLabel extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color iconColor;
  final Color textColor;

  const _HeartLabel({
    required this.iconSize,
    required this.fontSize,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'assets/icons/ic_heart.svg',
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      const SizedBox(width: 6),
      Text(
        AppLocalizations.of(context)!.supportDeveloper,
        style: TextStyle(fontSize: fontSize, color: textColor),
      ),
    ],
  );
}

/// The home screen's support banner: flush with the bottom edge, sized to
/// its own content rather than stretched, so it reads as a small secondary
/// tab rather than a third primary action next to PLAY and SCORES.
class SupportDeveloperBanner extends StatelessWidget {
  final VoidCallback onTap;

  const SupportDeveloperBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Semantics(
        button: true,
        label: l10n.supportDeveloper,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          // The screen is locked to landscape, but the first frames can
          // still be portrait, where this banner does not fit beside the
          // full-height PLAY/SCORES chevrons.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              children: [
                ClipPath(
                  clipper: const _BannerClipper(),
                  child: ColoredBox(
                    color: colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                      child: _HeartLabel(
                        iconSize: 12,
                        fontSize: 11,
                        iconColor: colorScheme.primary,
                        textColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BannerOutlinePainter(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The scores screen's support action, styled to match the app bar's
/// existing icon actions (e.g. clear all) rather than the home banner.
class SupportDeveloperAction extends StatelessWidget {
  final VoidCallback onTap;

  const SupportDeveloperAction({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.supportDeveloper,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _HeartLabel(
            iconSize: 15,
            fontSize: 11,
            iconColor: colorScheme.primary,
            textColor: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
