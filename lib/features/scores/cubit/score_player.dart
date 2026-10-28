import 'package:equatable/equatable.dart';

/// A saved player as the scoreboard shows them: current name and a photo path
/// that is already known to point at an existing file (or null).
class ScorePlayer extends Equatable {
  final String name;
  final String? photoPath;

  const ScorePlayer({required this.name, this.photoPath});

  @override
  List<Object?> get props => [name, photoPath];
}
