import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/arch/side_effect.dart';
import 'package:mocktail/mocktail.dart';

/// Test double for `BlocSideEffectHandler`.
///
/// Attach to a bloc with [attachSideEffectHandler]; every side effect the
/// bloc emits is recorded as a call, so tests can
/// `verify(() => sideEffectHandler.call(effect)).called(1)`.
class MockSideEffectHandler<E extends SideEffect> extends Mock {
  void call(E sideEffect);
}

/// Forwards every side effect newly appended to the bloc's state to
/// [handler], exactly once each, without mutating the bloc's state.
///
/// Delivery is asynchronous (bloc streams are async broadcast) — tests must
/// `await Future<void>.delayed(Duration.zero)` after acting and before
/// verifying.
StreamSubscription<S> attachSideEffectHandler<
  S extends WithSideEffects<S, E>,
  E extends SideEffect
>(BlocBase<S> bloc, MockSideEffectHandler<E> handler) {
  var reportedCount = bloc.state.sideEffects.length;
  return bloc.stream.listen((state) {
    final effects = state.sideEffects;
    if (effects.length > reportedCount) {
      effects.skip(reportedCount).forEach(handler.call);
    }
    reportedCount = effects.length;
  });
}
