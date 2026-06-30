# State Management

## Cubit

The app uses [flutter_bloc](https://pub.dev/packages/flutter_bloc) with **Cubit** (a simplified BLoC with no explicit events). Each feature has a `<FeatureName>Cubit` that holds state and exposes methods the UI calls.

- **UI → Cubit:** call a method like `cubit.onLoginClicked()`
- **Cubit → UI:** emit a new state; `BlocBuilder` or `BlocConsumer` rebuilds the widget
- **Cubit public methods** are named `onSomethingHappened` (e.g. `onEmailChanged`, `onSubmitTapped`)
- **No `BuildContext`** inside Cubits — they never call UI code directly

## Custom Side Effects

Some events are one-shot and don't belong in persistent state: showing a snackbar, navigating to another screen, dismissing a dialog. These are handled with a custom **SideEffect** pattern built on top of Cubit.

### How it works

1. Each feature defines a sealed class of side effects, e.g.:

```dart
// lib/features/login/cubit/login_side_effect.dart
sealed class LoginSideEffect with SideEffect {}

class GoToHomeScreen extends LoginSideEffect {}
class ShowInvalidCredentialsError extends LoginSideEffect implements ShowErrorMessage {
  @override
  final String message;
  const ShowInvalidCredentialsError(this.message);
}
```

2. The feature's `State` mixes in `WithSideEffects`:

```dart
class LoginState extends Equatable with WithSideEffects<LoginState, LoginSideEffect> {
  final bool isLoading;
  final List<LoginSideEffect> sideEffects;
  // ...
  @override
  LoginState withSideEffects(List<LoginSideEffect> sideEffects) =>
      copyWith(sideEffects: sideEffects);
}
```

3. The Cubit emits a side effect using `+`:

```dart
emit(state + GoToHomeScreen());
```

4. In the screen widget, `BlocSideEffectHandler` listens and handles it:

```dart
BlocSideEffectHandler<LoginCubit, LoginState, LoginSideEffect>(
  listener: (context, sideEffect) {
    switch (sideEffect) {
      case GoToHomeScreen():
        Navigator.of(context).pushReplacement(...);
      case ShowInvalidCredentialsError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  },
  child: ...,
)
```

`BlocSideEffectHandler` automatically removes the side effect from the state after it is consumed (via the `-` operator), so it fires exactly once.

### Base classes

All base types live in `lib/arch/`:

| File | Purpose |
|---|---|
| `side_effect.dart` | `SideEffect` mixin, `WithSideEffects` mixin, `ShowErrorMessage` mixin |
| `bloc_side_effect_handler.dart` | `BlocSideEffectHandler` widget |
| `side_effect_consumed_aware.dart` | Mixin for Cubits that need to react when a side effect is consumed |

### Adding a new side effect

1. Open the feature's `*_side_effect.dart` file and add a new class:
   ```dart
   class ShowSuccessToast extends LoginSideEffect {
     final String message;
     const ShowSuccessToast(this.message);
   }
   ```
2. In the Cubit, emit it: `emit(state + ShowSuccessToast('Saved!'));`
3. In the screen's `BlocSideEffectHandler`, add a `case` for it.

## Widget Integration Rules

- `BlocProvider` and `BlocBuilder` only in **screen** widgets, never inside Cubits or service classes
- Large widget constructors use an `Args` entity instead of many positional parameters
- Side effects for navigation, snackbars, and dialogs always go through `BlocSideEffectHandler`
