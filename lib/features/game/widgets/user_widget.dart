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
                        ? FileImage(File(photoPath!))
                        : null,
                    child: photoPath == null
                        ? Icon(
                            Icons.person,
                            size: 28,
                            color: colorScheme.onSurface,
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
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
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
