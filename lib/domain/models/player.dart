import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A saved player: a name plus an optional permanent photo that can be reused
/// across matches. [photoFile] is a file name inside the app's photo storage,
/// not a full path.
class Player extends Equatable {
  Player({
    String? id,
    required this.name,
    this.photoFile,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String? photoFile;
  final DateTime createdAt;

  Player copyWith({String? name, String? photoFile}) => Player(
    id: id,
    name: name ?? this.name,
    photoFile: photoFile ?? this.photoFile,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'photo_file': photoFile,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
    id: map['id'] as String,
    name: map['name'] as String,
    photoFile: map['photo_file'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );

  @override
  List<Object?> get props => [id, name, photoFile, createdAt];
}
