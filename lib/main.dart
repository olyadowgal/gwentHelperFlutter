import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'router.dart';

void main() => runApp(const GwentHelperApp());

class GwentHelperApp extends StatelessWidget {
  const GwentHelperApp({super.key});

  @override
  Widget build(BuildContext context) => RepositoryProvider(
        create: (_) => GwentRepository(),
        child: MaterialApp.router(
          routerConfig: appRouter,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF263238),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1FAA83),
              onPrimary: Color(0xFF263238),
              primaryContainer: Color(0xFF5FDCB3),
              onPrimaryContainer: Color(0xFF263238),
              secondary: Color(0xFFFFCA28),
              onSecondary: Color(0xFF263238),
              secondaryContainer: Color(0xFFC79A00),
              onSecondaryContainer: Color(0xFF263238),
              surface: Color(0xFF37474F),
              onSurface: Colors.white,
              outline: Color(0xFF6C6E6F),
              error: Color(0xFFE31829),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontFamily: 'Vollkorn',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5FDCB3),
                fontSize: 48,
              ),
              headlineLarge: TextStyle(
                fontFamily: 'Vollkorn',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5FDCB3),
                fontSize: 32,
              ),
              headlineMedium: TextStyle(
                fontFamily: 'Vollkorn',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5FDCB3),
                fontSize: 24,
              ),
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 6,
            ),
            useMaterial3: true,
          ),
        ),
      );
}
