# Adding a Feature

This is a step-by-step walkthrough for adding a new screen or flow to the app. All features follow the same structure — the example below adds a hypothetical "Notifications" screen.

The structure is standard Flutter architecture called **Bloc + SideEffect**. SideEffects handle one-time events (showing an alert, dialog, or error snackbar) that should not be repeated on every rebuild. They are optional, but it's better to add them even to screens that don't need them yet — this makes it easier to scale the screen later without refactoring the state layer.

## File Structure to Create

```
lib/features/notifications/
├── cubit/
│   ├── notifications_cubit.dart
│   ├── notifications_state.dart
│   └── notifications_side_effect.dart
├── model/
│   └── notifications_repository.dart
├── resources/
│   └── notifications_strings.dart
├── view/
│   ├── notifications_page.dart   ← provides Cubit, registered in router
│   └── notifications_view.dart   ← the actual UI, reads from Cubit
└── widgets/
    └── notification_item.dart    ← private widgets (if needed)
```

## Step 1: Side Effects

Create `lib/features/notifications/cubit/notifications_side_effect.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../../arch/side_effect.dart';

sealed class NotificationsSideEffect extends Equatable implements SideEffect {
  const NotificationsSideEffect();

  @override
  List<Object?> get props => [];
}

class ShowNotificationDetail extends NotificationsSideEffect {
  final String notificationId;
  const ShowNotificationDetail(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class ShowLoadError extends NotificationsSideEffect {
  final String message;
  const ShowLoadError(this.message);

  @override
  List<Object> get props => [message];
}
```

## Step 2: State

Create `lib/features/notifications/cubit/notifications_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../../arch/side_effect.dart';
import 'notifications_side_effect.dart';

final class NotificationsState extends Equatable
    with WithSideEffects<NotificationsState, NotificationsSideEffect> {
  final bool isLoading;
  final List<String> items;        // replace with your model type
  @override
  final List<NotificationsSideEffect> sideEffects;

  const NotificationsState({
    this.isLoading = false,
    this.items = const [],
    this.sideEffects = const [],
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<String>? items,
    List<NotificationsSideEffect>? sideEffects,
  }) =>
      NotificationsState(
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        sideEffects: sideEffects ?? this.sideEffects,
      );

  @override
  NotificationsState withSideEffects(List<NotificationsSideEffect> sideEffects) =>
      copyWith(sideEffects: sideEffects);

  @override
  List<Object?> get props => [isLoading, items, sideEffects];
}
```

## Step 3: Repository

Create `lib/features/notifications/model/notifications_repository.dart`. Repositories take datasources as constructor arguments and return domain objects:

```dart
import '../../../data/datasources/notifications_data_source.dart';  // create if needed

class NotificationsRepository {
  final NotificationsDataSource _dataSource;

  NotificationsRepository({required NotificationsDataSource dataSource})
      : _dataSource = dataSource;

  Future<List<String>> fetchNotifications() => _dataSource.getAll();
}
```

If you need a new API endpoint, add it as a method on an existing datasource in `lib/data/datasources/`, or create a new one that takes `StreetIQApiClient` as a dependency.

## Step 4: Cubit

Create `lib/features/notifications/cubit/notifications_cubit.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/notifications_repository.dart';
import 'notifications_state.dart';
import 'notifications_side_effect.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsState()) {
    onScreenOpened();
  }

  Future<void> onScreenOpened() async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _repository.fetchNotifications();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (e) {
      emit(state.copyWith(isLoading: false) + ShowLoadError(e.toString()));
    }
  }

  void onNotificationTapped(String id) {
    emit(state + ShowNotificationDetail(id));
  }
}
```

## Step 5: Page (dependency provider)

Create `lib/features/notifications/view/notifications_page.dart`. The Page's only job is to provide the Cubit and its dependencies — no UI here:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notifications_cubit.dart';
import '../model/notifications_repository.dart';
import 'notifications_view.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Page<void> page() =>
      const MaterialPage<void>(child: NotificationsPage());

  @override
  Widget build(BuildContext context) => RepositoryProvider(
        create: (context) => NotificationsRepository(
          dataSource: context.read(),   // must be registered in app.dart
        ),
        child: Builder(
          builder: (context) => BlocProvider(
            create: (context) =>
                NotificationsCubit(repository: context.read()),
            child: const NotificationsView(),
          ),
        ),
      );
}
```

## Step 6: View (UI)

Create `lib/features/notifications/view/notifications_view.dart`. Use `BlocConsumer` when you need both rebuilds and side effect handling, or `BlocBuilder` + `BlocSideEffectHandler` separately:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../arch/bloc_side_effect_handler.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_side_effect.dart';
import '../cubit/notifications_state.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) => BlocSideEffectHandler<
          NotificationsCubit, NotificationsState, NotificationsSideEffect>(
        listener: (context, sideEffect) {
          switch (sideEffect) {
            case ShowNotificationDetail(:final notificationId):
              // navigate to detail screen
              Navigator.of(context).pushNamed('/notification_detail',
                  arguments: notificationId);
            case ShowLoadError(:final message):
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(state.items[index]),
                      onTap: () => context
                          .read<NotificationsCubit>()
                          .onNotificationTapped(state.items[index]),
                    ),
                  ),
          ),
        ),
      );
}
```

## Step 7: Register in the Router

Open `lib/app/view/app_view.dart` and add your route to `onGenerateRoute`:

```dart
case '/notifications':
  return NotificationsPage.page().createRoute(context);
```

To navigate to it from anywhere:

```dart
Navigator.of(context).pushNamed('/notifications');
```

To navigate from a side effect inside another feature's `BlocSideEffectHandler`, emit the side effect from the Cubit and handle it in the listener the same way.

## Step 8: Register the Datasource (if new)

If you created a new datasource, register it in `lib/app/view/app.dart` inside `MultiRepositoryProvider`:

```dart
RepositoryProvider(
  create: (context) => NotificationsDataSource(
    apiClient: context.read<StreetIQApiClient>(),
  ),
),
```

Add it before any repository or service that depends on it — the list is read top-to-bottom.

## Strings

Put all user-visible strings in a `_Strings` private class inside the feature's `resources/` folder, not hardcoded in widgets:

```dart
// lib/features/notifications/resources/notifications_strings.dart
abstract class _Strings {
  static const title = 'Notifications';
  static const emptyState = 'No notifications yet';
}
```

## Checklist

- [ ] Side effect class created
- [ ] State class created with `WithSideEffects` mixin
- [ ] Repository created (takes datasources, not API clients directly)
- [ ] Cubit created (methods named `onSomethingHappened`)
- [ ] Page created (only provides Cubit + deps, no UI)
- [ ] View created (UI only, no business logic)
- [ ] Route added to `app_view.dart`
- [ ] New datasource registered in `app.dart` (if applicable)
- [ ] Strings in resources file, not hardcoded
