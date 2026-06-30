import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../arch/bloc_side_effect_handler.dart';
import '../cubit/scores_cubit.dart';
import '../cubit/scores_side_effect.dart';
import '../cubit/scores_state.dart';
import '../resources/scores_strings.dart';
import '../widgets/score_card_widget.dart';

class ScoresView extends StatelessWidget {
  const ScoresView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSideEffectHandler<ScoresCubit, ScoresState, ScoresSideEffect>(
        listener: (context, sideEffect) {
          switch (sideEffect) {
            case ShowClearConfirmDialog():
              showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text(ScoresStrings.clearConfirmTitle),
                  content: const Text(ScoresStrings.clearConfirmContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(ScoresStrings.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(ScoresStrings.clear),
                    ),
                  ],
                ),
              ).then((confirmed) {
                if (confirmed == true && context.mounted) {
                  context.read<ScoresCubit>().onClearConfirmed();
                }
              });
          }
        },
        child: BlocBuilder<ScoresCubit, ScoresState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text(ScoresStrings.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: ScoresStrings.clearAll,
                  onPressed: context.read<ScoresCubit>().onClearAllTapped,
                ),
              ],
            ),
            body: switch (state) {
              ScoresState(isLoading: true) =>
                const Center(child: CircularProgressIndicator()),
              ScoresState(errorMessage: final msg) when msg != null =>
                Center(child: Text('Error: $msg')),
              ScoresState(scores: final scores) when scores.isEmpty =>
                const Center(child: Text(ScoresStrings.empty)),
              ScoresState(scores: final scores) => ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) =>
                      ScoreCardWidget(score: scores[index]),
                ),
            },
          ),
        ),
      );
}
