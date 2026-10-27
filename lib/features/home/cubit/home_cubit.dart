import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/gwent_repository.dart';
import '../../../domain/models/player.dart';
import 'home_side_effect.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required GwentRepository repository})
    : _repository = repository,
      super(const HomeState());

  final GwentRepository _repository;

  // Saved players this cubit has seen (selected or saved), by id. The state
  // only keeps ids, but updating a player needs the full object.
  final Map<String, Player> _knownPlayers = {};

  void onPlayer1NameChanged(String name) =>
      emit(state.copyWith(player1Name: name));

  void onPlayer2NameChanged(String name) =>
      emit(state.copyWith(player2Name: name));

  void onPlayer1PhotoPicked(String path) =>
      emit(state.copyWith(player1PhotoPath: path, player1PhotoChanged: true));

  void onPlayer2PhotoPicked(String path) =>
      emit(state.copyWith(player2PhotoPath: path, player2PhotoChanged: true));

  Future<void> onSavedPlayersRequested({required bool isPlayer1}) async {
    final excludedId = isPlayer1 ? state.player2Id : state.player1Id;
    var options = <SavedPlayerOption>[];
    try {
      final players = await _repository.getPlayers();
      options = [
        for (final player in players)
          if (player.id != excludedId)
            SavedPlayerOption(
              player: player,
              photoPath: await _repository.photoPathOf(player),
            ),
      ];
    } catch (_) {
      options = [];
    }
    emit(state + ShowSavedPlayers(isPlayer1, options));
  }

  Future<void> onSavedPlayerSelected({
    required bool isPlayer1,
    required Player player,
  }) async {
    final photoPath = await _repository.photoPathOf(player);
    _knownPlayers[player.id] = player;
    emit(
      isPlayer1
          ? state.copyWith(
              clearPlayer1: true,
              player1Id: player.id,
              player1Name: player.name,
              player1PhotoPath: photoPath,
            )
          : state.copyWith(
              clearPlayer2: true,
              player2Id: player.id,
              player2Name: player.name,
              player2PhotoPath: photoPath,
            ),
    );
  }

  void onNewPlayerSelected({required bool isPlayer1}) => emit(
    isPlayer1
        ? state.copyWith(clearPlayer1: true, player1Name: '')
        : state.copyWith(clearPlayer2: true, player2Name: ''),
  );

  // Fallback names are passed in rather than read from a Strings class here,
  // since Cubits don't depend on Flutter's localization APIs (no BuildContext).
  Future<void> onPlayTapped({
    required String player1Fallback,
    required String player2Fallback,
  }) async {
    final snapshot = state;
    final side1 = await _resolveSide(
      name: snapshot.player1Name.trim(),
      id: snapshot.player1Id,
      photoPath: snapshot.player1PhotoPath,
      photoChanged: snapshot.player1PhotoChanged,
    );
    final side2 = await _resolveSide(
      name: snapshot.player2Name.trim(),
      id: snapshot.player2Id,
      photoPath: snapshot.player2PhotoPath,
      photoChanged: snapshot.player2PhotoChanged,
      excludedId: side1?.id,
    );

    // A side that stays a guest is left as it was in state; a saved side gets
    // its id, permanent photo path and a reset changed flag.
    var resolved = state;
    if (side1 != null) {
      resolved = resolved.copyWith(
        clearPlayer1: true,
        player1Id: side1.id,
        player1PhotoPath: side1.photoPath,
      );
    }
    if (side2 != null) {
      resolved = resolved.copyWith(
        clearPlayer2: true,
        player2Id: side2.id,
        player2PhotoPath: side2.photoPath,
      );
    }
    emit(
      resolved +
          NavigateToGame(
            player1Name: _nameOr(snapshot.player1Name, player1Fallback),
            player2Name: _nameOr(snapshot.player2Name, player2Fallback),
            player1PhotoPath: side1 == null
                ? snapshot.player1PhotoPath
                : side1.photoPath,
            player2PhotoPath: side2 == null
                ? snapshot.player2PhotoPath
                : side2.photoPath,
            player1Id: side1?.id,
            player2Id: side2?.id,
          ),
    );
  }

  void onScoresTapped() => emit(state + const NavigateToScores());

  /// Saves or links one side. Returns null when the side stays a guest: blank
  /// name, the same saved player as the other side ([excludedId]), or any
  /// repository failure (a match must always be able to start).
  Future<_SavedSide?> _resolveSide({
    required String name,
    required String? id,
    required String? photoPath,
    required bool photoChanged,
    String? excludedId,
  }) async {
    if (name.isEmpty) return null;
    final tempPath = photoChanged ? photoPath : null;
    try {
      var player = id == null ? null : _knownPlayers[id];
      if (player == null) {
        player = await _repository.findPlayerByName(name);
        if (player == null) {
          player = await _repository.createPlayer(
            name: name,
            photoTempPath: tempPath,
          );
        } else if (player.id == excludedId) {
          return null;
        } else if (tempPath != null) {
          player = await _repository.updatePlayer(
            player,
            photoTempPath: tempPath,
          );
        }
      } else if (player.id == excludedId) {
        return null;
      } else {
        // Same name in a different case is the same player (lookup by name is
        // case-insensitive), so it is not a rename.
        final renamed = player.name.toLowerCase() != name.toLowerCase();
        if (renamed || tempPath != null) {
          player = await _repository.updatePlayer(
            player,
            name: renamed ? name : null,
            photoTempPath: tempPath,
          );
        }
      }
      _knownPlayers[player.id] = player;
      return _SavedSide(player.id, await _repository.photoPathOf(player));
    } catch (_) {
      return null;
    }
  }

  static String _nameOr(String name, String fallback) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}

class _SavedSide {
  const _SavedSide(this.id, this.photoPath);

  final String id;
  final String? photoPath;
}
