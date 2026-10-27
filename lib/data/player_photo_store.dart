import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Keeps saved players' photos in permanent app storage, so they outlive the
/// cropper's temporary files.
class PlayerPhotoStore {
  PlayerPhotoStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  static const _folderName = 'player_photos';

  final Future<Directory> Function() _documentsDirectory;

  Future<Directory> _photosDirectory() async {
    final documents = await _documentsDirectory();
    return Directory('${documents.path}/$_folderName');
  }

  /// Copies [sourcePath] into permanent storage and returns the new file name.
  /// The source file is left untouched.
  Future<String> save(String sourcePath) async {
    final directory = await _photosDirectory();
    await directory.create(recursive: true);
    final name = '${const Uuid().v4()}.jpg';
    await File(sourcePath).copy('${directory.path}/$name');
    return name;
  }

  /// Returns the full path of a stored photo, or null if it does not exist.
  Future<String?> resolve(String fileName) async {
    final directory = await _photosDirectory();
    final path = '${directory.path}/$fileName';
    return await File(path).exists() ? path : null;
  }

  /// Deletes a stored photo. Does nothing if it does not exist.
  Future<void> delete(String fileName) async {
    final directory = await _photosDirectory();
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
