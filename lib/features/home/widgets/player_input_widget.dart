import 'dart:io';
import 'package:flutter/material.dart';
import '../../../widgets/hud/hud_avatar.dart';

class PlayerInputWidget extends StatelessWidget {
  static const _avatarSize = 96.0;

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
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      // The HUD card theme already supplies the panel fill, olive hairline and
      // 4px corners, so this only names itself for tests.
      key: Key('player-input-$hint'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onPhotoTap,
              child: HudAvatar(
                size: _avatarSize,
                iconSize: _avatarSize / 2,
                image: photoPath == null ? null : FileImage(File(photoPath!)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                maxLength: 15,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: hint,
                  // Dimmed rather than olive, which is too dark to read here.
                  hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
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
}
