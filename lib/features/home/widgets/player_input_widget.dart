import 'dart:io';
import 'package:flutter/material.dart';

class PlayerInputWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? photoPath;
  final VoidCallback onPhotoTap;
  final ValueChanged<String> onNameChanged;

  const PlayerInputWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.photoPath,
    required this.onPhotoTap,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: CircleAvatar(
              radius: 40,
              backgroundImage:
                  photoPath != null ? FileImage(File(photoPath!)) : null,
              child: photoPath == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: label),
              onChanged: onNameChanged,
            ),
          ),
        ],
      );
}
