import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'app_theme.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

void main() => runApp(const GwentHelperApp());

class GwentHelperApp extends StatelessWidget {
  /// Null (the default) follows the system locale. Tests pass a fixed
  /// value here instead of relying on platform-locale test doubles, which
  /// don't reliably propagate through MaterialApp's locale resolution.
  final Locale? locale;

  const GwentHelperApp({super.key, this.locale});

  @override
  Widget build(BuildContext context) => RepositoryProvider(
    create: (_) => GwentRepository(),
    child: MaterialApp.router(
      title: 'GwentHelper',
      routerConfig: appRouter,
      theme: AppTheme.data,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Flutter's default resolution falls back to the *first* entry in
      // supportedLocales (alphabetically "de") when nothing matches the
      // device's locales, not necessarily English. English is this app's
      // base language, so it's the explicit, deterministic fallback here.
      localeListResolutionCallback: (deviceLocales, supportedLocales) {
        for (final deviceLocale in deviceLocales ?? const <Locale>[]) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
    ),
  );
}
