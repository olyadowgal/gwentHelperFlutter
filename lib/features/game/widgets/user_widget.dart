import 'dart:io';
import 'package:flutter/material.dart';

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
    required this.isSelected,
    required this.isWinning,
    required this.onTap,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage:
                    photoPath != null ? FileImage(File(photoPath!)) : null,
                child: photoPath == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(height: 4),
              Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$totalPoints',
                style: TextStyle(
                  fontSize: 20,
                  color: isWinning ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  2,
                  (i) => Icon(
                    Icons.favorite,
                    size: 16,
                    color: i < lives ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
