import 'list_extensions.dart';

/// Should be mixed with some class to mark it as side effect
mixin SideEffect {}

/// Should be mixed with state.
/// S - State class.
/// E - Side effect class.
mixin WithSideEffects<S, E extends SideEffect> {
  List<E> get sideEffects;

  S operator +(E sideEffect) => withSideEffects(sideEffects + [sideEffect]);

  S operator -(E sideEffect) => withSideEffects(sideEffects - [sideEffect]);

  /// Must implement this in each state and return same state but with new sideEffects.
  S withSideEffects(List<E> sideEffects);
}

mixin ShowErrorMessage implements SideEffect {
  String get message;
}
