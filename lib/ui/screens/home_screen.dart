import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../state/main_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _p1Controller = TextEditingController();
  final _p2Controller = TextEditingController();

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(bool isPlayer1) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    );
    if (cropped == null) return;

    final notifier = ref.read(homeProvider.notifier);
    if (isPlayer1) {
      notifier.setPlayer1Photo(cropped.path);
    } else {
      notifier.setPlayer2Photo(cropped.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('GwentHelper')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PlayerInput(
                  label: 'Player 1',
                  controller: _p1Controller,
                  photoPath: state.player1PhotoPath,
                  onPhotoTap: () => _pickPhoto(true),
                  onNameChanged: notifier.setPlayer1Name,
                ),
                const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                _PlayerInput(
                  label: 'Player 2',
                  controller: _p2Controller,
                  photoPath: state.player2PhotoPath,
                  onPhotoTap: () => _pickPhoto(false),
                  onNameChanged: notifier.setPlayer2Name,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/game', extra: {
                'player1Name': state.player1Name.isEmpty ? 'Player 1' : state.player1Name,
                'player2Name': state.player2Name.isEmpty ? 'Player 2' : state.player2Name,
                'player1PhotoPath': state.player1PhotoPath,
                'player2PhotoPath': state.player2PhotoPath,
              }),
              child: const Text('PLAY'),
            ),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.leaderboard),
              onPressed: () => context.push('/scores'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? photoPath;
  final VoidCallback onPhotoTap;
  final ValueChanged<String> onNameChanged;

  const _PlayerInput({
    required this.label,
    required this.controller,
    required this.photoPath,
    required this.onPhotoTap,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPhotoTap,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: photoPath != null ? FileImage(File(photoPath!)) : null,
            child: photoPath == null ? const Icon(Icons.person, size: 40) : null,
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
}
