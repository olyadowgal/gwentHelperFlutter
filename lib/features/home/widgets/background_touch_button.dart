import 'package:flutter/material.dart';

enum ChevronSide { left, right }

class BackgroundTouchButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final ChevronSide side;
  final VoidCallback onTap;

  const BackgroundTouchButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
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
                      color: textColor,
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
