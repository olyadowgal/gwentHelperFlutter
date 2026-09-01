import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gwent_helper_flutter/data/gwent_repository.dart';
import 'app_theme.dart';
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
      theme: AppTheme.data,
    ),
  );
}
