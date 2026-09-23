import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/features/home/cubit/home_cubit.dart';
import 'package:gwent_helper_flutter/features/home/view/home_view.dart';
import 'package:gwent_helper_flutter/features/home/widgets/player_input_widget.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';

void main() {
  late HomeCubit cubit;

  setUp(() => cubit = HomeCubit());
  tearDown(() => cubit.close());

  Future<void> pumpHomeView(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(2400, 1080)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<HomeCubit>.value(
          value: cubit,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pump();
  }

  group('HomeView photo source dialog', () {
    testWidgets(
      '''
      Given the home screen is rendered
      When a player's avatar is tapped
      Then a dialog offers Camera and Gallery
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);

        // When
        await tester.tap(find.byType(PlayerInputWidget).first);
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Choose Photo'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Gallery'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given the photo source dialog is open
      When the barrier is tapped
      Then the dialog closes without changing either photo
      ''',
      (tester) async {
        // Given
        await pumpHomeView(tester);
        await tester.tap(find.byType(PlayerInputWidget).first);
        await tester.pumpAndSettle();

        // When
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Choose Photo'), findsNothing);
        expect(cubit.state.player1PhotoPath, isNull);
        expect(cubit.state.player2PhotoPath, isNull);
      },
    );
  });
}
