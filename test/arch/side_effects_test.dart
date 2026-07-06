import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:gwent_helper_flutter/arch/side_effect_consumed_aware.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_side_effect.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_state.dart';

class _ConsumedAwareCubit extends Cubit<HomeState>
    with SideEffectConsumedAware<HomeState> {
  _ConsumedAwareCubit() : super(const HomeState());

  final consumed = <SideEffect>[];

  void addEffect(HomeSideEffect effect) => emit(state + effect);

  void consumeEffect(HomeSideEffect effect) => emit(state - effect);

  @override
  void onSideEffectConsumed(SideEffect sideEffect) => consumed.add(sideEffect);
}

void main() {
  group('WithSideEffects', () {
    test('+ appends the effect and produces an unequal state', () {
      const initial = HomeState();
      final withEffect = initial + const NavigateToScores();
      expect(withEffect.sideEffects, [const NavigateToScores()]);
      expect(withEffect, isNot(equals(initial)));
    });

    test('- removes the effect', () {
      final withEffect = const HomeState() + const NavigateToScores();
      final consumed = withEffect - const NavigateToScores();
      expect(consumed.sideEffects, isEmpty);
    });

    test('+ preserves existing effects', () {
      const gameEffect = NavigateToGame(
        player1Name: 'A',
        player2Name: 'B',
      );
      final state =
          (const HomeState() + const NavigateToScores()) + gameEffect;
      expect(
        state.sideEffects,
        [const NavigateToScores(), gameEffect],
      );
    });
  });

  group('SideEffectConsumedAware', () {
    test('fires onSideEffectConsumed when one effect is consumed', () {
      final cubit = _ConsumedAwareCubit();
      cubit.addEffect(const NavigateToScores());
      cubit.consumeEffect(const NavigateToScores());
      expect(cubit.consumed, [const NavigateToScores()]);
      cubit.close();
    });

    test('does not fire when an effect is added', () {
      final cubit = _ConsumedAwareCubit();
      cubit.addEffect(const NavigateToScores());
      expect(cubit.consumed, isEmpty);
      cubit.close();
    });
  });
}
