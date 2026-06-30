import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: GwentHelperApp()));
}

class GwentHelperApp extends StatelessWidget {
  const GwentHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GwentHelper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2A4A)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
