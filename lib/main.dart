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
          title: 'GwentHelper',
          routerConfig: appRouter,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2A4A)),
            useMaterial3: true,
          ),
        ),
      );
}
