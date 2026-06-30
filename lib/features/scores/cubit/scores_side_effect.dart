import 'package:equatable/equatable.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';

sealed class ScoresSideEffect extends Equatable implements SideEffect {
  const ScoresSideEffect();

  @override
  List<Object?> get props => [];
}

class ShowClearConfirmDialog extends ScoresSideEffect {
  const ShowClearConfirmDialog();
}
