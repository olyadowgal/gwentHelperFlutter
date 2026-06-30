# Bloc
- Use **Cubit** for state management.
- State managment should consist of State and SideEffect. Every sideEffect file should extends Equatable implements SideEffect. 
- Screens should listen to Bloc via `BlocBuilder`, `BlocConsumer`, or `BlocListener`.
- Cubits should only manage state and emit new states, never call UI code.
- Side effects (navigation, snackbars, dialogs, etc.) should be handled with `BlocListener` or `BlocConsumer`.
- Cubit methods should follow `onSomethingHappened` naming (e.g. `onLoginClicked`, `onEmailChanged`).

# Imports/Exports
- Relative imports within the same feature.
- Absolute imports across features.

# Parts
- States and events: `part of` corresponding Cubit/Bloc.
- SideEffectHandler: private, part of screen/widget.
- Private widgets in separate files with `part of`.

# Naming
- Classes/Enums: UpperCamelCase
- Files/Directories: snake_case
- Variables/Parameters: lowerCamelCase
- Assets: lowercase_with_underscores
- Architecture specific:
  - Public methods in Cubits should be named `onSomethingHappened`.
  - Methods in services/providers should not start with `on` — instead, describe the action (`login`, `fetchData`).
  - Base side effect class: `<FeatureName>SideEffect`.
  - Side effects should have short, descriptive names (e.g. `ShowSuccessMessage`, `GoToHomeScreen`).

# Code Style
- Entities: final properties, const constructors, copyWith instead of mutable fields.
- Use simplest collection type (`Iterable > List`).
- Prefer private members.
- Avoid `as`, prefer `is`.
- Use `??`, `?.`, cascades, spread operators, raw strings.
- `debugPrint()` not `print()`.
- Use string interpolation.
- Use `ListView.builder` for long lists.
- Use `SizedBox` for spacing (no margins).
- Prefer `const` constructors/objects.
- No `new` keyword.
- Use trailing commas.
- Prefer `case final` in switch/if to avoid `!` operator and improve readability.

# Architecture
- One public widget per file.
- `BlocProvider` and `BlocBuilder` only in screens, not inside Cubits.
- Large constructors: use Args entity.
- Widgets: input via constructor, notify via callbacks.
- No `BuildContext` in Cubits/services.
- No service location in Cubits (use constructor DI).
- Mark new classes/functions with `// TODO: cover with tests`.

# Tests
- Prefer separate `setUp` block per mock.
- Prefer `verifyZeroInteractions` over `verifyNever`.
- Use `MockSideEffectHandler` to test side effects.
- If test uses Given/When/Then, it must be in description.
- In test description wrap member names in backticks ``.
- Order test groups following the order of members in class.

# Member Order
1. Final properties
2. Constructor
3. Private/public named constructors
4. Private/public factories
5. Getters/properties
6. Methods

# UI Design Guidelines
- Follow Material Design guidelines.
- Try to use standard Material widgets.
- Do not use PNG icons, prefer vector icons (e.g. from `flutter_vector_icons` package).
- Do not replace vector icons with images, even if in Figma they are PNGs.
- Use Theme for colors and text styles, not hardcoded values.
- Strings should be in _Strings, not hardcoded in widgets.
- Do not use block function body for widgets. Try using an expression function body as much as possible.
- Add trailing commas for better formatting.

⚠️ No Flutter SDK in Cubit/model layers.
⚠️ Do not create .md files with summary of changes if it was not asked in prompt.