import 'dart:io';
import 'package:flutter/material.dart';

class PlayerInputWidget extends StatelessWidget {
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 6,
      shape: const RoundedRectangleBorder(),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onPhotoTap,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFE0E0E0),
                backgroundImage: photoPath != null
                    ? FileImage(File(photoPath!)) as ImageProvider
                    : null,
                child: photoPath == null
                    ? Icon(
                        Icons.person,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                maxLength: 15,
                style: TextStyle(color: colorScheme.onPrimaryContainer),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: colorScheme.outline),
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
