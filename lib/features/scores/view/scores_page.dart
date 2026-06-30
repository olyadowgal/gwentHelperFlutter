import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/gwent_repository.dart';
import '../cubit/scores_cubit.dart';
import 'scores_view.dart';

class ScoresPage extends StatelessWidget {
  const ScoresPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            ScoresCubit(repository: context.read<GwentRepository>()),
        child: const ScoresView(),
      );
}
