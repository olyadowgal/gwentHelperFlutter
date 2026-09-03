import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../widgets/hud/hud_avatar.dart';

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
    return Semantics(
      button: true,
      selected: isSelected,
      label: name,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        // The gold avatar frame carries the selection, so the box the old
        // rectangle needed only keeps the sidebar spacing.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HudAvatar(
                size: _avatarSize,
                iconSize: 22,
                selected: isSelected,
                image: photoPath == null ? null : FileImage(File(photoPath!)),
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
                      ? colorScheme.primary
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
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.5),
                        BlendMode.srcIn,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
