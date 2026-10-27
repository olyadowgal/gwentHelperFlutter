import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/hud/hud_avatar.dart';

class PlayerInputWidget extends StatelessWidget {
  static const _avatarSize = 96.0;

  final String hint;
  final TextEditingController controller;
  final String? photoPath;
  final VoidCallback onPhotoTap;
  final String savedPlayersLabel;
  final VoidCallback onChooseSaved;

  const PlayerInputWidget({
    super.key,
    required this.hint,
    required this.controller,
    this.photoPath,
    required this.onPhotoTap,
    required this.savedPlayersLabel,
    required this.onChooseSaved,
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
            ActionChip(
              label: Text(savedPlayersLabel),
              avatar: const Icon(Icons.people_alt_outlined, size: 18),
              onPressed: onChooseSaved,
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(color: onSurface),
              iconTheme: IconThemeData(color: onSurface),
              side: const BorderSide(color: AppTheme.olive),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Change photo for $hint',
              onTap: onPhotoTap,
              // The avatar has nothing to read out on its own, so excluding it
              // keeps the picker a single node instead of two.
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onPhotoTap,
                child: HudAvatar(
                  size: _avatarSize,
                  iconSize: _avatarSize / 2,
                  image: photoPath == null ? null : FileImage(File(photoPath!)),
                ),
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
