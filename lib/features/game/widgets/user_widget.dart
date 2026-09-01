import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserWidget extends StatelessWidget {
  static const _avatarSize = 44.0;
  static const _nameWidth = 72.0;

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
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _avatarSize,
              height: _avatarSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: _avatarSize / 2,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: photoPath != null
                        ? FileImage(File(photoPath!))
                        : null,
                    child: photoPath == null
                        ? Icon(
                            Icons.person,
                            size: 22,
                            color: colorScheme.onSurface,
                          )
                        : null,
                  ),
                  SvgPicture.asset(
                    'assets/icons/ic_ring.svg',
                    width: _avatarSize,
                    height: _avatarSize,
                    colorFilter: ColorFilter.mode(
                      colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: _nameWidth,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$totalPoints',
              style: TextStyle(
                fontSize: 16,
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
                    width: 11,
                    height: 11,
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
