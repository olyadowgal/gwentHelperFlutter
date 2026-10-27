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

  // True while an `onPlayTapped` is resolving; a second tap in that window is
  // ignored so it cannot create the same player twice or navigate twice.
  bool _isPlaying = false;

  // Fallback names are passed in rather than read from a Strings class here,
  // since Cubits don't depend on Flutter's localization APIs (no BuildContext).
  Future<void> onPlayTapped({
    required String player1Fallback,
    required String player2Fallback,
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
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
        excludedId: side1.id,
      );

      // A saved side gets its id, exact name, permanent photo path and a reset
      // changed flag. A guest side drops its id but keeps its typed name, photo
      // path and changed flag. A failed side is left as it was (next Play
      // retries).
      var resolved = state;
      if (side1.kind == _SideKind.saved) {
        resolved = resolved.copyWith(
          clearPlayer1: true,
          player1Id: side1.id,
          player1Name: side1.name,
          player1PhotoPath: side1.photoPath,
        );
      } else if (side1.kind == _SideKind.guest) {
        resolved = resolved.copyWith(
          clearPlayer1: true,
          player1PhotoPath: snapshot.player1PhotoPath,
          player1PhotoChanged: snapshot.player1PhotoChanged,
        );
      }
      if (side2.kind == _SideKind.saved) {
        resolved = resolved.copyWith(
          clearPlayer2: true,
          player2Id: side2.id,
          player2Name: side2.name,
          player2PhotoPath: side2.photoPath,
        );
      } else if (side2.kind == _SideKind.guest) {
        resolved = resolved.copyWith(
          clearPlayer2: true,
          player2PhotoPath: snapshot.player2PhotoPath,
          player2PhotoChanged: snapshot.player2PhotoChanged,
        );
      }
      emit(
        resolved +
            NavigateToGame(
              player1Name: side1.kind == _SideKind.saved
                  ? side1.name!
                  : _nameOr(snapshot.player1Name, player1Fallback),
              player2Name: side2.kind == _SideKind.saved
                  ? side2.name!
                  : _nameOr(snapshot.player2Name, player2Fallback),
              player1PhotoPath: side1.kind == _SideKind.saved
                  ? side1.photoPath
                  : snapshot.player1PhotoPath,
              player2PhotoPath: side2.kind == _SideKind.saved
                  ? side2.photoPath
                  : snapshot.player2PhotoPath,
              player1Id: side1.id,
              player2Id: side2.id,
            ),
      );
    } finally {
      _isPlaying = false;
    }
  }

  void onScoresTapped() => emit(state + const NavigateToScores());

  /// Saves or links one side. The side is a guest when the name is blank or it
  /// is the same saved player as the other side ([excludedId]); it is failed on
  /// any repository exception (a match must always be able to start).
  Future<_SideResult> _resolveSide({
    required String name,
    required String? id,
    required String? photoPath,
    required bool photoChanged,
    String? excludedId,
  }) async {
    if (name.isEmpty) return const _SideResult.guest();
    final tempPath = photoChanged ? photoPath : null;
    try {
      var player = id == null ? null : _knownPlayers[id];
      var resolvedName = name;
      if (player == null) {
        player = await _repository.findPlayerByName(name);
        if (player == null) {
          player = await _repository.createPlayer(
            name: name,
            photoTempPath: tempPath,
          );
        } else if (player.id == excludedId) {
          return const _SideResult.guest();
        } else {
          // Linked by name: the saved player's exact spelling wins, so a
          // rematch compares equal names and does not rename.
          resolvedName = player.name;
          if (tempPath != null) {
            player = await _repository.updatePlayer(
              player,
              photoTempPath: tempPath,
            );
          }
        }
      } else if (player.id == excludedId) {
        return const _SideResult.guest();
      } else {
        final renamed = player.name != name;
        if (renamed || tempPath != null) {
          player = await _repository.updatePlayer(
            player,
            name: renamed ? name : null,
            photoTempPath: tempPath,
          );
        }
      }
      _knownPlayers[player.id] = player;
      return _SideResult.saved(
        player.id,
        resolvedName,
        await _repository.photoPathOf(player),
      );
    } catch (_) {
      return const _SideResult.failed();
    }
  }

  static String _nameOr(String name, String fallback) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}

enum _SideKind { saved, guest, failed }

class _SideResult {
  const _SideResult.saved(String this.id, String this.name, this.photoPath)
    : kind = _SideKind.saved;
  const _SideResult.guest()
    : kind = _SideKind.guest,
      id = null,
      name = null,
      photoPath = null;
  const _SideResult.failed()
    : kind = _SideKind.failed,
      id = null,
      name = null,
      photoPath = null;

  final _SideKind kind;
  final String? id;
  final String? name;
  final String? photoPath;
}
