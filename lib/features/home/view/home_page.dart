import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/gwent_repository.dart';
import '../cubit/home_cubit.dart';
import 'home_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => HomeCubit(repository: context.read<GwentRepository>()),
    child: const HomeView(),
  );
}
