import 'package:equatable/equatable.dart';

import 'models/ability.dart';
import 'models/cards_row.dart';
import 'models/cards_row_type.dart';
import 'models/game_data.dart';
import 'models/player_data.dart';
import 'models/player_side.dart';

final class ScorchTarget extends Equatable {
  final PlayerSide side;
  final CardsRowType rowType;
  final String cardId;

  const ScorchTarget({
    required this.side,
    required this.rowType,
    required this.cardId,
  });

  @override
  List<Object?> get props => [side, rowType, cardId];
}

typedef _Candidate = ({ScorchTarget target, int strength});

const _rowScorchThreshold = 10;

Iterable<ScorchTarget> specialScorchTargets(GameData data) => _strongest([
  for (final side in PlayerSide.values)
    for (final rowType in CardsRowType.values)
      ..._candidatesOf(_playerDataOf(data, side).cardsRows[rowType], side),
]);

Iterable<ScorchTarget> rowScorchTargets(
  GameData data, {
  required PlayerSide owner,
  required CardsRowType rowType,
}) {
  final enemySide = owner == PlayerSide.first
      ? PlayerSide.second
      : PlayerSide.first;
  final row = _playerDataOf(data, enemySide).cardsRows[rowType];

  if (row == null || row.totalPoints < _rowScorchThreshold) return const [];

  return _strongest(_candidatesOf(row, enemySide));
}

PlayerData _playerDataOf(GameData data, PlayerSide side) =>
    side == PlayerSide.first ? data.firstPlayerData : data.secondPlayerData;

Iterable<_Candidate> _candidatesOf(CardsRow? row, PlayerSide side) {
  if (row == null) return const [];

  final candidates = <_Candidate>[];
  for (final card in row.cards) {
    if (card.abilities.contains(Ability.hero)) continue;

    final strength = row.pointsOf(card);
    if (strength < 1) continue;

    candidates.add((
      target: ScorchTarget(side: side, rowType: row.type, cardId: card.cardId),
      strength: strength,
    ));
  }
  return candidates;
}

Iterable<ScorchTarget> _strongest(Iterable<_Candidate> candidates) {
  final maxStrength = candidates.fold(
    0,
    (max, candidate) => candidate.strength > max ? candidate.strength : max,
  );
  if (maxStrength < 1) return const [];

  return candidates
      .where((candidate) => candidate.strength == maxStrength)
      .map((candidate) => candidate.target)
      .toList();
}
