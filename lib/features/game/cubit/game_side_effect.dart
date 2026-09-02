import 'package:equatable/equatable.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/domain/models/player_side.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';

sealed class GameSideEffect extends Equatable implements SideEffect {
  const GameSideEffect();

  @override
  List<Object?> get props => [];
}

class ShowAddCardDialog extends GameSideEffect {
  final CardsRowType rowType;

  const ShowAddCardDialog(this.rowType);

  @override
  List<Object?> get props => [rowType];
}

class ShowEditCardDialog extends GameSideEffect {
  final CardsRow row;
  final Card card;

  const ShowEditCardDialog(this.row, this.card);

  @override
  List<Object?> get props => [row, card];
}

class ShowGameOverDialog extends GameSideEffect {
  final Winner winner;

  const ShowGameOverDialog(this.winner);

  @override
  List<Object?> get props => [winner];
}

enum ScorchNoTargetReason { nothingToScorch, rowBelowTen }

class ShowNoScorchTargets extends GameSideEffect {
  final ScorchNoTargetReason reason;

  const ShowNoScorchTargets(this.reason);

  @override
  List<Object?> get props => [reason];
}

class ShowMusterCountDialog extends GameSideEffect {
  final CardsRowType rowType;
  final Card card;
  final PlayerSide owner;

  const ShowMusterCountDialog(this.rowType, this.card, this.owner);

  @override
  List<Object?> get props => [rowType, card, owner];
}

class NavigateBack extends GameSideEffect {
  const NavigateBack();
}

class ShowSaveFailed extends GameSideEffect {
  final String message;

  const ShowSaveFailed(this.message);

  @override
  List<Object?> get props => [message];
}
