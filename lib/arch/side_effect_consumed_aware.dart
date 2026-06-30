import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'side_effect.dart';

mixin SideEffectConsumedAware<S extends WithSideEffects<dynamic, SideEffect>> on BlocBase<S> {
  @protected
  void onSideEffectConsumed(SideEffect sideEffect);

  @override
  void onChange(Change<S> change) {
    super.onChange(change);
    if (change.currentState.sideEffects.length - change.nextState.sideEffects.length == 1) {
      onSideEffectConsumed(change.currentState.sideEffects.first);
    }
  }
}
